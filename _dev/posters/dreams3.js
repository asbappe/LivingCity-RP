// The posters that hint at her propaganda dreams (dream_<codeword>), first half: adore, roses, saviour,
// quiz, harvest, shift, spy, newsreel. (Mirror, Mirror is in dreams.js; the rest in dreams4.js.)
const { C, P, R, G, rays, emblem, worker, officer, citizen, reader, adminBust, scanner, head } = require('./lib.js');
const { E, L, T, rng, row, crab, rose, skyline } = require('./dreamkit.js');

const ART = {};
const KNIT = '#e4dece', KNITD = '#c3bca8';

// Kneel Before Her
function kneeler(x, y, s, tone) {
  const b = [C.blue, '#335073', '#2d4666'][tone], bd = [C.blueD, '#263a55', '#22344c'][tone], skin = [C.paper, '#c8c2b1', '#b3ae9f'][tone];
  return G(`translate(${x},${y}) scale(${s})`, E(100, 136, 104, 8, C.ink, 'opacity=".35"') + P('M10,110 L96,104 L100,132 L8,134Z', bd) + P('M0,120 L14,112 L14,134 L0,134Z', C.ink) +
    P('M30,108 L44,54 L120,70 L150,100 L96,112Z', b) + P('M44,54 L120,70 L150,100 L128,96 L104,78 L46,66Z', bd, 'opacity=".6"') +
    E(160, 100, 20, 22, skin) + P('M141,94 A20,22 0 0 1 174,84 L160,100Z', C.ink) + P('M118,74 L140,84 L186,126 L168,134 L112,96Z', b) + P('M168,134 L186,126 L200,134Z', skin));
}
ART.dream_adore = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(540, 170, 44, 1000, C.slate2, 0, 360, 'opacity=".8"') + rays(540, 170, 22, 1000, C.cyan, 0, 360, 'opacity=".08"');
  s += R(0, 392, 720, 218, '#16212e') + R(0, 392, 720, 5, C.slate3);
  // a carpet for her
  s += P('M470,392 L720,392 L720,610 L330,610Z', C.cyanD, 'opacity=".5"');
  s += P('M430,400 L650,400 L690,610 L400,610Z', KNIT) + P('M560,400 L650,400 L690,610 L600,610Z', KNITD);
  s += G('translate(382,34) scale(1.86)', adminBust({ pin: C.cyan }));
  s += kneeler(236, 330, 0.84, 2) + kneeler(130, 380, 1.08, 1) + kneeler(6, 444, 1.36, 0);
  return s;
};

// Roses for Her
ART.dream_roses = () => {
  let s = R(0, 0, 720, 610, '#cfc8b4') + rays(360, 200, 40, 1000, C.paper, 0, 360, 'opacity=".7"');
  s += R(222, 24, 276, 330, '#10161f', 'opacity=".35"') + R(214, 16, 276, 330, C.slate) + R(230, 32, 244, 298, C.blueD);
  s += `<clipPath id="rosef"><rect x="230" y="32" width="244" height="298"/></clipPath><g clip-path="url(#rosef)">` + rays(352, 150, 30, 500, C.cyan, 0, 360, 'opacity=".25"') + G('translate(220,62) scale(1.56)', adminBust({ pin: C.red })) + '</g>';
  s += R(170, 346, 364, 26, C.steel) + R(190, 372, 324, 240, C.steel2) + R(190, 372, 324, 8, C.slate3, 'opacity=".5"');
  // what the city brought
  const r = rng(21);
  for (let i = 0; i < 150; i++) {
    const t = Math.sqrt(r()), y = 350 + t * 260, half = 60 + t * 330, x = 352 + (r() * 2 - 1) * half;
    if (r() < 0.25) s += P(`M${x - 14},${y + 6} L${x},${y - 2} L${x + 3},${y + 12}Z`, '#3f6b4a');
    s += rose(x, y, 0.75 + r() * 0.7, r() < 0.85 ? C.red : '#a8321f', C.redD);
  }
  // and still bring
  for (const [x, h, k] of [[90, 250, -8], [628, 270, 9], [560, 170, 4]]) {
    s += G(`translate(${x},610) rotate(${k})`, R(-22, -h + 90, 44, h, C.blue) + R(-22, -h + 90, 14, h, C.blueD) + R(-18, -h + 46, 36, 50, C.paper) + L(`M0,${-h + 60} L0,${-h - 40}`, '#3f6b4a', 6) + P(`M0,${-h} L22,${-h - 14} L4,${-h + 14}Z`, '#3f6b4a') + rose(0, -h - 50, 1.7));
  }
  return s;
};

