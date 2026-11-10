// The Resistance's answer: paint over the city's posters, and four paste-ups of their own.
const { C, P, R, G, emblem } = require('./lib.js');

const WHITE = '#f2eee4', BLACK = '#131313', ORANGE = '#e8912a';

// the lambda in a ring, about 100 across, centre at 0,0
function lambda(x, y, s, col, rot = 0) {
  return G(`translate(${x},${y}) rotate(${rot}) scale(${s})`,
    `<circle cx="0" cy="0" r="44" fill="none" stroke="${col}" stroke-width="9"/>` +
    P('M-16,-30 L-4,-30 L22,30 L9,30 L1,10 L-11,30 L-25,30 L-6,-6Z', col));
}
let seed = 3;
const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
// painted words: [text, x (centre), y (baseline), size, turn, colour]
function scrawl(w) {
  const [txt, x, y, size, rot, col] = w;
  const width = txt.length * size * 0.58;
  let drips = '';
  for (let i = 0; i < 4; i++) {
    const dx = x - width / 2 + rnd() * width, len = 18 + rnd() * size * 0.7, wd = 3 + rnd() * 4;
    drips += `<rect x="${dx.toFixed(1)}" y="${(y - size * 0.1).toFixed(1)}" width="${wd.toFixed(1)}" height="${len.toFixed(1)}" rx="${(wd / 2).toFixed(1)}" fill="${col}"/>`;
  }
  const t = `<text x="${x}" y="${y}" text-anchor="middle" font-family="Inter Display" font-style="italic" font-weight="900" font-size="${size}" fill="${col}" textLength="${Math.min(width, 700).toFixed(0)}" lengthAdjust="spacingAndGlyphs">${txt}</text>`;
  return `<g transform="rotate(${rot} ${x} ${y})"><g filter="url(#over)" opacity=".35">${t}</g><g filter="url(#brush)">${t}${drips}</g></g>`;
}
// a slash of paint through a headline line
function strike(y, col) {
  return `<g filter="url(#brush)"><path d="M40,${y + 8} L728,${y - 10}" stroke="${col}" stroke-width="20" stroke-linecap="round"/><path d="M60,${y + 22} L700,${y + 4}" stroke="${col}" stroke-width="9" stroke-linecap="round"/></g>`;
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
  administrator: { words: [['LIAR', 384, 500, 210, -8, WHITE]], lam: [660, 130, 0.9, 8],
    extra: `<g filter="url(#brush)" stroke="${BLACK}" stroke-width="16" stroke-linecap="round"><path d="M300,222 L372,278 M372,222 L300,278 M396,222 L468,278 M468,222 L396,278"/></g>` },
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
  s += `<g filter="url(#brush)">${lambda(d.lam[0], d.lam[1], d.lam[2], ORANGE, d.lam[3])}</g>`;
  // overspray and a few flecks
  for (let i = 0; i < 26; i++) s += `<circle cx="${(60 + rnd() * 650).toFixed(0)}" cy="${(80 + rnd() * 800).toFixed(0)}" r="${(1 + rnd() * 3.5).toFixed(1)}" fill="${rnd() > 0.5 ? WHITE : ORANGE}" opacity="${(0.4 + rnd() * 0.5).toFixed(2)}"/>`;
  return s;
}

// ---- the Resistance's own paste-ups: stencil and typewriter on scrap paper ----
const KRAFT = '#b79c70', NEWS = '#cfc7b1';
const stencil = (txt, x, y, size, col, len) => `<text x="${x}" y="${y}" text-anchor="middle" font-family="Inter Display" font-weight="900" font-size="${size}" fill="${col}" ${len ? `textLength="${len}" lengthAdjust="spacingAndGlyphs"` : ''} filter="url(#brush)">${txt}</text>`;
const typed = (txt, x, y, size = 30) => `<text x="${x}" y="${y}" text-anchor="middle" font-family="JetBrains Mono" font-weight="800" font-size="${size}" fill="${BLACK}">${txt}</text>`;
const tape = (x, y, rot) => `<rect x="${x - 60}" y="${y - 18}" width="120" height="36" fill="#e9e2c8" opacity=".75" transform="rotate(${rot} ${x} ${y})"/>`;

