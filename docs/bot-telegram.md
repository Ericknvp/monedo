# Contrato del bot de Telegram

Lo que el bot (hoy automatizado con **n8n**) tiene que hacer para que
la app de Monedo refleje la vinculación. Cualquier paso que no esté en
esta lista, la app no lo ve.

## 1. Colecciones y documentos

```
telegram_pins/{pin}          lo crea la app, lo canjea el bot
  pin:       string    "839201"       (el ID del documento ES el PIN)
  uid:       string    "abc123..."    (dueño del PIN)
  createdAt: timestamp (serverTimestamp)
  expiresAt: timestamp (ahora + 5 minutos)
  used:      bool      false

telegram_links/{uid}         lo escribe el bot
  chatId:    string    "123456789"    (chat.id de Telegram)
  username:  string    "usuario_tg"   (@usuario, opcional)
  linkedAt:  timestamp (serverTimestamp)

users/{uid}                  lo escribe el bot (parcial)
  telegramLinked: bool      true
  telegramChatId: string    "123456789"
```

`users/{uid}` ya lo crea la app con `username`, `email`, `createdAt` y
`currency`: el bot solo tiene que **añadir** los dos campos de
Telegram, nunca reescribir el documento entero.

## 2. Flujo de vinculación

El usuario envía al bot:

```
/vincular <usuario_de_monedo> <PIN>
```

Por ejemplo `/vincular narva 839201`.

### 2.1 Lectura previa (validación)

Leer `telegram_pins/{PIN}` y comprobar, en este orden:

| Comprobación | Si falla, el bot responde |
| --- | --- |
| el documento existe | "ese código no es válido" |
| `expiresAt` no ha pasado | "el código expiró" |
| `used != true` | "ese código ya se usó" |
| `uid` corresponde al `<usuario>` recibido | "ese código no es tuyo" |

El `uid` **no lo escribe el usuario**: sale del propio documento del PIN.
Ese es el motivo de que el PIN lleve dentro el `uid`.

### 2.2 Escrituras, EN ESTE ORDEN

n8n no puede hacer una transacción multidocumento, así que la seguridad
no viene de la atomicidad sino del **orden**: en todo momento el
usuario queda en un estado que se puede recuperar.

| # | Documento | Operación | Por qué aquí |
| --- | --- | --- | --- |
| 1 | `telegram_pins/{PIN}` | update `used = true` | Primero, para que el PIN no se pueda reutilizar aunque el flujo falle después. Si el flujo revienta aquí, el usuario pide un PIN nuevo: molestia, no agujero de seguridad. |
| 2 | `telegram_links/{uid}` | create/set | La relación chat ↔ cuenta. Es lo que permite al bot resolver de qué usuario es cada chat. |
| 3 | `users/{uid}` | update | El estado que lee la app: `telegramLinked` y `telegramChatId`. |
| 4 | `telegram_pins/{PIN}` | delete | Última, porque es la única que se puede perder sin daño: si falla, el PIN queda con `used = true` y la app lo purga en la siguiente generación. |

Si el flujo muere entre los pasos 2 y 3, la cuenta **ya está
vinculada**: la app lo detecta porque el estado se deriva de
`telegram_links/{uid}` aunque `telegramLinked` siga en `false`.

> Por qué se borra el PIN en el paso 4: su ID *es* el PIN, así que
> mientras el documento exista el PIN sigue siendo una clave de
> consulta válida. Dejarlo convierte `telegram_pins` en un registro
> permanente de qué PIN usó cada usuario. Además, nada en la app borra
> los PINs ya canjeados por su cuenta, y sin una política de TTL se
> acumulan para siempre.

## 3. Resolver qué usuario es el que escribe

Cuando el usuario mande un audio (o un texto), el bot tiene que saber a
qué cuenta de Monedo pertenece ese chat. Dos opciones:

- **Consultar Firestore**: `telegram_links` con filtro
  `chatId == <chat.id>`. Es un índice de campo simple, automático, y no
  necesita índice compuesto.
- **Guardarlo en el propio n8n** (Data Table con `chat_id → uid`).

