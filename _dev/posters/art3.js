// The Resistance's answer: paint over the city's posters, and four paste-ups of their own.
const { C, P, R, G, emblem } = require('./lib.js');

const WHITE = '#f2eee4', BLACK = '#131313', ORANGE = '#e8912a';

// Everything the Resistance writes is sprayed by hand from a can (the owner, 10 November: "like someone
// used a spray paint to write it by hand rather than stencil"): single round strokes, every letter a little
// different, every line at its own tilt, with overspray and runs.
let seed = 3;
const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;

// the lambda in a ring, sprayed in a few strokes, about 100 across, centre at 0,0
function lambda(x, y, s, col, rot = 0) {
  const d = 'M-30,-34 Q-46,-2 -34,26 Q-10,52 26,34 Q52,6 36,-28 Q8,-52 -26,-36 M-15,-27 L-5,-27 L17,28 M-1,-5 L-17,28';
  const st = `fill="none" stroke="${col}" stroke-linecap="round" stroke-linejoin="round"`;
  return G(`translate(${x},${y}) rotate(${rot + (rnd() * 16 - 8)}) scale(${s})`,
    `<path d="${d}" ${st} stroke-width="16" opacity=".3" filter="url(#over)"/><path d="${d}" ${st} stroke-width="9" filter="url(#spray)"/>`);
}

