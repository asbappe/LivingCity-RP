// Shared pieces for the Living City civil notice posters (flat, screen-printed look).
const C = {
  paper: '#ddd6c2', ink: '#18212c', slate: '#243446', slate2: '#34495f', slate3: '#4a6077',
  steel: '#7b8993', steel2: '#aab3b5', blue: '#3a5a84', blue2: '#5279a6', blueD: '#2a4161',
  red: '#c23b2a', redD: '#8f2a1f', cyan: '#5cc8d8', cyanD: '#2e8a9c', warm: '#ead9a2',
  night: '#0e1723', night2: '#172536',
};
const P = (d, f, extra = '') => `<path d="${d}" fill="${f}" ${extra}/>`;
const R = (x, y, w, h, f, extra = '') => `<rect x="${x}" y="${y}" width="${w}" height="${h}" fill="${f}" ${extra}/>`;
const G = (t, s) => `<g transform="${t}">${s}</g>`;

function rays(cx, cy, n, r, fill, a0 = 0, a1 = 360, extra = '') {
  let s = '';
  const step = (a1 - a0) / n;
  for (let i = 0; i < n; i += 2) {
    const A = (a0 + i * step) * Math.PI / 180, B = (a0 + (i + 1) * step) * Math.PI / 180;
    s += P(`M${cx},${cy} L${(cx + r * Math.cos(A)).toFixed(1)},${(cy + r * Math.sin(A)).toFixed(1)} L${(cx + r * Math.cos(B)).toFixed(1)},${(cy + r * Math.sin(B)).toFixed(1)}Z`, fill, extra);
  }
  return s;
}

// The regime's mark: a segmented shield, 40 x 46.
function emblem(x, y, s, fill) {
  return G(`translate(${x},${y}) scale(${s})`,
    P('M0,10 L17,2 L17,44 L0,30Z', fill) + P('M23,2 L40,10 L40,18 L23,18Z', fill) + P('M23,24 L40,24 L40,30 L23,44Z', fill));
}

