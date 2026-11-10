// The eleven posters hung by hand (the Director of Propaganda's poster roll).
const { C, P, R, G, rays, emblem, head, worker, officer, citizen, reader, adminBust, scanner, palm, TONES } = require('./lib.js');

const ART = {};
const blockWindows = (x0, y0, cols, rows, dx, dy, w, h, lit) => { let s = ''; for (let r = 0; r < rows; r++) for (let c = 0; c < cols; c++) s += R(x0 + c * dx, y0 + r * dy, w, h, lit(r, c) ? C.warm : '#1f3045'); return s; };

ART.administrator = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(360, 250, 36, 1000, C.slate2, 0, 360);
  s += `<circle cx="360" cy="236" r="212" fill="${C.red}"/><circle cx="360" cy="236" r="194" fill="${C.redD}" opacity=".45"/>`;
  s += G('translate(139,22) scale(2.6)', adminBust({ pin: C.red }));
  // her city, small beneath her
  s += '<g transform="translate(0,62)">' + P('M0,620 L0,520 L50,520 L50,480 L110,480 L110,540 L160,540 L160,500 L230,500 L230,556 L300,556 L300,516 L352,516 L352,470 L400,470 L400,540 L470,540 L470,496 L540,496 L540,548 L600,548 L600,486 L660,486 L660,520 L720,520 L720,620Z', C.ink);
  s += blockWindows(58, 492, 3, 5, 16, 22, 8, 12, (r, c) => (r + c) % 3 !== 0) + blockWindows(170, 512, 3, 4, 18, 22, 8, 12, (r, c) => (r * 2 + c) % 3 !== 1);
  s += blockWindows(360, 482, 2, 6, 16, 22, 8, 12, (r, c) => (r + c) % 2 === 0) + blockWindows(480, 508, 3, 4, 18, 22, 8, 12, (r, c) => (r + c) % 3 !== 2) + blockWindows(610, 498, 3, 5, 15, 22, 8, 12, (r, c) => (r + 2 * c) % 3 !== 0) + '</g>';
  return s;
};

ART.loyalty = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(330, 70, 30, 1000, C.slate2, 20, 160);
  // a door that opens
  s += R(560, 190, 130, 330, C.ink) + R(572, 202, 106, 318, C.paper) + P('M572,202 L630,226 L630,520 L572,520Z', C.slate3) + P('M560,520 L690,520 L720,620 L470,620Z', C.paper, 'opacity=".2"');
  s += R(0, 520, 720, 100, C.slate2) + R(0, 520, 720, 5, C.steel);
  // the row, and the one who is noticed
  for (const [x, t] of [[30, 3], [130, 3], [416, 3]]) s += citizen(x, 300, 1.0, { tone: t });
  s += P('M318,96 L346,96 L420,548 L212,548Z', C.cyan, 'opacity=".3"');
  s += `<ellipse cx="316" cy="548" rx="106" ry="18" fill="${C.cyan}" opacity=".6"/>`;
  s += citizen(262, 262, 1.22, { tone: 0 });
  s += emblem(322, 356, 0.6, C.cyan);
  s += scanner(332, 78, 1.0, C.cyan);
  return s;
};