Da igual cuál, pero **el estado de la vinculación siempre se lee de
Firestore**. Antes de procesar un audio, el bot comprueba que
`users/{uid}.telegramLinked == true`. Si el usuario desvinculó la
cuenta desde la app, el campo ya está en `false` y el bot debe
ignorar el mensaje. Sin esa comprobación, el bot seguiría anotando
movimientos de una cuenta que el usuario ya desconectó.

## 4. Desvincular

La desvinculación la hace **la app**, no el bot. Cuando el usuario la
pide desde Ajustes:

- se borra `telegram_links/{uid}`
- se pone `users/{uid}.telegramLinked = false` y `telegramChatId = null`

El bot no tiene que hacer nada: si guarda su propia tabla
`chat_id → uid`, puede seguir resolviendo el chat, pero la comprobación
de `telegramLinked` lo impide actuar.

## 5. Índice y TTL (opcional pero recomendado)

- **TTL sobre `expiresAt`** en `telegram_pins`: borra automáticamente
  los PINs que nadie canjeó. Es configuración de la consola de
  Firebase, no código. Es la red de seguridad para los PINs que el
  usuario generan y abandonan.
- No hace falta ningún índice compuesto: todas las consultas del bot
  son de igualdad sobre un solo campo.

## 7. Resumen de las escrituras del bot

| # | Documento | Operación | Campos |
| --- | --- | --- | --- |
| 1 | `telegram_pins/{PIN}` | update | `used = true` |
| 2 | `telegram_links/{uid}` | create/set | `chatId`, `username`, `linkedAt` |
| 3 | `users/{uid}` | update | `telegramLinked = true`, `telegramChatId` |
| 4 | `telegram_pins/{PIN}` | delete | — |

## 8. Guía rápida para n8n

### 8.1 Los campos, exactamente

**`users/{uid}`** — update (no set):

```json
{ "telegramLinked": true, "telegramChatId": "123456789" }
```

**`telegram_links/{uid}`** — create/set:

```json
{
  "chatId": "123456789",
  "username": "usuario_tg",
  "linkedAt": "2026-10-21T05:22:12.311Z"
}
```

**`telegram_pins/{PIN}`** — update: `{ "used": true }`, y después delete.

El `uid` sale de `telegram_pins/{PIN}.uid`. El `chatId` sale del mensaje
de Telegram (`chat.id`).

### 8.2 Cuidado con el nodo de Firestore de n8n

El nodo **Update Document** de n8n puede reemplazar el documento
entero en vez de fusionar campos. Si hace eso sobre `users/{uid}`,
**borra `username`, `email`, `currency` y `createdAt`**, y la cuenta
aparece sin nombre de usuario.

La forma segura de no arriesgarse es usar el nodo **HTTP Request** con
la API REST de Firestore, que hace un `PATCH` parcial:

```
PATCH https://firestore.googleapis.com/v1/projects/monedo-e7849/databases/(default)/documents/users/{{ $json.uid }}
     ?updateMask.fieldPaths=telegramLinked
     &updateMask.fieldPaths=telegramChatId
Authorization: Bearer <token de servicio>
Content-Type: application/json

{ "fields": { "telegramLinked": { "booleanValue": true },
              "telegramChatId": { "stringValue": "123456789" } } }
```

Lo mismo para `telegram_links/{uid}`, con `createDocument` en `POST`
(`https://firestore.googleapis.com/v1/projects/.../documents/telegram_links?documentId={{ $json.uid }}`).

Si prefieres el nodo de Firestore, comprueba antes en un documento de
prueba que un "Update Document" **no** borre los campos que no
mencionas.

### 8.3 Fechas

`linkedAt` se puede guardar como texto ISO-8601: la app lo lee y lo
convierte igual que si fuera un timestamp de Firestore. Si prefieres
guardarlo como timestamp nativo con la API REST, el valor es:

```json
{ "linkedAt": { "timestampValue": "2026-10-21T05:22:12.311Z" } }
```

## 9. Lo que NO debe hacer el bot

- **No** reescribir `users/{uid}` entero: se perderían `username`,
  `email`, `currency` y `createdAt`. Solo un update de los dos campos.
- **No** escribir `telegram_links` desde el cliente de la app: las
  reglas de seguridad lo prohíben a propósito, para que nadie pueda
  vincular un chat ajeno a su cuenta.
- **No** dejar el PIN en `telegram_pins` después de canjearlo (ver el
  punto 2.2).

