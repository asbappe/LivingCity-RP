// Draws the Civil Orientation pamphlet's paper (the words are drawn in game: cl_livingcity_dialog.lua).
// Run: node pamphlet.js OUTDIR   (writes paper.png, 1024 x 690)
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const { C, P, R, G, emblem } = require('./lib.js');
const W = 1024, H = 690;
let art = R(0, 0, W, H, C.paper);
// the cover panel's band, and the mark
art += R(0, 0, 333, 114, C.slate) + R(0, 114, 333, 7, C.red) + emblem(29, 28, 1.3, C.paper);
// a pale city along the foot of the cover panel
art += P('M0,690 L0,628 L30,628 L30,600 L70,600 L70,640 L104,640 L104,612 L150,612 L150,650 L196,650 L196,620 L230,620 L230,590 L262,590 L262,640 L300,640 L300,616 L333,616 L333,690Z', C.steel2, 'opacity=".55"');
for (let i = 0; i < 26; i++) art += R(36 + (i % 13) * 22.5, 618 + Math.floor(i / 13) * 22 + (i % 3) * 5, 6, 9, C.paper, 'opacity=".7"');
// a faint mark behind the page, a stamp, and the printer's marks
art += emblem(560, 250, 7.5, C.slate, ).replace('<g ', '<g opacity=".045" ');
art += `<g transform="rotate(-13 912 592)" opacity=".62"><circle cx="912" cy="592" r="50" fill="none" stroke="${C.red}" stroke-width="5"/><circle cx="912" cy="592" r="39" fill="none" stroke="${C.red}" stroke-width="2"/>${emblem(895, 570, 0.86, C.red)}<rect x="852" y="616" width="120" height="4" fill="${C.red}"/></g>`;
art += `<g stroke="${C.ink}" stroke-width="1.2" fill="none" opacity=".55"><circle cx="1000" cy="22" r="7"/><path d="M988,22 L1012,22 M1000,10 L1000,34"/></g>`;
art += R(940, 16, 12, 12, C.slate) + R(954, 16, 12, 12, C.red) + R(968, 16, 12, 12, C.steel);
const html = `<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0}svg{display:block}</style></head><body>
<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><defs>
  <filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="5"/><feColorMatrix values="0 0 0 0 0.12  0 0 0 0 0.11  0 0 0 0 0.09  0 0 0 -1.6 1.05"/></filter>
  <filter id="specks" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.5" numOctaves="1" seed="9"/><feColorMatrix values="0 0 0 0 0.87  0 0 0 0 0.84  0 0 0 0 0.76  0 0 0 14 -10.2"/></filter>
  <filter id="dirt" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.02 0.035" numOctaves="4" seed="21"/><feColorMatrix values="0 0 0 0 0.2  0 0 0 0 0.16  0 0 0 0 0.1  0 0 0 2.8 -1.5"/></filter>
  <filter id="rough" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="3" seed="4"/><feDisplacementMap in="SourceGraphic" scale="16"/></filter>
  <radialGradient id="edge" cx="50%" cy="50%" r="75%"><stop offset="62%" stop-color="#2a2015" stop-opacity="0"/><stop offset="100%" stop-color="#2a2015" stop-opacity=".45"/></radialGradient>
  <linearGradient id="foldV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".46" stop-color="#fff" stop-opacity=".3"/><stop offset=".5" stop-color="#000" stop-opacity=".34"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
</defs>${art}
<rect width="${W}" height="${H}" filter="url(#specks)" opacity=".8"/>
<rect width="${W}" height="${H}" filter="url(#dirt)" opacity=".26" style="mix-blend-mode:multiply"/>
<g filter="url(#rough)" opacity=".5" style="mix-blend-mode:multiply"><ellipse cx="760" cy="150" rx="74" ry="66" fill="#6b5837" fill-opacity=".1" stroke="#57452a" stroke-opacity=".5" stroke-width="3"/><ellipse cx="180" cy="520" rx="52" ry="44" fill="#6b5837" fill-opacity=".1" stroke="#57452a" stroke-opacity=".4" stroke-width="2.5"/></g>
<rect x="321" y="0" width="24" height="${H}" fill="url(#foldV)"/><rect x="667" y="0" width="24" height="${H}" fill="url(#foldV)" opacity=".8"/>
<rect width="${W}" height="${H}" fill="url(#edge)" style="mix-blend-mode:multiply"/>
<rect width="${W}" height="${H}" filter="url(#grain)" opacity=".5" style="mix-blend-mode:multiply"/>
</svg></body></html>`;
(async () => {
  const out = process.argv[2] || path.join(__dirname, 'out');
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const pg = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  await pg.setContent(html);
  await pg.screenshot({ path: path.join(out, 'paper.png') });
  await browser.close();
})();