// A head in profile, facing right, in a 100 x 122 box.
function head(o = {}) {
  const skin = o.skin || C.paper, sh = o.sh || C.steel, hair = o.hair || C.ink;
  let s = '';
  s += P('M30,122 L30,92 L22,74 L20,48 L28,24 L46,10 L66,10 L82,22 L86,40 L86,48 L97,64 L89,68 L91,76 L87,80 L88,90 L80,100 L62,98 L58,122Z', skin);
  s += P('M30,122 L30,92 L44,97 L62,98 L58,122Z', sh);
  s += P('M50,85 L62,98 L80,100 L86,93 L66,91Z', sh);
  s += P('M44,56 L54,54 L55,69 L47,72Z', sh);
  s += P('M20,48 L28,24 L46,10 L66,10 L82,22 L86,40 L62,38 L58,50 L42,50 L40,64 L30,68 L28,84 L22,74Z', hair);
  if (o.cap) s += P('M14,44 L20,22 L42,6 L68,6 L86,18 L90,34 L108,40 L108,46 L60,46Z', o.cap) + P('M14,44 L60,46 L108,46 L108,50 L14,49Z', C.ink);
  s += P('M70,56 L84,55 L82,60 L72,60Z', C.ink);
  s += `<path d="M79,82 L89,${o.smile ? 78 : 80}" stroke="${C.ink}" stroke-width="2.4" fill="none"/>`;
  return s;
}
// A child's head in profile, facing right.
function childHead(o = {}) {
  const skin = o.skin || C.paper, sh = o.sh || C.steel, hair = o.hair || C.ink;
  let s = '';
  s += P('M34,122 L34,98 L22,82 L16,54 L24,28 L44,12 L68,12 L84,26 L88,46 L96,58 L90,63 L91,72 L87,76 L86,88 L74,98 L60,98 L58,122Z', skin);
  s += P('M34,122 L34,98 L46,99 L60,98 L58,122Z', sh);
  s += P('M40,58 L50,56 L51,70 L43,73Z', sh);
  s += P('M16,54 L24,28 L44,12 L68,12 L84,26 L88,44 L70,36 L56,40 L50,52 L38,52 L36,68 L26,74 L24,86 L22,82Z', hair);
  s += P('M16,54 L22,82 L34,98 L36,112 L18,106 L8,80Z', hair);
  s += P('M72,53 L85,52 L84,60 L74,60Z', C.ink);
  s += `<path d="M78,80 L88,75" stroke="${C.ink}" stroke-width="2.4" fill="none"/>`;
  return s;
}
const TONES = [
  { b: C.blue, b2: C.blue2, bd: C.blueD, skin: C.paper, sh: C.steel },
  { b: '#335073', b2: '#456a93', bd: '#263a55', skin: '#c8c2b1', sh: '#727e88' },
  { b: '#2d4666', b2: '#3b5c82', bd: '#22344c', skin: '#b3ae9f', sh: '#67727c' },
  { b: '#283d59', b2: '#335071', bd: '#1f2f44', skin: '#9f9b8e', sh: '#5d6770' },
];
// A worker in profile, facing right. Head box at 0,0; the body runs down to 640.
function worker(tx, ty, s, o = {}) {
  const t = TONES[o.tone || 0];
  let g = '';
  g += P('M-14,160 L18,118 L72,118 L98,142 L104,640 L-20,640Z', t.b);
  g += P('M18,118 L72,118 L98,142 L58,136Z', t.b2);
  g += P('M36,118 L52,118 L66,640 L44,640Z', t.bd);
  g += head({ skin: t.skin, sh: t.sh, cap: o.cap === false ? null : t.bd, smile: o.smile });
  if (o.arm === 'out') {
    g += P('M58,140 L98,140 L200,162 L200,192 L78,192Z', t.b2);
    g += P('M190,160 L204,161 L204,193 L190,192Z', t.bd);
    g += P('M204,163 L236,160 L248,170 L240,187 L204,191Z', t.skin);
    if (o.hammer) g += P('M226,186 L240,188 L300,40 L286,36Z', C.steel) + P('M262,20 L330,44 L322,70 L254,46Z', C.red) + P('M216,160 L246,158 L250,186 L220,190Z', t.skin);
    if (o.card) g += P('M230,160 L306,153 L308,177 L232,184Z', C.red) + P('M222,159 L252,157 L254,166 L224,168Z', t.skin);
  } else {
    g += P('M40,142 L84,148 L90,300 L52,304Z', t.b2);
    g += P('M54,304 L90,300 L88,330 L60,332Z', t.skin);
  }
  return G(`translate(${tx},${ty}) scale(${s})`, g);
}
// A Civil Protection officer, front view, 120 wide by 480 tall.
function officer(tx, ty, s, o = {}) {
  const lens = o.lens || C.paper, band = o.band || C.red, dk = '#141c26';
  let g = '';
  g += P('M14,330 L56,330 L54,462 L20,462Z', dk) + P('M64,330 L106,330 L100,462 L66,462Z', dk);
  g += P('M14,462 L56,462 L56,480 L8,480Z', C.ink) + P('M64,462 L106,462 L112,480 L64,480Z', C.ink);
  g += P('M6,116 L28,104 L92,104 L114,116 L120,150 L108,340 L12,340 L0,150Z', dk);
  g += P('M56,104 L64,104 L64,340 L56,340Z', C.slate2);
  g += R(12, 226, 96, 14, C.steel);
  g += R(50, 222, 20, 22, C.steel2);
  g += P('M0,150 L6,116 L26,126 L24,262 L4,262Z', C.slate);
  g += R(3, 168, 22, 20, band);
  g += P('M4,262 L24,262 L24,286 L6,286Z', C.ink);
  if (o.point) {
    g += P('M96,110 L114,116 L226,128 L228,152 L110,154Z', C.slate);
    g += R(150, 132, 22, 20, band, 'transform="rotate(5 160 140)"');
    g += P('M226,127 L266,134 L266,142 L246,144 L228,152Z', C.ink);
  } else {
    g += P('M120,150 L114,116 L94,126 L96,262 L116,262Z', C.slate);
    g += R(95, 168, 22, 20, band);
    g += P('M96,262 L116,262 L114,286 L96,286Z', C.ink);
    if (o.baton) g += `<path d="M104,270 L128,372" stroke="${C.steel}" stroke-width="9" stroke-linecap="round"/><path d="M104,270 L109,292" stroke="${C.ink}" stroke-width="11" stroke-linecap="round"/>`;
  }
  g += P('M32,92 L88,92 L94,108 L26,108Z', C.slate2);
  g += P('M30,8 L50,0 L70,0 L90,8 L98,34 L96,70 L84,94 L36,94 L24,70 L22,34Z', dk);
  g += P('M30,8 L50,0 L46,30 L26,42 L22,34Z', C.slate2);
  g += `<circle cx="44" cy="46" r="12" fill="${C.ink}"/><circle cx="76" cy="46" r="12" fill="${C.ink}"/>`;
  g += `<circle cx="44" cy="46" r="8.5" fill="${lens}"/><circle cx="76" cy="46" r="8.5" fill="${lens}"/>`;
  g += P('M48,62 L72,62 L78,94 L42,94Z', C.steel);
  g += `<circle cx="60" cy="82" r="9" fill="${C.steel2}"/><circle cx="60" cy="82" r="4" fill="${dk}"/>`;
  return G(`translate(${tx},${ty}) scale(${s})`, g);
}
// A small citizen seen from the front, 80 x 230. o.scarf = a woman in a headscarf, o.case = a suitcase.
function citizen(tx, ty, s, o = {}) {
  const t = TONES[o.tone || 0];
  let g = '';
  g += P('M18,158 L38,158 L36,228 L20,228Z', t.bd) + P('M42,158 L62,158 L60,228 L44,228Z', t.bd);
  g += o.scarf ? P('M12,64 L34,56 L46,56 L68,64 L78,196 L2,196Z', t.b) : P('M12,64 L34,56 L46,56 L68,64 L72,164 L8,164Z', t.b);
  g += P('M34,56 L46,56 L42,100 L38,100Z', t.bd);
  g += P('M28,8 L52,8 L58,22 L56,44 L46,56 L34,56 L24,44 L22,22Z', t.skin);
  g += P('M40,8 L52,8 L58,22 L56,44 L46,56 L40,56Z', t.sh, 'opacity=".55"');
  g += o.scarf ? P('M20,26 L26,4 L54,4 L60,26 L62,52 L56,44 L54,20 L26,20 L24,44 L18,52Z', C.steel2) : P('M18,22 L26,2 L54,2 L62,22 L40,18Z', C.ink);
  if (o.case) g += R(64, 150, 34, 44, C.steel) + R(64, 150, 34, 8, C.ink) + `<path d="M74,150 L74,140 L88,140 L88,150" stroke="${C.ink}" stroke-width="3" fill="none"/>` + P('M62,70 L72,74 L80,142 L70,144Z', t.b2);
  return G(`translate(${tx},${ty}) scale(${s})`, g);
}
// A head and shoulders seen from behind (a reader in a crowd), 80 x 120.
function reader(tx, ty, s, tone, hat) {
  const t = TONES[tone || 0];
  let g = P('M0,120 L6,74 L28,62 L52,62 L74,74 L80,120Z', t.b) + P('M28,62 L52,62 L50,74 L30,74Z', t.sh);
  g += P('M24,10 L56,10 L62,26 L60,50 L50,64 L30,64 L20,50 L18,26Z', hat ? t.bd : C.ink);
  if (hat) g += P('M22,44 L58,44 L60,50 L50,64 L30,64 L20,50Z', C.ink);
  return G(`translate(${tx},${ty}) scale(${s})`, g);
}

