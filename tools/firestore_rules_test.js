// Pruebas de las reglas de seguridad de Firestore.
//
// Verifica `firestore.rules` contra el ruleset real del proyecto usando
// la API de Firebase Rules (projects.test), sin necesidad de desplegar.
//
//   node tools/firestore_rules_test.js
//
// Requiere haber hecho `firebase login` en esta maquina: usa el token
// que guarda el CLI en ~/.config/configstore/firebase-tools.json.
//
// Formato del harness (ver el esquema de firebaserules.test):
//   lecturas   -> TestCase.resource        = { data: { ...campos } }
//   escrituras -> TestCase.request.resource = { data: { ...campos } }
//
// Nota: el harness no sabe simular queries `list` con filtros, asi que
// esas se omiten. Para comprobar una list hay que mirarla en la consola
// de Firebase con un usuario real.

const fs = require('fs');
const https = require('https');
const path = require('path');

const PROJECT = process.env.FIREBASE_PROJECT_ID || 'monedo-e7849';
const UID = 'test-uid-123';
const OTRO = 'otro-uid-999';
const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

const RULES_PATH = path.join(__dirname, '..', 'firestore.rules');
const CONFIGSTORE = path.join(
  process.env.USERPROFILE || process.env.HOME,
  '.config', 'configstore', 'firebase-tools.json'
);

// Credenciales publicas del propio firebase-tools (son del proyecto de
// Google, no del usuario): solo sirven para renovar el token de la CLI.
const CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLI_CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

function post(url, body, token) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = https.request(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data),
        ...(token ? { Authorization: 'Bearer ' + token } : {}),
      },
    }, (res) => {
      let out = '';
      res.on('data', (c) => (out += c));
      res.on('end', () => resolve({ status: res.statusCode, body: out }));
    });
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

const D = (p) => `/databases/(default)/documents/${p}`;

const pinDoc = (uid, pin, used = false) => ({
  data: {
    pin: pin,
    uid: uid,
    createdAt: new Date().toISOString(),
    expiresAt: expiresAt,
    used: used,
  },
});

const cases = [
  // ── Crear PIN ────────────────────────────────────────────────
  { name: 'crear PIN propio', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('telegram_pins/839201'), method: 'create', resource: pinDoc(UID, '839201') } },
  { name: 'crear PIN con used=true (ya canjeado)', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_pins/839202'), method: 'create', resource: pinDoc(UID, '839202', true) } },
  { name: 'crear PIN a nombre de otro usuario', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_pins/839203'), method: 'create', resource: pinDoc(OTRO, '839203') } },
  { name: 'crear PIN con pin que no coincide con el id', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_pins/839204'), method: 'create', resource: pinDoc(UID, '999999') } },
  { name: 'crear PIN sin expiresAt', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_pins/839205'), method: 'create',
      resource: { data: { pin: '839205', uid: UID, used: false } } } },
  { name: 'crear PIN sin sesion', expectation: 'DENY',
    request: { path: D('telegram_pins/839206'), method: 'create', resource: pinDoc(UID, '839206') } },

  // ── Leer / borrar / editar PIN ───────────────────────────────
  { name: 'leer PIN propio', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('telegram_pins/839201'), method: 'get' },
    resource: pinDoc(UID, '839201') },
  { name: 'leer PIN de otro', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_pins/839207'), method: 'get' },
    resource: pinDoc(OTRO, '839207') },
  { name: 'borrar PIN propio (caducado)', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('telegram_pins/839201'), method: 'delete' },
    resource: pinDoc(UID, '839201') },
  { name: 'borrar PIN de otro', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_pins/839207'), method: 'delete' },
    resource: pinDoc(OTRO, '839207') },
  { name: 'editar un PIN emitido', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_pins/839201'), method: 'update', resource: pinDoc(UID, '839201', true) },
    resource: pinDoc(UID, '839201') },

  // ── telegram_links ───────────────────────────────────────────
  // La clave del documento es el chat.id, no el uid.
  { name: 'crear telegram_links desde el cliente', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D(`telegram_links/555`), method: 'create',
      resource: { data: { chatId: '555', uid: UID, username: 'x' } } } },
  { name: 'leer telegram_links propio', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('telegram_links/555'), method: 'get' },
    resource: { data: { chatId: '555', uid: UID, username: 'x' } } },
  { name: 'leer telegram_links de otro', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_links/666'), method: 'get' },
    resource: { data: { chatId: '666', uid: OTRO, username: 'x' } } },
  { name: 'borrar telegram_links propio (desvincular)', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('telegram_links/555'), method: 'delete' },
    resource: { data: { chatId: '555', uid: UID, username: 'x' } } },
  { name: 'borrar telegram_links de otro', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_links/666'), method: 'delete' },
    resource: { data: { chatId: '666', uid: OTRO, username: 'x' } } },
  { name: 'editar telegram_links', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('telegram_links/555'), method: 'update',
      resource: { data: { chatId: '555', uid: OTRO } } },
    resource: { data: { chatId: '555', uid: UID } } },

  // ── users ────────────────────────────────────────────────────
  { name: 'actualizar users propio (telegramLinked false)', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D(`users/${UID}`), method: 'update',
      resource: { data: { username: 'monedouser', email: 'a@b.com', telegramLinked: false, telegramChatId: null } } },
    resource: { data: { username: 'monedouser', email: 'a@b.com' } } },
  { name: 'actualizar users de otro', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D(`users/${OTRO}`), method: 'update',
      resource: { data: { telegramLinked: true } } },
    resource: { data: { telegramLinked: false } } },

  // ── Sin regresion en las reglas que ya existian ──────────────
  { name: 'leer transactions propias (sin regresion)', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('transactions/tx1'), method: 'get' },
    resource: { data: { userId: UID } } },
  { name: 'leer transactions de otro (sin regresion)', expectation: 'DENY',
    request: { auth: { uid: UID }, path: D('transactions/tx2'), method: 'get' },
    resource: { data: { userId: OTRO } } },
  { name: 'leer accounts propias (sin regresion)', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('accounts/a1'), method: 'get' },
    resource: { data: { userId: UID } } },
  { name: 'leer goals propias (sin regresion)', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('goals/g1'), method: 'get' },
    resource: { data: { userId: UID } } },
  { name: 'leer budgets propios (sin regresion)', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('budgets/b1'), method: 'get' },
    resource: { data: { userId: UID } } },
  { name: 'leer app_config (sin regresion)', expectation: 'ALLOW',
    request: { auth: { uid: UID }, path: D('app_config/c1'), method: 'get' },
    resource: { data: { any: 'value' } } },
];

