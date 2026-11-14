// The posters that hint at her propaganda dreams (dream_<codeword>), second half: hate, massgames,
// guidance, scrap, flowers, duck, ravenholm, battleline. Drawn by gen.js.
const { C, P, R, G, rays, emblem, worker, officer, citizen, reader, adminBust, palm } = require('./lib.js');
const { E, L, T, rng, row, crab, rose, gear, skyline } = require('./dreamkit.js');

const ART = {};
const KNIT = '#e4dece', KNITD = '#c3bca8', DARK = '#080d15';

// Two Minutes of Hate
function fist(x, y, s, tone, rot = 0) {
  const b = [C.blue, '#335073', '#2d4666'][tone], bd = [C.blueD, '#263a55', '#22344c'][tone], skin = [C.paper, '#c8c2b1', '#b3ae9f'][tone];
  return G(`translate(${x},${y}) rotate(${rot}) scale(${s})`, P('M-20,60 L22,60 L30,260 L-28,260Z', b) + P('M6,60 L22,60 L30,260 L12,260Z', bd) + R(-22, 52, 46, 12, bd) +
    P('M-26,0 L20,-4 L28,10 L26,52 L-22,54Z', skin) + P('M20,-4 L28,10 L26,52 L14,53Z', '#000', 'opacity=".18"') + L('M-16,2 L-15,24 M-4,0 L-3,24 M8,-1 L9,24', C.ink, 2.4, 'opacity=".6"') + P('M-34,18 L-22,14 L-20,40 L-32,38Z', skin));
}
ART.dream_hate = () => {
  let s = R(0, 0, 720, 610, DARK);
  s += R(108, 28, 504, 340, C.slate3) + R(120, 40, 480, 316, C.red) + `<clipPath id="hatef"><rect x="120" y="40" width="480" height="316"/></clipPath><g clip-path="url(#hatef)">` + rays(360, 200, 32, 700, C.redD, 0, 360, 'opacity=".7"');
  // the enemy's face
  s += P('M230,356 L262,300 L458,300 L490,356Z', '#141c26');
  s += P('M282,110 L438,110 L462,180 L452,262 L410,318 L310,318 L268,262 L258,180Z', '#1b2634');
  s += P('M268,150 L282,84 L330,56 L390,56 L438,84 L452,150 L360,136Z', '#3d4a35') + R(264, 140, 192, 16, '#2a3424') + T(360, 122, 'λ', 54, '#e08a2c');
  s += P('M290,186 L346,206 L344,222 L292,206Z', C.paper) + P('M430,186 L374,206 L376,222 L428,206Z', C.paper) + P('M282,170 L350,196 L348,204 L282,182Z', C.ink) + P('M438,170 L370,196 L372,204 L438,182Z', C.ink);
  s += P('M310,262 L410,262 L400,292 L320,292Z', C.ink) + [322, 340, 358, 376, 394].map(x => P(`M${x - 8},262 L${x + 8},262 L${x},278Z`, C.paper)).join('') + P('M300,300 L330,318 L390,318 L420,300 L400,330 L320,330Z', '#2b2118');
  s += '</g>';
  // what the city feels about it
  for (let i = 0; i < 6; i++) s += reader(-20 + i * 128, 470, 1.5, 2 + (i % 2), i % 2 === 0);
  s += fist(96, 300, 1.05, 1, -10) + fist(250, 340, 1.2, 0, 6) + fist(420, 320, 1.1, 2, -4) + fist(590, 290, 1.15, 0, 12) + fist(676, 380, 0.9, 1, 4) + fist(22, 400, 0.9, 2, 8);
  return s;
};

