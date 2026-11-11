#!/usr/bin/env node
// The Miscount loading screen: `node _dev/posters/loading.js OUTDIR` writes miscount_1080.jpg, miscount_4k.jpg,
// miscount_mark.png (the M mark alone) and miscount_loading.html (one file, the picture inside it, for sv_loadingurl).
// The scene: the Administrator at her balcony with two officers, the block's residents and what is on their minds
// in the scanner's readouts, and one lit window with no record: the miscount (the player).
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const { C, P, R, G, emblem, scanner, adminBust } = require('./lib.js');
const W = 1920, H = 1080, WW = 150, WH = 160, STREET = 770;
const T = (x, y, size, fill, txt, extra = '') => `<text x="${x}" y="${y}" font-family="Inter Display" font-weight="900" font-size="${size}" fill="${fill}" ${extra}>${txt}</text>`;
const M = (x, y, size, fill, txt) => `<text x="${x}" y="${y}" font-family="JetBrains Mono" font-weight="800" font-size="${size}" fill="${fill}">${txt}</text>`;

// What the scanner reads off each resident: the kinds of things the city's minds really hold (docs/features/city-minds.md).
const THOUGHTS = ['HAD A MEAL', 'WAS SEARCHED', 'MISSES 0398', '', '', 'FEARS UNIT 30', 'LOYAL, FOR NOW', 'CANNOT SLEEP',
  'SAW A BEATING', 'TRUSTS NO ONE', 'HUNGRY', '', '', 'HOPEFUL', 'KEEPS TO HERSELF', 'OWES 0407',
  'PROUD', 'ASLEEP', 'WAITING FOR 0431', '', '', 'HIDING SOMETHING', '', 'GRATEFUL'];
const AWAKE = { 2: 1, 5: 1, 8: 1, 14: 1, 23: 1 };
const LIT = [6, 2];

function person(x, y, f) {
  return `<circle cx="${x + WW / 2}" cy="${y + WH * 0.45}" r="${WW * 0.15}" fill="${f}"/>` + P(`M${x + WW * 0.22},${y + WH} L${x + WW * 0.3},${y + WH * 0.66} L${x + WW * 0.7},${y + WH * 0.66} L${x + WW * 0.78},${y + WH}Z`, f);
}
function win(x, y, n, on) {
  const awake = !on && AWAKE[n];
  let s = R(x, y, WW, WH, on ? C.warm : awake ? C.slate : C.night) + R(x - 10, y + WH, WW + 20, 10, C.slate);
  if (on) s += person(x, y, C.ink); else if (awake) s += person(x, y, C.night);
  s += R(x + WW / 2 - 2, y, 4, WH, on ? C.ink : C.night2) + R(x, y + WH * 0.36, WW, 4, on ? C.ink : C.night2);
  s += M(x - 8, y + WH + 34, 16, on ? C.paper : C.steel, on ? 'RESIDENT ????' : 'RESIDENT 0' + (412 + n));
  s += M(x - 8, y + WH + 56, 16, on ? C.red : C.cyan, on ? 'NO RECORD' : THOUGHTS[n]);
  return s;
}
const winAt = (c, r) => [35 + c * 240 + (c > 4 ? 20 : 0), 30 + r * 245];

