// Draws the Resistance pamphlet's paper (the words of each page are drawn in game: cl_livingcity_dialog.lua).
// A cheap sheet run off on a hand-cranked duplicator and folded once: purple ink that didn't take evenly,
// a typewritten masthead, the lambda sprayed over it in orange, thumbprints, a cup ring.
// Run: node rebelpamphlet.js OUTDIR   (writes rebel_paper.jpg, 1024 x 690)
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const W = 1024, H = 690, FOLD = 512;
const INK = '#3b2a6b', INK2 = '#56408f', ORANGE = '#d9691c', PAPER = '#d8cdab';
let seed = 11;
const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
const typed = (t, x, y, size, extra = '') => `<text x="${x}" y="${y}" font-family="Courier 10 Pitch, FreeMono, monospace" font-weight="700" font-size="${size}" fill="${INK}" ${extra}>${t}</text>`;

let art = `<rect width="${W}" height="${H}" fill="${PAPER}"/>`;

// the duplicator's drum: bands where the ink ran thin or heavy, down both panels
let bands = '';
for (let i = 0; i < 22; i++) {
  const x = rnd() * W, w = 6 + rnd() * 46;
  bands += `<rect x="${x.toFixed(0)}" y="0" width="${w.toFixed(0)}" height="${H}" fill="${INK2}" opacity="${(0.015 + rnd() * 0.03).toFixed(3)}"/>`;
}
art += bands;

// ---- the cover (left of the fold) ----
let ink = '';
// the masthead, typed in capitals and struck twice where it mattered
ink += typed('READ THIS.', 34, 74, 50, 'letter-spacing="1"');
ink += typed('READ THIS.', 35.5, 75, 50, 'letter-spacing="1" opacity=".45"');
ink += typed('THEN PASS IT ON.', 36, 108, 24, 'letter-spacing="1.5"');
ink += `<path d="M34,124 L462,121" stroke="${INK}" stroke-width="3.5" fill="none"/><path d="M34,130 L462,128" stroke="${INK}" stroke-width="1.2" fill="none"/>`;
ink += typed('INSIDE:', 36, 152, 15, 'letter-spacing="3" opacity=".85"');
// a cut block at the foot: a hand passing a folded sheet to another hand
const hand = (flip) => `<g transform="${flip}"><path d="M0,40 L46,36 Q62,30 78,34 L112,30 Q122,30 121,37 Q120,43 110,44 L88,47 L118,49 Q127,51 125,57 Q123,62 114,61 L84,60 L108,66 Q115,69 112,74 Q109,78 101,76 L72,70 Q56,78 40,74 L0,78 Z" fill="${INK}"/><path d="M0,34 L0,84 L-70,92 L-70,26 Z" fill="${INK}"/><path d="M-8,36 L-8,82" stroke="${PAPER}" stroke-width="3"/></g>`;
ink += `<g transform="translate(96,560)">${hand('')}</g>`;
ink += `<g transform="translate(418,628) rotate(180)">${hand('')}</g>`;
// the sheet between them
ink += `<g transform="translate(236,566) rotate(-14)"><rect x="-34" y="-24" width="68" height="50" fill="${PAPER}" stroke="${INK}" stroke-width="4"/><path d="M-34,1 L34,1" stroke="${INK}" stroke-width="2"/><path d="M-24,-13 L22,-13 M-24,-6 L12,-6 M-24,10 L24,10 M-24,17 L6,17" stroke="${INK}" stroke-width="2.2"/></g>`;
// short rays off it, cut by hand
for (let i = 0; i < 9; i++) {
  const a = (-150 + i * 15) * Math.PI / 180, r0 = 52, r1 = 70 + (i % 2) * 12;
  ink += `<path d="M${(236 + Math.cos(a) * r0).toFixed(1)},${(560 + Math.sin(a) * r0).toFixed(1)} L${(236 + Math.cos(a) * r1).toFixed(1)},${(560 + Math.sin(a) * r1).toFixed(1)}" stroke="${INK}" stroke-width="4" stroke-linecap="round"/>`;
}
ink += typed('do not keep it.  do not burn it.  leave it where it will be found.', 34, 668, 13.5, 'opacity=".9"');

// ---- the page (right of the fold) ----
// a typed rule over the page and one under, where the words go between
ink += typed('= = = = = = = = = = = = = = = = = = = = = = = = = = = =', 546, 52, 14, 'opacity=".8"');
ink += typed('- - - - - - - - - - - - - - - - - - - - - - - - - - - -', 546, 622, 14, 'opacity=".7"');
ink += typed('printed by hand in this city.  no. ' + (100 + Math.floor(rnd() * 800)), 546, 650, 13.5, 'opacity=".9"');
// the stencil slipped: a ghost of the rule, lower and paler
ink += typed('= = = = = = = = = = = = = = = = = = = = = = = = = = = =', 549, 58, 14, 'opacity=".16"');

art += `<g filter="url(#mimeo)">${ink}</g>`;