ART.informants = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(360, 330, 30, 1000, C.slate2, 0, 360);
  // neighbours' windows
  s += R(0, 0, 720, 150, C.ink) + blockWindows(30, 26, 9, 2, 78, 62, 40, 44, (r, c) => (r + c) % 4 === 1);
  s += P('M70,26 L78,38 L92,38 L98,70 L64,70Z', C.ink) + P('M388,88 L398,98 L410,98 L416,132 L382,132Z', C.ink);
  // the officer listens
  s += G('translate(404,120) scale(2.5)', [
    P('M-10,150 L6,116 L28,104 L92,104 L114,116 L130,150 L136,240 L-16,240Z', '#141c26'), P('M32,92 L88,92 L94,108 L26,108Z', C.slate2),
    P('M30,8 L50,0 L70,0 L90,8 L98,34 L96,70 L84,94 L36,94 L24,70 L22,34Z', '#141c26'), P('M30,8 L50,0 L46,30 L26,42 L22,34Z', C.slate2),
    `<circle cx="44" cy="46" r="12" fill="${C.ink}"/><circle cx="76" cy="46" r="12" fill="${C.ink}"/><circle cx="44" cy="46" r="8.5" fill="${C.paper}"/><circle cx="76" cy="46" r="8.5" fill="${C.paper}"/>`,
    P('M48,62 L72,62 L78,94 L42,94Z', C.steel), `<circle cx="60" cy="82" r="9" fill="${C.steel2}"/><circle cx="60" cy="82" r="4" fill="#141c26"/>`,
  ].join(''));
  // the citizen speaks
  for (let i = 0; i < 4; i++) s += `<path d="M${318 + i * 26},${346 - i * 14} A${40 + i * 22},${40 + i * 22} 0 0 1 ${318 + i * 26},${420 + i * 14}" stroke="${C.red}" stroke-width="${8 - i}" fill="none" opacity="${1 - i * 0.17}"/>`;
  s += G('translate(26,196) scale(2.3)', [
    P('M-30,170 L18,118 L72,118 L104,150 L112,260 L-36,260Z', C.blue), P('M18,118 L72,118 L104,150 L58,138Z', C.blue2),
    head({ smile: true }),
    P('M70,150 L104,150 L128,104 L112,92 L92,116Z', C.blue2), P('M108,90 L130,104 L136,84 L128,66 L112,64 L100,74Z', C.paper), P('M108,90 L130,104 L132,96 L112,84Z', C.steel),
  ].join(''));
  return s;
};

ART.contraband = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(360, 120, 30, 1000, C.slate2, 0, 180);
  s += officer(248, 10, 1.85, {});
  // the table and the open case
  s += R(0, 470, 720, 150, C.slate2) + R(0, 470, 720, 8, C.steel);
  s += P('M150,300 L570,300 L600,470 L120,470Z', C.ink) + P('M166,314 L554,314 L578,456 L142,456Z', C.slate3);
  s += P('M120,470 L600,470 L590,560 L130,560Z', C.steel) + R(120, 470, 480, 12, C.ink) + R(330, 486, 60, 22, C.ink);
  // what was in it: a crowbar, a radio, a bottle, a pistol
  s += `<path d="M190,430 L330,340 L352,340 L358,356" stroke="${C.ink}" stroke-width="13" fill="none" stroke-linejoin="round"/>`;
  s += R(382, 352, 100, 70, C.ink) + R(392, 362, 44, 26, C.steel) + `<circle cx="458" cy="376" r="12" fill="${C.steel}"/><path d="M470,352 L500,318" stroke="${C.ink}" stroke-width="5"/>` + R(392, 398, 80, 8, C.steel);
  s += P('M510,440 L510,384 L520,370 L520,356 L536,356 L536,370 L546,384 L546,440Z', C.steel2) + R(510, 396, 36, 20, C.ink);
  s += P('M214,356 L296,356 L296,374 L262,374 L258,412 L236,412 L240,374 L214,374Z', C.ink);
  // forbidden
  s += P('M92,286 L132,258 L628,548 L588,576Z', C.red) + P('M628,286 L588,258 L92,548 L132,576Z', C.red);
  return s;
};

