// The posters that hint at the Neutral dreams (dream_<codeword>), second half: simon, clocks, tea,
// photo, doors, shh, can. Drawn by gen.js.
const { C, P, R, G, rays, emblem, officer, citizen, adminBust, scanner } = require('./lib.js');
const { E, L, T, rng, row, walker, gear, skyline } = require('./dreamkit.js');
const { no, hand, clock, YEL, DARK, SKIN, SKIND } = require('./dreamkit2.js');

const ART = {};
const KNIT = '#e4dece', KNITD = '#c3bca8';

// Overwatch Says
ART.dream_simon = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(360, 96, 26, 900, C.slate2, 10, 170, 'opacity=".5"');
  s += R(346, 0, 28, 40, C.ink) + P('M318,36 L402,36 L468,128 L252,128Z', C.steel) + P('M360,36 L402,36 L468,128 L360,128Z', C.steel2) + R(244, 124, 232, 14, C.ink);
  for (const r of [70, 118, 166]) s += L(`M${360 - r},150 A${r},${r * 0.62} 0 0 0 ${360 + r},150`, C.cyan, 7, `opacity="${1.1 - r / 200}"`);
  const k = 1.12, y = 610 - 230 * k;
  [26, 164, 302, 440, 578].forEach((x, i) => {
    const wrong = i === 3, sx = wrong ? x + 66 * k : x + 14 * k, d = wrong ? 1 : -1, sy = y + 70 * k;
    s += citizen(x, y, k, { tone: wrong ? 0 : (i % 2) + 1 });
    s += P(`M${sx - 9},${sy} L${sx + 9},${sy} L${sx + d * 30 + 8},${sy - 110} L${sx + d * 30 - 8},${sy - 110}Z`, wrong ? C.blue2 : '#456a93') + `<circle cx="${sx + d * 31}" cy="${sy - 120}" r="12" fill="${C.paper}"/>`;
  });
  const cx = 440 + 40 * k;
  s += `<circle cx="${cx}" cy="${y + 60}" r="112" fill="none" stroke="${C.red}" stroke-width="8"/>` + R(cx + 70, y - 76, 62, 76, C.paper) + R(cx + 70, y - 76, 62, 14, C.ink) + L(`M${cx + 82},${y - 46} h38 M${cx + 82},${y - 30} h38`, C.steel, 4) + L(`M${cx + 84},${y - 16} l10,10 l22,-22`, C.red, 6);
  return s;
};

// Stop the Clocks
ART.dream_clocks = () => {
  let s = R(0, 0, 720, 610, '#cfc8b4') + rays(360, 262, 36, 900, C.paper, 0, 360, 'opacity=".7"');
  s += gear(104, 120, 86, 12, C.steel2, C.steel) + gear(632, 400, 70, 10, C.steel2, C.steel);
  s += clock(360, 262, 226, -62, -14, { rim: C.slate });
  s += R(0, 580, 720, 30, C.slate) + P('M600,470 L720,470 L720,582 L600,582Z', C.slate) + R(630, 510, 50, 72, '#cfc8b4') + R(610, 430, 22, 44, C.slate) + R(660, 400, 22, 74, C.slate);
  for (const x of [30, 130, 230, 420, 520]) s += walker(x, 582 - 258 * 0.4, 0.4, { turn: 8 });
  return s;
};

