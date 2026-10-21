// ============================================================
// telegram_user_state.dart
// Estado de vinculación de Telegram para un usuario concreto.
//
// Se combina la información de dos documentos:
//   - `users/{uid}`            → `telegramLinked`, `telegramChatId`,
//                                 `username` (el de Monedo)
//   - `telegram_links/{uid}`   → la relación chat_id <-> uid y el
//                                 @usuario de Telegram
// ============================================================

class TelegramUserState {
  /// UID de Firebase Auth del usuario.
  final String uid;

  /// Si la cuenta está vinculada a un chat de Telegram.
  ///
  /// Es `true` si el documento del usuario dice `telegramLinked` o si
  /// existe el registro del chat: cualquiera de las dos fuentes basta,
  /// así el estado es correcto aunque el bot escriba solo una.
  final bool linked;

  /// Campo `telegramChatId` del documento del usuario. Es el `chat.id`
  /// de Telegram; se guarda como texto porque puede llegar como número.
  final String? chatId;

  /// Nombre de usuario de Monedo. Se usa en el comando `/vincular`
  /// para que el bot sepa a qué cuenta enlazar el chat.
  final String? monedoUsername;

  /// @usuario de Telegram, leído del registro de `telegram_links`.
  final String? telegramUsername;

  const TelegramUserState({
    required this.uid,
    required this.linked,
    this.chatId,
    this.monedoUsername,
    this.telegramUsername,
  });

  /// Nombre visible de la cuenta de Telegram conectada: el @usuario si
  /// existe, y si no el ID de chat. `null` si no hay ninguno de los dos.
  String? get connectedName {
    final user = telegramUsername?.trim();
    if (user != null && user.isNotEmpty) return '@$user';
    final id = chatId?.trim();
    if (id != null && id.isNotEmpty) return 'ID $id';
    return null;
  }
}