// The Saviour
function zombie(x, y, s, flip, fill) {
  return G(`translate(${x},${y}) scale(${flip ? -s : s},${s})`, P('M10,330 L18,120 L44,92 L86,92 L112,120 L120,330Z', fill) + P('M18,120 L-34,30 L-20,22 L44,96Z', fill) + P('M112,120 L150,36 L138,28 L86,96Z', fill) +
    P('M-34,30 L-48,4 L-36,8 L-34,-8 L-24,10 L-14,-2 L-20,22Z', fill) + P('M150,36 L166,12 L154,14 L154,-2 L144,16 L132,6 L138,28Z', fill) + crab(66, 62, 0.3, fill));
}
ART.dream_saviour = () => {
  const dk = '#1a2738';
  let s = R(0, 0, 720, 610, '#080d15');
  s += rays(360, 190, 26, 900, C.cyan, 0, 360, 'opacity=".1"');
  s += P('M296,330 L424,330 L600,610 L120,610Z', C.cyan, 'opacity=".3"');
  s += R(284, 36, 152, 300, C.cyanD) + R(296, 48, 128, 282, '#eaf7f8');
  s += E(360, 124, 24, 30, C.ink) + P('M336,112 L344,90 L376,90 L386,112 L384,140 L378,116 L342,116 L338,140Z', C.ink) + P('M312,330 L322,186 L344,164 L376,164 L398,186 L408,330Z', C.ink) + P('M322,186 L300,262 L312,266 L334,206Z', C.ink) + P('M398,186 L470,150 L474,162 L396,206Z', C.ink);
  // what was closing in
  s += zombie(22, 250, 1.05, false, dk) + zombie(700, 262, 1.0, true, dk) + zombie(160, 200, 0.62, false, '#131d2a') + zombie(566, 206, 0.6, true, '#131d2a');
  s += crab(214, 540, 0.36, dk) + crab(520, 556, 0.3, dk) + crab(92, 96, 0.22, '#131d2a') + crab(632, 110, 0.2, '#131d2a');
  s += reader(292, 440, 1.7, 0);
  return s;
};

// The Loyalty Quiz
ART.dream_quiz = () => {
  let s = R(0, 0, 720, 610, C.slate) + R(0, 0, 720, 610, '#16212e', 'opacity=".4"');
  let sh = R(8, 10, 430, 560, '#0b1119', 'opacity=".5"') + R(0, 0, 430, 560, C.paper);
  sh += R(28, 28, 130, 160, C.blueD) + `<clipPath id="quizf"><rect x="28" y="28" width="130" height="160"/></clipPath><g clip-path="url(#quizf)">` + G('translate(20,40) scale(0.86)', adminBust({ pin: C.cyan })) + '</g>';
  sh += R(180, 34, 222, 16, C.ink) + R(180, 62, 180, 10, C.steel) + R(180, 82, 200, 10, C.steel) + R(180, 102, 120, 10, C.steel) + T(360, 186, '?', 96, C.cyanD);
  [['A', 232, true], ['B', 318, false], ['C', 404, false]].forEach(([l, y, tick]) => {
    sh += `<rect x="32" y="${y}" width="52" height="52" fill="none" stroke="${C.ink}" stroke-width="5"/>` + T(118, y + 42, l, 44, C.ink) + R(152, y + 12, 230, 10, C.steel) + R(152, y + 32, 170, 10, C.steel2);
    if (tick) sh += L(`M40,${y + 26} L56,${y + 44} L92,${y - 8}`, C.cyanD, 10);
  });
  sh += R(32, 490, 366, 6, C.ink) + G('translate(330,470)', emblem(0, 0, 1.3, C.red)) + `<circle cx="350" cy="500" r="46" fill="none" stroke="${C.red}" stroke-width="5" opacity=".8"/>`;
  s += G('translate(96,30) rotate(-5)', sh);
  s += G('translate(520,420) rotate(-38)', R(0, -11, 190, 22, C.warm) + P('M0,-11 L-34,0 L0,11Z', C.paper) + P('M-34,0 L-20,-4.6 L-20,4.6Z', C.ink) + R(190, -11, 22, 22, C.red) + R(176, -11, 14, 22, C.steel));
  s += scanner(606, 96, 1.15, C.red) + P('M596,120 L616,120 L560,330 L470,300Z', C.red, 'opacity=".12"');
  return s;
};

