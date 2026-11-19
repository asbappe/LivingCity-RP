// The Resistance's deck for the card table (cl_livingcity_cards.lua): thirteen faces, one for each rank
// (2 to 14, the ace high), four suits and the back. A deck made by hand in a back room: stencils cut with a
// knife, black paint and orange on the card of Union ration boxes.
//   2 the can, 3 a ration, 4 a headcrab, 5 a manhack, 6 a barnacle, 7 a scanner, 8 Civil Protection,
//   9 an Overwatch Elite, 10 a strider, J a vortigaunt, Q the Administrator, K the Colonel, A the Free Man
// A face is ink alone on nothing; the card under it is its suit's (the owner, 19 November: one set of faces
// and four suit pictures, not four sets): suit1 the Resistance, suit2 the Combine, suit3 the Union, suit4 the
// vortigaunts. The game lays the face over the suit.
// Run: node cards.js OUTDIR   (writes 2.png to 14.png, suit1.png to suit4.png and back.png, 256 x 356,
// see-through corners, for materials/livingcity/cards/). Then python3 cards_shrink.py OUTDIR [SHEET.png],
// which makes the files small (SHEET: every face on a suit, the suits and the back on one picture, to look at).
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const W = 256, H = 356;
const K = '#1c1a17', O = '#d8701f', P = '#e6dcc0', BACK = '#3a2f26';
let seed = 7;
const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
const f = (d, col = K, extra = '') => `<path d="${d}" fill="${col}" ${extra}/>`;
const s = (d, w, col = K, extra = '') => `<path d="${d}" fill="none" stroke="${col}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" ${extra}/>`;
const c = (x, y, r, col = K, extra = '') => `<circle cx="${x}" cy="${y}" r="${r}" fill="${col}" ${extra}/>`;
const mirror = body => body + `<g transform="scale(-1,1)">${body}</g>`;
const LAMBDA = 'M-34,-52 L-12,-52 L40,56 L18,56 L-3,12 L-25,56 L-47,56 L-14,-10 Z';

