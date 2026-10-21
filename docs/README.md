# Documentación de la integración con Telegram

Estos documentos describen el módulo de Telegram de Monedo: un bot que
recibe audios o textos, los interpreta con IA y registra el movimiento
en Firestore.

| Documento | Para qué sirve |
| --- | --- |
| [bot-telegram.md](bot-telegram.md) | El contrato: qué documentos y campos escribe el bot, en qué orden, y por qué. **Léelo si escribes el bot.** |
| [prompt-n8n.md](prompt-n8n.md) | Un prompt listo para Claude que corrige el flujo de n8n existente para que cumpla el contrato. **Pégalo junto con el JSON de tu flujo.** |

## Resumen en cinco líneas

1. La app genera un PIN de 6 dígitos y lo guarda en `telegram_pins/{pin}`
   con 5 minutos de validez.
2. El usuario manda `/vincular <usuario> <PIN>` al bot.
3. El bot valida el PIN, comprueba que sea del usuario que dice, y
   escribe el vínculo en `telegram_links/{chatId}` y
   `users/{uid}.telegramLinked`.
4. La app lo ve al instante (Firestore empuja el cambio) y muestra la
   tarjeta de "conectado" con el botón de desvincular.
5. Cuando mandas un audio o un texto, el bot usa
   `users/{uid}.enabledCategories` para elegir la categoría y guarda el
   movimiento en `transactions`.

## Lo que hay en la app

| Archivo | Qué hace |
| --- | --- |
| `lib/services/telegram_link_service.dart` | Genera el PIN, lee el estado de vinculación en tiempo real y desvincula. |
| `lib/services/enabled_categories_service.dart` | Publica las categorías que el usuario puede elegir, para que el bot las use. |
| `lib/widgets/telegram_link_dialog.dart` | El modal con el PIN, la cuenta atrás y el comando. |
| `lib/widgets/telegram_link_section.dart` | La tarjeta de ajustes: conectar y desconectar. |
| `firestore.rules` | Las reglas de seguridad de las colecciones del módulo. |

## Herramientas de verificación

| Comando | Qué comprueba |
| --- | --- |
| `node tools/firestore_rules_test.js` | Que las reglas de seguridad permiten y deniegan lo que deben. |
| `node tools/run_firestore_live_probe.js` | Las operaciones de Telegram contra el Firestore real, con un usuario desechable. |
