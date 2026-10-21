# Prompt para Claude: corregir el flujo n8n del bot de Telegram

Copia y pega el bloque de abajo en Claude, junto con el JSON de tu
flujo de n8n. Está escrito para que Claude pueda aplicarlo sin
preguntar nada.

---

## El prompt

````
Tengo un flujo de n8n para un bot de Telegram que se llama Monedo y
que registra gastos en una app de finanzas personales (Flutter +
Firestore, proyecto `monedo-e7849`). Ya funciona: recibe un audio o
un texto, se lo pasa a Gemini, guarda el movimiento en Firestore y
responde por Telegram.

Necesito que modifiques el flujo para que la app de Monedo sepa que la
cuenta quedó vinculada, y para que la IA elija la categoría usando las
categorías reales del usuario en vez de una lista fija.

Te paso el flujo completo en JSON más abajo. Trabaja sobre él y
devuélveme el JSON del flujo ya modificado, nodo por nodo.

### DATO CLAVE: de dónde saca el usuario sus categorías

La app tiene dos tipos de categorías:

1. **Las predeterminadas** (15 en total): Alimentación, Transporte,
   Entretenimiento, Salud, Educación, Ropa, Hogar, Niños, Mascotas,
   Gasolina, Trabajo, Inversión, Ahorro, Otros y Transferencia.
   `Transferencia` es de sistema: la pone la app sola al mover dinero
   entre bolsillos, nunca se elige a mano.
2. **Las propias del usuario**, que creates en la app.

La app publica en `users/{uid}.enabledCategories` la lista final de
categorías que el usuario puede elegir en ese momento: las
predeterminadas que no ha desactivado, más sus propias. **Ese campo
es la fuente de verdad y ya se actualiza solo**, así que el flujo no
debe mantener ninguna lista de categorías: hay que leer ese campo.

Ojo: el campo NO existe todavía en los usuarios que ya están
registrados (solo se escribe desde la app al cambiar algo o al
terminar la configuración inicial). Si el campo no existe o viene
vacío, usa la lista de predeterminadas de arriba, menos
`Transferencia`.

### CAMBIOS QUE HAY QUE HACER

#### 1) Rama `/vincular`: verificar que el PIN es de quien dice ser

Hoy se lee `telegram_pins/{pin}` y se valida que exista, que no esté
usado y que no haya expirado, pero **no se comprueba que el
`<usuario>` que escribió el comando sea el dueño del PIN**. Con eso,
cualquiera puede vincular su Telegram a la cuenta de otro con un PIN
que se robe.

Añade un nodo que lea `users/{uid}` (el `uid` sale del propio
documento del PIN, no del texto del comando) y compara su campo
`username` con el `<usuario>` que escribió el comando. Si no coinciden,
responde "ese código no es tuyo" y no continues con la vinculación.

#### 2) Rama `/vincular`: avisar a la app (esto es lo que faltaba)

Hoy el flujo solo marca `used = true` en el PIN. **La app nunca se
entera de que quedó vinculada**, porque no lee ese campo: lee
`users/{uid}.telegramLinked`.

Después de validar el PIN, añade estas dos escrituras:

**2.a. Crear el registro del vínculo.** Documento
`telegram_links/{chatId}`, donde `{chatId}` es `message.chat.id` del
mensaje de Telegram:

```json
{
  "chatId": "<chat.id>",
  "uid": "<uid del PIN>",
  "username": "<message.from.username, opcional>",
  "linkedAt": "<ISO-8601>"
}
```

La clave del documento es el **chat id**, no el uid, a propósito: así un
mismo chat no puede quedar vinculado a dos cuentas distintas, y el
bot resuelve "de qué cuenta es este chat" con una lectura directa por
ID en vez de una consulta.

**2.b. Actualizar el documento del usuario.** `users/{uid}`, con
**solo estos dos campos**:

```json
{ "telegramLinked": true, "telegramChatId": "<chat.id>" }
```

**AVISO IMPORTANTE**: esta escritura tiene que ser un *update*
parcial, no un *set* completo. Si el nodo "Update Document" de n8n
reemplaza el documento entero, se borran `username`, `email`, `currency`
y `createdAt` de la cuenta y el usuario se queda sin nombre de usuario.
Si el nodo hace eso, usa el nodo **HTTP Request** con la API REST de
Firestore, que hace PATCH:

```
PATCH https://firestore.googleapis.com/v1/projects/monedo-e7849/databases/(default)/documents/users/{{ $json.uid }}
     ?updateMask.fieldPaths=telegramLinked
     &updateMask.fieldPaths=telegramChatId
Authorization: Bearer <service account token>
Content-Type: application/json

{ "fields": { "telegramLinked": { "booleanValue": true },
              "telegramChatId": { "stringValue": "123456789" } } }
```

Lo mismo para `telegram_links/{chatId}`, que se crea con POST:

```
POST https://firestore.googleapis.com/v1/projects/monedo-e7849/databases/(default)/documents/telegram_links?documentId={{ $json.chatId }}
```

#### 3) Rama `/vincular`: borrar el PIN

Una vez escrito el vínculo, borra el documento
`telegram_pins/{pin}` (nodo Firestore "Delete a document"). Su ID *es*
el PIN, así que mientras el documento exista el PIN sigue siendo una
clave de consulta válida, y encima guarda qué PIN usó cada usuario
para siempre.

El paso 3 (borrar) va **el último** de la rama: si el flujo se rompe
antes, el PIN queda marcado como usado y el usuario pide otro. Mejor
un bother que un agujero de seguridad.

El orden completo de la rama `/vincular` queda:

1. Validar el PIN (existe, no usado, no expirado) y que el usuario
   coincida con el `uid` del PIN.
