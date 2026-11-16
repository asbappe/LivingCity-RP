// The posters that hint at the Happy dreams (dream_<codeword>): flying, dance, sheep, derby, paint,
// conga, bubbles. Drawn by gen.js.
const { C, P, R, G, rays, emblem, worker, scanner } = require('./lib.js');
const { E, L, T, rng, row, walker, crab, skyline } = require('./dreamkit.js');
const { no, hand, note, ORANGE, YEL, DARK } = require('./dreamkit2.js');

const ART = {};

// Wings
ART.dream_flying = () => {
  let s = R(0, 0, 720, 610, DARK);
  s += P('M110,610 L300,0 L470,0Z', C.cyan, 'opacity=".17"') + P('M630,610 L310,0 L480,0Z', C.cyan, 'opacity=".17"');
  s += skyline(540, '#101a27', '#2b3c50', 7, 170) + R(0, 540, 720, 70, '#0c131d');
  const wing = P('M-10,-34 L-56,-74 L-150,-96 L-132,-52 L-104,-44 L-116,-14 L-74,-18 L-80,8 L-12,2Z', C.paper);
  s += G('translate(392,170)', wing + G('scale(-1,1)', wing) + P('M-11,-40 L11,-40 L15,30 L9,92 L1,92 L0,40 L-1,92 L-9,92 L-15,30Z', C.blue2) + E(0, -56, 15, 17, C.paper));
  s += `<circle cx="392" cy="170" r="128" fill="none" stroke="${C.red}" stroke-width="7"/>` + L('M392,22 v40 M392,278 v40 M244,170 h40 M500,170 h40', C.red, 7);
  s += scanner(128, 118, 0.95, C.red) + scanner(628, 300, 0.7, C.red);
  s += R(0, 548, 720, 6, C.cyan);
  for (const [x, t] of [[70, 0], [250, 0], [560, 0]]) s += walker(x, 548 - 258 * 0.5, 0.5, { leg: '#31445a', hat: '#31445a' });
  return s;
};

// Dance Marathon
ART.dream_dance = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(360, 300, 28, 800, C.slate2, 0, 360, 'opacity=".5"');
  s += skyline(612, '#1b2836', null, 12, 90) + R(96, 400, 26, 210, '#1b2836') + R(140, 440, 22, 170, '#1b2836');
  // the gramophone
  s += P('M392,404 L420,404 L446,300 L420,292Z', C.steel) + P('M414,306 L452,286 L600,190 L500,56Z', YEL) + P('M452,286 L600,190 L566,150Z', '#b08a22');
  s += E(552, 120, 86, 44, '#b08a22', 'transform="rotate(52 552 120)"') + E(552, 120, 62, 28, C.ink, 'transform="rotate(52 552 120)" opacity=".7"');
  s += R(236, 420, 250, 96, '#4c3524') + R(236, 420, 250, 16, '#6b4a31') + R(226, 512, 270, 16, '#33231a') + E(350, 418, 104, 22, C.ink) + E(350, 418, 34, 8, C.red) + E(350, 418, 5, 2, C.paper);
  s += L('M486,470 h34 v-22', C.steel, 8) + R(512, 432, 16, 18, C.ink);
  s += note(150, 250, 1.1, C.paper, -12) + note(250, 150, 0.9, C.paper, 10) + note(120, 120, 0.7, C.paper, -4);
  return s + no(360, 300, 262, 28);
};

