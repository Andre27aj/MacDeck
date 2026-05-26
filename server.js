'use strict';
const express  = require('express');
const cors     = require('cors');
const crypto   = require('crypto');
const { exec, execFile, execFileSync, execSync } = require('child_process');
const path     = require('path');
const fs       = require('fs');
const os       = require('os');
const { Bonjour } = require('bonjour-service');

const app  = express();
const PORT = 3000;

// ── Token storage ─────────────────────────────────────────────────────────────

const TOKENS_FILE = path.join(os.homedir(), '.macdeck-tokens');
let validTokens = new Set();
try {
  const saved = JSON.parse(fs.readFileSync(TOKENS_FILE, 'utf8'));
  if (Array.isArray(saved)) saved.forEach(t => typeof t === 'string' && validTokens.add(t));
} catch {}

function saveTokens() {
  fs.writeFileSync(TOKENS_FILE, JSON.stringify([...validTokens]));
  try { fs.chmodSync(TOKENS_FILE, 0o600); } catch {}
}

// ── Pairing state ─────────────────────────────────────────────────────────────

let pairingSession = null; // { code, expiry, attempts }

// ── Helpers ───────────────────────────────────────────────────────────────────

function runFile(cmd, args = []) {
  return new Promise((resolve, reject) => {
    execFile(cmd, args, (err, stdout) => {
      if (err) reject(err); else resolve(stdout.trim());
    });
  });
}

function osascript(script) {
  return runFile('osascript', ['-e', script]);
}

// Sanitise a string to be safe inside an AppleScript double-quoted string
function osaStr(s) {
  return String(s).replace(/["\\\n\r]/g, '');
}

// ── Middleware ────────────────────────────────────────────────────────────────

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// ── Public routes (no auth) ───────────────────────────────────────────────────

app.get('/ping', (_req, res) => res.json({ alive: true }));

app.post('/pair/request', (_req, res) => {
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  pairingSession = { code, expiry: Date.now() + 120_000, attempts: 0 };

  // Show code on Mac — non-blocking
  exec(`osascript -e 'display dialog "MacDeck — Jumelage\\n\\nCode : ${code}\\n\\nEntrez ce code sur votre iPhone." buttons {"OK"} default button "OK" with title "MacDeck" with icon note'`);

  console.log('[pair] code shown on screen');
  res.json({ success: true });
});

app.post('/pair/confirm', (req, res) => {
  const { code } = req.body;
  if (typeof code !== 'string') return res.json({ success: false, error: 'invalid' });

  if (!pairingSession || Date.now() > pairingSession.expiry) {
    pairingSession = null;
    return res.json({ success: false, error: 'expired' });
  }

  pairingSession.attempts++;
  if (pairingSession.attempts > 5) {
    pairingSession = null;
    return res.json({ success: false, error: 'too_many_attempts' });
  }

  if (code !== pairingSession.code) {
    return res.json({ success: false, error: 'wrong_code' });
  }

  const token = crypto.randomUUID();
  validTokens.add(token);
  saveTokens();
  pairingSession = null;
  console.log('[pair] device paired');
  res.json({ success: true, token });
});

// ── Auth middleware ───────────────────────────────────────────────────────────

app.use((req, res, next) => {
  const token = req.headers['x-macdeck-token'];
  if (typeof token === 'string' && validTokens.has(token)) return next();
  res.status(401).json({ success: false, error: 'unauthorized' });
});

// ── Volume ────────────────────────────────────────────────────────────────────

app.get('/volume', async (_req, res) => {
  try {
    const vol   = await osascript('output volume of (get volume settings)');
    const muted = await osascript('output muted of (get volume settings)');
    res.json({ success: true, volume: parseInt(vol), muted: muted === 'true' });
  } catch (e) { res.json({ success: false, error: 'volume error' }); }
});

app.post('/volume', async (req, res) => {
  const { value } = req.body;
  if (value === undefined || value < 0 || value > 100)
    return res.json({ success: false, error: 'value must be 0-100' });
  try {
    await osascript(`set volume output volume ${Math.round(value)}`);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'volume error' }); }
});

app.post('/mute', async (req, res) => {
  const { muted } = req.body;
  try {
    await osascript(muted ? 'set volume with output muted' : 'set volume without output muted');
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'mute error' }); }
});

// ── Applications ──────────────────────────────────────────────────────────────

app.post('/launch', async (req, res) => {
  const { app: appName } = req.body;
  if (!appName || typeof appName !== 'string' || appName.length > 500)
    return res.json({ success: false, error: 'invalid' });
  try {
    const isURL = appName.startsWith('http://') || appName.startsWith('https://');
    if (isURL) {
      // Validate URL properly — no shell injection possible via execFile
      let u;
      try { u = new URL(appName); } catch { return res.json({ success: false, error: 'invalid URL' }); }
      if (!['http:', 'https:'].includes(u.protocol)) return res.json({ success: false, error: 'invalid URL' });
      await runFile('open', [u.toString()]);
    } else {
      await runFile('open', ['-a', appName]);
    }
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'launch failed' }); }
});