ART.radio = () => {
  let s = R(0, 0, 720, 620, C.night);
  s += rays(520, 150, 30, 1000, C.night2, 0, 360);
  for (let i = 1; i <= 7; i++) s += `<circle cx="520" cy="150" r="${i * 64}" fill="none" stroke="${C.cyan}" stroke-width="${7 - i * 0.6}" opacity="${0.95 - i * 0.11}"/>`;
  // the tower that listens
  s += P('M496,150 L544,150 L600,620 L440,620Z', C.ink);
  for (let i = 0; i < 6; i++) { const y = 200 + i * 72, w = 28 + i * 9.4; s += `<path d="M${520 - w},${y} L${520 + w + 8},${y + 72} M${520 + w},${y} L${520 - w - 8},${y + 72}" stroke="${C.slate3}" stroke-width="5"/>` + R(520 - w - 2, y, w * 2 + 4, 5, C.slate3); }
  s += R(514, 60, 12, 96, C.steel) + scanner(520, 150, 0.9, C.cyan);
  // a room, a citizen, an unlicensed set
  s += P('M0,330 L330,330 L330,620 L0,620Z', '#101a27') + R(0, 324, 336, 8, C.slate2) + R(330, 324, 8, 296, C.slate2);
  s += G('translate(20,378) scale(1.25)', [
    P('M-20,170 L18,118 L72,118 L104,150 L110,260 L-26,260Z', C.blueD), head({ skin: '#b3ae9f', sh: '#67727c' }),
    P('M70,150 L104,150 L150,128 L142,108 L96,120Z', TONES[2].b2), P('M142,106 L152,130 L170,124 L166,100Z', '#b3ae9f'),
  ].join(''));
  s += R(214, 470, 96, 62, C.steel) + R(222, 478, 40, 24, C.ink) + `<circle cx="286" cy="490" r="11" fill="${C.ink}"/><circle cx="286" cy="490" r="4" fill="${C.cyan}"/><path d="M300,470 L318,400" stroke="${C.steel2}" stroke-width="4"/>` + R(222, 512, 80, 6, C.ink);
  s += R(190, 532, 150, 10, C.slate3) + R(200, 542, 10, 78, C.slate3) + R(320, 542, 10, 78, C.slate3);
  return s;
};

ART.illness = () => {
  const g1 = '#8a9468', g2 = '#a9b47c';
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(250, 300, 26, 1000, C.slate2, -60, 60);
  // the cough
  s += P('M236,330 L640,150 L680,520Z', g1, 'opacity=".5"') + P('M236,330 L600,230 L640,440Z', g2, 'opacity=".45"');
  // the others, in the way of it
  s += G('translate(736,150) scale(-1.5,1.5)', P('M-20,170 L18,118 L72,118 L104,150 L110,330 L-26,330Z', TONES[1].b) + head({ skin: TONES[1].skin, sh: TONES[1].sh, cap: TONES[1].bd }));
  s += G('translate(626,236) scale(-1.2,1.2)', P('M-20,170 L18,118 L72,118 L104,150 L110,340 L-26,340Z', TONES[2].b) + head({ skin: TONES[2].skin, sh: TONES[2].sh }));
  let seed = 7; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 70; i++) { const t = 0.12 + rnd() * 0.88, a = (-22 + rnd() * 48) * Math.PI / 180, d = t * 430; s += `<circle cx="${(240 + d * Math.cos(a)).toFixed(1)}" cy="${(330 + d * Math.sin(a)).toFixed(1)}" r="${(2 + t * 7 * rnd()).toFixed(1)}" fill="${rnd() > 0.5 ? g2 : '#d6dcae'}"/>`; }
  // the one who did not report it
  s += G('translate(8,170) scale(1.75)', [
    P('M-20,170 L18,118 L72,118 L104,150 L110,300 L-26,300Z', C.blue), P('M18,118 L72,118 L104,150 L58,138Z', C.blue2),
    head({ cap: C.blueD }), P('M84,76 L96,80 L92,90 L82,88Z', C.ink),
    P('M60,150 L100,154 L124,118 L108,104 L88,124Z', C.blue2), P('M106,102 L126,116 L134,100 L126,84 L112,84Z', C.paper),
  ].join(''));
  // medicine
  s += R(600, 470, 66, 150, C.paper) + R(600, 452, 66, 20, C.ink) + R(600, 520, 66, 44, C.cyan) + emblem(620, 528, 0.62, C.paper) + R(612, 480, 8, 30, '#fff', 'opacity=".6"');
  return s;
};

