# Cambios pendientes en el flujo de n8n

Diagnóstico a 2026-10-21, sobre el flujo tal y como quedó tras aplicar
`prompt-n8n.md`. **El bot no registra ningún movimiento**: el flujo muere
antes de "Guardar movimiento" y, como ningún nodo tiene manejo de
errores, cada fallo es silencio.

Hay **4 cosas** que arreglar. La primera es una regresión que se coló al
reescribir el flujo.

---

## 1. "Get a file" volvió a dejar de descargar el audio

**Es la causa más probable de que no funcione con audios.**

En el flujo original, el nodo Telegram "Get a file" tenía `download:
true`. Al reaplicar el prompt, el nodo se reserializó y esa opción
desapareció: ahora tiene `additionalFields: {}`.

Sin descarga, el nodo "Audio a base64" no encuentra el binario y
`getBinaryDataBuffer(0, 'data')` lanza un error. Como no hay rama de
error, el flujo muere ahí y el usuario no recibe respuesta.

**Arreglo:** en el nodo "Get a file", vuelve a activar la descarga
del archivo. Depending de la versión del nodo es la opción "Download"
en los ajustes, o el parámetro `download: true` (en las versiones
nuevas, `additionalFields.download`).

**Cómo saber que funcionó:** el nodo "Audio a base64" debe recibir un
item con `binary.data` con contenido. Si `binary` viene vacío, la
descarga no está activa.

---

## 2. El nodo "Gemini" se cambió a HTTP crudo y puede estar fallando

El flujo original usaba el nodo de LangChain
(`@n8n/n8n-nodes-langchain.googleGemini`) con `modelId:
gemini-2.5-flash`, que se autentica solo. El flujo actual lo sustituyó
por dos nodos **HTTP Request** con `genericAuthType: httpHeaderAuth`.

Para que Gemini acepte la llamada, la cabecera tiene que ser
exactamente `x-goog-api-key: <TU_API_KEY>`. Si la credencial
"Header Auth account" tiene otro nombre de cabecera o el valor está
mal, Gemini responde 400 y el flujo muere en silencio.

**Arreglo (recomendado): volver al nodo de LangChain.** Es el que ya
funcionaba y no depende de una credencial montada a mano. Se
configura así:

- Nodo **Google Gemini** (LangChain)
- `Model`: `gemini-2.5-flash`
- Para **texto**: `Input Type` = `Message`, y en el mensaje:
  `={{ $('Preparar contexto').first().json.promptTexto }}`
- Para **audio**: `Input Type` = `Binary`, `Binary Property` = `data`

**O, si prefieres mantener el HTTP Request**, comprueba que la
credencial "Header Auth account" envía la cabecera `x-goog-api-key`.

---

## 3. Fallos silenciosos: que el bot siempre conteste

Ahora mismo, si cualquier nodo falla, el usuario no recibe nada y no
hay forma de saber qué pasó. Añade una salida de error al final de
cada rama que hoy muere en silencio.

**Nodos con falta de salida (deben pasar a una salida de error):**

| Nodo | Falta |
| --- | --- |
| `Gemini audio` | salida de error |
| `Gemini texto` | salida de error |
| `Armar movimiento` | salida de error |
| `Get a file` | salida de error |
| `¿Sigue vinculado?` | **salida FALSE entera** |

**"¿Sigue vinculado?" es el caso grave:** solo tiene la salida
`true` → "Cuentas". Si el usuario desvinculó la cuenta desde la app
(`telegramLinked` en `false`), el flujo **termina sin decir nada**.

**Salida FALSE de "¿Sigue vinculado?":** un nodo de Telegram que
conteste algo como

```
Tu cuenta ya no está vinculada con este chat. Vuelve a vincularla desde
la app de Monedo con /vincular TU_NOMBRE TU_PIN
```

y, si quieres que se limpie sola, un nodo de Firestore que borre
`telegram_links/{chatId}` antes de responder.

**Los dos nodos de Gemini, en error, deben contestar** (en vez de
callarse):

```
No pude analizar tu mensaje. Inténtalo de nuevo.
```

---

## 4. El bot no ajusta el saldo del bolsillo

**Esto no es un bug visible todavía, pero lo será en cuanto lo
arregles:** el movimiento se guardará y aparecerá en el listado, pero
el saldo no se moverá.

La app, al añadir un movimiento, hace **dos** cosas
(`lib/services/transaction_service.dart:27`):

```dart
Future<void> addTransaction(TransactionModel transaction) async {
  await _transactions.add(transaction.toMap());
  if (transaction.accountId != null) {
    await _accountService.adjustBalance(
        transaction.accountId!, _signedAmount(transaction));
  }
}
```

El bot solo hace la primera: escribe el documento y ya. El saldo
guardado en `accounts/{id}.balance` se queda como estaba.

**Arreglo:**

**4.a.** En el nodo "Preparar contexto", el código que arma las
cuentas tiene que **conservar el saldo**:

```js
const cuentas = $input.all()
  .map(i => i.json)
  .filter(c => c._id)
  .map(c => ({
    id: c._id,
    name: c.name ?? c.title ?? c.nombre ?? c._id,
    balance: c.balance ?? 0          // <-- esto faltaba
  }));
```

**4.b.** En el nodo "Armar movimiento", calcula el nuevo saldo igual
que lo hace la app (`_signedAmount`: ingreso positivo, gasto
negativo; en una transferencia el `isIncome` va forzado a `false`, así
que el origen pierde el importe):

```js
const cuenta = ctx.cuentas.find(c => c.id === accountId);
const saldoActual = cuenta ? (cuenta.balance ?? 0) : 0;
const delta = isIncome ? amount : -amount;
const nuevoSaldo = saldoActual + delta;
```

y añade al JSON de salida:

```js
nuevoSaldo: nuevoSaldo,
saldoAnterior: saldoActual,
```

**4.c.** Añade un nodo **después** de "Guardar movimiento" que
actualice el bolsillo:

- Nodo: **Google Cloud Firestore**, operación *Update a document*
- `collection`: `accounts`
- `documentId`: `={{ $('Armar movimiento').first().json.accountId }}`
- `columns`: `balance`
- valor de `balance`: `={{ $('Armar movimiento').first().json.nuevoSaldo }}`

> **Aviso:** esto es un leer-y-escribir, no un incremento atómico como
> el de la app (`FieldValue.increment`). Si en ese mismo instante
> añades un movimiento a mano desde la app, uno de los dos cambios
> puede pisarse. Es una ventana de milisegundos y en la práctica no
> pasa, pero conviene saberlo.

---

## Cómo comprobar que ya funciona

1. **Aísla el fallo en 2 minutos.** Añade un nodo de Telegram
   justo después de "Telegram Trigger" que conteste "recibido". Si
   llega ese mensaje, el trigger funciona y el problema está más
   adelante; si no llega, el problema es el trigger o el webhook.
2. Manda un **texto** primero (no un audio): es la rama más simple y
   descarta de golpe el nodo "Get a file".
3. Mira el **log de ejecución** de n8n: ahí está el nodo exacto que
   falló y su error.
4. Cuando funcione, el movimiento debe verse en el listado **y** el
   saldo del bolsillo debe moverse.