// each picture is drawn around 0,0, about 200 wide and 230 high
const ART = {
  // pick up that can
  2: () => `<ellipse cx="6" cy="92" rx="70" ry="9" fill="${K}" opacity=".25"/>` +
    s('M-88,-30 Q-70,-52 -52,-58', 5, K, 'opacity=".55"') + s('M-92,4 Q-80,-12 -66,-18', 5, K, 'opacity=".55"') +
    `<g transform="rotate(-20)"><rect x="-38" y="-62" width="76" height="126" rx="12" fill="${K}"/>` +
    `<rect x="-38" y="-20" width="76" height="40" fill="${O}"/>` + f('M38,-50 L20,-32 L38,-12 Z', P) +
    `<ellipse cx="0" cy="-62" rx="38" ry="10" fill="${P}" stroke="${K}" stroke-width="6"/><ellipse cx="4" cy="-62" rx="10" ry="3.5" fill="${K}"/>` +
    s('M-26,34 L-26,52', 5, P, 'opacity=".5"') + '</g>',
  // a ration packet
  3: () => f('M-56,-78 L56,-78 L64,92 L-64,92 Z') + s('M-52,-62 l13,-9 l13,9 l13,-9 l13,9 l13,-9 l13,9 l13,-9 l13,9', 4, P) +
    `<rect x="-42" y="-38" width="84" height="72" fill="${P}"/>` + `<circle cx="0" cy="-2" r="22" fill="none" stroke="${K}" stroke-width="7"/>` +
    f('M0,-2 L30,-20 L30,10 Z', P) + c(0, -2, 7) + f('M-63,50 L63,50 L64,72 L-64,72 Z', O),
  // a headcrab
  4: () => mirror(s('M-50,-10 Q-92,-22 -100,34', 12) + s('M-42,18 Q-74,34 -70,90', 14) + s('M-70,90 l-10,10', 7) + s('M-100,34 l-8,10', 7)) +
    f('M-64,12 Q-68,-48 0,-56 Q68,-48 64,12 Q40,38 0,34 Q-40,38 -64,12 Z') + s('M-36,-32 Q0,-48 36,-32', 5, P, 'opacity=".45"') +
    `<ellipse cx="0" cy="22" rx="22" ry="10" fill="${O}"/>` + f('M-16,14 l5,9 l5,-9 Z M-3,14 l5,9 l5,-9 Z M10,14 l4,8 l4,-8 Z', P),
  // a manhack
  5: () => `<circle cx="0" cy="0" r="92" fill="none" stroke="${K}" stroke-width="3.5" stroke-dasharray="46 54" opacity=".45"/>` +
    [0, 120, 240].map(a => `<g transform="rotate(${a})">${f('M0,-20 Q50,-70 86,-22 Q50,-38 14,-2 Z')}</g>`).join('') +
    c(0, 0, 30) + `<circle cx="0" cy="0" r="17" fill="none" stroke="${P}" stroke-width="4"/>` + c(0, 0, 8, O),
  // a barnacle, and what it caught
  6: () => `<rect x="-72" y="-116" width="176" height="14" fill="${K}"/>` + f('M-48,-104 Q-62,-40 -32,-22 Q0,-8 32,-22 Q62,-40 48,-104 Z') +
    f('M-30,-26 l6,13 l6,-12 Z M-15,-21 l6,14 l6,-14 Z M2,-21 l6,14 l6,-14 Z M18,-24 l6,12 l6,-13 Z', P) +
    s('M0,-18 Q12,22 -4,56 Q-10,76 2,92', 9, O) + f('M-10,88 L12,88 L12,106 L32,112 L32,122 L-10,122 Z') + s('M-10,114 L32,114', 3, P),
  // a city scanner
  7: () => s('M-30,58 L-48,100', 6, O) + s('M0,70 L0,112', 6, O) + s('M30,58 L48,100', 6, O) +
    f('M-22,-36 L0,-80 L22,-36 Z') + f('M-14,36 L0,64 L14,36 Z') + mirror(f('M-54,-12 L-100,-30 L-94,16 L-54,16 Z')) +
    `<ellipse cx="0" cy="0" rx="60" ry="42" fill="${K}"/>` + c(0, 4, 24, P) + c(0, 4, 14, O) + c(0, 4, 6) + c(-8, -4, 3, P),
  // Civil Protection
  8: () => s('M66,-84 L92,22', 8, O) + s('M88,8 L96,44', 12) + s('M56,-96 l-10,-8 M66,-102 l0,-12 M76,-96 l10,-8', 4, O) +
    f('M-74,116 L-74,88 Q-42,66 -22,62 L22,62 Q42,66 74,88 L74,116 Z') +
    f('M-52,-10 Q-54,-82 0,-84 Q54,-82 52,-10 Q50,42 24,64 L-24,64 Q-50,42 -52,-10 Z') + s('M-22,68 L0,96 L22,68', 4, P) +
    c(-23, -20, 16, P) + c(23, -20, 16, P) + c(-28, -25, 4, K, 'opacity=".25"') + c(18, -25, 4, K, 'opacity=".25"') +
    `<rect x="-17" y="20" width="34" height="32" rx="7" fill="${P}"/>` + s('M-9,29 L9,29 M-9,36 L9,36 M-9,43 L9,43', 3),
  // an Overwatch Elite
  9: () => f('M-76,116 L-76,90 Q-44,66 -26,60 L26,60 Q44,66 76,90 L76,116 Z') + mirror(s('M-16,36 Q-46,42 -54,72', 8)) +
    `<path d="M-56,0 Q-60,-88 0,-90 Q60,-88 56,0 Q56,38 30,60 L-30,60 Q-56,38 -56,0 Z" fill="${P}" stroke="${K}" stroke-width="8"/>` +
    s('M-40,-58 Q0,-78 40,-58', 4, K, 'opacity=".35"') + c(0, -18, 23) + c(0, -18, 13, O) + c(-5, -23, 3.5, P) +
    `<rect x="-19" y="20" width="38" height="28" rx="6" fill="${K}"/>` + s('M-10,30 L10,30 M-10,38 L10,38', 3, P),
  // a strider over the roofs
  10: () => f('M-104,116 L-104,98 L-84,98 L-84,84 L-62,84 L-62,104 L-40,104 L-40,90 L-18,90 L-18,106 L22,106 L22,94 L44,94 L44,80 L62,80 L62,102 L104,102 L104,116 Z', K, 'opacity=".5"') +
    s('M-26,-70 L-72,-108 L-86,114', 9) + s('M30,-72 L80,-104 L94,114', 9) + s('M2,-62 L12,-24 L-2,114', 9) +
    f('M-38,-94 L32,-100 L50,-80 L22,-60 L-34,-62 Z') + s('M-10,-60 L-20,-30', 7) + c(-21, -27, 6, O) + c(-18, -80, 4, P),
  // a vortigaunt, freed
  J: () => c(0, 54, 34, O, 'opacity=".22"') + f('M-17,-30 Q-31,-10 -27,40 L-20,116 L20,116 L27,40 Q31,-10 17,-30 Z') + s('M0,-40 L0,-24', 13) +
    mirror(s('M-20,-16 L-66,20 L-26,56', 15, P) + s('M-20,-16 L-66,20 L-26,56', 8) + s('M-26,56 l11,-9 M-26,56 l13,4', 5)) +
    s('M-16,54 L-7,43 L1,63 L9,45 L16,54', 4.5, O) + s('M0,32 l0,-11 M-18,36 l-8,-8 M18,36 l8,-8', 4, O) +
    f('M-30,-68 Q-32,-104 0,-106 Q32,-104 30,-68 Q20,-46 0,-38 Q-20,-46 -30,-68 Z') + c(0, -68, 14, O) + c(0, -68, 6) + c(-4, -72, 2.2, P) +
    c(-16, -89, 3, P) + c(0, -94, 3, P) + c(16, -89, 3, P),
  // the Administrator, on every screen in the city
  Q: () => `<rect x="-88" y="-108" width="176" height="196" rx="16" fill="${K}"/><rect x="-72" y="-92" width="144" height="164" rx="6" fill="${O}"/>` +
    `<rect x="-34" y="88" width="68" height="12" fill="${K}"/><rect x="-56" y="100" width="112" height="12" rx="4" fill="${K}"/>` +
    `<g clip-path="url(#screen)">` + c(0, -64, 10) + `<ellipse cx="0" cy="-34" rx="17" ry="23" fill="${K}"/>` + s('M0,-14 L0,10', 10) +
    f('M-38,76 L-38,40 Q-34,16 -11,8 L11,8 Q34,16 38,40 L38,76 Z') + s('M-9,10 L0,30 L9,10', 3.5, O) + c(0, 42, 3.5, O) +
    Array.from({ length: 16 }, (_, i) => `<rect x="-72" y="${-90 + i * 10}" width="144" height="3" fill="${P}" opacity=".16"/>`).join('') + '</g>' +
    c(60, 80, 4, O),
  // the Colonel
  K: () => f('M-80,116 L-80,84 Q-46,56 -22,50 L22,50 Q46,56 80,84 L80,116 Z') + s('M-20,54 L0,84 L20,54', 4, P) + c(-40, 92, 7, O) + s('M-40,76 L-40,86', 6, P) +
    `<ellipse cx="0" cy="-22" rx="33" ry="40" fill="${P}" stroke="${K}" stroke-width="7"/>` + mirror(s('M-22,-34 L-7,-29', 5) + c(-13, -22, 3.5)) +
    f('M-34,-4 Q-16,-22 0,-8 Q16,-22 34,-4 Q30,10 16,2 Q6,-2 0,2 Q-6,-2 -16,2 Q-30,10 -34,-4 Z') +
    f('M-42,-40 Q-46,-90 8,-88 Q62,-86 50,-48 Q12,-62 -42,-40 Z') + c(-14, -64, 8, O) + s('M10,-88 l4,-9', 5),
  // the Free Man
  A: () => `<circle cx="0" cy="0" r="84" fill="none" stroke="${O}" stroke-width="15"/>` +
    s('M-84,100 L60,-74 Q72,-100 102,-86', 13) + s('M-84,100 l-15,2 M-84,100 l-2,15', 8) + s('M-52,66 L30,-34', 3, P, 'opacity=".35"') +
    `<path d="${LAMBDA}" fill="${O}" stroke="${P}" stroke-width="7" stroke-linejoin="round" paint-order="stroke"/>`,
};
const INDEX = { 11: 'J', 12: 'Q', 13: 'K', 14: 'A' };

