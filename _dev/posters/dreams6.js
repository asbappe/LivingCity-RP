// The posters that hint at the Neutral dreams (dream_<codeword>), first half: rally (a Happy one),
// chairs, horse, boxing, exam, train, potato. Drawn by gen.js.
const { C, P, R, G, rays, emblem, head, worker, officer, citizen, reader, palm } = require('./lib.js');
const { E, L, T, rng, row, skyline } = require('./dreamkit.js');
const { no, hand, clock, YEL, DARK } = require('./dreamkit2.js');

const ART = {};

// Midnight Rally
ART.dream_rally = () => {
  let s = R(0, 0, 720, 610, DARK) + `<circle cx="590" cy="76" r="40" fill="${C.steel2}"/>` + skyline(212, '#101a27', '#2b3c50', 21, 120);
  s += P('M286,208 L434,208 L720,610 L0,610Z', '#162130');
  for (const [y, w, h] of [[226, 6, 22], [270, 9, 34], [336, 13, 52], [430, 19, 80], [560, 28, 60]]) s += P(`M${360 - w / 2},${y} L${360 + w / 2},${y} L${360 + w * 0.8},${y + h} L${360 - w * 0.8},${y + h}Z`, C.paper, 'opacity=".8"');
  // the lights, coming fast
  s += P('M286,372 L60,610 L330,610Z', C.warm, 'opacity=".28"') + P('M434,372 L390,610 L660,610Z', C.warm, 'opacity=".28"');
  s += R(246, 396, 44, 40, C.ink) + R(430, 396, 44, 40, C.ink) + P('M306,262 L414,262 L438,326 L282,326Z', '#22303f') + P('M316,272 L404,272 L420,318 L300,318Z', '#3d5068');
  s += P('M250,326 L470,326 L486,412 L234,412Z', '#2a3b4f') + R(322, 356, 76, 34, C.ink) + L('M330,366 h60 M330,378 h60', C.steel, 3) + R(234, 400, 252, 14, C.ink);
  for (const x of [286, 434]) s += `<circle cx="${x}" cy="366" r="34" fill="${C.warm}" opacity=".3"/><circle cx="${x}" cy="366" r="22" fill="${C.warm}"/><circle cx="${x}" cy="366" r="11" fill="#fff8e2"/>`;
  s += L('M150,250 h70 M120,290 h90 M520,250 h70 M530,290 h90', C.steel, 5, 'opacity=".5"');
  // and who stops them
  s += R(40, 520, 130, 90, '#141c26') + R(40, 536, 130, 26, C.red) + palm(38, 250, 1.5, C.ink) + palm(44, 256, 1.42, C.paper);
  return s;
};

// Musical Chairs
function seated(x, tone) {
  const b = [C.blue2, C.blue][tone % 2], bd = [C.blue, C.blueD][tone % 2];
  return R(x - 6, 318, 12, 136, C.steel) + R(x - 6, 446, 86, 12, C.steel) + R(x - 6, 458, 9, 84, C.steel) + R(x + 71, 458, 9, 84, C.steel) +
    P(`M${x + 12},358 L${x + 52},358 L${x + 58},448 L${x + 10},448Z`, b) + P(`M${x + 34},358 L${x + 52},358 L${x + 58},448 L${x + 40},448Z`, bd) +
    R(x + 12, 424, 88, 26, bd) + R(x + 78, 424, 24, 110, bd) + P(`M${x + 78},526 L${x + 102},526 L${x + 120},542 L${x + 78},542Z`, C.ink) +
    P(`M${x + 30},372 L${x + 46},372 L${x + 78},420 L${x + 66},428Z`, b) + G(`translate(${x + 2},276) scale(0.68)`, head({ cap: bd }));
}
ART.dream_chairs = () => {
  let s = R(0, 0, 720, 610, C.slate) + R(0, 540, 720, 70, C.slate2) + R(0, 540, 720, 5, '#1b2836');
  s += P('M590,0 L660,0 L720,300 L720,610 L530,610Z', C.paper, 'opacity=".13"') + E(634, 572, 100, 22, C.paper, 'opacity=".25"');
  let g = '';
  for (let i = 0; i < 3; i++) g += seated(36 + i * 132, i);
  s += G('translate(-10,-135) scale(1.25)', g + citizen(470, 318, 1.08, {}));
  s += R(0, 0, 720, 34, '#1b2836') + [90, 250, 410].map(x => L(`M${x},34 v56`, C.ink, 4) + P(`M${x - 34},90 L${x + 34},90 L${x + 50},128 L${x - 50},128Z`, C.steel) + P(`M${x - 46},128 L${x + 46},128 L${x + 120},300 L${x - 120},300Z`, C.paper, 'opacity=".06"')).join('');
  return s;
};

