// The posters that hint at the nightmares (dream_<codeword>): maze, barrels, crumble, freeze, molasses.
// (The Watchers is in dreams.js.) Drawn by gen.js.
const { C, P, R, G, officer, citizen } = require('./lib.js');
const { E, L, T, rng, row, walker } = require('./dreamkit.js');

const ART = {};
const DARK = '#080d15';

// The Maze: the patrol knows every turn.
ART.dream_maze = () => {
  let s = R(0, 0, 720, 610, DARK) + R(0, 0, 720, 212, C.slate2) + E(360, 70, 300, 170, C.slate3, 'opacity=".5"');
  s += officer(360 - 132, -26, 2.2, { lens: C.red });
  const X0 = 60, Y0 = 232, W = 15, H = 9, S = 40;
  s += R(X0 - 22, Y0 - 22, W * S + 44, H * S + 44, '#05080d') + R(X0 - 22, Y0 - 22, W * S + 44, 8, C.slate2);
  // carve it
  const r = rng(11), seen = {}, open = {}, key = (x, y) => x + ',' + y;
  const stack = [[0, 4]]; seen[key(0, 4)] = true;
  while (stack.length) {
    const [x, y] = stack[stack.length - 1];
    const nb = [[1, 0], [-1, 0], [0, 1], [0, -1]].map(([dx, dy]) => [x + dx, y + dy]).filter(([a, b]) => a >= 0 && b >= 0 && a < W && b < H && !seen[key(a, b)]);
    if (!nb.length) { stack.pop(); continue; }
    const [a, b] = nb[Math.floor(r() * nb.length)];
    open[key(x, y) + '>' + key(a, b)] = open[key(a, b) + '>' + key(x, y)] = true;
    seen[key(a, b)] = true; stack.push([a, b]);
  }
  let walls = '';
  for (let x = 0; x < W; x++) for (let y = 0; y < H; y++) {
    if (x < W - 1 && !open[key(x, y) + '>' + key(x + 1, y)]) walls += `M${X0 + (x + 1) * S},${Y0 + y * S} v${S} `;
    if (y < H - 1 && !open[key(x, y) + '>' + key(x, y + 1)]) walls += `M${X0 + x * S},${Y0 + (y + 1) * S} h${S} `;
  }
  walls += `M${X0},${Y0} h${W * S} M${X0},${Y0 + H * S} h${W * S} M${X0},${Y0} v${4 * S} M${X0},${Y0 + 5 * S} v${4 * S} M${X0 + W * S},${Y0} v${4 * S} M${X0 + W * S},${Y0 + 5 * S} v${4 * S}`;
  // the route they were given, from the way in to the way out
  const prev = {}, q = [[0, 4]]; prev[key(0, 4)] = null;
  while (q.length) {
    const [x, y] = q.shift();
    for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
      const a = x + dx, b = y + dy;
      if (open[key(x, y) + '>' + key(a, b)] && !(key(a, b) in prev)) { prev[key(a, b)] = [x, y]; q.push([a, b]); }
    }
  }
  const route = []; let c = [W - 1, 4];
  while (c) { route.push(c); c = prev[key(c[0], c[1])]; }
  const mid = ([x, y]) => `${X0 + x * S + S / 2},${Y0 + y * S + S / 2}`;
  s += L(`M${X0 - 20},${Y0 + 4.5 * S} L` + route.reverse().map(mid).join(' L') + ` L${X0 + W * S + 20},${Y0 + 4.5 * S}`, C.cyanD, 5, 'stroke-dasharray="2 12" opacity=".9"');
  s += L(walls, C.steel, 6, 'stroke-linecap="square"');
  // the one who left it, and the patrol
  const on = {}; route.forEach(p => { on[key(p[0], p[1])] = true; });
  const off = []; for (let x = 2; x < W - 2; x++) for (let y = 0; y < H; y++) if (!on[key(x, y)]) off.push([x, y]);
  const lost = off[Math.floor(r() * off.length)];
  const [lx, ly] = mid(lost).split(',').map(Number);
  s += `<circle cx="${lx}" cy="${ly}" r="13" fill="${C.paper}" opacity=".25"/><circle cx="${lx}" cy="${ly}" r="7.5" fill="${C.paper}"/>`;
  for (let i = 0; i < 5; i++) {
    const p = off[Math.floor(r() * off.length)];
    if (p === lost) continue;
    const [px, py] = mid(p).split(',').map(Number);
    s += `<circle cx="${px}" cy="${py}" r="12" fill="#141c26"/><circle cx="${px - 4.5}" cy="${py - 1}" r="3" fill="${C.red}"/><circle cx="${px + 4.5}" cy="${py - 1}" r="3" fill="${C.red}"/>`;
  }
  return s;
};

