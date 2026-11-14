// Draws the six civil notice posters and renders them to PNG (768 x 1024).
// Run: node gen.js OUTDIR
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const { C, P, R, G, rays, emblem, head, childHead, worker, officer, citizen, reader, adminBust } = require('./lib.js');
const more = require('./art2.js');
const res = require('./art3.js');
const dreams = require('./dreams.js');

const ART = {};

ART.dispenser = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(300, 330, 28, 900, C.slate2, 180, 360);
  // the raised hand of authority
  s += G('translate(318,8) scale(1.75)', [
    R(20, 26, 13, 70, C.slate3), R(36, 10, 13, 86, C.slate3), R(52, 14, 13, 82, C.slate3), R(68, 30, 12, 66, C.slate3),
    P('M20,84 L80,84 L82,190 L24,190Z', C.slate3), P('M20,96 L2,72 L10,60 L26,80Z', C.slate3),
  ].join(''));
  // the factory skyline
  s += P('M0,620 L0,300 L40,300 L40,210 L58,210 L58,300 L90,300 L120,268 L120,300 L150,268 L150,300 L180,268 L180,300 L230,300 L230,180 L252,180 L252,300 L300,300 L300,250 L360,250 L360,300 L400,300 L400,225 L418,225 L418,300 L450,280 L450,300 L480,280 L480,300 L520,300 L520,620Z', C.ink);
  s += P('M40,210 L58,210 L20,150 L-10,150Z', C.slate3, 'opacity=".5"') + P('M230,180 L252,180 L214,110 L180,110Z', C.slate3, 'opacity=".5"');
  // the queue, farthest first
  s += worker(-62, 262, 0.68, { tone: 3 }) + worker(8, 236, 0.82, { tone: 2 }) + worker(98, 206, 1.0, { tone: 1 });
  // the dispenser
  s += P('M488,112 L520,88 L520,620 L488,620Z', C.steel);
  s += R(520, 88, 200, 532, C.steel2);
  s += P('M508,66 L720,66 L720,88 L520,88Z', C.slate3);
  s += P('M610,88 L654,88 L566,620 L522,620Z', '#fff', 'opacity=".28"') + P('M668,88 L682,88 L594,620 L580,620Z', '#fff', 'opacity=".22"');
  s += R(546, 118, 156, 84, C.ink) + emblem(560, 132, 1.2, C.steel2) + R(622, 136, 64, 8, C.steel) + R(622, 152, 44, 8, C.steel) + `<circle cx="680" cy="182" r="7" fill="${C.red}"/>`;
  s += R(546, 340, 156, 62, C.slate) + R(560, 366, 120, 12, C.ink) + R(560, 348, 50, 6, C.red);
  s += R(546, 436, 156, 120, C.ink) + R(546, 436, 156, 10, C.slate3);
  s += P('M474,524 L612,484 L624,536 L486,578Z', C.steel) + P('M474,524 L612,484 L614,494 L476,534Z', C.paper) + P('M520,530 L560,518 L566,544 L526,556Z', C.slate);
  s += P('M470,584 L720,560 L720,580 L470,604Z', C.slate3);
  // the worker handing in his card
  s += worker(215, 170, 1.25, { arm: 'out', card: true });
  return s;
};