// Counting Headcrabs
ART.dream_sheep = () => {
  let s = R(0, 0, 720, 610, DARK);
  for (const [x, y, r] of [[250, 392, 13], [282, 356, 20]]) s += `<circle cx="${x}" cy="${y}" r="${r}" fill="${C.paper}"/>`;
  s += E(250, 200, 150, 120, C.paper) + E(420, 160, 190, 130, C.paper) + E(540, 230, 150, 110, C.paper) + E(380, 262, 230, 78, C.paper);
  s += `<clipPath id="think"><ellipse cx="390" cy="225" rx="290" ry="118"/></clipPath><g clip-path="url(#think)">`;
  s += crab(612, 232, 0.27, C.steel);
  for (let x = 160; x <= 640; x += 80) s += R(x, 236, 12, 90, C.slate3);
  s += R(120, 252, 560, 10, C.slate3) + R(120, 286, 560, 10, C.slate3) + '</g>';
  // the blessings, counted over the fence
  s += G('translate(238,176) rotate(-14)', R(-30, -22, 60, 44, C.steel) + R(-30, -8, 60, 18, C.red) + E(0, -22, 30, 7, C.steel2));
  s += G('translate(392,128)', R(-36, -24, 72, 48, C.red) + emblem(-12, -14, 0.6, C.paper));
  s += G('translate(540,176) rotate(14)', R(-13, -30, 26, 60, C.cyanD) + R(-7, -46, 14, 18, C.cyanD) + R(-8, -52, 16, 8, C.ink) + R(-13, -8, 26, 16, C.paper));
  s += T(238, 118, '1', 34, C.ink) + T(392, 82, '2', 34, C.ink) + T(566, 112, '3', 34, C.ink);
  // the citizen, awake
  s += R(52, 540, 640, 26, '#1c2836') + R(60, 566, 20, 44, '#1c2836') + R(664, 566, 20, 44, '#1c2836') + R(52, 420, 22, 146, '#1c2836');
  s += P('M80,440 L226,430 L236,540 L80,540Z', C.steel2) + G('translate(96,540) rotate(-90) scale(1.25)', require('./lib.js').head({ cap: null }));
  s += P('M236,440 L680,470 L690,540 L236,540Z', C.blue) + P('M236,440 L316,446 L300,540 L236,540Z', C.blue2) + P('M226,512 L690,516 L690,540 L226,540Z', C.blueD);
  return s;
};

// Headcrab Derby
ART.dream_derby = () => {
  let s = R(0, 0, 720, 610, '#1b2836');
  for (let i = 0; i < 3; i++) s += R(0, 96 + i * 144, 720, 132, i % 2 ? '#2d4057' : C.slate2) + L(`M0,${96 + i * 144} h720`, C.paper, 4, 'stroke-dasharray="26 18" opacity=".7"');
  s += L('M0,528 h720', C.paper, 4, 'stroke-dasharray="26 18" opacity=".7"');
  for (let y = 96; y < 528; y += 24) for (let k = 0; k < 2; k++) s += R(600 + k * 24, y, 24, 24, ((y - 96) / 24 + k) % 2 ? C.paper : C.ink);
  [[420, 162, 3], [500, 306, 1], [300, 450, 2]].forEach(([x, y, n]) => {
    s += L(`M${x - 250},${y - 16} h110 M${x - 280},${y + 14} h130`, C.steel2, 5, 'opacity=".6"');
    s += crab(x, y, 0.36, '#c9b48a') + `<circle cx="${x}" cy="${y}" r="24" fill="${C.paper}"/>` + T(x, y + 13, n, 36, C.ink);
  });
  for (const [x, y] of [[92, 566], [132, 580], [166, 560]]) s += E(x, y, 26, 12, '#b08a22') + E(x, y - 6, 26, 12, YEL);
  return s + no(360, 310, 262, 28);
};

// Splat!
function splat(x, y, r, col, seed) {
  const q = rng(seed);
  let d = '';
  for (let i = 0; i < 18; i++) { const a = i * Math.PI / 9, rr = r * (i % 2 ? 0.62 + q() * 0.2 : 0.95 + q() * 0.5); d += (i ? 'L' : 'M') + (x + rr * Math.cos(a)).toFixed(0) + ',' + (y + rr * Math.sin(a)).toFixed(0); }
  let s = P(d + 'Z', col);
  for (let i = 0; i < 3; i++) { const dx = (q() - 0.5) * r * 1.1, h = r * (0.7 + q() * 1.1); s += `<rect x="${(x + dx - 6).toFixed(0)}" y="${y}" width="12" height="${h.toFixed(0)}" rx="6" fill="${col}"/>`; }
  for (let i = 0; i < 5; i++) s += `<circle cx="${(x + (q() - 0.5) * r * 3.4).toFixed(0)}" cy="${(y + (q() - 0.5) * r * 3).toFixed(0)}" r="${(4 + q() * 8).toFixed(0)}" fill="${col}"/>`;
  return s;
}
ART.dream_paint = () => {
  let s = R(0, 0, 720, 610, '#7f878c'), g = '';
  for (let y = 0; y < 610; y += 44) { g += `M0,${y} h720 `; for (let x = (y / 44) % 2 ? 0 : 48; x < 720; x += 96) g += `M${x},${y} v44 `; }
  s += L(g, '#6c7479', 3);
  s += splat(130, 150, 78, ORANGE, 5) + splat(300, 330, 92, '#c8457f', 9) + splat(110, 440, 60, YEL, 14) + splat(330, 110, 56, '#4fa56b', 21) + splat(420, 470, 50, C.cyan, 33);
  // painted over, a strip at a time
  s += P('M470,0 L720,0 L720,610 L452,610Z', '#b9c0c0') + R(384, 0, 90, 300, '#b9c0c0') + R(384, 300, 90, 10, '#a3abab');
  s += L('M494,318 L436,226', '#4c3524', 12) + R(378, 176, 104, 46, C.ink, 'rx="12"') + R(384, 180, 92, 38, '#d9dedc', 'rx="10"');
  s += G('translate(720,0) scale(-1,1)', worker(36, 176, 0.8, { arm: 'out' }));
  return s;
};