2. Marcar `telegram_pins/{pin}.used = true`.
3. Crear `telegram_links/{chatId}`.
4. Actualizar `users/{uid}` con `telegramLinked` y `telegramChatId`.
5. Borrar `telegram_pins/{pin}`.
6. Responder por Telegram.

#### 4) Rama de mensajes: resolver el chat con la nueva tabla

Hoy el nodo "Usuario" busca el uid con una consulta a
`telegram_pins` filtrando por `telegramChatId`. Como ahora el índice
está en `telegram_links`, **sustituye ese nodo por una lectura
directa** del documento `telegram_links/{chatId}` (nodo Firestore
"Get a document", con `documentId = {{ $json.message.chat.id }}`).

El `uid` sale del campo `uid` de ese documento. Si el documento no
existe, el chat no está vinculado: sigue el camino "Aviso no
vinculado" que ya tienes.

Además, en esa misma rama añade una lectura de `users/{uid}` para dos
cosas:

- Comprobar que `telegramLinked` sigue en `true`. Si el usuario
  desconectó la cuenta desde la app, el campo ya está en `false` y el
  bot debe ignorar el mensaje en vez de seguir anotando movimientos.
- Leer `enabledCategories` (ver el punto 5).

#### 5) La IA debe usar las categorías del usuario

En el nodo "Preparar contexto", **elimina la constante `CATEGORIAS`
que está hardcodeada** y usa la lista que viene de
`users/{uid}.enabledCategories`.

Reglas para la lista:

- Si `enabledCategories` existe y no está vacío, úsala tal cual.
- Si no existe o está vacía, usa esta lista de respaldo (las
  predeterminadas menos `Transferencia`):
  `["Alimentación","Transporte","Entretenimiento","Salud","Educación","Ropa","Hogar","Niños","Mascotas","Gasolina","Trabajo","Inversión","Ahorro","Otros"]`
- `Transferencia` **nunca** va en la lista: es de sistema.

El prompt de Gemini queda así (sustituye el bloque de categorías del
prompt actual):

```
Eres un asistente de finanzas personales. Extrae UN movimiento de lo que dice el usuario (audio o texto).
Fecha de hoy: ${hoy}. Moneda: pesos colombianos (COP).

Categorías válidas (las que este usuario tiene habilitadas en su app): ${categoriasJson}
Cuentas válidas: ${cuentasJson}

Reglas:
- "22 mil" = 22000, "una luca" = 1000, "2 palos" = 2000000.
- isIncome=true solo si es un ingreso (me pagaron, recibí, salario...).
- isTransfer=true solo si mueve plata entre cuentas propias; en ese caso indica transferAccountId.
- Si no menciona cuenta, usa la primera de la lista.
- Si no menciona fecha, usa la de hoy; "ayer" = hoy menos un día.
- title: descripción corta (ej. "Hamburguesa"). note: null salvo que haya un detalle extra.
- Elige SIEMPRE una categoría de la lista: si ninguna encaja, usa "Otros".
- Si NO hay un movimiento claro, responde {"error":"no_entendido"}.

Responde SOLO con JSON, sin texto ni bloques de código:
{"accountId":"","amount":0,"category":"","date":"YYYY-MM-DD","isIncome":false,"isTransfer":false,"note":null,"title":"","transferAccountId":null}
```

#### 6) Lo que NO hay que tocar

- El nodo "Gemini audio" y "Gemini texto": se quedan igual.
- El nodo "Guardar movimiento": los campos que escribe
  (`accountId, amount, category, date, goalId, isIncome, isTransfer,
  note, title, transferAccountId, userId`) ya coinciden con el modelo
  de la app. No lo cambies.
- El nodo "Cuentas": sigue consultando `accounts` por `userId`.
- La clave del documento de `transactions` la genera Firestore.

### CÓMO VERIFICAR QUE QUEDÓ BIEN

Después de aplicar los cambios, estas cuatro comprobaciones tienen que
darse:

1. `/vincular <usuario> <pin>` correcto → el bot responde que quedó
   vinculada, `users/{uid}.telegramLinked` queda en `true`,
   `users/{uid}.telegramChatId` tiene el chat, existe
   `telegram_links/{chatId}` con el `uid` correcto, y el documento del
   PIN desaparece.
2. En la app, Ajustes → Asistente de IA, la tarjeta pasa a "Telegram
   conectado" con el botón de desvincular, sin recargar.
3. `/vincular <usuario equivocado> <pin>` → el bot responde "ese
   código no es tuyo" y no vincula nada.
4. Un audio o un texto suelto desde un chat vinculado → el bot registra
   el movimiento con una categoría de la lista de `enabledCategories` del
   usuario, y desde un chat no vinculado responde lo de "Primero vincula
   tu cuenta".

Devuélveme el JSON del flujo completo modificado y una lista de los
nodos que has añadido, quitado o cambiado.
````

---

## Nota sobre el orden de las escrituras

n8n no puede hacer una transacción multidocumento, así que la
seguridad no viene de la atomicidad sino del **orden**: en todo
momento el usuario queda en un estado recuperable.

| Orden | Escritura | Qué pasa si falla aquí |
| --- | --- | --- |
| 1 | `telegram_pins/{pin}.used = true` | El PIN queda consumido y el usuario pide otro. Molestia, no agujero. |
| 2 | `telegram_links/{chatId}` | La cuenta ya está vinculada: la app lo detecta aunque `telegramLinked` siga en `false`. |
| 3 | `users/{uid}` | Igual que el anterior. |
| 4 | `telegram_pins/{pin}` (borrar) | El PIN queda marcado como usado y la app lo purga en la siguiente generación. |

Por eso el registro del chat va **antes** que el documento del
usuario: `telegram_links` es el que la app usa como segunda fuente
para saber que la cuenta quedó vinculada.