ART.commissary = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(140, 140, 24, 900, C.slate2, -20, 100);
  // shelves
  for (let r = 0; r < 3; r++) {
    const y = 110 + r * 88;
    s += R(262, y, 458, 10, C.ink) + R(262, y + 10, 458, 5, C.slate3);
    for (let i = 0; i < 9; i++) {
      const x = 276 + i * 50;
      if (r === 0) s += R(x, y - 50, 36, 50, C.steel2) + R(x, y - 36, 36, 14, C.slate3) + R(x, y - 50, 36, 5, C.steel);
      if (r === 1) s += P(`M${x + 4},${y} L${x + 4},${y - 44} L${x + 12},${y - 56} L${x + 12},${y - 66} L${x + 24},${y - 66} L${x + 24},${y - 56} L${x + 32},${y - 44} L${x + 32},${y}Z`, C.cyan) + R(x + 4, y - 34, 28, 16, C.paper) + R(x + 11, y - 70, 14, 6, C.ink);
      if (r === 2) s += R(x + 2, y - 34, 12, 34, C.paper) + R(x + 2, y - 40, 12, 7, C.ink) + R(x + 2, y - 18, 12, 6, C.cyan) + R(x + 22, y - 34, 12, 34, C.paper) + R(x + 22, y - 40, 12, 7, C.ink) + R(x + 22, y - 18, 12, 6, C.cyan);
    }
  }
  // the Administrator's portrait
  s += R(44, 30, 186, 230, C.ink) + R(52, 38, 170, 214, C.paper) + R(60, 46, 154, 198, C.slate3);
  s += '<svg x="60" y="46" width="154" height="198" viewBox="8 16 154 198">' + adminBust({}) + '</svg>';
  s += R(44, 268, 186, 6, C.cyan);
  // the hatch
  s += R(488, 344, 232, 206, C.steel) + R(502, 358, 218, 192, C.ink);
  for (let i = 0; i < 4; i++) s += R(502, 358 + i * 9, 218, 5, C.slate3);
  s += R(502, 398, 218, 6, C.slate) + R(560, 368, 30, 30, C.slate) + R(600, 368, 30, 30, C.slate) + R(640, 368, 30, 30, C.slate);
  // the gloved hand and the parcel
  s += P('M520,440 L720,424 L720,486 L522,478Z', C.slate2) + P('M520,440 L540,438 L542,478 L522,478Z', C.steel);
  s += P('M474,440 L522,438 L524,480 L486,486 L470,470Z', C.ink);
  s += R(392, 408, 92, 84, C.paper) + R(392, 444, 92, 7, C.slate3) + R(434, 408, 7, 84, C.slate3) + R(400, 416, 28, 20, C.cyan);
  s += P('M470,470 L486,486 L466,496 L456,484Z', C.ink);
  // the counter
  s += R(0, 548, 720, 14, C.steel2) + R(0, 562, 720, 58, C.slate2) + R(0, 562, 720, 6, C.ink);
  for (let i = 0; i < 5; i++) s += R(520 + i * 40, 504, 30, 44, C.steel2) + R(520 + i * 40, 518, 30, 12, C.cyanD);
  // the citizen
  s += worker(118, 270, 1.12, { arm: 'out', cap: false, smile: true });
  s += R(0, 548, 250, 14, C.steel2) + R(0, 562, 250, 58, C.slate2) + R(0, 562, 250, 6, C.ink);
  return s;
};