// a hand alphabet: each letter a few strokes on a grid 14 high (the baseline at 14). [strokes, width]
const HAND = {
  A: ['M0,14 L5,0 L10,14 M2.2,9 L7.8,9', 10], B: ['M0,14 L0,0 L5,0 Q9,0 9,3.5 Q9,7 5,7 L0,7 M5,7 Q10,7 10,10.5 Q10,14 5,14 L0,14', 10],
  C: ['M10,2.5 Q8,0 5.5,0 Q0,0 0,7 Q0,14 5.5,14 Q8,14 10,11.5', 10], D: ['M0,0 L0,14 L4,14 Q10,14 10,7 Q10,0 4,0 L0,0', 10],
  E: ['M9,0 L0,0 L0,14 L9,14 M0,7 L7,7', 9], F: ['M9,0 L0,0 L0,14 M0,7 L7,7', 9],
  G: ['M10,2.5 Q8,0 5.5,0 Q0,0 0,7 Q0,14 5.5,14 Q10,14 10,8 L5.5,8', 10], H: ['M0,0 L0,14 M10,0 L10,14 M0,7 L10,7', 10],
  I: ['M1,0 L1,14', 2], J: ['M7,0 L7,10 Q7,14 3.5,14 Q0,14 0,10.5', 7], K: ['M0,0 L0,14 M9,0 L0,8 M3.5,5.5 L10,14', 10],
  L: ['M0,0 L0,14 L8,14', 8], M: ['M0,14 L0,0 L6,9 L12,0 L12,14', 12], N: ['M0,14 L0,0 L10,14 L10,0', 10],
  O: ['M5.5,0 Q0,0 0,7 Q0,14 5.5,14 Q11,14 11,7 Q11,0 5.5,0', 11], P: ['M0,14 L0,0 L5,0 Q10,0 10,4 Q10,8 5,8 L0,8', 10],
  Q: ['M5.5,0 Q0,0 0,7 Q0,14 5.5,14 Q11,14 11,7 Q11,0 5.5,0 M7,10 L11,14.5', 11], R: ['M0,14 L0,0 L5,0 Q10,0 10,4 Q10,8 5,8 L0,8 M5,8 L10,14', 10],
  S: ['M9.5,2.5 Q8,0 5,0 Q0.5,0 0.5,3.5 Q0.5,6.5 5,7 Q9.5,7.5 9.5,10.5 Q9.5,14 5,14 Q1.5,14 0,11.5', 10], T: ['M0,0 L10,0 M5,0 L5,14', 10],
  U: ['M0,0 L0,9 Q0,14 5,14 Q10,14 10,9 L10,0', 10], V: ['M0,0 L5,14 L10,0', 10], W: ['M0,0 L3.5,14 L7,3 L10.5,14 L14,0', 14],
  X: ['M0,0 L10,14 M10,0 L0,14', 10], Y: ['M0,0 L5,7 L10,0 M5,7 L5,14', 10], Z: ['M0,0 L10,0 L0,14 L10,14', 10],
  "'": ['M1.2,0 L0.6,3.5', 2], '.': ['M1,13.4 L1.3,14', 2], ' ': ['', 5],
};
// sprayed words: [text, x (centre), y (baseline), size, turn (ignored: each line finds its own), colour]
function scrawl(w) {
  const [raw, x, y0, size, , col, o = {}] = w;
  const tm = o.tm || 11, jit = o.jit === undefined ? 12 : o.jit, run = o.run || 0.75;
  const txt = raw.toUpperCase();
  let k = size * 0.727 / 14; // (size is a type size: its capitals are about 0.727 of it)
  const gap = 2.6;
  let width = 0;
  for (const ch of txt) width += (HAND[ch] || HAND[' '])[1] + gap;
  width -= gap;
  if (width * k > 660) k = 660 / width;
  const sw = Math.max(1.5, 2.3 - k * 0.04); // (the can's line: about the same on the wall whatever the letter size)
  const tilt = rnd() * 2 * tm - tm * 1.18, cx = x + (rnd() * 50 - 25) * (jit / 12), y = y0 + (rnd() * 2 - 1) * jit;
  const rise = (rnd() * 2 - 1) * 1.6; // (the line drifts up or down as the arm moves)
  let letters = '', drips = '', px = -width / 2, n = 0;
  const rad = tilt * Math.PI / 180;
  for (const ch of txt) {
    const [d, lw] = HAND[ch] || HAND[' '];
    if (d) {
      const t = (px + width / 2) / width;
      const ly = -14 + rise * (t - 0.5) * 4 + (rnd() * 2 - 1) * 0.9, lr = rnd() * 12 - 6, ls = 0.9 + rnd() * 0.22;
      letters += `<path transform="translate(${px.toFixed(2)},${ly.toFixed(2)}) rotate(${lr.toFixed(1)} ${lw / 2} 14) scale(${ls.toFixed(2)})" d="${d}"/>`;
      if (rnd() < 0.42) {
        // a run: straight down the wall from somewhere along the letter's foot
        const ux = (px + rnd() * lw) * k, uy = (ly + 14) * k;
        const gx = cx + ux * Math.cos(rad) - uy * Math.sin(rad), gy = y + ux * Math.sin(rad) + uy * Math.cos(rad);
        const len = 14 + rnd() * size * run;
        drips += `<path d="M${gx.toFixed(1)},${(gy - 4).toFixed(1)} L${gx.toFixed(1)},${(gy + len).toFixed(1)}" stroke="${col}" stroke-width="${(sw * k * (0.28 + rnd() * 0.2)).toFixed(1)}" stroke-linecap="round" fill="none"/>`;
      }
      n++;
    }
    px += lw + gap;
  }
  const st = `fill="none" stroke="${col}" stroke-linecap="round" stroke-linejoin="round"`;
  const place = `translate(${cx.toFixed(1)},${y.toFixed(1)}) rotate(${tilt.toFixed(1)}) scale(${k.toFixed(3)})`;
  return `<g transform="${place}" ${st} stroke-width="${(sw * 2.1).toFixed(2)}" opacity=".28" filter="url(#over)">${letters}</g>` +
    `<g filter="url(#spray)"><g transform="${place}" ${st} stroke-width="${sw.toFixed(2)}">${letters}</g>${drips}</g>`;
}
// a slash of the can through a headline line
function strike(y, col) {
  const a = rnd() * 26 - 13, b = rnd() * 26 - 13;
  const d = `M${40 + rnd() * 30},${y + a} L${700 + rnd() * 30},${y - a + 6} M${690 + rnd() * 30},${y + b + 14} L${60 + rnd() * 40},${y - b + 20}`;
  const st = `fill="none" stroke="${col}" stroke-linecap="round" stroke-linejoin="round"`;
  return `<path d="${d}" ${st} stroke-width="30" opacity=".28" filter="url(#over)"/><path d="${d}" ${st} stroke-width="15" filter="url(#spray)"/>`;
}

