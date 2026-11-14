// The posters that hint at dreams (sv_livingcity_dreamposters.lua): dream_<codeword>, drawn by gen.js.
// The words are LC.DreamPosterHints' own. Five so far: lamarr, cheese, watchers, mirror, and the melons' (dream_forecast, inside the dream only).
// The small words are one sentence each (the owner, 14 November).
const { C, P, R, G, rays, emblem, worker, officer, reader, adminBust } = require('./lib.js');

const E = (cx, cy, rx, ry, f, extra = '') => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="${ry}" fill="${f}" ${extra}/>`;
const L = (d, col, w, extra = '') => `<path d="${d}" stroke="${col}" stroke-width="${w}" fill="none" stroke-linecap="round" ${extra}/>`;
// the same scatter every run
function rng(seed) { let a = seed; return () => { a = (a * 16807) % 2147483647; return a / 2147483647; }; }

const ART = {};

// It's Raining Melons: fair weather, with produce. Nobody looks up. (dream_forecast: it hangs only
// inside that dream, never in the waking city: the owner, 14 November.)
let melonN = 0;
function melon(x, y, s, rot, fall = 0) {
  const gr = '#3f6b4a', gd = '#264a33';
  let g = '';
  if (fall) for (const dx of [-34, 0, 34]) g += R(dx - 4, -60 - fall - (dx ? 0 : 40), 8, fall, C.slate3, 'opacity=".45"');
  const id = 'mel' + (melonN++);
  let m = `<clipPath id="${id}"><ellipse cx="0" cy="0" rx="62" ry="48"/></clipPath>` + E(0, 0, 62, 48, gr) + `<g clip-path="url(#${id})">`;
  for (const [dx, k] of [[-42, -14], [-15, -6], [15, 6], [42, 14]]) m += L(`M${dx},${-Math.sqrt(1 - (dx / 62) ** 2) * 46} Q${dx + k},0 ${dx},${Math.sqrt(1 - (dx / 62) ** 2) * 46}`, gd, 9);
  m += '</g>';
  m += E(-22, -24, 16, 7, '#8fb08f', 'opacity=".55" transform="rotate(-24 -22 -24)"');
  return G(`translate(${x},${y}) scale(${s})`, g + G(`rotate(${rot})`, m));
}
ART.dream_forecast = () => {
  let s = R(0, 0, 720, 610, '#b9c6c4') + rays(360, -60, 40, 1000, C.paper, 0, 180, 'opacity=".55"');
  // the city, far off
  const sky = [[0, 400, 90], [80, 350, 70], [150, 420, 80], [230, 330, 60], [470, 340, 70], [540, 410, 90], [630, 360, 90]];
  for (const [x, y, w] of sky) {
    s += R(x, y, w, 300, C.slate3) + R(x, y, w, 8, C.slate2);
    for (let wy = y + 22; wy < 520; wy += 30) for (let wx = x + 10; wx < x + w - 14; wx += 22) s += R(wx, wy, 10, 14, C.slate2);
  }
  s += R(0, 520, 720, 90, C.slate);
  // the produce
  s += melon(130, 120, 1.25, -18, 70) + melon(590, 96, 0.95, 24, 60) + melon(372, 176, 1.6, 10, 90) + melon(250, 300, 0.7, -30, 46) + melon(520, 286, 0.78, 14, 50) + melon(60, 300, 0.55, 8, 36) + melon(668, 250, 0.5, -12, 34);
  // one that landed, on a rooftop
  s += G('translate(576,404) rotate(-8)', P('M-52,0 A52,44 0 0 0 52,0Z', '#3f6b4a') + P('M-44,0 A44,36 0 0 0 44,0Z', C.paper) + P('M-39,0 A39,31 0 0 0 39,0Z', C.red) +
    [-22, -6, 10, 24].map((x, i) => E(x, 9 + (i % 2) * 7, 2.6, 4.2, C.ink)).join(''));
  // the citizens, eyes front; a unit sees to it
  s += reader(14, 452, 1.5, 2, true) + reader(160, 440, 1.6, 1) + reader(432, 440, 1.6, 0, true) + reader(580, 452, 1.5, 2);
  s += officer(306, 316, 0.9, { baton: true, lens: C.red });
  return s;
};

// Where's Lamarr?: a mugshot of a small, bald pet.
ART.dream_lamarr = () => {
  const tan = '#d8c59c', tanD = '#b39c72', tanDD = '#8a7652';
  let s = R(0, 0, 720, 610, C.slate) + G('translate(40,36)', emblem(0, 0, 1.5, C.slate2)) + G('translate(620,500)', emblem(0, 0, 1.5, C.slate2));
  // the board, with its height lines
  s += R(118, 48, 500, 520, '#10161f', 'opacity=".5"') + R(110, 40, 500, 520, '#d2cbb6');
  for (let i = 0; i < 9; i++) {
    const y = 84 + i * 44;
    s += R(110, y, 500, i % 2 ? 2 : 4, C.steel);
    if (i % 2 === 0) s += `<text x="124" y="${y - 7}" font-family="Inter" font-weight="800" font-size="19" fill="${C.steel}">${50 - i * 5}</text><text x="596" y="${y - 7}" text-anchor="end" font-family="Inter" font-weight="800" font-size="19" fill="${C.steel}">${50 - i * 5}</text>`;
  }
  // the animal
  let c = E(0, 96, 190, 20, C.ink, 'opacity=".22"');
  c += P('M-70,-20 L-168,-96 L-214,60 L-196,66 L-160,-44 L-60,26Z', tanDD) + P('M70,-20 L168,-96 L214,60 L196,66 L160,-44 L60,26Z', tanDD);
  c += P('M-214,60 L-196,66 L-208,98Z', C.ink) + P('M214,60 L196,66 L208,98Z', C.ink);
  c += E(0, 0, 118, 84, tan) + P('M-118,0 A118,84 0 0 0 118,0 Q0,58 -118,0Z', tanD);
  c += L('M-54,-58 Q-20,-70 4,-60', tanD, 5) + L('M22,-66 Q52,-58 70,-40', tanD, 5) + L('M-84,-22 Q-70,-40 -52,-44', tanD, 4);
  c += E(-34, -34, 26, 12, '#efe3c4', 'opacity=".6" transform="rotate(-18 -34 -34)"');
  c += P('M-64,34 L-128,58 L-150,150 L-128,152 L-104,86 L-40,66Z', tan) + P('M64,34 L128,58 L150,150 L128,152 L104,86 L40,66Z', tan);
  c += P('M-128,58 L-150,150 L-140,151 L-118,70Z', tanD) + P('M128,58 L150,150 L140,151 L118,70Z', tanD);
  c += P('M-150,150 L-128,152 L-144,186Z', C.ink) + P('M150,150 L128,152 L144,186Z', C.ink);
  s += G('translate(360,268)', c);
  // its plate, and the stamp
  s += R(226, 470, 268, 58, C.ink) + R(232, 476, 256, 46, C.ink, `stroke="${C.steel2}" stroke-width="2"`);
  s += `<text x="360" y="508" text-anchor="middle" font-family="Inter" font-weight="800" font-size="23" fill="${C.paper}" letter-spacing="3">UNLICENSED PET</text>`;
  s += G('translate(520,112) rotate(-13)', `<rect x="-118" y="-36" width="236" height="72" fill="none" stroke="${C.red}" stroke-width="7"/><text x="0" y="17" text-anchor="middle" font-family="Inter Display" font-weight="900" font-size="48" fill="${C.red}" letter-spacing="2">AT LARGE</text>`);
  for (const [x, y] of [[124, 54], [596, 54], [124, 546], [596, 546]]) s += `<circle cx="${x}" cy="${y}" r="6" fill="${C.steel}"/><circle cx="${x - 1.5}" cy="${y - 1.5}" r="2.4" fill="${C.paper}"/>`;
  return s;
};

// The Cheese Dream: citizens do not think about cheese.
ART.dream_cheese = () => {
  const ch = '#e3b93c', chL = '#f2d570', chD = '#b98a1f';
  let s = R(0, 0, 720, 610, C.night);
  const r = rng(77);
  for (let i = 0; i < 70; i++) s += `<circle cx="${(r() * 720).toFixed(0)}" cy="${(r() * 610).toFixed(0)}" r="${(0.8 + r() * 1.6).toFixed(1)}" fill="${C.paper}" opacity="${(0.25 + r() * 0.5).toFixed(2)}"/>`;
  // the thought
  const cloud = [[330, 232, 92], [430, 168, 112], [548, 214, 100], [488, 296, 104], [384, 306, 84], [600, 290, 60]];
  for (const [x, y, rad] of cloud) s += `<circle cx="${x}" cy="${y + 8}" r="${rad}" fill="#060b12" opacity=".6"/>`;
  for (const [x, y, rad] of cloud) s += `<circle cx="${x}" cy="${y}" r="${rad}" fill="${C.paper}"/>`;
  s += `<circle cx="266" cy="376" r="30" fill="${C.paper}"/><circle cx="242" cy="424" r="16" fill="${C.paper}"/>`;
  // the cheese
  s += P('M318,254 L566,212 L566,318 L318,338Z', ch) + P('M318,254 L500,150 L566,212Z', chL) + P('M318,254 L566,212 L566,222 L318,264Z', chD, 'opacity=".5"');
  s += E(382, 296, 22, 17, chD) + E(456, 272, 14, 11, chD) + E(520, 290, 19, 15, chD) + E(426, 316, 9, 7, chD) + E(548, 246, 8, 6, chD) + E(470, 196, 17, 8, ch) + E(520, 206, 8, 4, ch);
  // refused
  s += `<circle cx="446" cy="240" r="150" fill="none" stroke="${C.red}" stroke-width="22"/>` + L('M340,134 L552,346', C.red, 22);
  // the citizen, and what he is to think about instead
  s += worker(26, 360, 1.9, { tone: 1 });
  s += R(498, 440, 196, 150, C.slate2) + R(498, 440, 196, 10, C.slate3) + R(588, 590, 16, 20, C.slate3);
  [34, 58, 50, 84, 106].forEach((h, i) => { s += R(514 + i * 35, 574 - h, 24, h, i === 4 ? C.red : C.steel2); });
  s += L('M516,528 L552,500 L584,512 L622,470 L664,452', C.paper, 4) + P('M652,444 L674,448 L662,466Z', C.paper);
  return s;
};

// The Watchers: you are never alone.
function eyes(x, y, w, look = 0, col = C.red) {
  const rx = w * 0.3, ry = w * 0.17;
  return [-1, 1].map(k => E(x + k * w * 0.42, y, rx, ry, C.paper) + `<circle cx="${x + k * w * 0.42 + look * rx * 0.45}" cy="${y}" r="${(ry * 0.78).toFixed(1)}" fill="${col}"/><circle cx="${x + k * w * 0.42 + look * rx * 0.45}" cy="${y}" r="${(ry * 0.32).toFixed(1)}" fill="${C.ink}"/>`).join('');
}
ART.dream_watchers = () => {
  let s = R(0, 0, 720, 610, '#080d15') + R(0, 470, 720, 140, '#0c141f');
  // the window, and who stands at it
  s += R(232, 44, 256, 330, C.slate2) + R(246, 58, 228, 302, '#27405f') + P('M246,58 L474,58 L474,150 L246,230Z', '#34557c');
  s += `<circle cx="430" cy="108" r="30" fill="${C.paper}" opacity=".85"/>`;
  s += `<clipPath id="pane"><rect x="246" y="58" width="228" height="302"/></clipPath><g clip-path="url(#pane)">`;
  for (const [x, top, w] of [[300, 150, 1], [362, 112, 1.12], [424, 168, 0.94]]) {
    s += E(x, top + 26, 21 * w, 27 * w, '#070b11') + P(`M${x - 40 * w},${top + 78} L${x - 12 * w},${top + 48} L${x + 12 * w},${top + 48} L${x + 40 * w},${top + 78} L${x + 46 * w},380 L${x - 46 * w},380Z`, '#070b11');
    s += eyes(x, top + 24, 22 * w, 0, C.red);
  }
  s += '</g>' + R(354, 58, 10, 302, C.slate2) + R(246, 196, 228, 10, C.slate2) + R(222, 360, 276, 16, C.slate3);
  s += P('M246,376 L474,376 L640,610 L80,610Z', '#34557c', 'opacity=".22"');
  // the dark is looking too
  const r = rng(31);
  const spots = [[70, 90, 40], [150, 190, 26], [60, 270, 30], [170, 330, 22], [96, 400, 34], [40, 180, 18], [640, 80, 36], [560, 170, 24], [660, 250, 30], [548, 300, 20], [620, 380, 34], [690, 160, 16], [540, 70, 16], [190, 80, 18]];
  for (const [x, y, w] of spots) s += G(`rotate(${(r() * 10 - 5).toFixed(1)} ${x} ${y})`, eyes(x, y, w, x < 360 ? 0.9 : -0.9));
  // the bed, and the sleeper
  s += R(86, 392, 26, 160, C.slate2) + R(608, 452, 22, 100, C.slate2) + R(86, 520, 544, 22, C.slate3) + R(96, 542, 16, 50, C.slate2) + R(604, 542, 16, 50, C.slate2);
  s += R(112, 478, 496, 44, C.steel2) + E(186, 470, 70, 22, C.paper);
  s += G('translate(196,444)', E(0, 0, 30, 25, '#c8c2b1') + P('M-30,2 A30,25 0 0 1 -6,-24 L4,-12 L-14,10Z', C.ink) + L('M6,-6 L18,-4', C.ink, 2.6) + L('M14,10 L24,10', C.ink, 2.2) + P('M26,-4 L36,2 L27,6Z', '#c8c2b1'));
  s += P('M224,478 Q250,420 330,430 Q430,400 520,440 Q590,430 608,470 L608,506 L224,506Z', C.blueD) + P('M224,478 Q250,420 330,430 Q300,450 290,506 L224,506Z', C.blue);
  // and under it
  s += R(112, 542, 492, 52, '#05080d') + eyes(330, 568, 30, -0.6);
  return s;
};

// Mirror, Mirror: who is the fairest? You already know.
ART.dream_mirror = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(360, 250, 44, 900, C.slate2, 0, 360, 'opacity=".7"');
  // the glass, and who is in it
  s += E(366, 262, 204, 240, '#131c28', 'opacity=".55"') + E(360, 252, 204, 240, C.steel) + E(360, 252, 190, 226, C.steel2) + E(360, 252, 172, 208, C.blueD);
  s += `<clipPath id="glass"><ellipse cx="360" cy="252" rx="172" ry="208"/></clipPath><g clip-path="url(#glass)">`;
  s += rays(360, 250, 30, 500, C.cyan, 0, 360, 'opacity=".3"');
  s += G('translate(181,52) scale(2.1)', adminBust({ pin: C.cyan }));
  s += P('M150,60 L250,60 L90,460 L-10,460Z', '#fff', 'opacity=".12"') + P('M270,60 L300,60 L140,460 L110,460Z', '#fff', 'opacity=".1"');
  s += '</g>';
  for (let i = 0; i < 12; i++) { const a = i * Math.PI / 6; s += `<circle cx="${(360 + 197 * Math.cos(a)).toFixed(1)}" cy="${(252 + 233 * Math.sin(a)).toFixed(1)}" r="6" fill="${C.slate}"/>`; }
  s += G('translate(330,-4)', emblem(0, 0, 1.5, C.cyan));
  // the citizens who ask it
  s += reader(26, 430, 1.7, 2, true) + reader(558, 430, 1.7, 2);
  s += reader(238, 372, 3.05, 0);
  return s;
};

const TAG = 'SLEEP WELL, CITIZEN';
const POSTERS = [
  { id: 'dream_forecast', n: 51, accent: 'red', tag: TAG, head: [['FORECAST: FAIR,', 78], ['WITH PRODUCE', 92]],
    small: ['Fresh fruit is a privilege of compliance;', 'do not look up for it.'] },
  { id: 'dream_lamarr', n: 52, accent: 'red', tag: TAG, head: [['HAVE YOU SEEN', 84], ['THIS ANIMAL?', 92]],
    small: ['A small, bald, beaked pet is loose in the city:', 'do not approach it, do not feed it, report it.'] },
  { id: 'dream_cheese', n: 53, accent: 'cyan', dark: true, acc: '#e3b93c', tag: TAG, head: [['DAIRY IS', 132], ['A PRIVILEGE', 98]],
    small: ['Citizens do not think about cheese;', 'citizens think about their quota.'] },
  { id: 'dream_watchers', n: 54, accent: 'cyan', dark: true, acc: C.red, ground: '#080d15', tag: TAG, head: [['YOU ARE', 140], ['NEVER ALONE', 96]],
    small: ['Even when you close your eyes.'] },
  { id: 'dream_mirror', n: 55, accent: 'cyan', tag: TAG, head: [['WHO IS', 140], ['THE FAIREST?', 92]],
    small: ['You already know the answer.'] },
];

module.exports = { ART, POSTERS };