ART.intake = () => {
  let s = R(0, 0, 720, 620, C.ink);
  s += R(0, 0, 720, 500, C.slate);
  // the station roof
  for (let i = 0; i < 9; i++) s += P(`M${i * 90 - 40},0 L${i * 90 - 22},0 L${i * 90 + 50},70 L${i * 90 + 32},70Z`, C.slate2);
  s += R(0, 66, 720, 12, C.ink);
  // the platform and the pool of light
  s += R(0, 500, 720, 120, C.slate2) + R(0, 500, 720, 6, C.steel);
  s += P('M366,40 L384,40 L560,560 L190,560Z', C.paper, 'opacity=".17"');
  s += `<ellipse cx="375" cy="552" rx="190" ry="40" fill="${C.paper}"/>`;
  s += R(350, 22, 50, 22, C.ink) + R(360, 40, 30, 8, C.paper);
  // the train
  const yT = x => 130 + 0.24 * x, yB = x => 566 - 0.26 * x;
  s += P(`M0,${yT(0)} L270,${yT(270)} L270,${yB(270)} L0,${yB(0)}Z`, C.slate3);
  s += P(`M0,${yT(0)} L270,${yT(270)} L270,${yT(270) + 16} L0,${yT(0) + 24}Z`, C.ink);
  s += P(`M0,${yB(0) - 40} L270,${yB(270) - 26} L270,${yB(270)} L0,${yB(0)}Z`, C.ink);
  const win = (x0, x1, a, b, f) => { const h0 = yB(x0) - yT(x0), h1 = yB(x1) - yT(x1); return P(`M${x0},${yT(x0) + a * h0} L${x1},${yT(x1) + a * h1} L${x1},${yT(x1) + b * h1} L${x0},${yT(x0) + b * h0}Z`, f); };
  s += win(14, 62, 0.2, 0.46, C.warm) + win(78, 122, 0.2, 0.46, C.warm) + win(138, 178, 0.2, 0.46, C.warm);
  s += win(0, 196, 0.56, 0.6, C.red);
  s += win(204, 252, 0.16, 0.9, C.paper);
  // the arrivals
  s += citizen(232, 330, 0.95, { tone: 1, case: true }) + citizen(300, 312, 1.02, { scarf: true, case: true }) + citizen(384, 322, 1.0, { tone: 0, case: true });
  // the officer and the registration desk
  s += R(590, 318, 130, 44, C.paper) + R(594, 322, 122, 36, C.ink);
  s += `<text x="655" y="346" text-anchor="middle" font-family="Inter Display" font-weight="900" font-size="12.5" fill="${C.paper}" letter-spacing="0.3">REGISTRATION</text>`;
  s += R(600, 362, 6, 60, C.ink) + R(704, 362, 6, 60, C.ink);
  s += P('M610,470 L650,404 L720,404 L720,470Z', C.paper, 'opacity=".22"');
  s += R(590, 462, 130, 12, C.steel2) + R(596, 474, 124, 80, C.slate3) + R(596, 474, 124, 6, C.ink) + emblem(642, 492, 0.9, C.steel2);
  s += R(676, 440, 36, 22, C.paper) + R(676, 446, 36, 2, C.steel) + R(676, 452, 36, 2, C.steel);
  s += P('M640,404 L666,404 L672,416 L634,416Z', C.ink) + R(650, 416, 5, 46, C.ink);
  s += officer(452, 262, 0.62, { point: true });
  // the hand holding up papers
  s += P('M-10,620 L0,566 L70,540 L170,620Z', C.blue) + P('M0,566 L70,540 L82,556 L8,584Z', C.blueD);
  s += G('rotate(-9 150 480)', [
    R(34, 384, 262, 196, C.ink), R(40, 390, 250, 184, C.paper),
    R(54, 404, 82, 104, C.slate3), P('M70,508 L74,478 L86,470 L104,470 L116,478 L120,508Z', C.ink), P('M84,436 L106,436 L110,452 L104,468 L86,468 L80,452Z', C.paper),
    R(150, 406, 124, 12, C.ink), R(150, 428, 96, 7, C.steel), R(150, 444, 110, 7, C.steel), R(150, 460, 80, 7, C.steel),
    R(54, 522, 120, 7, C.steel), R(54, 538, 150, 7, C.steel), R(54, 554, 90, 7, C.steel),
    `<g transform="rotate(14 222 512)"><circle cx="222" cy="512" r="42" fill="none" stroke="${C.red}" stroke-width="6"/><circle cx="222" cy="512" r="32" fill="none" stroke="${C.red}" stroke-width="2.5"/>${emblem(207, 492, 0.75, C.red)}<rect x="170" y="532" width="104" height="5" fill="${C.red}"/></g>`,
  ].join(''));
  s += P('M40,620 L34,566 L60,520 L104,498 L128,512 L112,548 L122,620Z', C.paper) + P('M40,620 L34,566 L60,520 L70,524 L56,570 L62,620Z', C.steel) + P('M96,506 L120,514 L114,528 L92,520Z', C.steel2);
  return s;
};