// Record Harvest
function wheat(x, y, h, lean, col, dk) {
  const tx = x + lean, ty = y - h;
  let s = L(`M${x},${y} Q${x + lean * 0.2},${y - h * 0.6} ${tx},${ty}`, dk, 4);
  for (let i = 0; i < 5; i++) { const yy = ty + i * 13, xx = tx - lean * 0.06 * i; s += E(xx - 7, yy + 6, 5, 10, col, `transform="rotate(-28 ${xx - 7} ${yy + 6})"`) + E(xx + 7, yy + 6, 5, 10, col, `transform="rotate(28 ${xx + 7} ${yy + 6})"`); }
  return s + E(tx, ty - 4, 5, 11, col);
}
ART.dream_harvest = () => {
  const gold = '#d9b54a', goldD = '#a8842a', sack = '#cdbb8e', sackD = '#a39064';
  let s = R(0, 0, 720, 340, C.paper) + rays(360, 340, 40, 1000, C.red, 180, 360, 'opacity=".2"') + `<circle cx="360" cy="340" r="132" fill="${C.red}"/>`;
  s += R(0, 336, 720, 274, gold);
  for (let i = -6; i <= 6; i++) s += L(`M${360 + i * 20},340 L${360 + i * 150},610`, goldD, 3, 'opacity=".55"');
  // more than was planned
  const pile = [[470, 560], [560, 560], [650, 560], [515, 492], [605, 492], [560, 424]];
  for (const [x, y] of pile) s += E(x, y + 34, 50, 8, goldD, 'opacity=".5"') + P(`M${x - 44},${y + 34} Q${x - 54},${y - 6} ${x - 26},${y - 30} L${x + 26},${y - 30} Q${x + 54},${y - 6} ${x + 44},${y + 34}Z`, sack) + P(`M${x + 10},${y - 30} L${x + 26},${y - 30} Q${x + 54},${y - 6} ${x + 44},${y + 34} L${x + 22},${y + 34}Z`, sackD) + P(`M${x - 14},${y - 30} L${x - 20},${y - 46} L${x + 20},${y - 46} L${x + 14},${y - 30}Z`, sackD) + G(`translate(${x - 16},${y - 16})`, emblem(0, 0, 0.7, C.red));
  s += worker(64, 150, 0.98, { arm: 'out', smile: true });
  for (const [l, h] of [[-34, 150], [-16, 172], [2, 186], [20, 170], [38, 148]]) s += wheat(292, 330, h, l, gold, goldD);
  s += R(276, 300, 32, 14, C.red);
  for (let i = 0; i < 12; i++) s += wheat(20 + i * 62, 640, 110 + (i % 3) * 22, (i % 2 ? 10 : -8), '#e6c869', goldD);
  return s;
};

// The Stakhanov Shift
ART.dream_shift = () => {
  let s = R(0, 0, 720, 610, C.paper) + rays(330, 250, 44, 1000, C.red, 0, 360, 'opacity=".16"');
  for (const [x, h] of [[30, 250], [96, 310], [600, 280], [662, 230]]) s += R(x, 610 - h - 160, 30, h + 160, C.slate3) + R(x - 4, 610 - h - 160, 38, 12, C.slate2) + E(x + 26, 610 - h - 190, 36, 22, C.steel2, 'opacity=".7"') + E(x + 62, 610 - h - 222, 44, 24, C.steel2, 'opacity=".45"');
  s += R(0, 470, 720, 140, C.slate3) + skyline(480, C.slate2, null, 4, 60);
  // the work of fourteen
  for (let i = 5; i >= 1; i--) s += G(`translate(${-i * 46},${i * 6})`, `<g opacity="${(0.34 - i * 0.05).toFixed(2)}">` + worker(196, 64, 1.2, { arm: 'out', hammer: true, tone: 3 }) + '</g>');
  s += worker(196, 64, 1.2, { arm: 'out', hammer: true });
  s += `<circle cx="604" cy="470" r="86" fill="${C.red}"/><circle cx="604" cy="470" r="74" fill="none" stroke="${C.paper}" stroke-width="4"/>` + T(604, 506, '×14', 84, C.paper);
  return s;
};

