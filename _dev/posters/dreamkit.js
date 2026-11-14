// Shared pieces for the dream posters (dreams2.js, dreams3.js), and their words, read from the code
// (LC.DreamPosterHints in sv_livingcity_dreamposters.lua) so a poster can never say something else.
const fs = require('fs'), path = require('path');
const { C, P, R, G } = require('./lib.js');

const E = (cx, cy, rx, ry, f, extra = '') => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${f}" ${extra}/>`;
const L = (d, col, w, extra = '') => `<path d="${d}" stroke="${col}" stroke-width="${w}" fill="none" stroke-linecap="round" stroke-linejoin="round" ${extra}/>`;
const T = (x, y, txt, size, fill, extra = '') => `<text x="${x}" y="${y}" text-anchor="middle" font-family="Inter Display" font-weight="900" font-size="${size}" fill="${fill}" ${extra}>${txt}</text>`;
function rng(seed) { let a = seed; return () => { a = (a * 16807) % 2147483647; return a / 2147483647; }; }

const lua = fs.readFileSync(path.join(__dirname, '../../gamemodes/livingcity/gamemode/modules/server/sv_livingcity_dreamposters.lua'), 'utf8');
function words(id) {
  const m = lua.match(new RegExp('\\n    ' + id + ' = \\{ "([^"]*)", "([^"]*)" \\}'));
  if (!m) throw new Error('no hint for ' + id);
  return [m[1], m[2]];
}
// the small words, on one to three lines of about the same length
function wrap(text) {
  const k = text.length <= 52 ? 1 : text.length <= 96 ? 2 : 3;
  const ws = text.split(' '), out = [];
  let line = '', left = text.length, lines = k;
  for (const w of ws) {
    if (line && lines > 1 && line.length + w.length / 2 > left / lines) { out.push(line); left -= line.length + 1; lines--; line = w; }
    else line = line ? line + ' ' + w : w;
  }
  out.push(line);
  return out.map(l => l.replace(/'/g, '’'));
}
// a poster's row: the heading cut into the given lines (checked against the code), sized to fit
function row(id, n, lines, o = {}) {
  const [head, body] = words(id);
  if (lines.join(' ') !== head) throw new Error(id + ': heading is "' + head + '"');
  let sizes = lines.map(l => Math.min(o.cap || 140, Math.round(1090 / l.length)));
  const sum = sizes.reduce((a, b) => a + b, 0), max = lines.length === 1 ? 150 : 246;
  if (sum > max) sizes = sizes.map(x => Math.round(x * max / sum));
  return Object.assign({ id: 'dream_' + id, n, tag: 'SLEEP WELL, CITIZEN', head: lines.map((l, i) => [l.replace(/'/g, '’'), sizes[i]]), small: wrap(body) }, o.night ? { accent: 'cyan', dark: true, acc: o.acc || C.red, ground: o.ground || '#080d15' } : { accent: o.accent || 'cyan', acc: o.acc });
}

// a citizen walking, in profile (104 x 258); o.leg for dark grounds
function walker(x, y, s, o = {}) {
  const leg = o.leg || C.ink, hat = o.hat || C.ink;
  return G(`translate(${x},${y}) scale(${s}) ${o.turn ? `rotate(${o.turn} 50 258)` : ''}`, [
    o.nolegs ? '' : P('M50,148 L74,148 L90,246 L72,250 L58,176Z', leg) + P('M72,250 L90,246 L104,252 L104,258 L72,258Z', leg) + P('M30,148 L54,148 L46,200 L30,248 L12,244 L28,196Z', leg) + P('M12,244 L30,248 L28,258 L2,256Z', leg),
    P('M32,46 L68,46 L80,156 L24,156Z', C.blueD), P('M52,46 L68,46 L80,156 L60,156Z', C.blue),
    P('M62,58 L74,62 L86,122 L76,126Z', C.blue), P('M34,58 L24,62 L18,120 L28,122Z', leg),
    P('M40,8 L62,8 L68,22 L66,36 L58,46 L42,46 L36,34 L34,20Z', C.steel2), P('M30,20 L38,2 L64,2 L72,18 L80,22 L80,26 L30,24Z', hat),
  ].join(''));
}
// a headcrab's outline, about 430 x 280, centre at 0,0
function crab(x, y, s, fill) {
  return G(`translate(${x},${y}) scale(${s})`, P('M-70,-20 L-168,-96 L-214,60 L-196,66 L-160,-44 L-60,26Z', fill) + P('M70,-20 L168,-96 L214,60 L196,66 L160,-44 L60,26Z', fill) +
    E(0, 0, 118, 84, fill) + P('M-64,34 L-128,58 L-150,150 L-128,152 L-104,86 L-40,66Z', fill) + P('M64,34 L128,58 L150,150 L128,152 L104,86 L40,66Z', fill));
}
// a rose's head, about 34 across
function rose(x, y, s, col = C.red, dk = C.redD) {
  return G(`translate(${x},${y}) scale(${s})`, P('M-15,-6 L0,-17 L15,-6 L13,10 L0,17 L-13,10Z', col) + L('M-7,-2 Q0,-10 7,-2 Q4,6 -2,3', dk, 3) + P('M-13,10 L0,17 L13,10 L0,13Z', dk));
}
// a toothed wheel
function gear(cx, cy, r, teeth, fill, hub) {
  let s = '';
  for (let i = 0; i < teeth; i++) s += `<rect x="${cx - r * 0.13}" y="${cy - r * 1.2}" width="${r * 0.26}" height="${r * 0.36}" fill="${fill}" transform="rotate(${i * 360 / teeth} ${cx} ${cy})"/>`;
  return s + `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${fill}"/><circle cx="${cx}" cy="${cy}" r="${r * 0.62}" fill="${hub}" opacity=".5"/><circle cx="${cx}" cy="${cy}" r="${r * 0.22}" fill="${hub}"/>`;
}
// far-off blocks along a ground line
function skyline(y, fill, win, seed, h = 150) {
  const r = rng(seed);
  let s = '', x = -10;
  while (x < 720) {
    const w = 50 + r() * 60, top = y - 40 - r() * h;
    s += R(x.toFixed(0), top.toFixed(0), w.toFixed(0), (y - top + 4).toFixed(0), fill);
    if (win) for (let wy = top + 14; wy < y - 14; wy += 26) for (let wx = x + 10; wx < x + w - 12; wx += 20) if (r() < 0.6) s += R(wx.toFixed(0), wy.toFixed(0), 9, 13, win);
    x += w + r() * 8;
  }
  return s;
}

module.exports = { E, L, T, rng, row, walker, crab, rose, gear, skyline };
