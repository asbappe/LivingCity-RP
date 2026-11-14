// The owner's slogan as a poster (14 November): LOVE YOUR NEIGHBOUR, HATE THE TRAITOR. Kind "neighbour",
// one of the Director of Propaganda's hand-hung posters (entities/lc_civposter.lua). Drawn by gen.js.
const { C, P, R, G, rays, head } = require('./lib.js');
const { E, L, T, skyline } = require('./dreamkit.js');

const ART = {};
ART.neighbour = () => {
  let s = R(0, 0, 720, 610, '#d6cfba') + rays(232, 250, 40, 1000, C.paper, 0, 360, 'opacity=".75"');
  s += skyline(470, C.steel2, '#d6cfba', 22, 110) + R(0, 466, 720, 144, C.steel);
  // the neighbours
  const body = (t, bd) => P('M-34,214 L-16,152 L30,118 L72,118 L112,142 L128,214Z', t) + P('M36,118 L52,118 L62,214 L44,214Z', bd);
  s += G('translate(8,176) scale(1.62)', body(C.blue, C.blueD) + head({ cap: C.blueD, smile: true }));
  s += G('translate(456,176) scale(-1.62,1.62)', body('#335073', '#263a55') + head({ skin: '#c8c2b1', sh: '#727e88', hair: '#3a2c22', smile: true }));
  // their hands
  s += P('M150,440 L226,446 L236,478 L156,492Z', C.blue2) + P('M314,440 L238,446 L228,478 L308,492Z', '#456a93');
  s += P('M206,444 L262,448 L266,476 L210,482Z', C.paper) + P('M258,444 L214,450 L210,470 L256,480Z', '#c8c2b1') + L('M222,452 L222,474 M234,452 L234,476 M246,452 L246,476', C.ink, 2.2, 'opacity=".5"');
  s += G('translate(232,112) scale(1.5)', P('M0,26 L-30,-4 Q-34,-28 -14,-28 Q-2,-28 0,-14 Q2,-28 14,-28 Q34,-28 30,-4Z', C.red));
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