const DEFS = `
  <clipPath id="card"><rect x="1" y="1" width="${W - 2}" height="${H - 2}" rx="18"/></clipPath>
  <clipPath id="screen"><rect x="-72" y="-92" width="144" height="164" rx="6"/></clipPath>
  <filter id="cut" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.06" numOctaves="2" seed="4"/><feDisplacementMap in="SourceGraphic" scale="3.2"/></filter>
  <filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.022" numOctaves="2" seed="SEED"/><feColorMatrix values="0 0 0 0 0.25  0 0 0 0 0.18  0 0 0 0 0.1  0 0 0 0.75 -0.33"/></filter>
  <filter id="blur"><feGaussianBlur stdDeviation="9"/></filter>
  <radialGradient id="wear" cx="50%" cy="50%" r="72%"><stop offset="62%" stop-color="#3a2a16" stop-opacity="0"/><stop offset="100%" stop-color="#3a2a16" stop-opacity=".38"/></radialGradient>`;

// thumbed and scuffed, differently on every card
function wear(dark) {
  let out = `<rect width="${W}" height="${H}" fill="url(#wear)"/>`;
  for (let i = 0; i < 5; i++) {
    const x = rnd() * W, y = rnd() * H, a = rnd() * 6.28, l = 14 + rnd() * 40;
    out += s(`M${x.toFixed(0)},${y.toFixed(0)} l${(Math.cos(a) * l).toFixed(0)},${(Math.sin(a) * l).toFixed(0)}`, 1.2, dark ? P : '#5a4630', `opacity="${(0.12 + rnd() * 0.16).toFixed(2)}"`);
  }
  const corner = rnd() < 0.5 ? [W - 26, 0, W, 30] : [0, H - 30, 26, H];
  out += s(`M${corner[0]},${corner[1]} L${corner[2]},${corner[3]}`, 1.5, '#5a4630', 'opacity=".4"'); // (a bent corner)
  return out + `<rect width="${W}" height="${H}" filter="url(#grain)"/>`;
}