ART.infestation = () => {
  const g1 = '#5d6b3e', g2 = '#7f9450', g3 = '#b9d06a', g4 = '#39422a';
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(560, 300, 26, 1000, C.slate2, 90, 270);
  s += R(0, 520, 720, 100, C.slate2) + R(0, 520, 720, 5, C.steel);
  // the growth
  s += P('M720,90 L600,120 L520,220 L470,340 L500,470 L560,540 L720,560Z', g4);
  for (const [x, y, r, f] of [[640, 200, 78, g1], [560, 300, 70, g1], [650, 380, 92, g1], [580, 450, 60, g1], [690, 280, 60, g2], [600, 250, 34, g2], [630, 420, 44, g2], [560, 340, 26, g2], [676, 190, 26, g2], [600, 250, 14, g3], [634, 418, 20, g3], [560, 340, 10, g3], [690, 280, 24, g3]]) s += `<circle cx="${x}" cy="${y}" r="${r}" fill="${f}"/>`;
  for (const d of ['M500,470 C440,490 420,540 360,548', 'M470,340 C420,330 400,290 350,300', 'M520,220 C480,180 470,140 430,120', 'M560,540 C520,570 480,560 450,590']) s += `<path d="${d}" stroke="${g4}" stroke-width="12" fill="none" stroke-linecap="round"/>`;
  let seed = 11; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
  for (let i = 0; i < 46; i++) s += `<circle cx="${(250 + rnd() * 330).toFixed(1)}" cy="${(60 + rnd() * 420).toFixed(1)}" r="${(1.5 + rnd() * 4).toFixed(1)}" fill="${g3}" opacity="${(0.4 + rnd() * 0.6).toFixed(2)}"/>`;
  // the citizen keeps away, hand raised
  s += citizen(70, 222, 1.36, { tone: 0 });
  s += P('M164,318 L180,312 L222,262 L210,252 L172,290Z', C.blue2) + palm(196, 196, 0.42, C.paper, 18);
  // the line
  s += P('M250,620 L300,620 L360,0 L310,0Z', C.red);
  for (let i = 0; i < 9; i++) { const y = 20 + i * 70; s += P(`M${310 - (y / 620) * 60},${y} L${360 - (y / 620) * 60},${y - 24} L${360 - ((y + 30) / 620) * 60},${y + 6} L${310 - ((y + 30) / 620) * 60},${y + 30}Z`, C.paper); }
  return s;
};

ART.housing = () => {
  let s = R(0, 0, 720, 620, C.night);
  s += P('M60,60 L660,60 L660,620 L60,620Z', C.slate) + R(60, 60, 600, 16, C.slate2);
  for (let r = 0; r < 5; r++) for (let c = 0; c < 6; c++) {
    const x = 96 + c * 92, y = 104 + r * 104, lit = (r * 6 + c) % 5 !== 2;
    s += R(x - 5, y - 5, 66, 82, '#16212e') + R(x, y, 56, 72, lit ? C.warm : '#1f3045');
    if (lit) s += R(x + 26, y, 4, 72, C.slate) + R(x, y + 34, 56, 4, C.slate) + R(x, y, 56, 72, '#c98f3a', 'opacity=".2"');
  }
  s += R(0, 0, 720, 620, C.night, 'opacity=".35"');
  // the hand that gives, and the key
  s += P('M430,-10 L560,-10 L520,150 L420,140Z', C.ink) + P('M418,132 L524,144 L520,170 L414,158Z', C.slate3) + P('M404,156 L522,170 L510,250 L440,262 L396,230Z', '#141c26');
  s += `<path d="M452,250 L452,300" stroke="${C.steel2}" stroke-width="5"/>`;
  s += `<circle cx="452" cy="336" r="40" fill="${C.cyan}"/><circle cx="452" cy="336" r="17" fill="${C.night}"/>` + R(440, 370, 24, 150, C.cyan) + R(464, 452, 34, 16, C.cyan) + R(464, 486, 26, 16, C.cyan);
  // the hand that receives
  s += palm(248, 380, 1.5, C.paper, 14) + P('M240,640 L300,560 L420,590 L400,660Z', C.blue);
  return s;
};