ART.water = () => {
  const g1 = '#6a7153', g2 = '#565c44', g3 = '#454a38', g4 = '#343829';
  let s = '<svg x="0" y="0" width="357" height="620" viewBox="0 0 357 620">' + R(0, 0, 357, 620, g1);
  s += rays(180, 620, 16, 900, g2, 200, 340);
  // a pipe dripping into the canal
  s += R(0, 96, 150, 46, g4) + R(140, 88, 18, 62, g3) + P('M158,104 L176,104 L182,150 L152,150Z', g4, 'opacity=".0"');
  s += P('M150,142 C160,200 130,240 150,300 L132,300 C118,240 142,200 136,142Z', g3);
  // the canal water
  const wave = (y, a, f) => P(`M0,${y} C60,${y - a} 120,${y + a} 180,${y} S300,${y - a} 360,${y} L360,620 L0,620Z`, f);
  s += wave(290, 16, g2) + wave(370, 14, g3) + wave(470, 16, g4);
  // the cracked bottle
  s += G('rotate(-24 230 330)', [
    P('M196,250 L196,236 L214,236 L214,250 L232,274 L232,400 L178,400 L178,274Z', '#b7b89e'),
    P('M178,330 L232,330 L232,400 L178,400Z', g2),
    `<path d="M214,262 L200,290 L216,312 L198,340 L212,366 L196,400" stroke="${C.ink}" stroke-width="3.5" fill="none"/><path d="M216,312 L232,324" stroke="${C.ink}" stroke-width="3" fill="none"/>`,
    R(194, 228, 22, 9, g4),
  ].join(''));
  // the parasites
  const worm = (d, w) => `<path d="${d}" stroke="${C.ink}" stroke-width="${w}" stroke-linecap="round" fill="none"/>`;
  s += worm('M40,420 C60,400 70,440 92,420 S120,400 138,424', 9) + worm('M190,470 C210,490 226,450 246,470 S280,492 300,468', 8);
  s += worm('M70,520 C84,540 104,506 122,524 S150,548 168,522', 10) + worm('M230,556 C246,540 258,574 278,556 S306,540 322,560', 8);
  s += worm('M30,330 C44,318 56,342 72,328', 6) + worm('M270,392 C284,404 296,380 312,392', 6) + worm('M150,590 C166,578 178,602 196,588', 7);
  // the clean side
  s += '</svg><svg x="363" y="0" width="357" height="620" viewBox="363 0 357 620">' + R(363, 0, 357, 620, C.slate);
  s += rays(540, 250, 20, 900, C.slate2, 0, 360);
  s += R(590, 0, 40, 96, C.steel2) + R(584, 86, 52, 16, C.steel) + P('M600,0 L610,0 L610,96 L600,96Z', '#fff', 'opacity=".4"');
  s += P('M470,102 L636,102 L636,150 L520,150 L520,188 L470,188Z', C.steel2) + P('M470,102 L636,102 L636,114 L470,114Z', '#fff', 'opacity=".35"');
  s += R(462, 184, 66, 14, C.steel) + R(566, 72, 96, 12, C.ink) + R(606, 60, 16, 14, C.ink);
  s += R(482, 198, 26, 216, C.cyan) + R(488, 198, 6, 216, '#fff', 'opacity=".5"');
  // the child and the cup
  s += G('translate(712,318) scale(-1.3,1.3)', [
    P('M-20,170 L16,120 L74,120 L104,146 L110,260 L-26,260Z', C.blue), P('M16,120 L74,120 L104,146 L60,138Z', C.blue2),
    P('M60,146 L100,150 L176,112 L170,84 L96,118Z', C.blue2), P('M170,84 L176,112 L190,106 L184,80Z', C.blueD),
    childHead({}),
    P('M184,80 L190,106 L212,100 L214,74 L200,68Z', C.paper),
  ].join(''));
  s += P('M452,392 L538,392 L528,468 L462,468Z', C.paper) + P('M452,392 L538,392 L536,406 L454,406Z', C.cyan) + P('M510,406 L536,406 L528,468 L504,468Z', C.steel2);
  s += P('M430,410 L454,404 L458,424 L436,432Z', C.paper);
  s += '</svg>' + R(354, 0, 12, 620, C.paper) + R(357, 0, 6, 620, C.red);
  return s;
};