// a face: the picture and its rank in two corners, in ink alone on nothing (the suit's card goes under it in game)
function face(rank) {
  const idx = INDEX[rank] || String(rank), art = ART[idx]();
  const corner = `<text x="31" y="52" text-anchor="middle" font-family="Liberation Sans, DejaVu Sans, sans-serif" font-weight="700" font-size="${idx.length > 1 ? 34 : 42}" ${idx.length > 1 ? 'letter-spacing="-3"' : ''} fill="${K}">${idx}</text>`;
  return `<g clip-path="url(#card)"><g filter="url(#cut)"><g transform="translate(${W / 2},${H / 2 + 4}) scale(.9)">${art}</g>${corner}<g transform="rotate(180 ${W / 2} ${H / 2})">${corner}</g></g></g>`;
}

// the four suits: the card itself (its paper, its line, wear) with the suit's mark under each rank and faint in the
// middle. 1 the Resistance, 2 the Combine, 3 the Union, 4 the vortigaunts. Each mark is drawn around 0,0, about 100 across.
const SUITS = [
  { paper: '#e6dcc0', col: O, mark: col => f(LAMBDA, col) },
  { paper: '#d5dcdc', col: '#2c6a82', mark: col => s('M36,-36 A50,50 0 1 0 36,36', 17, col, 'stroke-linecap="butt"') + s('M40,0 L-6,0 L-6,24', 15, col, 'stroke-linecap="butt" stroke-linejoin="miter"') },
  { paper: '#e2d9b4', col: '#a87c14', mark: col => `<circle cx="0" cy="0" r="30" fill="none" stroke="${col}" stroke-width="15"/>` +
      [0, 45, 90, 135, 180, 225, 270, 315].map(a => `<rect x="-9" y="-54" width="18" height="20" fill="${col}" transform="rotate(${a})"/>`).join('') + c(0, 0, 8, col) },
  { paper: '#d6dfc2', col: '#4c8527', mark: col => `<path d="M-54,6 Q0,-42 54,6 Q0,50 -54,6 Z" fill="none" stroke="${col}" stroke-width="11" stroke-linejoin="round"/>` + c(0, 6, 17, col) +
      c(-24, -40, 6, col) + c(0, -48, 6, col) + c(24, -40, 6, col) },
];
function suit(n) {
  const S = SUITS[n - 1];
  const corner = `<g transform="translate(31,76) scale(.24)">${S.mark(S.col)}</g>`;
  return `<g clip-path="url(#card)"><rect width="${W}" height="${H}" fill="${S.paper}"/>` +
    `<rect x="10" y="10" width="${W - 20}" height="${H - 20}" rx="11" fill="none" stroke="${S.col}" stroke-width="3" opacity=".75"/>` +
    `<g filter="url(#cut)"><g transform="translate(${W / 2},${H / 2 + 4}) scale(1.9)" opacity=".13">${S.mark(S.col)}</g>${corner}<g transform="rotate(180 ${W / 2} ${H / 2})">${corner}</g></g>` +
    wear(false) + '</g>' +
    `<rect x="1" y="1" width="${W - 2}" height="${H - 2}" rx="18" fill="none" stroke="#2a241c" stroke-width="2" opacity=".7"/>`;
}