// id = { strike: [headline lines struck out], words: [...], lam: [x, y, size, turn], extra }
const DEFACE = {
  dispenser: { strike: [1], words: [['CHAINS', 384, 430, 160, -8, WHITE]], lam: [640, 150, 1.0, -10] },
  commissary: { strike: [1], words: [['THE', 384, 300, 110, -7, WHITE], ['COMBINE', 384, 430, 130, -7, ORANGE]], lam: [120, 520, 1.0, 8] },
  intake: { words: [['LIKE', 384, 270, 120, -9, WHITE], ['CATTLE', 384, 400, 140, -9, ORANGE]], lam: [650, 560, 0.9, 6] },
  water: { words: [["DON'T DRINK IT", 384, 300, 92, -8, WHITE], ['it makes you forget', 384, 400, 56, -8, ORANGE]], lam: [200, 540, 1.0, -8] },
  law: { strike: [0], words: [['BREAK IT', 384, 380, 150, -10, WHITE]], lam: [130, 150, 0.9, 8] },
  curfew: { words: [['THE NIGHT', 384, 290, 112, -7, WHITE], ['IS OURS', 384, 410, 124, -7, ORANGE]], lam: [120, 540, 0.9, -6] },
  work: { words: [['BUSY HANDS', 384, 300, 98, -7, WHITE], ['BUILD CAGES', 384, 410, 98, -7, ORANGE]], lam: [660, 130, 0.9, 10] },
  loyalty: { words: [['SO IS', 384, 320, 110, -8, WHITE], ['COURAGE', 384, 450, 132, -8, ORANGE]], lam: [130, 150, 0.9, -8] },
  informants: { words: [['SNITCHES', 384, 300, 124, -8, WHITE], ['BURN', 384, 450, 170, -8, ORANGE]], lam: [660, 560, 0.9, 8] },
  contraband: { strike: [1], words: [['ARMS US', 384, 420, 140, -8, WHITE]], lam: [130, 140, 1.0, -8] },
  radio: { words: [['WE HEAR', 384, 290, 122, -8, WHITE], ['YOU TOO', 384, 420, 122, -8, ORANGE]], lam: [150, 150, 0.9, 6] },
  illness: { words: [['THE CITY IS', 384, 290, 98, -7, WHITE], ['THE SICKNESS', 384, 400, 98, -7, ORANGE]], lam: [150, 560, 0.9, -6] },
  infestation: { words: [['THEY LET', 384, 290, 112, -8, WHITE], ['IT GROW', 384, 420, 122, -8, ORANGE]], lam: [150, 560, 0.9, 6] },
  housing: { strike: [1], words: [['IS A', 384, 300, 120, -7, WHITE], ['CELL', 384, 450, 170, -7, ORANGE]], lam: [130, 540, 1.0, -8] },
  vortigaunt: { words: [['FREE', 384, 280, 150, -9, WHITE], ['THEM', 384, 430, 150, -9, ORANGE]], lam: [130, 130, 0.9, 8] },
  recruit: { words: [['TRAITORS', 384, 360, 132, -8, WHITE]], lam: [130, 150, 0.9, -8] },
  neighbour: { words: [['LIES', 384, 400, 230, -8, WHITE]], lam: [130, 150, 0.9, -8] },
  administrator: { words: [['LIAR', 384, 500, 210, -8, WHITE]], lam: [660, 130, 0.9, 8],
    extra: `<g filter="url(#spray)" stroke="${BLACK}" stroke-width="15" stroke-linecap="round" fill="none"><path d="M296,218 L374,282 M378,226 L302,274 M394,224 L470,280 M466,216 L398,284"/></g>` },
};