ART.law = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(350, 250, 32, 1000, C.slate2, 0, 360);
  // the tablet of laws, seen from below
  s += P('M470,24 L506,44 L604,620 L560,620Z', C.steel);
  s += P('M226,24 L470,24 L560,620 L130,620Z', C.paper);
  s += P('M226,24 L470,24 L476,62 L220,62Z', C.red);
  s += emblem(334, 30, 0.62, C.paper);
  const lx = (y, f) => 226 + (130 - 226) * ((y - 24) / 596) + f * ((470 + (560 - 470) * ((y - 24) / 596)) - (226 + (130 - 226) * ((y - 24) / 596)));
  let y = 84, h = 9;
  for (let a = 0; a < 7; a++) {
    s += P(`M${lx(y, 0.08)},${y} L${lx(y, 0.16)},${y} L${lx(y + h * 1.6, 0.16)},${y + h * 1.6} L${lx(y + h * 1.6, 0.08)},${y + h * 1.6}Z`, C.red);
    s += P(`M${lx(y, 0.2)},${y} L${lx(y, 0.92)},${y} L${lx(y + h, 0.92)},${y + h} L${lx(y + h, 0.2)},${y + h}Z`, C.ink);
    y += h * 1.9;
    for (let l = 0; l < 2; l++) { const e = l ? 0.7 : 0.92; s += P(`M${lx(y, 0.2)},${y} L${lx(y, e)},${y} L${lx(y + h * 0.6, e)},${y + h * 0.6} L${lx(y + h * 0.6, 0.2)},${y + h * 0.6}Z`, C.steel); y += h * 1.5; }
    y += h * 1.4; h *= 1.17;
  }
  // the officer, on a step beside it
  s += P('M572,560 L720,560 L720,620 L560,620Z', C.ink) + R(572, 552, 148, 10, C.slate3);
  s += officer(600, 232, 0.68, { baton: true });
  // the citizens, reading
  const back = [[150, 498, 0.62, 3, 1], [214, 506, 0.6, 3, 0], [280, 500, 0.62, 2, 1], [346, 506, 0.6, 3, 0], [410, 500, 0.62, 2, 1], [474, 506, 0.6, 3, 0], [86, 508, 0.6, 2, 0]];
  for (const b of back) s += reader(...b);
  const front = [[-14, 536, 0.86, 1, 1], [64, 544, 0.84, 0, 0], [144, 536, 0.88, 1, 1], [226, 546, 0.84, 0, 1], [306, 538, 0.86, 1, 0], [386, 546, 0.84, 0, 1], [466, 538, 0.86, 1, 0], [540, 548, 0.8, 0, 1]];
  for (const b of front) s += reader(...b);
  return s;
};

ART.curfew = () => {
  let s = R(0, 0, 720, 620, C.night);
  // far blocks, dark and empty
  s += P('M0,620 L0,210 L120,210 L120,260 L200,260 L200,170 L300,170 L300,300 L380,300 L380,240 L440,240 L440,620Z', C.night2);
  for (let r = 0; r < 6; r++) for (let c = 0; c < 4; c++) { s += R(12 + c * 26, 230 + r * 40, 12, 18, '#1f3045'); s += R(210 + c * 22, 190 + r * 40, 10, 18, '#1f3045'); }
  // the searchlight
  s += P('M-20,-20 L60,-20 L420,560 L100,560Z', C.cyan, 'opacity=".2"');
  s += P('M-20,-20 L20,-20 L330,560 L190,560Z', C.cyan, 'opacity=".22"');
  // the street
  s += R(0, 548, 720, 72, '#1a2838') + R(0, 548, 720, 4, '#2b3f55');
  s += `<ellipse cx="258" cy="572" rx="176" ry="30" fill="${C.cyan}" opacity=".55"/><ellipse cx="258" cy="572" rx="120" ry="19" fill="#dff3f4" opacity=".7"/>`;
  // the housing block
  s += P('M430,100 L720,100 L720,620 L430,620Z', C.slate) + P('M414,116 L430,100 L430,620 L414,620Z', '#16212e') + R(430, 100, 290, 14, C.slate2);
  for (let r = 0; r < 4; r++) for (let c = 0; c < 5; c++) {
    const x = 452 + c * 54, y = 138 + r * 78, lit = !((r === 1 && c === 3) || (r === 3 && c === 0));
    s += R(x - 4, y - 4, 42, 60, '#16212e') + R(x, y, 34, 52, lit ? C.warm : '#1f3045');
    if (lit) s += R(x + 15, y, 4, 52, C.slate) + R(x, y + 24, 34, 4, C.slate) + R(x, y, 34, 52, '#c98f3a', 'opacity=".18"');
  }
  // the lit door, mother and child
  s += P('M540,620 L560,470 L660,470 L690,620Z', C.warm, 'opacity=".25"');
  s += R(552, 444, 116, 132, '#16212e') + R(562, 454, 96, 122, C.warm) + R(562, 454, 96, 122, '#c98f3a', 'opacity=".15"');
  s += R(540, 576, 140, 10, C.slate3) + R(528, 586, 164, 10, C.slate2);
  s += P('M604,490 L620,490 L626,504 L622,520 L636,530 L644,576 L584,576 L590,530 L602,520 L598,504Z', C.ink);
  s += P('M592,534 L604,530 L582,560 L574,552Z', C.ink);
  s += P('M566,528 L580,528 L584,540 L580,550 L590,558 L592,576 L556,576 L558,558 L566,550 L562,540Z', C.ink);
  // the citizen, walking home
  s += P('M250,572 L262,572 L120,606 L84,602Z', C.ink, 'opacity=".55"');
  s += G('translate(206,334) scale(0.94)', [
    P('M50,148 L74,148 L90,246 L72,250 L58,176Z', C.ink), P('M72,250 L90,246 L104,252 L104,258 L72,258Z', C.ink),
    P('M30,148 L54,148 L46,200 L30,248 L12,244 L28,196Z', C.ink), P('M12,244 L30,248 L28,258 L2,256Z', C.ink),
    P('M32,46 L68,46 L80,156 L24,156Z', C.blueD), P('M52,46 L68,46 L80,156 L60,156Z', C.blue),
    P('M62,58 L74,62 L86,122 L76,126Z', C.blue), P('M34,58 L24,62 L18,120 L28,122Z', C.ink),
    P('M40,8 L62,8 L68,22 L66,36 L58,46 L42,46 L36,34 L34,20Z', C.steel2), P('M30,20 L38,2 L64,2 L72,18 L80,22 L80,26 L30,24Z', C.ink),
  ].join(''));
  // the scanner
  s += P('M352,86 L372,86 L420,548 L300,548Z', C.cyan, 'opacity=".0"');
  s += G('translate(360,74)', [
    P('M-70,0 L-28,-24 L30,-20 L72,0 L30,18 L-28,24Z', C.steel), P('M-70,0 L-28,-24 L30,-20 L72,0Z', C.steel2),
    P('M-28,-24 L-44,-44 L-18,-38 L4,-22Z', C.slate3), P('M30,18 L52,36 L20,34 L0,22Z', C.slate3),
    `<circle cx="0" cy="0" r="30" fill="${C.cyan}" opacity=".18"/><circle cx="0" cy="0" r="19" fill="${C.ink}"/><circle cx="0" cy="0" r="12" fill="${C.cyan}"/><circle cx="0" cy="0" r="5" fill="#eafcff"/>`,
  ].join(''));
  return s;
};