const REBEL = {
  rebel_leash: { paper: KRAFT, art: () => {
    let s = '';
    // a collar and its chain, down to a ration tin
    s += `<g filter="url(#brush)"><circle cx="384" cy="250" r="130" fill="none" stroke="${BLACK}" stroke-width="34"/><rect x="354" y="356" width="60" height="44" fill="${ORANGE}"/>`;
    for (let i = 0; i < 4; i++) s += `<ellipse cx="384" cy="${430 + i * 44}" rx="17" ry="27" fill="none" stroke="${BLACK}" stroke-width="12"/>`;
    s += R(304, 590, 160, 110, BLACK) + R(304, 622, 160, 34, KRAFT) + R(304, 590, 160, 12, ORANGE) + '</g>';
    s += stencil('THE RATION', 384, 800, 104, BLACK, 640) + stencil('IS THE LEASH', 384, 900, 104, WHITE, 640);
    s += typed('They feed you so you will not bite.', 384, 958, 26);
    return s; }, lam: [640, 110, 0.8, 10] },
  rebel_water: { paper: NEWS, art: () => {
    let s = `<g filter="url(#brush)">`;
    s += P('M250,120 L520,120 L520,180 L380,180 L380,250 L310,250 L310,180 L250,180Z', BLACK) + R(296, 250, 98, 22, BLACK);
    s += P('M345,300 C320,350 322,372 345,378 C368,372 370,350 345,300Z', ORANGE) + P('M345,400 C326,440 328,456 345,460 C362,456 364,440 345,400Z', ORANGE);
    s += P('M270,490 L420,490 L404,640 L286,640Z', BLACK) + P('M290,512 L400,512 L396,548 L294,548Z', NEWS);
    s += `<path d="M190,420 L520,700 M520,420 L190,700" stroke="${ORANGE}" stroke-width="30" stroke-linecap="round"/></g>`;
    s += stencil("DON'T DRINK", 384, 808, 104, BLACK, 640) + stencil('THE WATER', 384, 904, 110, BLACK, 640);
    s += typed('They put something in it', 384, 944, 26) + typed('to make you forget.', 384, 976, 26);
    return s; }, lam: [640, 150, 0.8, -8] },
  rebel_home: { paper: KRAFT, art: () => {
    let s = `<g filter="url(#brush)">` + P('M190,110 L578,110 L578,690 L190,690Z', BLACK);
    for (let r = 0; r < 5; r++) for (let c = 0; c < 4; c++) s += R(226 + c * 86, 150 + r * 104, 58, 70, (r * 4 + c) % 5 === 1 ? ORANGE : KRAFT);
    for (let i = 0; i < 7; i++) s += R(150 + i * 78, 70, 22, 660, BLACK);
    s += R(120, 70, 528, 26, BLACK) + R(120, 706, 528, 26, BLACK) + '</g>';
    s += stencil('THIS IS NOT', 384, 826, 96, BLACK, 640) + stencil('YOUR HOME', 384, 916, 104, WHITE, 640);
    s += typed('Remember who you were.', 384, 966, 28);
    return s; }, lam: [660, 800, 0.0, 0] },
  rebel_watch: { paper: NEWS, art: () => {
    let s = `<g filter="url(#brush)">`;
    s += P('M70,380 C200,180 568,180 698,380 C568,580 200,580 70,380Z', BLACK) + P('M150,380 C240,250 528,250 618,380 C528,510 240,510 150,380Z', NEWS);
    s += `<circle cx="384" cy="380" r="118" fill="${BLACK}"/>` + '</g>';
    s += `<g filter="url(#brush)">${lambda(384, 380, 1.9, ORANGE, 0)}</g>`;
    for (let i = 0; i < 7; i++) s += `<path d="M${150 + i * 78},${200 - Math.abs(3 - i) * -14} L${130 + i * 84},${130 - Math.abs(3 - i) * -18}" stroke="${BLACK}" stroke-width="14" stroke-linecap="round" filter="url(#brush)"/>`;
    s += stencil('SHE WATCHES.', 384, 740, 100, BLACK, 640) + stencil('WE SEE.', 384, 868, 150, ORANGE, 640);
    s += typed('The Resistance is closer', 384, 928, 28) + typed('than you think.', 384, 962, 28);
    return s; }, lam: [0, 0, 0, 0] },
};

function rebelPage(id) {
  const r = REBEL[id];
  let s = R(0, 0, 768, 1024, r.paper);
  // uneven, hand-cut paper: pale slivers at the edges
  s += P('M0,0 L768,0 L768,14 L620,8 L400,16 L180,6 L0,12Z', '#00000022') + P('M0,1024 L768,1024 L768,1008 L560,1016 L300,1006 L0,1014Z', '#00000022');
  s += r.art();
  if (r.lam[2] > 0) s += `<g filter="url(#brush)">${lambda(r.lam[0], r.lam[1], r.lam[2], ORANGE, r.lam[3])}</g>`;
  s += tape(110, 16, -6) + tape(660, 14, 5) + tape(384, 1010, 2);
  return s;
}

const FILTERS = `
  <filter id="brush" x="-5%" y="-20%" width="110%" height="150%"><feTurbulence type="fractalNoise" baseFrequency="0.035" numOctaves="3" seed="8"/><feDisplacementMap in="SourceGraphic" scale="9"/></filter>
  <filter id="over" x="-10%" y="-30%" width="120%" height="170%"><feGaussianBlur stdDeviation="9"/></filter>`;

module.exports = { DEFACE, defaceLayer, REBEL, rebelPage, FILTERS };
