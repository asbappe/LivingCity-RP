// The Resistance's way marks: sprayed arrows (left, right, up for "straight on", down) with the lambda,
// and FREEDOM THIS WAY, for the editor's permanent wall marks (sv_livingcity_waymarks.lua).
// Run: node arrows.js OUTDIR   (writes arrow_left.png, arrow_right.png, arrow_up.png, arrow_down.png,
// freedom.png: 512 x 512, see-through, for materials/livingcity/graffiti/)
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const { FILTERS, lambda, scrawl, WHITE, ORANGE } = require('./art3.js');

// a sprayed stroke, with its overspray
const st = col => `fill="none" stroke="${col}" stroke-linecap="round" stroke-linejoin="round"`;
const spray = (d, col, w) => `<path d="${d}" ${st(col)} stroke-width="${w * 1.9}" opacity=".28" filter="url(#over)"/><path d="${d}" ${st(col)} stroke-width="${w}" filter="url(#spray)"/>`;
// an arrow pointing left, drawn by hand in three strokes, from x 300 to 60 around y 0; then turned
const ARROW = 'M300,6 Q210,-10 70,4 M150,-74 Q104,-30 62,4 Q108,40 156,82';
function arrow(turn, cx, cy, runs) {
  let s = `<g transform="translate(${cx},${cy}) rotate(${turn}) translate(-180,0)">` + spray(ARROW, ORANGE, 30) + '</g>';
  for (const [x, y, len, w] of runs) s += `<path d="M${x},${y} L${x},${y + len}" ${st(ORANGE)} stroke-width="${w}" filter="url(#spray)"/>`;
  return s;
}
const MARKS = {
  arrow_left: () => arrow(0, 196, 256, [[150, 268, 70, 9], [236, 262, 44, 7], [318, 270, 96, 8]]) + lambda(412, 256, 1.55, ORANGE),
  arrow_right: () => arrow(180, 316, 256, [[362, 268, 80, 9], [280, 262, 40, 7], [196, 270, 58, 8]]) + lambda(100, 256, 1.55, ORANGE),
  arrow_up: () => arrow(90, 256, 196, [[176, 180, 60, 8], [334, 196, 84, 8]]) + lambda(256, 412, 1.55, ORANGE),
  arrow_down: () => arrow(-90, 256, 316, [[178, 330, 54, 8], [336, 350, 70, 8], [256, 440, 44, 9]]) + lambda(256, 100, 1.55, ORANGE),
  freedom: () => scrawl(['FREEDOM', 256, 196, 100, -6, WHITE]) + scrawl(['THIS WAY', 256, 322, 92, -6, ORANGE]) + lambda(256, 430, 1.1, ORANGE),
};

(async () => {
  const out = process.argv[2] || path.join(__dirname, 'out');
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const pg = await browser.newPage({ viewport: { width: 512, height: 512 }, deviceScaleFactor: 1 });
  for (const [name, draw] of Object.entries(MARKS)) {
    await pg.setContent(`<!doctype html><html><head><style>html,body{margin:0;background:transparent}svg{display:block}</style></head><body>
<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="0 0 512 512"><defs>${FILTERS}</defs>${draw()}</svg></body></html>`);
    await pg.screenshot({ path: path.join(out, name + '.png'), omitBackground: true });
  }
  await browser.close();
})();