// The Mass Games
ART.dream_massgames = () => {
  let s = R(0, 0, 720, 610, '#16212e');
  const X = 60, Y = 26, W = 600, H = 420, K = 20;
  s += `<clipPath id="cards"><rect x="${X}" y="${Y}" width="${W}" height="${H}"/></clipPath><g clip-path="url(#cards)">` + R(X, Y, W, H, C.cyanD) + rays(360, 210, 28, 700, C.cyan, 0, 360, 'opacity=".5"') + G('translate(168,22) scale(2.26)', adminBust({ pin: C.red }));
  const r = rng(41);
  for (let i = 0; i < 26; i++) s += R(X + Math.floor(r() * (W / K)) * K, Y + Math.floor(r() * (H / K)) * K, K, K, r() < 0.5 ? C.paper : C.slate2, 'opacity=".8"');
  let grid = '';
  for (let x = X; x <= X + W; x += K) grid += `M${x},${Y} v${H} `;
  for (let y = Y; y <= Y + H; y += K) grid += `M${X},${y} h${W} `;
  s += L(grid, '#16212e', 3.2) + '</g>';
  // the ten thousand
  for (let row2 = 0; row2 < 6; row2++) for (let i = 0; i < 31; i++) {
    const x = 6 + i * 24 + (row2 % 2) * 12, y = 466 + row2 * 26;
    s += `<circle cx="${x}" cy="${y}" r="9" fill="${row2 % 2 ? '#0e1620' : C.ink}"/>` + R(x - 11, y + 8, 22, 20, [C.blueD, '#263a55', C.blue][(i + row2) % 3]);
  }
  return s;
};

// On-the-Spot Guidance
ART.dream_guidance = () => {
  let s = R(0, 0, 720, 610, '#cfc8b4') + rays(140, 200, 40, 1000, C.paper, 0, 360, 'opacity=".6"');
  for (let x = 330; x < 720; x += 130) s += R(x, 0, 14, 300, C.steel2) + R(x - 40, 60, 94, 10, C.steel2);
  s += R(0, 540, 720, 70, C.steel) + R(0, 540, 720, 6, C.slate3);
  // the station
  s += R(372, 356, 250, 190, C.slate) + R(372, 356, 250, 14, C.slate2) + R(392, 392, 90, 60, '#16212e') + L('M400,436 L420,410 L440,426 L470,402', C.cyan, 4) + `<circle cx="520" cy="410" r="12" fill="${C.red}"/><circle cx="560" cy="410" r="12" fill="${C.steel2}"/>`;
  s += gear(470, 300, 62, 12, C.steel, C.slate) + gear(566, 250, 40, 9, C.slate3, C.slate) + R(392, 476, 210, 10, C.slate2) + R(392, 500, 150, 10, C.slate2);
  // her, and her advice
  s += P('M40,330 L238,330 L262,610 L16,610Z', KNIT) + P('M150,330 L238,330 L262,610 L190,610Z', KNITD);
  s += P('M206,318 L232,292 L404,246 L412,274 L236,352Z', KNIT) + P('M220,330 L404,262 L412,274 L236,352Z', KNITD) + P('M400,244 L446,236 L450,246 L428,254 L436,262 L414,276Z', '#dfc6a8');
  s += G('translate(22,44) scale(1.38)', adminBust({ pin: C.red }));
  // the worker, taking it down
  s += G('translate(736,0) scale(-1,1)', worker(0, 168, 0.92, { tone: 1, cap: true }));
  s += G('translate(600,438) rotate(-14)', R(0, 0, 56, 70, C.paper) + R(0, 0, 56, 10, C.slate3) + R(8, 22, 40, 5, C.steel) + R(8, 34, 34, 5, C.steel) + R(8, 46, 38, 5, C.steel));
  return s;
};