// The Tea Party
ART.dream_tea = () => {
  let s = R(0, 0, 720, 610, DARK) + E(360, 318, 330, 280, '#162130') + E(360, 318, 250, 214, C.slate);
  s += `<circle cx="360" cy="318" r="118" fill="${C.steel}"/><circle cx="360" cy="318" r="108" fill="${C.paper}"/><circle cx="360" cy="318" r="72" fill="none" stroke="${C.steel2}" stroke-width="3"/>`;
  s += P('M392,300 L448,286 L452,300 L396,322Z', C.slate3) + L('M326,300 Q290,318 326,338', C.slate3, 9) + `<circle cx="360" cy="318" r="40" fill="${C.slate3}"/><circle cx="360" cy="318" r="30" fill="${C.slate2}"/><circle cx="360" cy="318" r="9" fill="${C.paper}"/>`;
  [[0, 1], [90, 2], [180, 3], [270, 4]].forEach(([a, n]) => {
    const four = n === 4, rad = (a - 90) * Math.PI / 180, px = 360 + 198 * Math.cos(rad), py = 318 + 198 * Math.sin(rad), ux = 360 + 82 * Math.cos(rad), uy = 318 + 82 * Math.sin(rad);
    s += `<circle cx="${ux.toFixed(0)}" cy="${uy.toFixed(0)}" r="21" fill="${C.steel2}"/><circle cx="${ux.toFixed(0)}" cy="${uy.toFixed(0)}" r="15" fill="${C.paper}"/><circle cx="${ux.toFixed(0)}" cy="${uy.toFixed(0)}" r="11" fill="#8a5a33"/>`;
    const hair = [C.ink, '#5b4630', '#8a8f93', '#3a2a1e'][n - 1], bl = four ? C.blue2 : C.blue;
    s += G(`translate(${px.toFixed(0)},${py.toFixed(0)}) rotate(${a})`, R(-62, 0, 22, 78, bl, 'rx="10"') + R(40, 0, 22, 78, bl, 'rx="10"') + `<circle cx="-51" cy="82" r="12" fill="${C.paper}"/><circle cx="51" cy="82" r="12" fill="${C.paper}"/>` +
      R(-72, -30, 144, 56, bl, 'rx="26"') + R(-72, -30, 144, 22, C.blueD, 'rx="11" opacity=".5"') + `<circle cx="0" cy="2" r="29" fill="${hair}"/>` + E(0, 26, 12, 8, C.paper));
    const lx = 360 + 286 * Math.cos(rad + 0.42), ly = 318 + 262 * Math.sin(rad + 0.42);
    s += T(lx.toFixed(0), (ly + 16).toFixed(0), n, 46, four ? C.red : C.cyan);
    if (four) s += `<circle cx="${px.toFixed(0)}" cy="${py.toFixed(0)}" r="104" fill="none" stroke="${C.red}" stroke-width="9"/>`;
  });
  return s + scanner(622, 84, 0.95, C.red);
};

// Say Cheese
ART.dream_photo = () => {
  let s = R(0, 0, 720, 610, DARK) + P('M360,110 L20,610 L700,610Z', C.cyan, 'opacity=".16"') + rays(360, 110, 22, 800, C.cyan, 40, 140, 'opacity=".1"');
  s += scanner(360, 112, 1.9, C.cyan);
  const k = 1.5;
  [[104, 1], [300, 0], [496, 1]].forEach(([x, tone]) => {
    const y = 290, cx = x + 40 * k, my = y + 42 * k;
    s += citizen(x, y, k, { tone, scarf: x === 104 });
    s += R(cx - 14, y + 26 * k, 9, 5, C.ink) + R(cx + 5, y + 26 * k, 9, 5, C.ink) + L(`M${cx - 13},${my} Q${cx},${my + 13} ${cx + 13},${my}`, C.ink, 3.4);
  });
  s += L('M56,300 v-56 h56 M664,300 v-56 h-56 M56,540 v56 h56 M664,540 v56 h-56', C.paper, 7) + `<circle cx="96" cy="212" r="12" fill="${C.red}"/>` + `<text x="118" y="224" font-family="Inter Display" font-weight="900" font-size="34" fill="${C.paper}">REC</text>`;
  return s;
};

// The Doors
ART.dream_doors = () => {
  let s = R(0, 0, 720, 610, C.slate) + R(0, 530, 720, 80, C.slate2) + R(0, 530, 720, 6, '#1b2836');
  const door = (x, f, pf) => R(x - 10, 90, 200, 440, '#1b2836') + R(x, 100, 180, 430, f) + R(x + 22, 124, 136, 150, pf) + R(x + 22, 300, 136, 200, pf);
  s += door(30, C.slate3, '#42566c') + `<circle cx="186" cy="320" r="9" fill="${C.steel2}"/>` + door(510, C.slate3, '#42566c') + `<circle cx="666" cy="320" r="9" fill="${C.steel2}"/>`;
  // the one that stays shut, and what is behind it
  s += R(256, 86, 208, 444, C.warm) + P('M262,530 L458,530 L540,610 L180,610Z', C.warm, 'opacity=".4"') + R(268, 98, 184, 432, '#101822') + R(290, 122, 140, 150, '#162130') + R(290, 298, 140, 204, '#162130');
  s += emblem(338, 150, 1.1, C.red);
  s += R(268, 286, 184, 14, C.steel) + R(268, 392, 184, 14, C.steel) + L('M334,326 v-22 a26,26 0 0 1 52,0 v22', C.steel2, 13) + R(318, 322, 84, 72, C.red) + R(318, 322, 84, 12, C.redD) + `<circle cx="360" cy="352" r="9" fill="${C.ink}"/>` + R(356, 354, 8, 22, C.ink);
  s += `<circle cx="432" cy="440" r="11" fill="${C.steel2}"/>` + hand(540, 560, 1.0, -132);
  return s;
};