ART.vortigaunt = () => {
  const v1 = '#4b4a38', v2 = '#66654b', v3 = '#33332a';
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(140, 120, 28, 1000, C.slate2, 0, 120);
  s += P('M0,620 L0,250 L90,250 L90,190 L200,190 L200,280 L290,280 L290,620Z', C.ink) + blockWindows(14, 276, 3, 6, 26, 40, 12, 20, (r, c) => (r + c) % 3 === 0) + blockWindows(108, 216, 3, 7, 28, 40, 12, 20, (r, c) => (r + 2 * c) % 4 === 0);
  s += R(0, 500, 720, 120, C.slate2) + R(0, 500, 720, 5, C.steel);
  // a citizen passes, eyes forward
  s += citizen(86, 300, 1.0, { tone: 1 });
  // the vortigaunt sweeps
  s += G('translate(330,176) scale(1.25)', [
    P('M150,230 L178,226 L198,290 L172,300 L184,352 L206,360 L160,362 L146,300 L162,282Z', v3), P('M116,232 L146,236 L134,290 L112,300 L120,352 L92,362 L84,354 L96,348 L90,296 L112,282Z', v1),
    P('M108,112 L170,96 L204,150 L190,238 L114,242 L94,172Z', v1), P('M108,112 L170,96 L160,150 L112,170 L94,172Z', v2),
    P('M48,86 L94,60 L130,76 L134,110 L104,130 L62,124Z', v1), P('M48,86 L94,60 L104,84 L62,104Z', v2),
    `<circle cx="80" cy="98" r="14" fill="${C.ink}"/><circle cx="80" cy="98" r="9" fill="${C.warm}"/><circle cx="78" cy="99" r="3.5" fill="${C.ink}"/><circle cx="104" cy="84" r="4" fill="${C.warm}"/><circle cx="58" cy="108" r="3.5" fill="${C.warm}"/>`,
    P('M104,120 L136,104 L142,122 L110,138Z', C.cyan),
    `<path d="M170,116 L60,330" stroke="${C.steel2}" stroke-width="7" stroke-linecap="round"/>`,
    P('M28,318 L82,340 L72,364 L18,342Z', C.warm) + P('M28,318 L82,340 L80,346 L26,324Z', C.ink),
    P('M150,116 L172,112 L150,196 L128,192Z', v2), P('M128,192 L150,196 L112,252 L94,240Z', v2), P('M92,238 L114,254 L104,268 L84,254Z', v3), P('M96,240 L112,252 L109,257 L93,245Z', C.cyan),
    P('M130,150 L146,150 L140,196 L126,194Z', v3),
    `<path d="M124,134 C150,220 210,300 250,356" stroke="${C.cyan}" stroke-width="5" fill="none" stroke-dasharray="12 8"/>`, R(240, 350, 26, 12, C.steel),
  ].join(''));
  return s;
};

ART.recruit = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(430, 240, 32, 1000, C.slate2, 0, 360);
  s += `<circle cx="430" cy="230" r="190" fill="${C.slate3}"/>`;
  s += P('M300,520 L560,520 L590,620 L270,620Z', C.ink) + R(300, 512, 260, 10, C.slate3);
  s += officer(354, 56, 1.3, {});
  // plenty
  s += R(560, 420, 160, 14, C.steel2) + R(572, 434, 148, 186, C.slate2);
  for (let r = 0; r < 3; r++) for (let c = 0; c < 4 - r; c++) { const x = 574 + c * 38 + r * 19, y = 374 - r * 46; s += R(x, y, 32, 46, C.steel2) + R(x, y + 14, 32, 14, C.red) + R(x, y, 32, 5, C.steel); }
  // those who look up
  const row = [[-10, 478, 1.0, 1, 1], [84, 492, 0.96, 0, 0], [176, 482, 1.0, 1, 1], [20, 400, 0.72, 3, 0], [104, 408, 0.7, 2, 1], [186, 402, 0.72, 3, 0]];
  for (const b of row.slice(3)) s += reader(...b);
  for (const b of row.slice(0, 3)) s += reader(...b);
  return s;
};