// The Scrap Drive
function can(x, y, s, rot, col, dk) {
  return G(`translate(${x},${y}) rotate(${rot}) scale(${s})`, R(-13, -20, 26, 40, col) + R(4, -20, 9, 40, dk) + E(0, -20, 13, 4.5, C.steel2) + R(-13, -6, 26, 9, dk, 'opacity=".55"'));
}
ART.dream_scrap = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(360, 110, 40, 1000, C.slate2, 0, 360, 'opacity=".8"') + rays(360, 110, 20, 1000, C.cyan, 0, 360, 'opacity=".07"');
  s += skyline(470, '#1c2a3a', '#2c4058', 8, 120);
  // what it is built into
  const ci = '#0d141d';
  s += P('M318,610 L334,150 L346,40 L352,0 L372,0 L380,60 L392,170 L412,610Z', ci) + P('M334,150 L296,210 L300,610 L318,610Z', ci) + P('M392,170 L430,236 L428,610 L412,610Z', ci) + P('M346,40 L326,70 L330,150Z', ci) + P('M380,60 L400,96 L392,170Z', ci);
  for (const y of [120, 200, 290, 380]) s += R(340, y, 44, 5, C.cyan, 'opacity=".55"');
  // the heap
  const r = rng(63);
  for (let i = 0; i < 120; i++) {
    const t = Math.sqrt(r()), y = 420 + t * 200, half = 40 + t * 330, x = 364 + (r() * 2 - 1) * half, k = r();
    if (k < 0.62) s += can(x, y, 0.8 + r() * 0.7, r() * 180, [C.steel, C.steel2, C.red, C.blue2, C.warm][Math.floor(r() * 5)], '#00000055');
    else if (k < 0.8) s += gear(x, y, 12 + r() * 14, 8, C.slate3, C.slate);
    else s += G(`rotate(${(r() * 180).toFixed(0)} ${x.toFixed(0)} ${y.toFixed(0)})`, R(x - 40, y - 5, 80, 10, C.steel) + R(x + 30, y - 8, 12, 16, C.slate3));
  }
  // one more for it
  s += citizen(40, 330, 1.08, { tone: 0 }) + can(126, 440, 1.5, -12, C.red, '#00000055') + P('M104,410 L116,404 L128,432 L116,438Z', C.blue2);
  return s;
};

// Flowers for the Liberators
function bloom(x, y, s, col, rot) {
  let g = '';
  for (let i = 0; i < 5; i++) g += E(0, -9, 6, 9, col, `transform="rotate(${i * 72})"`);
  return G(`translate(${x},${y}) rotate(${rot}) scale(${s})`, g + `<circle r="4.5" fill="${C.warm}"/>`);
}
ART.dream_flowers = () => {
  let s = R(0, 0, 720, 610, '#cfd3cb') + rays(360, 130, 40, 1000, C.paper, 0, 360, 'opacity=".7"');
  // what walks behind them
  const st = '#8d9aa2';
  s += L('M330,96 L210,250 L150,610', st, 13) + L('M380,100 L500,236 L572,610', st, 13) + L('M356,104 L372,300 L350,610', st, 11);
  s += P('M286,50 L420,40 L458,70 L436,108 L300,112 L270,84Z', st) + P('M270,84 L226,96 L226,104 L276,98Z', st) + `<circle cx="300" cy="80" r="9" fill="${C.cyan}" opacity=".8"/>`;
  s += skyline(460, C.steel2, null, 12, 90) + R(0, 456, 720, 154, C.slate3);
  // the liberators
  for (const [x, y, k] of [[96, 246, 0.74], [528, 246, 0.74], [240, 226, 0.84], [396, 226, 0.84]]) s += officer(x, y, k, { lens: C.cyan, band: C.red });
  // the welcome
  const r = rng(17);
  for (let i = 0; i < 34; i++) s += bloom(20 + r() * 680, 130 + r() * 300, 1 + r() * 0.9, r() < 0.6 ? C.red : C.paper, r() * 72);
  for (let i = 0; i < 3; i++) s += rose(120 + i * 230 + r() * 40, 200 + r() * 120, 1.5);
  const hands = [[30, 470, -10, C.paper, C.blue], [150, 500, 6, '#c8c2b1', '#335073'], [286, 480, -4, C.paper, C.blueD], [420, 502, 8, '#b3ae9f', C.blue], [540, 474, -8, C.paper, '#335073'], [650, 498, 10, '#c8c2b1', C.blueD]];
  for (const [x, y, a, skin, sl] of hands) s += G(`translate(${x},${y}) rotate(${a})`, R(18, 150, 70, 200, sl)) + palm(x, y, 0.92, skin, a);
  return s;
};