// A broad Civil Protection officer, front view (the posters keep lib.js's slighter one). Box 120 x 480, the shoulders spill past it.
function guard(tx, ty, s) {
  const dk = '#141c26', vest = '#1f2b3a';
  const arm = P('M-26,116 L-38,162 L-34,274 L-4,274 L-2,150 L6,126Z', C.slate) + R(-37, 174, 34, 22, C.red) + P('M-34,274 L-4,274 L-7,300 L-31,300Z', C.ink) + P('M-30,110 L22,96 L26,124 L-24,138Z', C.slate2);
  let g = P('M8,330 L57,330 L55,462 L16,462Z', dk) + P('M63,330 L112,330 L104,462 L65,462Z', dk);
  g += P('M10,462 L56,462 L56,480 L2,480Z', C.ink) + P('M64,462 L110,462 L118,480 L64,480Z', C.ink);
  g += P('M-26,116 L20,98 L100,98 L146,116 L140,206 L114,340 L6,340 L-20,206Z', dk);
  g += P('M-4,126 L124,126 L114,216 L6,216Z', vest) + R(56, 100, 8, 240, C.slate2) + R(14, 150, 30, 12, C.slate2) + R(76, 150, 30, 12, C.slate2);
  g += R(6, 226, 108, 16, C.steel) + R(49, 222, 22, 24, C.steel2);
  g += arm + G('translate(120,0) scale(-1,1)', arm);
  g += P('M30,90 L90,90 L98,108 L22,108Z', C.slate2);
  g += P('M30,8 L50,0 L70,0 L90,8 L98,34 L96,70 L84,94 L36,94 L24,70 L22,34Z', dk) + P('M30,8 L50,0 L46,30 L26,42 L22,34Z', C.slate2);
  g += `<circle cx="44" cy="46" r="12" fill="${C.ink}"/><circle cx="76" cy="46" r="12" fill="${C.ink}"/><circle cx="44" cy="46" r="8.5" fill="${C.paper}"/><circle cx="76" cy="46" r="8.5" fill="${C.paper}"/>`;
  g += P('M48,62 L72,62 L78,94 L42,94Z', C.steel) + `<circle cx="60" cy="82" r="9" fill="${C.steel2}"/><circle cx="60" cy="82" r="4" fill="${dk}"/>`;
  return G(`translate(${tx},${ty}) scale(${s})`, g);
}

// The Administrator as on the posters, with a faint smile laid over her mouth.
function administrator(cx, top, s) {
  const smile = R(75, 108, 20, 9, '#dfc6a8') + P('M74,109 L80,111 L85,110 L90,111 L96,109 L91,115 L85,117 L79,115Z', '#8a4a40');
  return G(`translate(${cx - 85 * s},${top}) scale(${s})`, adminBust({ pin: C.red }) + smile);
}

// The Miscount mark: the title's own M (Inter Display Black), its last leg cut off, dropped and coloured.
// MM (where that leg starts and ends, and the letter's width, as parts of the font size) is measured from the font in main().
let MM = { adv: 0.925, rs: 0.6875, re: 0.885 }, LID = 0;
function mark(x, base, S, main, odd) {
  const id = 'mk' + (LID++), cut = x + MM.rs * S, gap = S * 0.035, drop = S * 0.1;
  const t = (f, extra) => `<text x="${x}" y="${base}" font-family="Inter Display" font-weight="900" font-size="${S}" fill="${f}" ${extra}>M</text>`;
  return `<clipPath id="${id}a"><rect x="${x - S}" y="${base - S}" width="${S + MM.rs * S - gap}" height="${S * 1.3}"/></clipPath><clipPath id="${id}b"><rect x="${cut}" y="${base - S}" width="${S}" height="${S * 1.5}"/></clipPath>` +
    t(main, `clip-path="url(#${id}a)"`) + `<g clip-path="url(#${id}b)">` + t(odd, `transform="translate(0,${drop})"`) + '</g>';
}