// The City Administrator (after Judith Mossman: dark hair parted and pulled back, tan skin,
// a pale coat over a dark high collar), front view, in a 170 x 214 box.
function adminBust(o = {}) {
  const skin = '#c9a384', sh = '#9b7860', hair = '#1b1819', lip = o.lip || '#7d3f36';
  return [
    P('M44,88 L48,44 L68,22 L102,22 L122,44 L126,88 L118,116 L52,116Z', hair),
    P('M4,214 L22,166 L66,148 L104,148 L148,166 L166,214Z', C.ink),
    P('M58,152 L85,200 L80,214 L34,214 L44,164Z', C.paper), P('M112,152 L85,200 L90,214 L136,214 L126,164Z', C.paper),
    P('M112,152 L85,200 L90,214 L104,214 L100,196 L118,160Z', C.steel2),
    P('M68,118 L68,150 L85,172 L102,150 L102,118Z', C.slate2), P('M68,134 L102,134 L102,140 L68,140Z', C.ink),
    P('M56,72 L62,50 L85,42 L108,50 L114,72 L112,100 L100,122 L85,130 L70,122 L58,100Z', skin),
    P('M102,58 L108,50 L114,72 L112,100 L100,122 L85,130 L96,112 L104,92Z', sh),
    P('M85,38 L60,44 L50,70 L53,96 L60,76 L70,60 L85,52Z', hair), P('M85,38 L110,44 L120,70 L117,96 L110,76 L100,60 L85,52Z', hair),
    P('M63,73 L80,70 L80,73 L63,77Z', hair), P('M90,70 L107,73 L107,77 L90,73Z', hair),
    P('M66,81 L80,81 L78,86 L68,86Z', C.ink), P('M90,81 L104,81 L102,86 L92,86Z', C.ink),
    P('M70,82 L74,82 L74,84 L70,84Z', C.paper), P('M94,82 L98,82 L98,84 L94,84Z', C.paper),
    P('M85,84 L90,103 L81,103Z', sh),
    P('M76,111 L85,109 L94,111 L85,116Z', lip),
    P('M70,122 L85,130 L100,122 L96,128 L85,134 L74,128Z', sh),
    emblem(118, 178, 0.42, o.pin || C.cyan),
  ].join('');
}
// A scanner: the city's flying eye. Centre at 0,0, about 144 wide.
function scanner(x, y, s, eye) {
  return G(`translate(${x},${y}) scale(${s})`, [
    P('M-70,0 L-28,-24 L30,-20 L72,0 L30,18 L-28,24Z', C.steel), P('M-70,0 L-28,-24 L30,-20 L72,0Z', C.steel2),
    P('M-28,-24 L-44,-44 L-18,-38 L4,-22Z', C.slate3), P('M30,18 L52,36 L20,34 L0,22Z', C.slate3),
    `<circle cx="0" cy="0" r="30" fill="${eye}" opacity=".18"/><circle cx="0" cy="0" r="19" fill="${C.ink}"/><circle cx="0" cy="0" r="12" fill="${eye}"/><circle cx="0" cy="0" r="5" fill="#fff4ee"/>`,
  ].join(''));
}
// An open hand, fingers up, 84 x 190.
function palm(x, y, s, fill, rot = 0) {
  return G(`translate(${x},${y}) rotate(${rot}) scale(${s})`, [
    R(20, 26, 13, 70, fill), R(36, 10, 13, 86, fill), R(52, 14, 13, 82, fill), R(68, 30, 12, 66, fill),
    P('M20,84 L80,84 L82,190 L24,190Z', fill), P('M20,96 L2,72 L10,60 L26,80Z', fill),
  ].join(''));
}

module.exports = { adminBust, scanner, palm, C, P, R, G, rays, emblem, head, childHead, worker, officer, citizen, reader, TONES };