// Duck and Cover
ART.dream_duck = () => {
  let s = R(0, 0, 720, 610, C.slate) + R(0, 500, 720, 110, '#16212e') + R(0, 500, 720, 5, C.slate3);
  // the flash at the window
  s += rays(600, 150, 30, 1100, C.warm, 60, 250, 'opacity=".22"');
  s += R(486, 36, 204, 224, C.slate3) + R(498, 48, 180, 200, '#fff6d8') + `<circle cx="588" cy="148" r="56" fill="#fff" opacity=".9"/>` + R(583, 48, 10, 200, C.slate3) + R(498, 143, 180, 10, C.slate3);
  // the siren
  s += R(92, 90, 12, 180, C.steel) + R(60, 262, 76, 12, C.steel) + P('M98,96 L196,50 L196,170Z', C.red) + P('M98,96 L60,82 L60,134 L98,120Z', C.steel2) + E(196, 110, 12, 60, C.redD);
  s += L('M226,66 Q252,110 226,154', C.red, 7) + L('M256,44 Q296,110 256,176', C.red, 7, 'opacity=".7"') + L('M286,22 Q340,110 286,198', C.red, 7, 'opacity=".4"');
  // the desk, and who trusts it
  s += P('M150,500 L560,500 L700,610 L60,610Z', '#0b1119', 'opacity=".55"');
  s += R(180, 318, 380, 26, C.steel2) + R(180, 344, 380, 8, C.steel) + R(196, 352, 18, 150, C.steel) + R(526, 352, 18, 150, C.steel) + R(214, 352, 90, 60, C.slate3) + R(250, 376, 18, 6, C.steel2);
  s += P('M300,500 Q300,410 372,402 Q452,398 470,452 L476,500Z', C.blue) + P('M300,500 Q300,470 330,452 L420,500Z', C.blueD);
  s += E(446, 462, 27, 29, C.paper) + P('M424,446 A27,29 0 0 1 470,448 L446,462Z', C.ink);
  s += P('M372,410 L436,416 L484,452 L470,468 L428,440 L372,438Z', C.blueD) + P('M470,468 L484,452 L494,468 L480,480Z', C.paper);
  s += P('M396,500 L404,470 L470,476 L476,500Z', C.blueD);
  return s;
};

// Ravenholm
ART.dream_ravenholm = () => {
  const sil = '#05080d';
  let s = R(0, 0, 720, 610, '#1b2c44') + `<circle cx="566" cy="112" r="96" fill="${C.steel2}" opacity=".1"/><circle cx="566" cy="112" r="56" fill="${C.paper}" opacity=".9"/>`;
  // the town
  s += P('M0,360 L0,300 L40,262 L80,300 L80,270 L130,220 L180,270 L180,310 L220,310 L220,250 L262,206 L304,250 L304,170 L318,170 L332,70 L346,170 L360,170 L360,290 L410,290 L410,240 L460,196 L510,240 L510,300 L560,300 L560,260 L604,220 L648,260 L648,310 L690,280 L720,300 L720,360Z', sil);
  for (const [x, y] of [[104, 286], [150, 286], [240, 270], [430, 262], [478, 262], [590, 276]]) s += R(x, y, 14, 20, C.warm, 'opacity=".28"');
  s += R(324, 190, 16, 26, C.warm, 'opacity=".35"') + crab(262, 198, 0.09, sil) + crab(604, 212, 0.08, sil);
  s += R(0, 356, 720, 254, '#0d1620') + P('M300,356 L420,356 L640,610 L80,610Z', C.slate2) + P('M354,356 L366,356 L384,610 L336,610Z', C.slate3, 'opacity=".5"');
  // the city has seen to it
  const wood = '#6e5a40', woodD = '#4c3d2a';
  s += R(150, 470, 26, 140, woodD) + R(544, 470, 26, 140, woodD);
  s += G('rotate(-5 360 470)', R(110, 448, 500, 34, wood) + R(110, 474, 500, 8, woodD)) + G('rotate(4 360 540)', R(120, 520, 480, 34, wood) + R(120, 546, 480, 8, woodD));
  s += G('rotate(34 360 500)', R(190, 486, 340, 26, wood)) + G('rotate(-34 360 500)', R(190, 486, 340, 26, woodD));
  for (let i = 0; i < 8; i++) s += P(`M${132 + i * 60},452 L${162 + i * 60},449 L${152 + i * 60},480 L${122 + i * 60},483Z`, i % 2 ? C.paper : C.red, 'opacity=".9" transform="rotate(-5 360 470)"');
  // the sign
  s += R(86, 150, 14, 330, C.steel) + G('rotate(-4 180 200)', R(30, 160, 300, 84, C.paper) + R(30, 160, 300, 84, 'none', `stroke="${C.ink}" stroke-width="5"`) + T(180, 218, 'RAVENHOLM', 43, C.ink) + L('M36,236 L324,168', C.red, 14));
  return s;
};

