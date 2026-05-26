const express = require('express');
const cors = require('cors');
const { exec, execSync } = require('child_process');
const path = require('path');
const fs = require('fs');
const { Bonjour } = require('bonjour-service');

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

function run(cmd) {
  return new Promise((resolve, reject) => {
    console.log('[exec]', cmd);
    exec(cmd, (err, stdout, stderr) => {
      if (err) reject(err);
      else resolve(stdout.trim());
    });
  });
}

function osascript(script) {
  return run(`osascript -e '${script.replace(/'/g, "'\\''")}'`);
}

// ─── Volume & Son ──────────────────────────────────────────────────────────

app.get('/volume', async (req, res) => {
  try {
    const vol = await osascript('output volume of (get volume settings)');
    const muted = await osascript('output muted of (get volume settings)');
    res.json({ success: true, volume: parseInt(vol), muted: muted === 'true' });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.post('/volume', async (req, res) => {
  const { value } = req.body;
  if (value === undefined || value < 0 || value > 100)
    return res.json({ success: false, error: 'value must be 0-100' });
  try {
    await osascript(`set volume output volume ${value}`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.post('/mute', async (req, res) => {
  const { muted } = req.body;
  try {
    if (muted) {
      await osascript('set volume with output muted');
    } else {
      await osascript('set volume without output muted');
    }
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

// ─── Applications ──────────────────────────────────────────────────────────

app.post('/launch', async (req, res) => {
  const { app: appName } = req.body;
  if (!appName) return res.json({ success: false, error: 'app required' });
  try {
    const isURL = appName.startsWith('http://') || appName.startsWith('https://');
    const cmd = isURL ? `open "${appName.replace(/"/g, '')}"` : `open -a "${appName.replace(/"/g, '')}"`;
    await run(cmd);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.get('/apps/list', (req, res) => {
  const HOME = process.env.HOME;
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

  const all = dirs.flatMap(d => scan(d));
  const unique = [...new Set(all)].sort((a, b) => a.localeCompare(b, undefined, { sensitivity: 'base' }));
  res.json({ success: true, apps: unique });
});

app.post('/quit', async (req, res) => {
  const { app: appName } = req.body;
  if (!appName) return res.json({ success: false, error: 'app required' });
  try {
    await osascript(`tell application "${appName.replace(/"/g, '')}" to quit`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.get('/apps/running', async (req, res) => {
  try {
    const out = await osascript(
      'tell application "System Events" to get name of (processes where background only is false)'
    );
    const apps = out.split(', ').map(s => s.trim()).filter(Boolean);
    res.json({ success: true, apps });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

// ─── Raccourcis clavier ────────────────────────────────────────────────────

const KEY_MAP = {
  cmd: 'command',
  ctrl: 'control',
  alt: 'option',
  shift: 'shift',
};

// macOS key codes for keys that can't be used with keystroke
const KEY_CODES = {
  F1:122, F2:120, F3:99,  F4:118, F5:96,  F6:97,
  F7:98,  F8:100, F9:101, F10:109,F11:103,F12:111,
  space:49, return:36, tab:48, delete:51, escape:53,
  home:115, end:119, pageup:116, pagedown:121,
  up:126, down:125, left:123, right:124,
};

// Native alternatives for common shortcuts — no Accessibility permission needed
const NATIVE_SHORTCUTS = {
  // Screenshot: ouvre l'app Screenshot native (mode plein écran ou zone)
  'cmd+shift+3': async () => osascript('do shell script "open -a Screenshot"'),
  'cmd+shift+4': async () => osascript('do shell script "open -a Screenshot"'),
  'cmd+space':   async () => osascript('do shell script "open -b com.apple.Spotlight"'),
  'cmd+ctrl+q':  async () => osascript('do shell script "open -a ScreenSaverEngine"'),
  'F3':          async () => osascript('do shell script "open -b com.apple.exposelauncher"'),
  'cmd+q':       async () => {
    const front = await osascript('tell application "System Events" to name of first process whose frontmost is true');
    await osascript(`tell application "${front.trim()}" to quit`);
  },
  'cmd+tab':     async () => osascript(`tell application "System Events"\nkey down command\nkey code 48\ndelay 0.05\nkey up command\nend tell`),
};

app.post('/shortcut', async (req, res) => {
  const { keys } = req.body;
  if (!Array.isArray(keys) || keys.length === 0)
    return res.json({ success: false, error: 'keys array required' });

  const combo = keys.join('+');
  if (NATIVE_SHORTCUTS[combo]) {
    try {
      await NATIVE_SHORTCUTS[combo]();
      return res.json({ success: true });
    } catch (e) {
      return res.json({ success: false, error: e.message });
    }
  }

  // Generic fallback via System Events (requires Accessibility permission)
  const lastKey = keys[keys.length - 1];
  const mods = keys.slice(0, -1).map(k => (KEY_MAP[k] || k) + ' down');
  const modUsing = mods.length ? `using {${mods.join(', ')}}` : '';

  try {
    const code = KEY_CODES[lastKey];
    const script = code
      ? `tell application "System Events" to key code ${code} ${modUsing}`
      : `tell application "System Events" to keystroke "${lastKey}" ${modUsing}`;
    await osascript(script);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

// ─── Média ─────────────────────────────────────────────────────────────────

async function getActiveMediaApp() {
  try {
    const spotifyRunning = await osascript('application "Spotify" is running');
    if (spotifyRunning === 'true') return 'Spotify';
  } catch (_) {}
  try {
    const musicRunning = await osascript('application "Music" is running');
    if (musicRunning === 'true') return 'Music';
  } catch (_) {}
  return null;
}

app.post('/media/play-pause', async (req, res) => {
  try {
    const app = await getActiveMediaApp();
    if (!app) return res.json({ success: false, error: 'No media app running' });
    await osascript(`tell application "${app}" to playpause`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.post('/media/next', async (req, res) => {
  try {
    const app = await getActiveMediaApp();
    if (!app) return res.json({ success: false, error: 'No media app running' });
    await osascript(`tell application "${app}" to next track`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.post('/media/prev', async (req, res) => {
  try {
    const app = await getActiveMediaApp();
    if (!app) return res.json({ success: false, error: 'No media app running' });
    await osascript(`tell application "${app}" to previous track`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.get('/media/now-playing', async (req, res) => {
  try {
    const app = await getActiveMediaApp();
    if (!app) return res.json({ success: true, app: null, title: null, artist: null });
    const title = await osascript(`tell application "${app}" to get name of current track`);
    const artist = await osascript(`tell application "${app}" to get artist of current track`);
    res.json({ success: true, app, title, artist });
  } catch (e) {
    res.json({ success: true, app: null, title: null, artist: null });
  }
});

// ─── Système ───────────────────────────────────────────────────────────────

app.post('/system/sleep', async (req, res) => {
  try {
    await osascript('tell application "System Events" to sleep');
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.post('/system/dnd', async (req, res) => {
  // Toggle Focus/DND via shortcut (macOS 12+ uses Focus, toggle with shortcut)
  try {
    // Use shortcut to toggle Focus — works in Monterey and later
    await osascript(`tell application "System Events" to keystroke "d" using {option down, command down}`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.post('/system/brightness', async (req, res) => {
  const { value } = req.body;
  if (value === undefined || value < 0 || value > 100)
    return res.json({ success: false, error: 'value must be 0-100' });
  try {
    await run(`/usr/local/bin/macdeck-brightness ${value}`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.get('/system/brightness', async (req, res) => {
  try {
    const out = await run('/usr/local/bin/macdeck-brightness');
    const match = out.match(/display 0[^:]*: (\d+)%/);
    const value = match ? parseInt(match[1]) : 100;
    res.json({ success: true, value });
  } catch (e) {
    res.json({ success: true, value: 100 });
  }
});

app.get('/system/status', async (req, res) => {
  const status = { volume: 50, muted: false, nowPlaying: null };
  try {
    status.volume = parseInt(await osascript('output volume of (get volume settings)'));
    status.muted = (await osascript('output muted of (get volume settings)')) === 'true';
    status.micMuted = parseInt(await osascript('input volume of (get volume settings)')) === 0;
  } catch (_) {}
  try {
    const app = await getActiveMediaApp();
    if (app) {
      const title = await osascript(`tell application "${app}" to get name of current track`);
      const artist = await osascript(`tell application "${app}" to get artist of current track`);
      status.nowPlaying = { app, title, artist };
    }
  } catch (_) {}
  try {
    const battOut = execSync('pmset -g batt', { encoding: 'utf8' });
    const bm = battOut.match(/(\d+)%;/);
    if (bm) status.battery = parseInt(bm[1]);
    status.charging = battOut.includes('AC Power') || battOut.includes('charging');
  } catch (_) {}
  try {
    status.darkMode = execSync(
      `osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode'`,
      { encoding: 'utf8' }
    ).trim() === 'true';
  } catch (_) {}
  try {
    status.activeApp = execSync(
      `osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true'`,
      { encoding: 'utf8' }
    ).trim();
  } catch (_) {}
  try {
    const out = execSync(
      `osascript -e 'tell application "System Events" to get name of (processes where background only is false)'`,
      { encoding: 'utf8' }
    ).trim();
    status.runningApps = out.split(', ').map(s => s.trim()).filter(Boolean);
  } catch (_) {}
  res.json({ success: true, ...status });
});

// ─── Microphone ────────────────────────────────────────────────────────────

app.post('/mic/mute', async (req, res) => {
  try {
    const vol = parseInt(await osascript('input volume of (get volume settings)'));
    if (vol > 0) {
      await osascript('set volume input volume 0');
      res.json({ success: true, micMuted: true });
    } else {
      await osascript('set volume input volume 75');
      res.json({ success: true, micMuted: false });
    }
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

// ─── Audio ─────────────────────────────────────────────────────────────────

const SAS = '/usr/local/bin/SwitchAudioSource';

app.get('/audio/devices', async (req, res) => {
  try {
    const list    = await run(`${SAS} -a -t output`);
    const current = (await run(`${SAS} -c`)).trim();
    const devices = list.split('\n').map(s => s.trim()).filter(Boolean);
    res.json({ success: true, devices, current });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

app.post('/audio/device', async (req, res) => {
  const { name } = req.body;
  if (!name) return res.json({ success: false, error: 'name required' });
  try {
    await run(`${SAS} -s "${name.replace(/"/g, '')}"`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

// ─── App icons ─────────────────────────────────────────────────────────────

app.get('/app-icon', (req, res) => {
  const name = req.query.name;
  if (!name) return res.status(400).end();

  const HOME = process.env.HOME;
  const searchDirs = [
    '/Applications',
    `${HOME}/Applications`,
    '/System/Applications',
    '/System/Applications/Utilities',
    '/System/Library/CoreServices',
  ];

  let appPath = null;
  outer: for (const dir of searchDirs) {
    // Direct match
    const direct = path.join(dir, `${name}.app`);
    if (fs.existsSync(direct)) { appPath = direct; break; }
    // One level deep (e.g. /Applications/DaVinci Resolve/DaVinci Resolve.app)
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
  const tmpPng = `/tmp/macdeck_icon_${cacheKey}.png`;

  if (fs.existsSync(tmpPng)) {
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Cache-Control', 'public, max-age=86400');
    return res.sendFile(tmpPng);
  }

  try {
    let iconName = null;
    try { iconName = execSync(`defaults read "${appPath}/Contents/Info" CFBundleIconFile 2>/dev/null`, { encoding: 'utf8' }).trim(); } catch {}

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

    execSync(`sips -s format png "${iconPath}" --out "${tmpPng}" -z 128 128 2>/dev/null`);
    res.setHeader('Content-Type', 'image/png');
    res.setHeader('Cache-Control', 'public, max-age=86400');
    res.sendFile(path.resolve(tmpPng));
  } catch {
    res.status(500).end();
  }
});

// ─── Corbeille ─────────────────────────────────────────────────────────────

app.post('/system/trash', async (req, res) => {
  const home = process.env.HOME;
  try {
    await run(`/bin/rm -rf "${home}/.Trash/"* 2>/dev/null; /bin/rm -rf "${home}/.Trash/".??* 2>/dev/null; echo done`);
    res.json({ success: true });
  } catch (e) {
    res.json({ success: false, error: e.message });
  }
});

// ─── Contrôles système avancés ─────────────────────────────────────────────

app.post('/system/lock', async (req, res) => {
  try {
    await run('open -a ScreenSaverEngine');
    res.json({ success: true });
  } catch (e) { res.json({ success: false, error: e.message }); }
});

app.post('/system/sleep-display', async (req, res) => {
  try {
    await run('pmset displaysleepnow');
    res.json({ success: true });
  } catch (e) { res.json({ success: false, error: e.message }); }
});

app.post('/system/dark-mode', async (req, res) => {
  try {
    await osascript('tell app "System Events" to tell appearance preferences to set dark mode to not dark mode');
    const darkMode = execSync(
      `osascript -e 'tell application "System Events" to tell appearance preferences to return dark mode'`,
      { encoding: 'utf8' }
    ).trim() === 'true';
    res.json({ success: true, darkMode });
  } catch (e) { res.json({ success: false, error: e.message }); }
});

// ─── Start ─────────────────────────────────────────────────────────────────

app.listen(PORT, '0.0.0.0', () => {
  const { hostname } = require('os');
  const host = hostname().endsWith('.local') ? hostname() : hostname() + '.local';
  exec('ipconfig getifaddr en0', (err, ip) => {
    const addr = ip ? ip.trim() : host;
    console.log(`MacDeck running → http://${addr}:${PORT}`);
  });
  const bonjour = new Bonjour();
  bonjour.publish({ name: 'MacDeck', type: 'macdeck', port: PORT, txt: { host } });
  console.log(`Bonjour published — hostname: ${host}`);
});