ART.work = () => {
  let s = R(0, 0, 720, 620, C.slate);
  s += rays(200, 380, 28, 1000, C.slate2, 180, 360);
  // the gear and the works
  const cx = 500, cy = 250, r1 = 190;
  for (let i = 0; i < 12; i++) s += G(`rotate(${i * 30 + 8} ${cx} ${cy})`, R(cx - 26, cy - r1 - 34, 52, 60, C.slate3));
  s += `<circle cx="${cx}" cy="${cy}" r="${r1}" fill="${C.slate3}"/><circle cx="${cx}" cy="${cy}" r="120" fill="${C.slate}"/><circle cx="${cx}" cy="${cy}" r="46" fill="${C.slate3}"/>`;
  for (let i = 0; i < 6; i++) s += G(`rotate(${i * 60 + 8} ${cx} ${cy})`, R(cx - 12, cy - 124, 24, 124, C.slate3));
  s += P('M0,620 L0,430 L40,430 L40,330 L60,330 L60,430 L110,400 L110,430 L160,400 L160,430 L720,430 L720,620Z', C.ink);
  // the idle one, in the shade
  s += P('M560,430 L720,430 L720,620 L520,620Z', '#101820');
  s += G('translate(600,470)', P('M20,40 L44,36 L60,70 L96,84 L92,150 L10,150 L4,90Z', '#2a3848') + P('M26,4 L48,4 L56,20 L50,38 L34,42 L22,30Z', '#3a4a5c') + P('M56,84 L96,84 L104,150 L60,150Z', '#222e3c'));
  // the worker
  s += worker(60, 190, 1.4, { arm: 'out', hammer: true });
  return s;
};

const POSTERS = [
  { id: 'work', n: 7, accent: 'red', head: [['IDLE HANDS', 118], ['BURDEN THE CITY', 84]],
    small: ['Every citizen has a shift.', 'Report to Labor Assignment.', 'The Union remembers who works.'] },
  { id: 'loyalty', n: 8, accent: 'cyan', head: [['LOYALTY', 138], ['IS NOTICED', 108]],
    small: ['Good standing opens doors.', 'Poor standing closes them.', 'Your record is always current.'] },
  { id: 'informants', n: 9, accent: 'red', head: [['REPORT WHAT', 102], ['YOU HEAR', 138]],
    small: ['A word to Civil Protection', 'keeps your block safe.', 'Silence protects no one.'] },
  { id: 'contraband', n: 10, accent: 'red', head: [['CONTRABAND', 112], ['FEEDS THE ENEMY', 84]],
    small: ['Unlicensed goods are confiscated.', 'So are those who carry them.', 'Submit to search.'] },
  { id: 'radio', n: 11, accent: 'cyan', dark: true, head: [['UNLICENSED FREQUENCIES', 56], ['ARE MONITORED', 98]],
    small: ['The city speaks on approved channels only.', 'We hear the others too.'] },
  { id: 'illness', n: 12, accent: 'cyan', head: [['A COUGH UNREPORTED', 70], ['IS A COUGH SHARED', 78]],
    small: ['Report illness at once.', 'Medicine is available at the Commissary.', 'Rest, and return to work.'] },
  { id: 'infestation', n: 13, accent: 'red', head: [['DO NOT APPROACH.', 82], ['REPORT.', 156]],
    small: ['Growths and spores spread by touch. Keep away.', 'Sanitation crews will cleanse the area.'] },
  { id: 'housing', n: 14, accent: 'cyan', dark: true, head: [['YOUR ROOM', 130], ['IS A PRIVILEGE', 90]],
    small: ['Housing is assigned to registered workers.', 'Keep it clean. Keep it quiet.', 'Keep it.'] },
  { id: 'vortigaunt', n: 15, accent: 'cyan', head: [['THEY SERVE,', 106], ['AS YOU SERVE', 106]],
    small: ['Shackled labor keeps your streets clean.', 'Do not speak to it.', 'Do not free it.'] },
  { id: 'recruit', n: 16, accent: 'red', head: [['JOIN CIVIL PROTECTION.', 58], ['EAT BETTER.', 120]],
    small: ['Better rations. Better housing.', 'A place in the new order.', 'Apply at any post.'] },
  { id: 'administrator', n: 17, accent: 'red', head: [['SHE WATCHES', 108], ['OVER YOU', 150]],
    small: ['Your Administrator works while you sleep.', 'Work well, sleep well, and trust in her.'] },
];

module.exports = { ART, POSTERS };
