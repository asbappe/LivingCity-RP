// The owner's slogan as a poster (14 November): LOVE YOUR NEIGHBOUR, HATE THE TRAITOR. Kind "neighbour",
// one of the Director of Propaganda's hand-hung posters (entities/lc_civposter.lua). Drawn by gen.js.
const { C, P, R, G, rays, head } = require('./lib.js');
const { E, L, T, skyline } = require('./dreamkit.js');

const ART = {};
ART.neighbour = () => {
  let s = R(0, 0, 720, 610, '#d6cfba') + rays(232, 250, 40, 1000, C.paper, 0, 360, 'opacity=".75"');
  s += skyline(470, C.steel2, '#d6cfba', 22, 110) + R(0, 466, 720, 144, C.steel);
  // the neighbours: a man and a woman of the block, shaking hands
  const body = (t, bd) => P('M-34,270 L-16,152 L30,118 L72,118 L112,142 L128,270Z', t) + P('M36,118 L52,118 L62,270 L44,270Z', bd);
  const scarf = P('M16,52 L24,22 L44,4 L70,4 L86,18 L88,40 L64,38 L58,52 L42,54 L40,72 L32,96 L46,120 L22,126 L10,86Z', C.steel2) + P('M24,22 L44,4 L70,4 L86,18 L60,20 L40,30Z', '#c9d0d0');
  s += G('translate(-22,150) scale(1.62)', body(C.blue, C.blueD) + head({ cap: C.blueD, smile: true }));
  s += G('translate(488,150) scale(-1.62,1.62)', body('#335073', '#263a55') + head({ skin: '#d8cdb8', sh: '#8f8a7c', hair: C.steel2, smile: true }) + scarf);
  // their arms (shoulder, elbow, wrist), meeting in the open between them: his thumb over her hand
  const O = `stroke="${C.ink}" stroke-width="2.2" stroke-opacity=".5" stroke-linejoin="round"`;
  const skinB = '#d8cdb8';
  s += P('M380,392 L342,388 L318,476 L354,490Z', '#4f77a3', O) + P('M354,492 L324,462 L262,438 L252,468 L334,502Z', '#4f77a3', O) + P('M270,441 L258,437 L249,468 L261,472Z', '#263a55');
  s += P('M222,440 L258,438 L258,470 L224,470Z', skinB, O);
  s += P('M84,392 L122,388 L146,476 L110,490Z', C.blue2, O) + P('M110,492 L140,462 L202,438 L212,468 L130,502Z', C.blue2, O) + P('M194,441 L206,437 L215,468 L203,472Z', C.blueD);
  s += P('M206,438 L240,436 L246,444 L246,466 L210,470Z', C.paper, O) + P('M216,427 L238,425 L242,438 L220,440Z', C.paper, O);
  s += P('M205,449 L219,448 L219,455 L205,456Z', skinB, O) + P('M205,458 L219,457 L219,464 L205,465Z', skinB, O);
  // the traitor
  s += P('M500,0 L720,0 L720,610 L420,610Z', '#0b1119') + P('M500,0 L512,0 L432,610 L420,610Z', C.red);
  s += G('translate(322,96) scale(0.82)', [
    P('M230,470 L262,300 L458,300 L490,470Z', '#2c3a4a'),
    P('M282,110 L438,110 L462,180 L452,262 L410,318 L310,318 L268,262 L258,180Z', '#4a5a6c'),
    P('M268,150 L282,84 L330,56 L390,56 L438,84 L452,150 L360,136Z', '#3d4a35'), R(264, 140, 192, 16, '#2a3424'), T(360, 122, 'λ', 54, '#e08a2c'),
    P('M290,186 L346,206 L344,222 L292,206Z', C.red), P('M430,186 L374,206 L376,222 L428,206Z', C.red), P('M282,170 L350,196 L348,204 L282,182Z', C.ink), P('M438,170 L370,196 L372,204 L438,182Z', C.ink),
    P('M318,270 L402,270 L394,284 L326,284Z', C.ink),
  ].join(''));
  s += `<circle cx="617" cy="250" r="128" fill="none" stroke="${C.red}" stroke-width="20"/>` + L('M527,160 L707,340', C.red, 20);
  return s;
};

const POSTERS = [
  { id: 'neighbour', n: 18, accent: 'red', headShift: 26, head: [['LOVE YOUR NEIGHBOUR', 78, C.slate], ['HATE THE TRAITOR', 96]], small: [] },
];

module.exports = { ART, POSTERS };