const POSTERS = [
  { id: 'dispenser', n: 1, accent: 'red', head: [['LABOR EARNS', 100], ['RATIONS', 150]],
    small: ['One ration card for each ration.', 'One card for each completed Union shift.', 'No card, no ration.'] },
  { id: 'commissary', n: 2, accent: 'cyan', head: [['THE COMMISSARY SERVES', 62], ['THE COMPLIANT', 104]],
    small: ['Food, water, medicine and tablets, for credits.', 'Credits are earned by work.'] },
  { id: 'intake', n: 3, accent: 'red', head: [['ALL ARRIVALS', 100], ['MUST REGISTER', 94]],
    small: ['Unregistered persons receive no rations,', 'no work and no housing.', 'Carry your papers at all times.'] },
  { id: 'water', n: 4, accent: 'cyan', head: [['UNTREATED WATER', 84], ['CARRIES PARASITES', 76]],
    small: ['Drink only from approved taps and machines.', 'Antiparasitic tablets are available', 'at the Commissary.'] },
  { id: 'law', n: 5, accent: 'red', head: [['KNOW THE LAW', 124]],
    small: ['Ignorance of the law is no defence.', 'The city’s laws are posted here.', 'Comply.'] },
  { id: 'curfew', n: 6, accent: 'cyan', head: [['CURFEW', 150], ['IS ABSOLUTE', 108]],
    small: ['At the two-minute warning,', 'return to your housing block.', 'Do not run in the presence of Civil Protection.'] },
];

Object.assign(ART, more.ART);
POSTERS.push(...more.POSTERS);
// the posters that hint at dreams (dream_<codeword>; never painted over one by one: dream_x is for all)
Object.assign(ART, dreams.ART);
POSTERS.push(...dreams.POSTERS);
for (const f of ['./dreams2.js', './dreams3.js', './dreams4.js', './slogan.js']) if (fs.existsSync(path.join(__dirname, f))) { const d = require(f); Object.assign(ART, d.ART); POSTERS.push(...d.POSTERS); }