// the lambda in its ring, sprayed over the cover's corner after printing, and a small one signing the page
const LAM = 'M-30,-34 Q-46,-2 -34,26 Q-10,52 26,34 Q52,6 36,-28 Q8,-52 -26,-36 M-15,-27 L-5,-27 L17,28 M-1,-5 L-17,28';
const lambda = (x, y, s, rot) => `<g transform="translate(${x},${y}) rotate(${rot}) scale(${s})" fill="none" stroke="${ORANGE}" stroke-linecap="round" stroke-linejoin="round"><path d="${LAM}" stroke-width="17" opacity=".28" filter="url(#over)"/><path d="${LAM}" stroke-width="9" filter="url(#spray)"/></g>`;
art += lambda(418, 78, 1.25, -9);
art += `<path d="M430,128 q-2,22 1,38" stroke="${ORANGE}" stroke-width="4" fill="none" stroke-linecap="round" opacity=".8" filter="url(#spray)"/>`;
art += lambda(950, 632, 0.42, 7);

// thumbprints in the duplicator's ink, where it was lifted off the drum
const thumb = (x, y, rot, op) => {
  let s = '';
  for (let i = 1; i <= 8; i++) s += `<ellipse cx="0" cy="${i * 0.8}" rx="${i * 3.1}" ry="${i * 4.3}" fill="none" stroke="${INK2}" stroke-width="1.5" stroke-dasharray="${5 + i} ${2 + (i % 3)}"/>`;
  return `<g transform="translate(${x},${y}) rotate(${rot})" opacity="${op}" filter="url(#mimeo)">${s}</g>`;
};
art += thumb(986, 318, 24, 0.34) + thumb(30, 380, -18, 0.2);

const html = `<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:#000}svg{display:block}</style></head><body>
<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><defs>
  <filter id="mimeo" x="-5%" y="-5%" width="110%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="3" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="2.6" result="d"/><feGaussianBlur in="d" stdDeviation="0.4" result="b"/><feTurbulence type="fractalNoise" baseFrequency="0.035 0.6" numOctaves="2" seed="8" result="m"/><feColorMatrix in="m" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -2.0 1.85" result="mask"/><feComposite in="b" in2="mask" operator="in"/></filter>
  <filter id="spray" x="-30%" y="-30%" width="160%" height="160%"><feTurbulence type="fractalNoise" baseFrequency="0.7" numOctaves="2" seed="6" result="n"/><feDisplacementMap in="SourceGraphic" in2="n" scale="5"/><feGaussianBlur stdDeviation="0.7"/></filter>
  <filter id="over" x="-40%" y="-40%" width="180%" height="180%"><feGaussianBlur stdDeviation="5"/></filter>
  <filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="2" seed="5"/><feColorMatrix values="0 0 0 0 0.16  0 0 0 0 0.13  0 0 0 0 0.08  0 0 0 -1.5 1.0"/></filter>
  <filter id="fibre" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.012 0.4" numOctaves="3" seed="14"/><feColorMatrix values="0 0 0 0 0.35  0 0 0 0 0.28  0 0 0 0 0.14  0 0 0 1.6 -0.75"/></filter>
  <filter id="dirt" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.016 0.028" numOctaves="4" seed="27"/><feColorMatrix values="0 0 0 0 0.24  0 0 0 0 0.18  0 0 0 0 0.09  0 0 0 3 -1.4"/></filter>
  <filter id="rough" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="3" seed="4"/><feDisplacementMap in="SourceGraphic" scale="14"/></filter>
  <radialGradient id="edge" cx="50%" cy="50%" r="75%"><stop offset="58%" stop-color="#2a1d0e" stop-opacity="0"/><stop offset="100%" stop-color="#2a1d0e" stop-opacity=".55"/></radialGradient>
  <linearGradient id="foldV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".44" stop-color="#fff" stop-opacity=".34"/><stop offset=".5" stop-color="#000" stop-opacity=".42"/><stop offset=".58" stop-color="#000" stop-opacity=".1"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
  <linearGradient id="foldH" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".45" stop-color="#fff" stop-opacity=".2"/><stop offset=".5" stop-color="#000" stop-opacity=".2"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
</defs>${art}
<rect width="${W}" height="${H}" filter="url(#fibre)" opacity=".3" style="mix-blend-mode:multiply"/>
<rect width="${W}" height="${H}" filter="url(#dirt)" opacity=".17" style="mix-blend-mode:multiply"/>
<g filter="url(#rough)" opacity=".55" style="mix-blend-mode:multiply"><ellipse cx="820" cy="560" rx="70" ry="64" fill="#6b5230" fill-opacity=".08" stroke="#57401f" stroke-opacity=".55" stroke-width="3.5"/><ellipse cx="300" cy="300" rx="120" ry="60" fill="#6b5230" fill-opacity=".1"/></g>
<rect x="${FOLD - 16}" y="0" width="32" height="${H}" fill="url(#foldV)"/>
<rect x="0" y="336" width="${W}" height="18" fill="url(#foldH)" opacity=".7"/>
<path d="M${W},0 L${W - 74},0 L${W},62 Z" fill="#b9ad8b"/><path d="M${W - 74},0 L${W},62 L${W - 70},58 Z" fill="#e3d9ba" stroke="#8f8362" stroke-width="1"/>
<rect width="${W}" height="${H}" fill="url(#edge)" style="mix-blend-mode:multiply"/>
<rect width="${W}" height="${H}" filter="url(#grain)" opacity=".55" style="mix-blend-mode:multiply"/>
</svg></body></html>`;
(async () => {
  const out = process.argv[2] || path.join(__dirname, 'out');
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const pg = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  await pg.setContent(html);
  await pg.evaluate(() => document.fonts.ready);
  await pg.screenshot({ path: path.join(out, 'rebel_paper.jpg'), type: 'jpeg', quality: 88 });
  await browser.close();
})();
