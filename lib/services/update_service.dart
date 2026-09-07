import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateInfo {
  final String version;
  final String downloadUrl;
  const UpdateInfo({required this.version, required this.downloadUrl});
}

class UpdateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const _kDismissedKey = 'update_dismissed_version';

  // ---- Compara "a.b.c" contra "d.e.f"; > 0 si [a] es más nueva que [b] ----
  int _compareVersions(String a, String b) {
    final pa = a.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final pb = b.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    for (var i = 0; i < pa.length || i < pb.length; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }

  // ---- Consulta si hay una versión más nueva que la instalada ----
  //
  // Lee el documento app_config/version en Firestore (creado y actualizado
  // a mano en cada release: campos `latestVersion` y `downloadUrl`). Si el
  // documento no existe o falla la lectura, devuelve null en silencio: la
  // app nunca debe romperse por este chequeo.
  Future<UpdateInfo?> checkForUpdate() async {
    try {
      final doc =
          await _firestore.collection('app_config').doc('version').get();
      final data = doc.data();
      if (data == null) return null;

      final latestVersion = data['latestVersion'] as String?;
      final downloadUrl = data['downloadUrl'] as String?;
      if (latestVersion == null || downloadUrl == null) return null;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (_compareVersions(latestVersion, currentVersion) <= 0) return null;
      return UpdateInfo(version: latestVersion, downloadUrl: downloadUrl);
    } catch (_) {
      return null;
    }
  }

  // ---- Recuerda que el usuario ya vio el aviso de esta versión ----
  Future<void> dismissVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDismissedKey, version);
  }

  Future<bool> wasDismissed(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDismissedKey) == version;
  }
}
