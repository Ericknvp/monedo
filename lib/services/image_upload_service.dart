import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Sube imágenes a Cloudinary (plan gratuito, sin necesitar el plan Blaze de
/// Firebase). Usa un upload preset "unsigned": no expone ningún secreto, solo
/// el cloud name y el nombre del preset, que son públicos por diseño.
///
/// Configura estos dos valores desde tu cuenta de Cloudinary:
/// Dashboard → "Cloud name" / Settings → Upload → Upload presets (Unsigned).
class ImageUploadService {
  static const String _cloudName = 'ousqumer';
  static const String _uploadPreset = 'monedo_goals';

  /// Sube [file] y devuelve la URL pública de la imagen, o null si falla.
  //
  // Se usa fromBytes (no fromPath) para que funcione igual en web, donde
  // XFile.path es una blob URL y no una ruta real de archivo.
  Future<String?> uploadImage(XFile file) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final bytes = await file.readAsBytes();
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: file.name));

    final response = await request.send();
    if (response.statusCode != 200) return null;

    final body = jsonDecode(await response.stream.bytesToString());
    return body['secure_url'] as String?;
  }
}