// Shh!
ART.dream_shh = () => {
  let s = R(0, 0, 720, 610, DARK);
  const q = rng(17);
  for (let x = 14; x < 720; x += 58) for (let y = 20; y < 600; y += 66) s += R(x, y, 34, 42, x === 594 && y === 152 ? C.warm : q() < 0.5 ? '#111c2a' : '#0e1622');
  s += rays(360, 300, 30, 700, C.cyanD, 0, 360, 'opacity=".22"');
  s += P('M172,524 L548,524 L566,610 L154,610Z', KNIT) + P('M420,524 L548,524 L566,610 L440,610Z', KNITD) + G('translate(165,40) scale(2.3)', adminBust());
  // her finger to her lips: her left hand (the arm at our right), its back to us, so the other
  // knuckles run to our left of the finger and the thumb tucks in at our right
  const HAND = '#eedcc3', HANDD = '#a3835f';
  s += P('M322,390 L366,388 L452,610 L384,610Z', KNIT) + P('M350,389 L366,388 L452,610 L432,610Z', KNITD) + R(318, 384, 52, 12, KNITD, 'rx="5"');
  s += R(357, 275, 16, 70, HANDD, 'rx="7"') + R(352, 272, 16, 72, HAND, 'rx="8"');
  s += R(366, 344, 13, 34, HANDD, 'rx="6"') + R(364, 342, 12, 34, HAND, 'rx="6"');
  s += [319, 333, 346].map(x => `<circle cx="${x}" cy="342" r="9" fill="${HAND}"/>`).join('') + R(310, 338, 60, 50, HAND, 'rx="13"');
  s += L('M326,340 v9 M340,340 v9', HANDD, 2.2) + R(310, 372, 60, 16, HANDD, 'rx="8" opacity=".35"');
  return s;
};

// Pick Up That Can
ART.dream_can = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(110, 200, 24, 1000, C.slate2, -30, 80, 'opacity=".5"') + R(0, 520, 720, 90, C.slate2) + R(0, 520, 720, 6, '#1b2836');
  s += walker(566, 520 - 258 * 0.86, 0.86);
  s += E(452, 566, 110, 22, C.cyan, 'opacity=".3"') + L('M356,220 Q470,260 456,500', C.red, 7, 'stroke-dasharray="4 20"');
  s += G('translate(452,548) rotate(-8)', R(-40, -20, 80, 40, C.red) + R(-14, -20, 20, 40, C.paper) + E(-40, 0, 8, 20, C.steel) + E(40, 0, 8, 20, C.steel2) + E(40, 0, 4, 10, C.ink));
  s += officer(60, 66, 1.1, { point: true, lens: C.cyan, band: C.cyan });
  return s;
};

const POSTERS = [
  row('simon', 111, ['DO AS OVERWATCH SAYS']),
  row('clocks', 112, ['BE ON TIME'], { accent: 'red' }),
  row('tea', 113, ['NO GATHERINGS OF', 'MORE THAN THREE'], { night: true }),
  row('photo', 114, ["SMILE, YOU'RE", 'ON CAMERA'], { night: true, acc: C.cyan }),
  row('doors', 115, ['SOME DOORS', 'STAY LOCKED']),
  row('shh', 116, ['QUIET HOURS', 'ARE IN EFFECT'], { night: true, acc: C.cyan }),
  row('can', 117, ['PICK IT UP']),
];
module.exports = { ART, POSTERS };