// Hooves and All
ART.dream_horse = () => {
  let s = R(0, 0, 720, 610, '#cfc8b4') + rays(-40, 620, 26, 1200, C.paper, 270, 360, 'opacity=".6"');
  // the shadow he casts
  const sh = '#958f7e';
  s += G('translate(352,40) scale(1.32)', P('M30,440 L44,330 L96,300 L80,170 L74,96 L62,30 L92,66 L106,22 L128,80 L214,196 L240,244 L228,274 L190,280 L152,238 L140,262 L170,300 L262,340 L290,440Z', sh) +
    [112, 150, 190, 230].map(y => P(`M82,${y} L54,${y + 14} L82,${y + 34}Z`, sh)).join(''));
  s += R(46, 40, 86, 86, C.cyanD) + R(76, 54, 26, 58, C.paper) + R(60, 70, 58, 26, C.paper);
  s += worker(92, 210, 0.92, { cap: false });
  s += R(0, 560, 720, 50, C.steel) + R(0, 560, 720, 6, C.slate3);
  return s;
};

// The Main Event
function glove(x, y, s, col, dk, flip) {
  return G(`translate(${x},${y}) scale(${flip ? -s : s},${s})`, R(-330, -44, 200, 88, C.blue) + R(-330, 10, 200, 34, C.blueD, 'opacity=".5"') + R(-150, -58, 74, 116, C.paper, 'rx="10"') + L('M-132,-40 v80 M-112,-40 v80 M-92,-40 v80', C.steel, 4) +
    E(10, 0, 100, 82, col) + E(34, -62, 50, 30, dk) + P('M-80,30 L70,60 L40,82 L-60,70Z', dk, 'opacity=".6"') + L('M40,-20 Q78,0 60,40', C.paper, 5, 'opacity=".35"'));
}
ART.dream_boxing = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(360, 120, 24, 900, C.slate2, 0, 180, 'opacity=".6"');
  for (const y of [150, 240, 330]) s += R(0, y, 720, 10, C.paper, 'opacity=".75"');
  s += R(0, 100, 26, 510, C.steel) + R(694, 100, 26, 510, C.steel) + R(0, 560, 720, 50, '#1b2836');
  s += officer(294, 86, 1.1, { baton: true, lens: C.cyan, band: C.cyan });
  s += glove(150, 420, 0.86, C.red, C.redD) + glove(570, 420, 0.86, C.blue2, C.blueD, true);
  return s;
};

// The Exam
ART.dream_exam = () => {
  let s = R(0, 0, 720, 610, C.slate) + R(0, 280, 720, 330, C.slate2) + R(0, 280, 720, 6, '#1b2836');
  s += clock(360, 104, 70, -60, -30);
  s += R(64, 30, 190, 222, C.paper) + R(64, 30, 190, 30, C.ink) + emblem(76, 34, 0.48, C.paper);
  const q = rng(8);
  for (let r = 0; r < 6; r++) for (let c = 0; c < 4; c++) { const on = Math.floor(q() * 4) === c; s += `<circle cx="${100 + c * 40}" cy="${84 + r * 28}" r="9" fill="${on ? C.ink : 'none'}" stroke="${C.ink}" stroke-width="2.5"/>`; }
  s += officer(540, 40, 0.74, { lens: C.cyan, band: C.cyan });
  const desk = (x, y, k, tone) => R(x - 26 * k, y + 78 * k, 132 * k, 12 * k, C.steel) + R(x - 26 * k, y + 90 * k, 132 * k, 40 * k, '#1b2836') + R(x + 78 * k, y + 66 * k, 22 * k, 13 * k, C.paper) + reader(x, y, k, tone, tone % 2 === 0);
  s += desk(70, 300, 1.15, 2) + desk(300, 300, 1.15, 3) + desk(530, 300, 1.15, 2);
  s += desk(-10, 420, 1.6, 0) + desk(290, 420, 1.6, 1) + desk(590, 420, 1.6, 0);
  return s;
};