// Careless Talk
ART.dream_spy = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(360, 240, 36, 900, C.slate2, 0, 360, 'opacity=".6"');
  // who is behind them
  s += P('M110,610 L150,360 L250,300 L470,300 L570,360 L610,610Z', '#0b1119') + E(360, 214, 96, 104, '#0b1119') + P('M214,150 L506,150 L470,126 L452,36 L268,36 L250,126Z', '#0b1119') + R(250, 118, 220, 14, C.slate2);
  s += P('M300,206 L344,216 L342,228 L302,220Z', C.red) + P('M420,206 L376,216 L378,228 L418,220Z', C.red);
  // the two who talk
  const body = (t, bd) => P('M-40,330 L-20,250 L30,236 L84,236 L130,262 L150,330Z', t) + P('M30,236 L84,236 L70,330 L44,330Z', bd);
  s += G('translate(40,300) scale(1.75)', G('translate(0,-12)', '') + P('M-30,200 L-14,150 L30,118 L72,118 L110,140 L124,200Z', C.blue) + P('M36,118 L52,118 L62,200 L44,200Z', C.blueD) + head({ cap: C.blueD }));
  s += G('translate(680,300) scale(-1.75,1.75)', P('M-30,200 L-14,150 L30,118 L72,118 L110,140 L124,200Z', '#335073') + P('M36,118 L52,118 L62,200 L44,200Z', '#263a55') + head({ skin: '#c8c2b1', sh: '#727e88', hair: '#3a2c22' }));
  s += L('M250,452 Q280,440 250,428', C.cyan, 6) + L('M270,470 Q318,440 270,410', C.cyan, 6) + L('M470,452 Q440,440 470,428', C.cyan, 6) + L('M450,470 Q402,440 450,410', C.cyan, 6);
  s += R(0, 570, 720, 40, '#16212e');
  return s;
};

// The Newsreel
ART.dream_newsreel = () => {
  let s = R(0, 0, 720, 610, '#0a111a');
  s += P('M720,0 L720,70 L612,352 L108,48Z', C.paper, 'opacity=".07"') + P('M720,10 L720,40 L612,200 L108,48Z', C.paper, 'opacity=".06"');
  s += R(96, 36, 528, 328, C.slate3) + R(108, 48, 504, 304, '#d9e6e6');
  s += `<clipPath id="reel"><rect x="108" y="48" width="504" height="304"/></clipPath><g clip-path="url(#reel)">` + rays(360, 190, 36, 700, C.cyan, 0, 360, 'opacity=".45"') + G('translate(232,60) scale(1.5)', adminBust({ pin: C.cyan })) +
    R(108, 48, 504, 304, C.cyanD, 'opacity=".12"') + '</g>';
  for (const [x, y] of [[122, 62], [598, 62], [122, 338], [598, 338]]) s += `<circle cx="${x}" cy="${y}" r="7" fill="none" stroke="${C.ink}" stroke-width="2.5" opacity=".6"/>`;
  s += R(96, 364, 528, 8, C.ink);
  for (let i = 0; i < 7; i++) s += reader(8 + i * 102, 392, 1.2, 3, i % 3 === 0);
  for (let i = 0; i < 5; i++) s += reader(-30 + i * 152, 446, 1.75, 2, i % 2 === 1);
  return s;
};

const POSTERS = [
  row('adore', 71, ['KNEEL WHEN', 'SHE PASSES']),
  row('roses', 72, ['FLOWERS FOR THE', 'ADMINISTRATOR'], { accent: 'red' }),
  row('saviour', 73, ['SHE WILL', 'COME FOR YOU'], { night: true, acc: C.cyan }),
  row('quiz', 74, ['DO YOU KNOW YOUR', 'ADMINISTRATOR?']),
  row('harvest', 75, ['A RECORD', 'HARVEST'], { accent: 'red' }),
  row('shift', 76, ['DOUBLE THE QUOTA.', 'DOUBLE THE GLORY.'], { accent: 'red' }),
  row('spy', 77, ['CARELESS TALK', 'COSTS LIVES']),
  row('newsreel', 78, ['THE NEWS', 'IS GOOD'], { night: true, acc: C.cyan, ground: '#0a111a' }),
];

module.exports = { ART, POSTERS };