// The Battle Line
function giant(x, base, h, col) {
  const w = h * 0.36;
  return P(`M${x - w * 0.5},${base} L${x - w * 0.56},${base - h * 0.62} L${x - w * 0.3},${base - h * 0.74} L${x + w * 0.3},${base - h * 0.74} L${x + w * 0.56},${base - h * 0.62} L${x + w * 0.5},${base}Z`, col) +
    E(x, base - h * 0.86, w * 0.2, h * 0.11, col) + P(`M${x - w * 0.56},${base - h * 0.62} L${x - w * 0.95},${base - h * 0.98} L${x - w * 0.78},${base - h * 1.02} L${x - w * 0.3},${base - h * 0.74}Z`, col) + P(`M${x + w * 0.56},${base - h * 0.62} L${x + w * 0.9},${base - h * 0.3} L${x + w * 0.72},${base - h * 0.26} L${x + w * 0.4},${base - h * 0.56}Z`, col);
}
ART.dream_battleline = () => {
  let s = R(0, 0, 720, 610, DARK) + E(360, 400, 520, 260, C.red, 'opacity=".16"') + E(360, 400, 340, 170, C.red, 'opacity=".16"');
  // the giants
  for (const [x, h, o] of [[150, 300, 0.5], [600, 250, 0.45], [370, 400, 0.85]]) s += `<g opacity="${o}">` + giant(x, 440, h * 1.04, C.redD) + giant(x, 440, h, C.red) + '</g>';
  s += `<circle cx="358" cy="94" r="5" fill="#fff4ee"/><circle cx="384" cy="94" r="5" fill="#fff4ee"/>`;
  s += skyline(440, '#0d141d', '#3a2420', 5, 110) + R(0, 436, 720, 174, '#0d141d');
  // the line
  s += P('M0,520 L60,490 L150,496 L230,484 L330,494 L420,486 L520,496 L610,486 L720,500 L720,610 L0,610Z', C.slate2) + P('M0,540 L720,524 L720,610 L0,610Z', C.slate);
  for (let i = 0; i < 9; i++) s += E(40 + i * 82, 508, 44, 16, C.slate3) + E(40 + i * 82, 504, 44, 13, '#52677d');
  // her soldiers
  for (const [x, y, k] of [[20, 400, 1.5], [170, 392, 1.6], [330, 388, 1.65], [490, 392, 1.6], [630, 400, 1.5]]) {
    s += L(`M${x + 70 * k},${y + 96 * k} L${x + 100 * k},${y - 6 * k}`, C.steel, 7) + `<circle cx="${x + 100 * k}" cy="${y - 8 * k}" r="5" fill="${C.cyan}"/>`;
    s += reader(x, y, k, 3, true) + R(x + 22 * k, y + 38 * k, 36 * k, 5 * k, C.cyan, 'opacity=".7"');
  }
  return s;
};

const POSTERS = [
  row('hate', 81, ['TWO MINUTES.', 'EVERY CITIZEN.'], { night: true }),
  row('massgames', 82, ['TEN THOUSAND', 'AS ONE']),
  row('guidance', 83, ['SHE IS COMING TO', 'YOUR WORKPLACE'], { accent: 'red' }),
  row('scrap', 84, ['EVERY CAN', 'COUNTS']),
  row('flowers', 85, ['GREET THE', 'LIBERATORS'], { accent: 'red' }),
  row('duck', 86, ['WHEN THE SIREN SOUNDS,', 'DUCK AND COVER']),
  row('ravenholm', 87, ["WE DON'T GO", 'TO RAVENHOLM'], { night: true, ground: '#0a111a' }),
  row('battleline', 88, ['THE LINE', 'HOLDS'], { night: true }),
];

module.exports = { ART, POSTERS };