function scene() {
  let s = R(0, 0, W, H, C.night2), n = 0;
  for (let r = 0; r < 3; r++) for (let c = 0; c < 8; c++) { if ((c < 3 || c > 4) && !(c === LIT[0] && r === LIT[1])) { const [x, y] = winAt(c, r); s += win(x, y, n, false); } n++; }
  // the scanner's beam, then the lit window over it so the beam doesn't dull it
  const [lx, ly] = winAt(LIT[0], LIT[1]), sx = 120, sy = 120, m = (ly + WH / 2 - sy) / (lx + WW / 2 - sx);
  s += `<clipPath id="facade"><rect x="0" y="0" width="${W}" height="${STREET}"/></clipPath>`;
  s += P(`M${sx},${sy} L${W},${sy + (W - sx) * (m - 0.11)} L${W},${sy + (W - sx) * (m + 0.11)}Z`, C.cyan, 'opacity=".12" clip-path="url(#facade)"');
  s += win(lx, ly, 0, true) + scanner(sx, sy, 1.0, C.cyan);
  // the pier, the Administrator, her officers, the balcony and her banner
  s += R(690, 0, 540, STREET, C.slate) + R(690, 0, 12, STREET, C.slate2) + R(1218, 0, 12, STREET, C.night);
  s += `<circle cx="960" cy="200" r="185" fill="${C.red}"/>` + administrator(960, 40, 1.75);
  s += guard(721, 100, 0.62) + guard(1125, 100, 0.62);
  s += R(660, 398, 600, 26, C.steel) + R(676, 424, 568, 70, C.slate2) + R(676, 424, 568, 8, C.night);
  s += R(840, 494, 240, 276, C.red) + P(`M840,${STREET} L960,720 L1080,${STREET}Z`, C.slate) + emblem(960 - 52, 546, 2.6, C.paper);
  // the street band: the title (its M is the mark) and the two lines
  const S = 150, tx = 100, ix = tx + MM.adv * S + 6 + S * 0.06;
  s += R(0, STREET, W, H - STREET, C.night) + R(0, STREET, W, 6, C.slate);
  s += mark(tx, 960, S, C.paper, C.red) + T(ix, 960, S, C.paper, 'ISCOUNT', 'letter-spacing="6"');
  s += T(1040, 880, 30, C.cyan, 'MISCOUNT DETECTED IN YOUR BLOCK.', 'letter-spacing="2"');
  s += T(1040, 928, 23, C.steel2, 'EVERY RESIDENT HAS A MIND OF THEIR OWN,', 'letter-spacing="2"') + T(1040, 962, 23, C.steel2, 'BUT ONLY SOME ARE OTHER PLAYERS.', 'letter-spacing="2"');
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${W} ${H}" width="${W}" height="${H}">${s}</svg>`;
}
function markAlone() {
  const S = 380, x = 256 - (MM.re + 0.04) * S / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">${R(0, 0, 512, 512, C.night)}${mark(x, 256 + S * 0.335, S, C.paper, C.red)}</svg>`;
}

(async () => {
  const out = path.resolve(process.argv[2] || path.join(__dirname, 'out'));
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  for (const [name, scale] of [['miscount_1080.jpg', 1], ['miscount_4k.jpg', 2]]) {
    const pg = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: scale });
    await pg.setContent('<body style="margin:0"><span style="font:900 100px Inter Display">M</span></body>');
    MM = await pg.evaluate(async () => {
      await document.fonts.ready;
      const c = document.createElement('canvas'); c.width = 600; c.height = 500; const g = c.getContext('2d');
      g.font = '900 400px "Inter Display"'; g.fillText('M', 50, 400);
      const adv = g.measureText('M').width / 400, d = g.getImageData(0, 380, 600, 1).data, runs = []; let st = -1;
      for (let x = 0; x < 600; x++) { const on = d[x * 4 + 3] > 128; if (on && st < 0) st = x; if (!on && st >= 0) { runs.push([st, x]); st = -1; } }
      const last = runs[runs.length - 1];
      return { adv, rs: (last[0] - 50) / 400, re: (last[1] - 50) / 400 };
    });
    await pg.setContent(`<body style="margin:0">${scene()}</body>`);
    await pg.screenshot({ path: path.join(out, name), type: 'jpeg', quality: 92 });
    if (scale === 1) { await pg.setViewportSize({ width: 512, height: 512 }); await pg.setContent(`<body style="margin:0">${markAlone()}</body>`); await pg.screenshot({ path: path.join(out, 'miscount_mark.png') }); }
    await pg.close();
  }
  await browser.close();
  const b64 = fs.readFileSync(path.join(out, 'miscount_1080.jpg')).toString('base64');
  fs.writeFileSync(path.join(out, 'miscount_loading.html'), `<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Miscount</title>
<style>html,body{height:100%;margin:0;overflow:hidden;background:${C.night}}
body{background:${C.night} url(data:image/jpeg;base64,${b64}) center center no-repeat;-webkit-background-size:cover;background-size:cover}</style>
</head><body></body></html>
`);
  console.log('wrote', fs.readdirSync(out).join(', '));
})();
