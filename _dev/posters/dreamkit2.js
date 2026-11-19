// More shared pieces for the dream posters (dreams5.js to dreams7.js).
const { C, P, R, G } = require('./lib.js');
const { E, L } = require('./dreamkit.js');

// the red "not allowed" ring
const no = (cx, cy, r, w = 24) => `<circle cx="${cx}" cy="${cy}" r="${r}" fill="none" stroke="${C.red}" stroke-width="${w}"/>` +
  L(`M${(cx - r * 0.707).toFixed(0)},${(cy - r * 0.707).toFixed(0)} L${(cx + r * 0.707).toFixed(0)},${(cy + r * 0.707).toFixed(0)}`, C.red, w);
// a hand on a sleeve, reaching right from x,y (the fingertips about 100 past it); o.flip reaches left
function hand(x, y, s, rot, o = {}) {
  const skin = o.skin || C.paper, sl = o.sleeve || C.blue, dk = o.cuff || C.blueD;
  return G(`translate(${x},${y}) rotate(${rot}) scale(${o.flip ? -s : s},${s})`, R(-420, -30, 420, 60, sl) + R(-420, 6, 420, 24, dk, 'opacity=".5"') + R(-26, -34, 26, 68, dk) +
    P('M0,-24 L66,-28 L96,-14 L102,10 L72,26 L0,24Z', skin) + P('M26,-26 L46,-52 L60,-44 L52,-24Z', skin) + L('M58,-6 L98,-4 M56,8 L96,10', C.steel, 2.4, 'opacity=".7"') + (o.band ? R(-90, -30, 34, 60, o.band) : ''));
}
// a note of music
const note = (x, y, s, col, rot = 0) => G(`translate(${x},${y}) rotate(${rot}) scale(${s})`, E(0, 0, 15, 11, col, 'transform="rotate(-20)"') + R(10, -62, 6, 62, col) + P('M10,-62 L44,-48 L44,-30 L16,-44Z', col));
// a round clock face
function clock(cx, cy, r, h, m, o = {}) {
  let s = `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${o.rim || C.ink}"/><circle cx="${cx}" cy="${cy}" r="${r * 0.86}" fill="${o.face || C.paper}"/>`;
  for (let i = 0; i < 12; i++) s += R(cx - r * 0.025, cy - r * 0.8, r * 0.05, r * (i % 3 ? 0.1 : 0.18), C.ink, `transform="rotate(${i * 30} ${cx} ${cy})"`);
  s += R(cx - r * 0.045, cy - r * 0.46, r * 0.09, r * 0.52, C.ink, `transform="rotate(${h} ${cx} ${cy})"`) + R(cx - r * 0.03, cy - r * 0.7, r * 0.06, r * 0.78, o.hand || C.red, `transform="rotate(${m} ${cx} ${cy})"`);
  return s + `<circle cx="${cx}" cy="${cy}" r="${r * 0.07}" fill="${C.ink}"/>`;
}
module.exports = { no, hand, note, clock, ORANGE: '#d9792b', YEL: '#e0b83a', DARK: '#080d15', SKIN: '#dfc6a8', SKIND: '#b59a7e' };