app.get('/apps/list', (_req, res) => {
  const HOME = process.env.HOME || os.homedir();
  const dirs = ['/Applications', `${HOME}/Applications`, '/System/Applications'];

  function scan(dir, depth = 2) {
    const apps = [];
    try {
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        if (entry.name.endsWith('.app') && !entry.name.startsWith('.')) {
          apps.push(entry.name.replace(/\.app$/, ''));
        } else if (entry.isDirectory() && depth > 1) {
          apps.push(...scan(path.join(dir, entry.name), depth - 1));
        }
      }
    } catch {}
    return apps;
  }

  const all    = dirs.flatMap(d => scan(d));
  const unique = [...new Set(all)].sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }));
  res.json({ success: true, apps: unique });
});

app.post('/quit', async (req, res) => {
  const { app: appName } = req.body;
  if (!appName || typeof appName !== 'string') return res.json({ success: false, error: 'app required' });
  try {
    await osascript(`tell application "${osaStr(appName)}" to quit`);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'quit failed' }); }
});

app.get('/apps/running', async (_req, res) => {
  try {
    const out  = await osascript('tell application "System Events" to get name of (processes where background only is false)');
    const apps = out.split(', ').map(s => s.trim()).filter(Boolean);
    res.json({ success: true, apps });
  } catch { res.json({ success: false, error: 'running apps error' }); }
});

// ── Raccourcis clavier ────────────────────────────────────────────────────────

const KEY_MAP = { cmd: 'command', ctrl: 'control', alt: 'option', shift: 'shift' };

const KEY_CODES = {
  F1:122, F2:120, F3:99,  F4:118, F5:96,  F6:97,
  F7:98,  F8:100, F9:101, F10:109, F11:103, F12:111,
  space:49, return:36, tab:48, delete:51, escape:53,
  home:115, end:119, pageup:116, pagedown:121,
  up:126, down:125, left:123, right:124,
};

const NATIVE_SHORTCUTS = {
  'cmd+shift+3': () => runFile('open', ['-a', 'Screenshot']),
  'cmd+shift+4': () => runFile('open', ['-a', 'Screenshot']),
  'cmd+space':   () => runFile('open', ['-b', 'com.apple.Spotlight']),
  'cmd+ctrl+q':  () => runFile('open', ['-a', 'ScreenSaverEngine']),
  'F3':          () => runFile('open', ['-b', 'com.apple.exposelauncher']),
  'cmd+q': async () => {
    const front = await osascript('tell application "System Events" to name of first process whose frontmost is true');
    await osascript(`tell application "${osaStr(front)}" to quit`);
  },
  'cmd+tab': () => osascript('tell application "System Events"\nkey down command\nkey code 48\ndelay 0.05\nkey up command\nend tell'),
};

app.post('/shortcut', async (req, res) => {
  const { keys } = req.body;
  if (!Array.isArray(keys) || keys.length === 0 || keys.length > 5)
    return res.json({ success: false, error: 'invalid keys' });

  // Validate all elements are strings
  if (!keys.every(k => typeof k === 'string' && k.length <= 10))
    return res.json({ success: false, error: 'invalid key value' });

  const combo = keys.join('+');
  if (NATIVE_SHORTCUTS[combo]) {
    try { await NATIVE_SHORTCUTS[combo](); return res.json({ success: true }); }
    catch { return res.json({ success: false, error: 'shortcut failed' }); }
  }

  const mods    = keys.slice(0, -1);
  const lastKey = keys[keys.length - 1];

  // Validate modifiers — must be in KEY_MAP
  if (!mods.every(k => KEY_MAP[k]))
    return res.json({ success: false, error: 'invalid modifier' });

  // Validate last key — must be in KEY_CODES or a single alphanumeric char
  if (!KEY_CODES[lastKey] && !/^[a-zA-Z0-9]$/.test(lastKey))
    return res.json({ success: false, error: 'invalid key' });

  try {
    const modUsing = mods.length ? `using {${mods.map(k => KEY_MAP[k] + ' down').join(', ')}}` : '';
    const code     = KEY_CODES[lastKey];
    const script   = code
      ? `tell application "System Events" to key code ${code} ${modUsing}`
      : `tell application "System Events" to keystroke "${lastKey}" ${modUsing}`;
    await osascript(script);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'shortcut failed' }); }
});

// ── Média ─────────────────────────────────────────────────────────────────────