// The Barrels: they are heavier than they look.
function barrel(x, y, rot, col, dk) {
  return G(`translate(${x},${y}) rotate(${rot})`, `<rect x="-36" y="-48" width="72" height="96" rx="9" fill="${col}"/>` + R(-38, -31, 76, 8, dk) + R(-38, 23, 76, 8, dk) + R(-25, -48, 10, 96, '#fff', 'opacity=".18"') + R(14, -48, 22, 96, '#000', 'opacity=".2"'));
}
ART.dream_barrels = () => {
  let s = R(0, 0, 720, 610, '#101a27');
  for (let x = 0; x < 720; x += 90) s += R(x, 0, 44, 560, '#131f2e');
  s += R(0, 556, 720, 54, C.slate) + R(0, 556, 720, 6, C.slate2);
  s += P('M70,470 L128,360 L186,470Z', C.red) + P('M92,456 L128,388 L164,456Z', C.paper) + T(128, 452, '!', 60, C.red);
  s += R(120, 470, 16, 90, C.slate3);
  const steel = [C.steel, '#4c5a66'], red = [C.red, C.redD], blue = [C.blue2, C.blueD];
  s += E(360, 560, 190, 14, '#05080d', 'opacity=".6"');
  [[262, 508, 0, steel], [340, 508, 0, red], [418, 508, 0, blue], [304, 410, -2, blue], [382, 410, 3, steel], [350, 312, 7, red], [368, 216, 15, steel]].forEach(([x, y, a, c]) => { s += barrel(x, y, a, c[0], c[1]); });
  s += barrel(430, 116, 38, red[0], red[1]);
  s += L('M360,80 Q400,40 452,48', C.paper, 4, 'opacity=".5"') + L('M344,112 Q372,84 400,78', C.paper, 4, 'opacity=".35"') + L('M486,70 Q516,96 520,132', C.paper, 4, 'opacity=".5"');
  // where it will land
  s += E(590, 562, 78, 12, '#05080d', 'opacity=".75"');
  s += G('translate(652,0) scale(-1,1)', walker(0, 556 - 258 * 0.92, 0.92, { leg: '#4a6077', hat: '#4a6077' }));
  s += L('M520,120 Q590,190 592,300', C.red, 5, 'stroke-dasharray="10 12" opacity=".8"') + P('M580,296 L604,296 L592,320Z', C.red, 'opacity=".8"');
  return s;
};

// The Crumbling Floor: not every floor will hold you.
ART.dream_crumble = () => {
  let s = R(0, 0, 720, 300, C.slate2);
  for (let x = 40; x < 720; x += 120) s += R(x, 0, 3, 300, C.slate);
  s += R(0, 96, 720, 3, C.slate) + R(0, 198, 720, 3, C.slate);
  // the lamp
  s += R(382, 0, 4, 60, C.steel) + P('M356,60 L412,60 L424,84 L344,84Z', C.steel) + P('M344,84 L424,84 L560,300 L208,300Z', C.warm, 'opacity=".16"') + E(384, 86, 22, 6, C.warm);
  // below
  s += R(0, 300, 720, 310, '#04070b') + E(384, 640, 300, 130, C.red, 'opacity=".28"') + E(384, 640, 170, 70, C.red, 'opacity=".4"');
  // the floor, and where it gave
  s += P('M0,300 L262,300 L280,312 L268,326 L290,342 L0,342Z', C.steel2) + P('M0,342 L290,342 L276,356 L0,356Z', C.slate3);
  s += P('M720,300 L486,300 L472,316 L492,330 L470,342 L720,342Z', C.steel2) + P('M720,342 L470,342 L482,356 L720,356Z', C.slate3);
  s += L('M262,300 L236,312 L214,304 L190,320 L170,342', C.ink, 3.5) + L('M214,304 L206,330', C.ink, 3) + L('M236,312 L250,340', C.ink, 3) + L('M486,300 L520,318 L548,342', C.ink, 3.5) + L('M150,300 L138,322 L110,342', C.ink, 3);
  [[330, 380, 44, 22, 14], [420, 430, 34, 20, -24], [366, 486, 26, 16, 38], [440, 540, 20, 12, -10], [318, 560, 16, 10, 22], [394, 350, 20, 12, -30]].forEach(([x, y, w, h, a]) => {
    s += G(`translate(${x},${y}) rotate(${a})`, P(`M${-w / 2},${-h / 2} L${w / 2},${-h / 2 + 4} L${w / 2 - 6},${h / 2} L${-w / 2 + 4},${h / 2 - 3}Z`, C.steel2) + P(`M${-w / 2 + 4},${h / 2 - 3} L${w / 2 - 6},${h / 2} L${w / 2 - 8},${h / 2 + 6} L${-w / 2 + 6},${h / 2 + 3}Z`, C.slate3));
    s += R(x - 1.5, y - h - 34, 3, 26, C.paper, 'opacity=".2"');
  });
  s += walker(128, 300 - 258 * 0.92, 0.92);
  s += E(170, 302, 60, 5, C.ink, 'opacity=".4"');
  return s;
};