function defaceLayer(p) {
  const d = DEFACE[p.id];
  if (!d) return '';
  let s = '';
  // where the headline lines sit (as page() lays them out)
  let y = 634 + 20 + (p.head.length === 1 ? 14 : 0);
  const mids = [];
  for (const [, size] of p.head) { const cap = size * 0.727; y += cap; mids.push(y - cap / 2); y += 15; }
  const dark = p.accent === 'cyan';
  for (const i of d.strike || []) s += strike(mids[i], dark ? WHITE : BLACK);
  if (d.extra) s += d.extra;
  for (const w of d.words) s += scrawl(w);
  s += lambda(d.lam[0], d.lam[1], d.lam[2], ORANGE, d.lam[3]);
  // overspray and a few flecks
  for (let i = 0; i < 26; i++) s += `<circle cx="${(60 + rnd() * 650).toFixed(0)}" cy="${(80 + rnd() * 800).toFixed(0)}" r="${(1 + rnd() * 3.5).toFixed(1)}" fill="${rnd() > 0.5 ? WHITE : ORANGE}" opacity="${(0.4 + rnd() * 0.5).toFixed(2)}"/>`;
  return s;
}

// ---- the Resistance's own paste-ups: brush and spray can on scrap paper, a typed line under ----
const KRAFT = '#b79c70', NEWS = '#cfc7b1';
const stencil = (txt, x, y, size, col) => scrawl([txt, x, y, size, 0, col, { tm: 4.5, jit: 3, run: 0.28 }]);
const typed = (txt, x, y, size = 30) => `<text x="${x}" y="${y}" text-anchor="middle" font-family="JetBrains Mono" font-weight="800" font-size="${size}" fill="${BLACK}">${txt}</text>`;
const tape = (x, y, rot) => `<rect x="${x - 60}" y="${y - 18}" width="120" height="36" fill="#e9e2c8" opacity=".75" transform="rotate(${rot} ${x} ${y})"/>`;