// the back: a ration box's card, a knife-cut border and the lambda sprayed over it
function back() {
  let hatch = '';
  for (let i = -H; i < W + H; i += 14) hatch += `<path d="M${i},0 L${i + H},${H} M${i + H},0 L${i},${H}" stroke="#57483a" stroke-width="2" fill="none"/>`;
  const ring = 'M-30,-34 Q-46,-2 -34,26 Q-10,52 26,34 Q52,6 36,-28 Q8,-52 -26,-36 M-15,-27 L-5,-27 L17,28 M-1,-5 L-17,28';
  return `<g clip-path="url(#card)"><rect width="${W}" height="${H}" fill="${BACK}"/>` +
    `<clipPath id="in"><rect x="20" y="20" width="${W - 40}" height="${H - 40}" rx="8"/></clipPath><g clip-path="url(#in)" opacity=".8">${hatch}</g>` +
    `<rect x="20" y="20" width="${W - 40}" height="${H - 40}" rx="8" fill="none" stroke="${P}" stroke-width="3" opacity=".55"/>` +
    `<rect x="12" y="12" width="${W - 24}" height="${H - 24}" rx="13" fill="none" stroke="${P}" stroke-width="1.5" opacity=".35"/>` +
    c(W / 2, H / 2, 74, BACK) + `<g transform="translate(${W / 2},${H / 2}) rotate(-6) scale(1.5)">` +
    s(ring, 18, O, 'opacity=".3" filter="url(#blur)"') + `<g filter="url(#cut)">${s(ring, 10, O)}</g></g>` +
    s(`M${W / 2 + 12},${H / 2 + 62} l1,38`, 4, O, 'opacity=".8"') + wear(true) + '</g>' +
    `<rect x="1" y="1" width="${W - 2}" height="${H - 2}" rx="18" fill="none" stroke="#17120d" stroke-width="2" opacity=".8"/>`;
}

const svg = (body, n) => `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}"><defs>${DEFS.replace(/SEED/g, String(n))}</defs>${body}</svg>`;
const page = body => `<!doctype html><html><head><style>html,body{margin:0;background:transparent}svg{display:block}</style></head><body>${body}</body></html>`;

(async () => {
  const out = process.argv[2] || path.join(__dirname, 'out');
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const pg = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 1 });
  const names = [];
  for (let rank = 2; rank <= 14; rank++) {
    await pg.setContent(page(svg(face(rank), rank)));
    await pg.screenshot({ path: path.join(out, rank + '.png'), omitBackground: true });
    names.push(rank + '.png');
  }
  for (let n = 1; n <= 4; n++) {
    await pg.setContent(page(svg(suit(n), 20 + n)));
    await pg.screenshot({ path: path.join(out, 'suit' + n + '.png'), omitBackground: true });
  }
  await pg.setContent(page(svg(back(), 1)));
  await pg.screenshot({ path: path.join(out, 'back.png'), omitBackground: true });
  await browser.close();
})();