function page(p, defaced) {
  const dark = p.accent === 'cyan';
  const acc = p.acc || (dark ? C.cyan : C.red), body = dark ? C.paper : C.ink, ground = p.ground || (dark ? (p.id === 'curfew' || p.dark ? C.night : C.slate) : C.paper);
  const T0 = 634, X0 = 50, TW = 668;
  let t = '', y = T0 + 20 + (p.headShift || 0);
  if (p.head.length === 1) y += 14;
  for (const [txt, size, col] of p.head) {
    const cap = size * 0.727;
    y += cap;
    t += `<text x="${X0}" y="${y.toFixed(1)}" font-family="Inter Display" font-weight="900" font-size="${size}" fill="${col || acc}" textLength="${TW}" lengthAdjust="spacingAndGlyphs">${txt}</text>`;
    y += 15;
  }
  const n = p.small.length, last = 944, step = n <= 2 ? 34 : 29.5, fs = n === 1 ? (p.small[0].length > 40 ? 24 : 28) : n === 2 ? 25 : 22.5;
  let sy = Math.max(y + 22, last - (n - 1) * step);
  if (n <= 2 || p.head.length === 1) sy = (y + 8 + last - (n - 1) * step) / 2 + 6;
  p.small.forEach((line, i) => {
    t += `<text x="384" y="${(sy + i * step).toFixed(1)}" text-anchor="middle" font-family="Inter" font-weight="${i === n - 1 && n === 3 ? 800 : 600}" font-size="${fs}" fill="${body}">${line}</text>`;
  });
  const footFill = dark ? C.ink : C.slate, footInk = C.paper;
  return `<!doctype html><html><head><meta charset="utf-8"><style>html,body{margin:0;background:${C.paper}}svg{display:block}</style></head><body>
<svg xmlns="http://www.w3.org/2000/svg" width="768" height="1024" viewBox="0 0 768 1024">
<defs>
  <clipPath id="art"><rect x="0" y="0" width="720" height="610"/></clipPath>
  <clipPath id="sheet"><rect x="0" y="0" width="768" height="1024"/></clipPath>
  <filter id="grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed="${p.n * 7}"/><feColorMatrix values="0 0 0 0 0.12  0 0 0 0 0.11  0 0 0 0 0.09  0 0 0 -1.6 1.05"/></filter>
  <filter id="fade" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.008 0.012" numOctaves="3" seed="${p.n * 11 + 2}"/><feColorMatrix values="0 0 0 0 0.87  0 0 0 0 0.84  0 0 0 0 0.76  0 0 0 2.6 -1.05"/></filter>
  <filter id="specks" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.5" numOctaves="1" seed="${p.n * 5 + 1}"/><feColorMatrix values="0 0 0 0 0.87  0 0 0 0 0.84  0 0 0 0 0.76  0 0 0 14 -10.2"/></filter>
  <filter id="dirt" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.02 0.035" numOctaves="4" seed="${p.n * 13 + 5}"/><feColorMatrix values="0 0 0 0 0.2  0 0 0 0 0.16  0 0 0 0 0.1  0 0 0 2.8 -1.5"/></filter>
  <filter id="rough" x="-10%" y="-10%" width="120%" height="120%"><feTurbulence type="fractalNoise" baseFrequency="0.03" numOctaves="3" seed="${p.n}"/><feDisplacementMap in="SourceGraphic" scale="16"/></filter>
  ${res.FILTERS}
  <filter id="soft"><feGaussianBlur stdDeviation="1.2"/></filter>
  <radialGradient id="edge" cx="50%" cy="50%" r="72%"><stop offset="62%" stop-color="#2a2015" stop-opacity="0"/><stop offset="100%" stop-color="#2a2015" stop-opacity=".5"/></radialGradient>
  <linearGradient id="foldH" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".46" stop-color="#fff" stop-opacity=".2"/><stop offset=".5" stop-color="#000" stop-opacity=".28"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
  <linearGradient id="foldV" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#fff" stop-opacity="0"/><stop offset=".46" stop-color="#fff" stop-opacity=".2"/><stop offset=".5" stop-color="#000" stop-opacity=".28"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient>
  <linearGradient id="lift" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#000" stop-opacity="0"/><stop offset=".55" stop-color="#000" stop-opacity=".0"/><stop offset=".8" stop-color="#000" stop-opacity=".3"/><stop offset=".86" stop-color="#fff" stop-opacity=".3"/><stop offset="1" stop-color="#fff" stop-opacity=".05"/></linearGradient>
</defs>
<rect width="768" height="1024" fill="${C.paper}"/>
<rect x="24" y="24" width="720" height="976" fill="${ground}"/>
<g transform="translate(24,24)" clip-path="url(#art)">${ART[p.id]()}</g>
<rect x="24" y="630" width="720" height="8" fill="${acc}"/>
${t}
<rect x="24" y="958" width="720" height="42" fill="${footFill}"/>
${emblem(40, 965, 0.62, acc)}
<text x="76" y="985.5" font-family="Inter" font-weight="800" font-size="15.5" fill="${footInk}" letter-spacing="2.6">OFFICE OF THE CITY ADMINISTRATOR</text>
<text x="728" y="985.5" text-anchor="end" font-family="Inter" font-weight="700" font-size="13" fill="${footInk}" letter-spacing="1.6" opacity=".8">${p.tag || 'CIVIL NOTICE ' + p.n}</text>
${defaced ? res.defaceLayer(p) : ''}
<g clip-path="url(#sheet)" style="pointer-events:none">
  <rect width="768" height="1024" filter="url(#fade)" opacity=".15"/>
  <rect width="768" height="1024" filter="url(#specks)" opacity=".8"/>
  <rect width="768" height="1024" filter="url(#dirt)" opacity=".22" style="mix-blend-mode:multiply"/>
  <g filter="url(#rough)" opacity=".5" style="mix-blend-mode:multiply">
    <ellipse cx="${p.n % 2 ? 150 : 610}" cy="${p.n % 2 ? 890 : 150}" rx="120" ry="92" fill="#6b5837" fill-opacity=".16" stroke="#57452a" stroke-opacity=".5" stroke-width="3"/>
    <ellipse cx="${p.n % 2 ? 650 : 120}" cy="${p.n % 2 ? 260 : 700}" rx="66" ry="54" fill="#6b5837" fill-opacity=".12" stroke="#57452a" stroke-opacity=".4" stroke-width="2.5"/>
  </g>
  <rect x="0" y="500" width="768" height="24" fill="url(#foldH)" opacity=".7"/>
  <rect x="372" y="0" width="24" height="1024" fill="url(#foldV)" opacity=".7"/>
  <rect x="${p.n % 2 ? 660 : 0}" y="930" width="108" height="94" fill="url(#lift)" ${p.n % 2 ? '' : 'transform="translate(108,0) scale(-1,1)"'} opacity=".8"/>
  <rect width="768" height="1024" fill="url(#edge)" style="mix-blend-mode:multiply"/>
  <rect width="768" height="1024" filter="url(#grain)" opacity=".5" style="mix-blend-mode:multiply"/>
</g>
</svg></body></html>`;
}

// a Resistance paste-up: its own paper, the same wear
function rebelPage(id, n) {
  const base = page({ id: 'curfew', n, accent: 'red', head: [], small: [] });
  const a = base.indexOf('<rect width="768" height="1024" fill='), b = base.indexOf('<g clip-path="url(#sheet)"');
  return base.slice(0, a) + res.rebelPage(id) + base.slice(b);
}

(async () => {
  const out = process.argv[2] || path.join(__dirname, 'out');
  fs.mkdirSync(out, { recursive: true });
  const only = process.argv[3];
  const browser = await chromium.launch();
  const pg = await browser.newPage({ viewport: { width: 768, height: 1024 }, deviceScaleFactor: 1 });
  const shot = async (html, name) => {
    if (only && only !== name) return;
    await pg.setContent(html);
    await pg.evaluate(() => document.fonts.ready);
    await pg.screenshot({ path: path.join(out, name + '.png') });
  };
  for (const p of POSTERS) {
    await shot(page(p), p.id);
    if (!p.tag) await shot(page(p, true), p.id + '_x'); // (painted over by the Resistance)
  }
  let n = 40;
  for (const id of Object.keys(res.REBEL)) await shot(rebelPage(id, n++), id);
  await browser.close();
})();