async function getActiveMediaApp() {
  try { if ((await osascript('application "Spotify" is running')) === 'true') return 'Spotify'; } catch {}
  try { if ((await osascript('application "Music" is running'))  === 'true') return 'Music';   } catch {}
  return null;
}

app.post('/media/play-pause', async (_req, res) => {
  try {
    const a = await getActiveMediaApp();
    if (!a) return res.json({ success: false, error: 'no media app' });
    await osascript(`tell application "${a}" to playpause`);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'media error' }); }
});

app.post('/media/next', async (_req, res) => {
  try {
    const a = await getActiveMediaApp();
    if (!a) return res.json({ success: false, error: 'no media app' });
    await osascript(`tell application "${a}" to next track`);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'media error' }); }
});

app.post('/media/prev', async (_req, res) => {
  try {
    const a = await getActiveMediaApp();
    if (!a) return res.json({ success: false, error: 'no media app' });
    await osascript(`tell application "${a}" to previous track`);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'media error' }); }
});

// ── Système ───────────────────────────────────────────────────────────────────

app.post('/system/sleep',         async (_req, res) => { try { await osascript('tell application "System Events" to sleep'); res.json({ success: true }); } catch { res.json({ success: false, error: 'sleep error' }); } });
app.post('/system/sleep-display', async (_req, res) => { try { await runFile('pmset', ['displaysleepnow']); res.json({ success: true }); } catch { res.json({ success: false, error: 'sleep display error' }); } });
app.post('/system/lock',          async (_req, res) => { try { await runFile('open', ['-a', 'ScreenSaverEngine']); res.json({ success: true }); } catch { res.json({ success: false, error: 'lock error' }); } });

app.post('/system/dnd', async (_req, res) => {
  try {
    await osascript('tell application "System Events" to keystroke "d" using {option down, command down}');
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'dnd error' }); }
});

app.post('/system/brightness', async (req, res) => {
  const { value } = req.body;
  if (value === undefined || value < 0 || value > 100)
    return res.json({ success: false, error: 'value must be 0-100' });
  try {
    await runFile('/usr/local/bin/macdeck-brightness', [String(Math.round(value))]);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'brightness error' }); }
});

app.get('/system/brightness', async (_req, res) => {
  try {
    const out   = await runFile('/usr/local/bin/macdeck-brightness', []);
    const match = out.match(/display 0[^:]*: (\d+)%/);
    res.json({ success: true, value: match ? parseInt(match[1]) : 100 });
  } catch { res.json({ success: true, value: 100 }); }
});

app.post('/system/dark-mode', async (_req, res) => {
  try {
    await osascript('tell app "System Events" to tell appearance preferences to set dark mode to not dark mode');
    const darkMode = execFileSync('osascript', ['-e', 'tell application "System Events" to tell appearance preferences to return dark mode'], { encoding: 'utf8' }).trim() === 'true';
    res.json({ success: true, darkMode });
  } catch { res.json({ success: false, error: 'dark mode error' }); }
});

app.post('/system/trash', async (_req, res) => {
  const home = process.env.HOME || os.homedir();
  try {
    // Use shell only for glob expansion; home is from process env, not user input
    exec(`/bin/rm -rf "${home}/.Trash/"* 2>/dev/null; /bin/rm -rf "${home}/.Trash/".??* 2>/dev/null; echo done`);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'trash error' }); }
});

app.get('/system/status', async (_req, res) => {
  const status = { volume: 50, muted: false };
  try {
    status.volume   = parseInt(await osascript('output volume of (get volume settings)'));
    status.muted    = (await osascript('output muted of (get volume settings)')) === 'true';
    status.micMuted = parseInt(await osascript('input volume of (get volume settings)')) === 0;
  } catch {}
  try {
    const a = await getActiveMediaApp();
    if (a) {
      const title  = await osascript(`tell application "${a}" to get name of current track`);
      const artist = await osascript(`tell application "${a}" to get artist of current track`);
      status.nowPlaying = { app: a, title, artist };
    }
  } catch {}
  try {
    const battOut   = execFileSync('pmset', ['-g', 'batt'], { encoding: 'utf8' });
    const bm        = battOut.match(/(\d+)%;/);
    if (bm) status.battery = parseInt(bm[1]);
    status.charging = battOut.includes('AC Power') || battOut.includes('charging');
  } catch {}
  try {
    status.darkMode = execFileSync('osascript', ['-e', 'tell application "System Events" to tell appearance preferences to return dark mode'], { encoding: 'utf8' }).trim() === 'true';
  } catch {}
  try {
    status.activeApp = execFileSync('osascript', ['-e', 'tell application "System Events" to get name of first application process whose frontmost is true'], { encoding: 'utf8' }).trim();
  } catch {}
  try {
    const out = execFileSync('osascript', ['-e', 'tell application "System Events" to get name of (processes where background only is false)'], { encoding: 'utf8' }).trim();
    status.runningApps = out.split(', ').map(s => s.trim()).filter(Boolean);
  } catch {}
  res.json({ success: true, ...status });
});