// The Last Train
ART.dream_train = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(720, 250, 30, 1000, C.slate2, 150, 210, 'opacity=".5"') + skyline(300, '#1f2d3d', null, 31, 120);
  s += P('M-20,214 L420,214 L530,330 L530,480 L-20,480Z', '#141c26') + P('M-20,214 L420,214 L436,232 L-20,232Z', C.slate3);
  for (let x = -6; x < 400; x += 86) s += R(x, 262, 70, 62, C.cyan) + R(x, 262, 70, 12, C.cyanD);
  s += P('M426,262 L466,262 L512,324 L426,324Z', C.cyan) + R(-20, 356, 550, 16, C.red) + R(-20, 440, 550, 40, C.ink);
  s += L('M560,300 h90 M574,350 h110 M560,400 h70', C.paper, 6, 'opacity=".5"');
  s += R(0, 480, 720, 130, C.steel) + R(0, 480, 720, 10, YEL) + R(0, 490, 720, 6, '#5d6770');
  s += R(650, 150, 12, 330, C.ink) + clock(656, 110, 56, 0, 0);
  s += citizen(250, 370, 1.02, { case: true });
  return s;
};

// Hot Potato
ART.dream_potato = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(360, 210, 24, 800, C.slate2, 0, 360, 'opacity=".45"');
  s += `<circle cx="360" cy="210" r="130" fill="${C.red}" opacity=".22"/><circle cx="360" cy="210" r="96" fill="${C.red}" opacity=".3"/>`;
  s += L('M316,96 q-16,-22 0,-44 q16,-22 0,-44 M360,84 q-16,-22 0,-44 q16,-22 0,-44 M404,96 q-16,-22 0,-44 q16,-22 0,-44', C.red, 7);
  s += hand(214, 236, 1.2, 0) + G('translate(0,0)', hand(506, 236, 1.2, 0, { flip: true, sleeve: '#335073', cuff: '#263a55', skin: '#c8c2b1' }));
  s += P('M290,200 L310,160 L360,146 L412,158 L438,198 L428,244 L390,268 L330,266 L296,242Z', '#a9825a') + P('M360,146 L412,158 L438,198 L428,244 L390,268 L400,220 L390,176Z', '#86643f');
  for (const [x, y] of [[326, 196], [352, 232], [376, 180], [398, 240]]) s += E(x, y, 6, 4, '#5e452b');
  s += L('M560,170 L640,300 M640,170 L560,300', C.red, 16);
  // where it goes instead
  s += L('M360,296 v70', C.cyan, 12) + P('M330,360 L390,360 L360,400Z', C.cyan);
  s += E(360, 470, 120, 96, C.cyan, 'opacity=".12"') + hand(360, 528, 1.25, -90, { sleeve: '#141c26', cuff: C.ink, skin: C.steel2, band: C.cyan });
  return s;
};

const POSTERS = [
  row('rally', 101, ['NO RACING', 'AFTER CURFEW'], { night: true }),
  row('chairs', 102, ['A SEAT FOR', 'EVERY WORKER']),
  row('horse', 103, ['NOT FEELING', 'YOURSELF?'], { accent: 'red' }),
  row('boxing', 104, ['NO FIGHTING']),
  row('exam', 105, ['ARE YOU READY FOR', 'YOUR ASSESSMENT?']),
  row('train', 106, ['EVERY TRAIN', 'LEAVES ON TIME']),
  row('potato', 107, ["DON'T PASS IT ON"]),
];
module.exports = { ART, POSTERS };