// The Freeze: when a unit says freeze.
function iced(x, y, s, o) {
  const w = 80 * s, h = 230 * s;
  const d = `M${x - 14},${y + h + 4} L${x - 20},${y + h * 0.3} L${x + w * 0.2},${y - 22} L${x + w * 0.8},${y - 26} L${x + w + 22},${y + h * 0.28} L${x + w + 14},${y + h + 4}Z`;
  return citizen(x, y, s, o) + P(d, C.cyan, 'opacity=".3"') + L(d, C.cyan, 3.5) + L(`M${x - 4},${y + h * 0.36} L${x + w * 0.26},${y - 6}`, '#fff', 5, 'opacity=".55"') + L(`M${x + 6},${y + h * 0.62} L${x + 12},${y + h * 0.46}`, '#fff', 4, 'opacity=".4"');
}
ART.dream_freeze = () => {
  let s = R(0, 0, 720, 610, C.slate2) + R(0, 540, 720, 70, C.slate) + R(0, 540, 720, 4, C.slate3);
  const r = rng(9);
  for (let i = 0; i < 80; i++) s += `<circle cx="${(r() * 720).toFixed(0)}" cy="${(r() * 540).toFixed(0)}" r="${(1 + r() * 2).toFixed(1)}" fill="${C.cyan}" opacity="${(0.2 + r() * 0.5).toFixed(2)}"/>`;
  s += iced(402, 300, 1.02, { tone: 2 }) + iced(604, 304, 1.0, { tone: 1, scarf: true }) + iced(498, 268, 1.16, { tone: 0, case: true });
  s += E(130, 560, 90, 10, C.ink, 'opacity=".4"') + officer(60, 60, 1.05, { lens: C.cyan, band: C.cyan, point: true });
  s += L('M350,196 L376,196', C.cyan, 5) + L('M346,172 L368,160', C.cyan, 5) + L('M346,220 L368,232', C.cyan, 5);
  return s;
};

// Running in Molasses: you will not get far.
ART.dream_molasses = () => {
  const mo = '#3b2110', moL = '#7a4a22';
  let s = R(0, 0, 720, 610, DARK);
  s += P('M0,0 L250,0 L250,170 L0,470Z', '#0f1722') + P('M720,0 L470,0 L470,170 L720,470Z', '#0f1722');
  for (let i = 0; i < 5; i++) s += R(20 + i * 42, 50 + i * 22, 20, 30, i % 2 ? C.warm : '#1a2636', 'opacity=".7"') + R(680 - i * 42, 50 + i * 22, 20, 30, i % 3 ? '#1a2636' : C.warm, 'opacity=".7"');
  s += P('M250,170 L470,170 L720,610 L0,610Z', C.slate2) + P('M354,170 L366,170 L384,610 L336,610Z', C.slate3, 'opacity=".6"');
  // the unit, in no hurry
  s += E(530, 372, 44, 7, C.ink, 'opacity=".5"') + officer(500, 128, 0.5, { lens: C.red, baton: true });
  // the runner, and what has him by the legs
  s += G('translate(214,96) scale(1.5) rotate(13 50 258)', walker(0, 0, 1, { nolegs: true }) +
    P('M28,150 L54,150 Q52,205 34,264 L-14,264 Q18,214 28,150Z', mo) + P('M50,150 L76,150 Q86,208 118,264 L58,264 Q62,204 50,150Z', mo) +
    L('M38,160 Q38,210 14,256', moL, 4) + L('M64,160 Q72,212 96,256', moL, 4));
  s += P('M0,610 L0,486 Q90,452 180,474 Q270,500 360,470 Q470,440 560,476 Q650,500 720,470 L720,610Z', mo);
  s += L('M60,520 Q150,500 240,524', moL, 6) + L('M470,530 Q560,506 650,526', moL, 6) + L('M250,570 Q340,556 430,574', moL, 5);
  s += L('M196,480 Q190,430 222,396', mo, 10) + L('M470,470 Q470,420 430,392', mo, 9);
  return s;
};

const N = { night: true };
const POSTERS = [
  row('maze', 61, ['THE PATROL KNOWS', 'EVERY TURN'], N),
  row('barrels', 62, ['DO NOT', 'STACK BARRELS'], N),
  row('crumble', 63, ['WATCH', 'YOUR STEP'], N),
  row('freeze', 64, ['WHEN A UNIT SAYS', 'FREEZE, YOU FREEZE'], { accent: 'cyan' }),
  row('molasses', 65, ['RUNNING', 'IS FORBIDDEN'], N),
];

module.exports = { ART, POSTERS };