(async () => {
  if (!fs.existsSync(CONFIGSTORE)) {
    console.error('No se encontro el token del CLI en ' + CONFIGSTORE);
    console.error('Ejecuta primero: firebase login');
    process.exit(1);
  }
  const store = JSON.parse(fs.readFileSync(CONFIGSTORE, 'utf8'));
  const tokens = store.tokens || {};
  if (!tokens.refresh_token) {
    console.error('El CLI no tiene refresh_token. Ejecuta: firebase login');
    process.exit(1);
  }

  const refreshed = await post('https://oauth2.googleapis.com/token', {
    grant_type: 'refresh_token',
    refresh_token: tokens.refresh_token,
    client_id: CLI_CLIENT_ID,
    client_secret: CLI_CLIENT_SECRET,
  }, null);

  const access = JSON.parse(refreshed.body).access_token;
  if (!access) {
    console.error('No se pudo renovar el token:', refreshed.body);
    process.exit(1);
  }

  const source = fs.readFileSync(RULES_PATH, 'utf8');

  const res = await post(
    `https://firebaserules.googleapis.com/v1/projects/${PROJECT}:test`,
    {
      source: { files: [{ name: 'firestore.rules', content: source }] },
      testSuite: {
        testCases: cases.map((c) => ({
          expectation: c.expectation,
          request: c.request,
          ...(c.resource ? { resource: c.resource } : {}),
        })),
      },
    },
    access
  );

  if (res.status !== 200) {
    console.error('Error de la API:', res.status, res.body);
    process.exit(1);
  }

  const body = JSON.parse(res.body);
  let pass = 0;
  let fail = 0;

  body.testResults.forEach((r, i) => {
    const ok = r.state === 'SUCCESS';
    ok ? pass++ : fail++;
    console.log(
      `${ok ? 'OK   ' : 'FALLA'} ${cases[i].name.padEnd(48)} esperado=${cases[i].expectation}`
    );
    if (!ok) {
      console.log('       ' + (r.debugMessages || []).join(' | ').slice(0, 220));
    }
  });

  console.log(`\n${pass} correctos, ${fail} fallidos`);
  process.exit(fail ? 1 : 0);
})();