// Conga!
ART.dream_conga = () => {
  let s = R(0, 0, 720, 610, C.slate) + R(0, 540, 720, 70, C.slate2) + R(0, 566, 720, 8, YEL);
  s += R(604, 236, 104, 306, '#141c26') + R(604, 236, 104, 14, C.slate3) + R(622, 270, 68, 56, C.cyanD) + R(630, 278, 52, 40, C.cyan) + R(622, 400, 68, 22, C.ink) + emblem(640, 344, 0.8, C.steel) + R(624, 440, 64, 8, C.red);
  const k = 0.88, y = 540 - 258 * k;
  for (const x of [8, 124, 472]) s += walker(x, y, k);
  s += G('rotate(-13 398 540)', walker(352, y - 14, k) + P('M384,278 L398,282 L372,196 L358,202Z', C.blue2) + P('M410,280 L424,274 L464,204 L450,196Z', C.blue2) +
    `<circle cx="364" cy="192" r="12" fill="${C.paper}"/><circle cx="460" cy="194" r="12" fill="${C.paper}"/>`);
  s += note(250, 150, 0.8, C.paper, -10) + note(520, 120, 0.7, C.paper, 12);
  s += `<circle cx="398" cy="360" r="186" fill="none" stroke="${C.red}" stroke-width="9"/>` + L('M267,229 L529,491', C.red, 9);
  s += walker(240, y, k);
  return s;
};

// Bubbles
ART.dream_bubbles = () => {
  let s = R(0, 0, 720, 610, C.slate) + rays(250, 420, 26, 900, C.slate2, 0, 360, 'opacity=".45"');
  s += R(226, 0, 40, 150, C.steel) + R(226, 0, 14, 150, C.steel2) + P('M206,150 L286,150 L286,196 L262,214 L230,214 L206,196Z', C.steel) + R(160, 118, 172, 20, C.steel2) + R(236, 214, 20, 150, C.cyan);
  s += P('M40,500 L460,500 L430,610 L70,610Z', C.steel2) + P('M40,500 L460,500 L454,522 L46,522Z', C.paper) + E(250, 520, 170, 16, C.cyanD);
  s += hand(176, 420, 1, 14) + hand(322, 420, 1, -14, { flip: true });
  s += R(190, 356, 120, 62, C.paper, 'rx="16"') + R(190, 398, 120, 20, C.steel2, 'rx="10" opacity=".7"') + emblem(232, 366, 0.8, C.steel);
  const b = (x, y, r) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${C.cyan}" fill-opacity=".14" stroke="${C.cyan}" stroke-width="4"/>` + L(`M${x - r * 0.55},${y - r * 0.2} A${r * 0.6},${r * 0.6} 0 0 1 ${x - r * 0.1},${y - r * 0.6}`, C.paper, 4);
  s += b(380, 330, 20) + b(430, 270, 30) + b(410, 200, 16) + b(500, 220, 44) + b(560, 130, 58) + b(470, 120, 26) + b(620, 230, 30) + b(640, 60, 24) + b(540, 330, 18);
  return s + no(540, 180, 160, 18);
};

const N = { night: true };
const POSTERS = [
  row('flying', 91, ['KEEP YOUR FEET', 'ON THE GROUND'], N),
  row('dance', 92, ['SAVE YOUR ENERGY', 'FOR YOUR SHIFT']),
  row('sheep', 93, ["CAN'T SLEEP?", 'COUNT YOUR BLESSINGS'], { night: true, acc: C.cyan }),
  row('derby', 94, ['GAMBLING', 'IS ILLEGAL'], N),
  row('paint', 95, ['KEEP OUR', 'CITY CLEAN'], { accent: 'red' }),
  row('conga', 96, ['SINGLE FILE,', 'NO DANCING']),
  row('bubbles', 97, ['SOAP IS', 'FOR WASHING']),
];
module.exports = { ART, POSTERS };