// ── Microphone ────────────────────────────────────────────────────────────────

app.post('/mic/mute', async (_req, res) => {
  try {
    const vol = parseInt(await osascript('input volume of (get volume settings)'));
    if (vol > 0) {
      await osascript('set volume input volume 0');
      res.json({ success: true, micMuted: true });
    } else {
      await osascript('set volume input volume 75');
      res.json({ success: true, micMuted: false });
    }
  } catch { res.json({ success: false, error: 'mic error' }); }
});

// ── Audio ─────────────────────────────────────────────────────────────────────

const SAS = '/usr/local/bin/SwitchAudioSource';

app.get('/audio/devices', async (_req, res) => {
  try {
    const list    = await runFile(SAS, ['-a', '-t', 'output']);
    const current = (await runFile(SAS, ['-c'])).trim();
    const devices = list.split('\n').map(s => s.trim()).filter(Boolean);
    res.json({ success: true, devices, current });
  } catch { res.json({ success: false, error: 'audio devices error' }); }
});

app.post('/audio/device', async (req, res) => {
  const { name } = req.body;
  if (!name || typeof name !== 'string' || name.length > 200)
    return res.json({ success: false, error: 'name required' });
  try {
    await runFile(SAS, ['-s', name]);
    res.json({ success: true });
  } catch { res.json({ success: false, error: 'audio device error' }); }
});

// ── App icons ─────────────────────────────────────────────────────────────────

app.get('/app-icon', (req, res) => {
  const name = req.query.name;

  // Prevent path traversal — reject slashes, null bytes, and double dots
  if (!name || typeof name !== 'string' || name.includes('/') || name.includes('\0') || name.includes('..'))
    return res.status(400).end();

  const HOME       = process.env.HOME || os.homedir();
  const searchDirs = [
    '/Applications', `${HOME}/Applications`,
    '/System/Applications', '/System/Applications/Utilities',
    '/System/Library/CoreServices',
  ];

  let appPath = null;
  outer: for (const dir of searchDirs) {
    const direct = path.join(dir, `${name}.app`);
    if (fs.existsSync(direct)) { appPath = direct; break; }
    try {
      for (const sub of fs.readdirSync(dir, { withFileTypes: true })) {
        if (!sub.isDirectory()) continue;
        const nested = path.join(dir, sub.name, `${name}.app`);
        if (fs.existsSync(nested)) { appPath = nested; break outer; }
      }
    } catch {}
  }
  if (!appPath) return res.status(404).end();

  const cacheKey = Buffer.from(name).toString('hex');
  const tmpPng   = path.join(os.tmpdir(), `macdeck_icon_${cacheKey}.png`);

  if (fs.existsSync(tmpPng)) {
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Cache-Control', 'public, max-age=86400');
    return res.sendFile(tmpPng);
  }

  try {
    let iconName = null;
    try {
      iconName = execFileSync('defaults', ['read', `${appPath}/Contents/Info`, 'CFBundleIconFile'], { encoding: 'utf8' }).trim();
    } catch {}

    let iconPath = null;
    if (iconName) {
      const base = path.join(appPath, 'Contents', 'Resources', iconName);
      if (fs.existsSync(base)) iconPath = base;
      else if (fs.existsSync(base + '.icns')) iconPath = base + '.icns';
    }

    if (!iconPath) {
      const resourcesDir = path.join(appPath, 'Contents', 'Resources');
      try {
        const icns = fs.readdirSync(resourcesDir).find(f => f.endsWith('.icns'));
        if (icns) iconPath = path.join(resourcesDir, icns);
      } catch {}
    }

    if (!iconPath) return res.status(404).end();

    execFileSync('sips', ['-s', 'format', 'png', iconPath, '--out', tmpPng, '-z', '128', '128']);
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.sendFile(path.resolve(tmpPng));
  } catch {
    res.status(500).end();
  }
});

// ── Start ─────────────────────────────────────────────────────────────────────

app.listen(PORT, '0.0.0.0', () => {
  const { hostname } = require('os');
  const host = hostname().endsWith('.local') ? hostname() : hostname() + '.local';
  execFile('ipconfig', ['getifaddr', 'en0'], (err, ip) => {
    const addr = ip ? ip.trim() : host;
    console.log(`MacDeck running → http://${addr}:${PORT}`);
  });
  const bonjour = new Bonjour();
  bonjour.publish({ name: 'MacDeck', type: 'macdeck', port: PORT, txt: { host } });
  console.log(`Bonjour published — hostname: ${host}`);
});
