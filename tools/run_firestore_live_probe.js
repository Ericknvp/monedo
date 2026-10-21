// Ejecuta la sonda de Firestore en un Chrome headless y muestra el
// resultado. Verifica contra el Firestore real las operaciones que hace
// la app al vincular Telegram con reglas de seguridad.
//
//   node tools/run_firestore_live_probe.js
//
// Necesita Node (v18+) y Google Chrome instalado.
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');
const http = require('http');

const HTML = path.join(__dirname, 'firestore_live_probe.html');
const PORT = 8099;
const CDP_PORT = 9350;

const CHROME_CANDIDATES = [
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
];

const chromePath = CHROME_CANDIDATES.find((p) => fs.existsSync(p));
if (!chromePath) {
  console.error('No se encontro Google Chrome.');
  process.exit(1);
}

const server = http
  .createServer((req, res) => {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end(fs.readFileSync(HTML));
  })
  .listen(PORT, '127.0.0.1');

const profile = path.join(require('os').tmpdir(), 'monedo-live-probe');
fs.rmSync(profile, { recursive: true, force: true });

const chrome = spawn(chromePath, [
  '--headless=new',
  `--remote-debugging-port=${CDP_PORT}`,
  `--user-data-dir=${profile}`,
  '--no-first-run',
  '--no-default-browser-check',
  '--disable-gpu',
  'about:blank',
], { stdio: 'ignore' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function getTarget() {
  for (let i = 0; i < 60; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${CDP_PORT}/json/list`);
      const list = await res.json();
      const page = list.find((t) => t.type === 'page');
      if (page) return page;
    } catch {}
    await sleep(500);
  }
  throw new Error('Chrome no expuso un target de depuracion');
}

(async () => {
  const target = await getTarget();
  const ws = new WebSocket(target.webSocketDebuggerUrl);
  let id = 0;
  const pending = new Map();

  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const msgId = ++id;
      pending.set(msgId, { resolve, reject });
      ws.send(JSON.stringify({ id: msgId, method, params }));
    });

  await new Promise((r) => ws.addEventListener('open', r));
  ws.addEventListener('message', (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) {
      const { resolve, reject } = pending.get(m.id);
      pending.delete(m.id);
      m.error ? reject(new Error(JSON.stringify(m.error))) : resolve(m.result);
    }
  });

  await send('Runtime.enable');
  await send('Page.enable');
  await send('Page.navigate', { url: `http://127.0.0.1:${PORT}/` });

  for (let i = 0; i < 40; i++) {
    await sleep(2000);
    const done = await send('Runtime.evaluate', {
      expression: 'window.__done === true',
      returnByValue: true,
    });
    if (done.result.value) break;
  }

  const r = await send('Runtime.evaluate', {
    expression: 'document.getElementById("out").textContent',
    returnByValue: true,
  });
  console.log(r.result.value);

  ws.close();
  chrome.kill();
  server.close();
  process.exit(0);
})().catch((e) => {
  console.error('La sonda fallo: ' + e.message);
  chrome.kill();
  server.close();
  process.exit(1);
});