const REBEL = {
  rebel_leash: { paper: KRAFT, art: () => {
    let s = '';
    // a collar and its chain, down to a ration tin
    s += `<g filter="url(#brush)"><circle cx="384" cy="250" r="130" fill="none" stroke="${BLACK}" stroke-width="34"/><rect x="354" y="356" width="60" height="44" fill="${ORANGE}"/>`;
    for (let i = 0; i < 4; i++) s += `<ellipse cx="384" cy="${430 + i * 44}" rx="17" ry="27" fill="none" stroke="${BLACK}" stroke-width="12"/>`;
    s += R(304, 590, 160, 110, BLACK) + R(304, 622, 160, 34, KRAFT) + R(304, 590, 160, 12, ORANGE) + '</g>';
    s += stencil('THE RATION', 384, 806, 104, BLACK) + stencil('IS THE LEASH', 384, 912, 104, WHITE);
    s += typed('They feed you so you will not bite.', 384, 986, 26);
    return s; }, lam: [640, 110, 0.8, 10] },
  rebel_water: { paper: NEWS, art: () => {
    let s = `<g filter="url(#brush)">`;
    s += P('M250,120 L520,120 L520,180 L380,180 L380,250 L310,250 L310,180 L250,180Z', BLACK) + R(296, 250, 98, 22, BLACK);
    s += P('M345,300 C320,350 322,372 345,378 C368,372 370,350 345,300Z', ORANGE) + P('M345,400 C326,440 328,456 345,460 C362,456 364,440 345,400Z', ORANGE);
    s += P('M270,490 L420,490 L404,640 L286,640Z', BLACK) + P('M290,512 L400,512 L396,548 L294,548Z', NEWS);
    s += `<path d="M190,420 L520,700 M520,420 L190,700" stroke="${ORANGE}" stroke-width="30" stroke-linecap="round"/></g>`;
    s += stencil("DON'T DRINK", 384, 800, 100, BLACK) + stencil('THE WATER', 384, 902, 104, BLACK);
    s += typed('They put something in it', 384, 962, 24) + typed('to make you forget.', 384, 992, 24);
    return s; }, lam: [640, 150, 0.8, -8] },
  rebel_home: { paper: KRAFT, art: () => {
    let s = `<g filter="url(#brush)">` + P('M190,110 L578,110 L578,690 L190,690Z', BLACK);
    for (let r = 0; r < 5; r++) for (let c = 0; c < 4; c++) s += R(226 + c * 86, 150 + r * 104, 58, 70, (r * 4 + c) % 5 === 1 ? ORANGE : KRAFT);
    for (let i = 0; i < 7; i++) s += R(150 + i * 78, 70, 22, 660, BLACK);
    s += R(120, 70, 528, 26, BLACK) + R(120, 706, 528, 26, BLACK) + '</g>';
    s += stencil('THIS IS NOT', 384, 822, 92, BLACK) + stencil('YOUR HOME', 384, 922, 100, WHITE);
    s += typed('Remember who you were.', 384, 988, 28);
    return s; }, lam: [660, 800, 0.0, 0] },
  rebel_watch: { paper: NEWS, art: () => {
    let s = `<g filter="url(#brush)">`;
    s += P('M70,380 C200,180 568,180 698,380 C568,580 200,580 70,380Z', BLACK) + P('M150,380 C240,250 528,250 618,380 C528,510 240,510 150,380Z', NEWS);
    s += `<circle cx="384" cy="380" r="118" fill="${BLACK}"/>` + '</g>';
    s += lambda(384, 380, 1.9, ORANGE, 0);
    for (let i = 0; i < 7; i++) s += `<path d="M${150 + i * 78},${200 - Math.abs(3 - i) * -14} L${130 + i * 84},${130 - Math.abs(3 - i) * -18}" stroke="${BLACK}" stroke-width="14" stroke-linecap="round" filter="url(#brush)"/>`;
    s += stencil('SHE WATCHES.', 384, 724, 100, BLACK) + stencil('WE SEE.', 384, 852, 140, ORANGE);
    s += typed('The Resistance is closer', 384, 942, 28) + typed('than you think.', 384, 976, 28);
    return s; }, lam: [0, 0, 0, 0] },
};

function rebelPage(id) {
  const r = REBEL[id];
  let s = R(0, 0, 768, 1024, r.paper);
  // uneven, hand-cut paper: pale slivers at the edges
  s += P('M0,0 L768,0 L768,14 L620,8 L400,16 L180,6 L0,12Z', '#00000022') + P('M0,1024 L768,1024 L768,1008 L560,1016 L300,1006 L0,1014Z', '#00000022');
  s += r.art();
  if (r.lam[2] > 0) s += lambda(r.lam[0], r.lam[1], r.lam[2], ORANGE, r.lam[3]);
  s += tape(110, 16, -6) + tape(660, 14, 5) + tape(384, 1010, 2);
  return s;
}

const FILTERS = `
  <filter id="brush" x="-5%" y="-20%" width="110%" height="150%"><feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="3" seed="8"/><feDisplacementMap in="SourceGraphic" scale="9"/></filter>
  <filter id="over" x="-20%" y="-40%" width="140%" height="180%"><feGaussianBlur stdDeviation="7"/></filter>
  <filter id="spray" x="-10%" y="-20%" width="120%" height="150%"><feTurbulence type="fractalNoise" baseFrequency="0.09" numOctaves="2" seed="5"/><feDisplacementMap in="SourceGraphic" scale="3.5" result="d"/><feGaussianBlur in="d" stdDeviation="0.7"/></filter>`;

module.exports = { DEFACE, defaceLayer, REBEL, rebelPage, FILTERS, lambda, scrawl, WHITE, ORANGE };
