// The backs of the game's windows, one per look (cl_livingcity_theme.lua), and a preview sheet.
// Run: node ui.js OUTDIR   (writes combine.png, rust.png, concrete.png at 512 x 512, and ui_preview.png)
const fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const S = 512;
const wrap = (defs, body) => `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}"><defs>${defs}
<radialGradient id="edge" cx="50%" cy="50%" r="75%"><stop offset="55%" stop-color="#000" stop-opacity="0"/><stop offset="100%" stop-color="#000" stop-opacity=".55"/></radialGradient></defs>${body}<rect width="${S}" height="${S}" fill="url(#edge)"/></svg>`;
const noise = (id, f, oct, seed, m) => `<filter id="${id}" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="${f}" numOctaves="${oct}" seed="${seed}"/><feColorMatrix values="${m}"/></filter>`;
const TEX = {
  // black glass: a faint grid, a cold glow from one corner
  combine: () => {
    let g = '';
    for (let i = 0; i <= S; i += 32) g += `<path d="M${i},0 L${i},${S} M0,${i} L${S},${i}" stroke="#3aa6bb" stroke-width="1" opacity=".07"/>`;
    for (let i = 0; i < 9; i++) g += `<rect x="${(i * 97) % 480}" y="${(i * 151) % 480}" width="${30 + (i * 37) % 60}" height="3" fill="#48c8de" opacity=".10"/>`;
    return wrap(noise('n', 0.9, 2, 3, '0 0 0 0 0.5  0 0 0 0 0.8  0 0 0 0 0.9  0 0 0 -1.2 0.62') +
      `<radialGradient id="glow" cx="12%" cy="8%" r="80%"><stop offset="0" stop-color="#1c4a5c" stop-opacity=".9"/><stop offset="100%" stop-color="#0a1018" stop-opacity="0"/></radialGradient>`,
      `<rect width="${S}" height="${S}" fill="#0a1018"/><rect width="${S}" height="${S}" fill="url(#glow)"/>${g}<rect width="${S}" height="${S}" filter="url(#n)" opacity=".16"/>`);
  },
  // scrap plate: rust blooming through dark steel, scratches, a weld seam
  rust: () => {
    let sc = '';
    for (let i = 0; i < 26; i++) { const x = (i * 131) % 500, y = (i * 211) % 500, l = 30 + (i * 53) % 120; sc += `<path d="M${x},${y} l${l},${(i % 5) - 2}" stroke="${i % 3 ? '#000' : '#d8a070'}" stroke-width="${1 + (i % 2)}" opacity="${i % 3 ? 0.35 : 0.16}"/>`; }
    return wrap(noise('blot', '0.012 0.02', 4, 8, '0 0 0 0 0.62  0 0 0 0 0.3  0 0 0 0 0.1  0 0 0 3.2 -1.5') + noise('blot2', '0.035', 3, 15, '0 0 0 0 0.34  0 0 0 0 0.16  0 0 0 0 0.07  0 0 0 3 -1.5') + noise('n', 0.8, 2, 4, '0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -1.6 1.0'),
      `<rect width="${S}" height="${S}" fill="#2a1d15"/><rect width="${S}" height="${S}" filter="url(#blot)" opacity=".3"/><rect width="${S}" height="${S}" filter="url(#blot2)" opacity=".5"/>${sc}` +
      `<path d="M0,330 C120,322 260,340 512,328" stroke="#0c0806" stroke-width="5" fill="none" opacity=".7"/><path d="M0,333 C120,325 260,343 512,331" stroke="#b9703a" stroke-width="1.5" fill="none" opacity=".35"/>` +
      `<rect width="${S}" height="${S}" filter="url(#n)" opacity=".5"/>`);
  },
  // poured concrete: grey grain, formwork seams, a water stain or two
  concrete: () => {
    return wrap(noise('blot', '0.01 0.016', 4, 5, '0 0 0 0 0.6  0 0 0 0 0.6  0 0 0 0 0.6  0 0 0 2.6 -1.3') + noise('dark', '0.02 0.05', 3, 12, '0 0 0 0 0.08  0 0 0 0 0.08  0 0 0 0 0.08  0 0 0 2.8 -1.5') + noise('n', 0.95, 2, 6, '0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -1.5 1.0') + noise('pit', 0.4, 1, 9, '0 0 0 0 0.05  0 0 0 0 0.05  0 0 0 0 0.05  0 0 0 14 -10.4'),
      `<rect width="${S}" height="${S}" fill="#35373a"/><rect width="${S}" height="${S}" filter="url(#blot)" opacity=".2"/><rect width="${S}" height="${S}" filter="url(#dark)" opacity=".7"/>` +
      `<path d="M0,170 L512,170 M0,342 L512,342" stroke="#000" stroke-width="2" opacity=".35"/><path d="M0,172 L512,172 M0,344 L512,344" stroke="#fff" stroke-width="1" opacity=".07"/>` +
      `<path d="M120,172 L118,300 M360,344 L364,470" stroke="#000" stroke-width="7" opacity=".14"/>` +
      `<rect width="${S}" height="${S}" filter="url(#pit)" opacity=".8"/><rect width="${S}" height="${S}" filter="url(#n)" opacity=".5"/>`);
  },
};

// the preview: the same numbers the game paints with (cl_livingcity_theme.lua)
const LOOKS = [
  { n: 'combine', who: 'Civil Protection, the Administration', tex: 'combine', head: '#0d1822', plate: '#142230', hot: '#1c3446', line: '#48c8de', dim: '#266878', text: '#d6ecf2', accent: '#48c8de', label: 'OVERWATCH LINK  //  SECTOR ACTIVE', title: 'Unit tools', body: 'Citizen 4471 is wanted for Vandalism. Last seen near the ration line.', btn: ['Detain', 'Search', 'Request backup'] },
  { n: 'rebel', who: 'The Resistance', tex: 'rust', head: '#4a2e1a', plate: '#3e291a', hot: '#58381e', line: '#e28a2c', dim: '#764824', text: '#f2e4ce', accent: '#e8912a', label: 'NO GODS  NO MASTERS  NO BENEFACTORS', title: 'Black market', body: 'Spray cans, paste-ups, a pistol if you have the credits. Keep your voice down.', btn: ['Spray cans (3)', 'Paste-ups (3)', 'Leave'] },
  { n: 'citizen', who: 'Citizens', tex: 'concrete', head: '#545759', plate: '#484b4d', hot: '#5c6063', line: '#7e8284', dim: '#222324', text: '#e4e4de', accent: '#708caa', label: 'UNION RESIDENT SERVICES', title: 'Citizen Information', body: 'All residents are assigned labor. Report to Labor Assignment for your shift.', btn: ['Where do I get rations?', 'Where do I sleep?', 'Leave'] },
  { n: 'custody', who: 'Anyone, while being questioned', tex: 'combine', head: '#7c1612', plate: '#161a1e', hot: '#2c3238', line: '#e8ecf0', dim: '#6e747a', text: '#eceef0', accent: '#ce342a', label: 'DETAINED.  ANSWER.  COMPLY.', title: 'Interrogation', body: 'Where were you during the curfew? Think carefully before you answer.', btn: ['I was in my block.', 'I do not remember.', 'Say nothing'] },
];
function win(l, dir) {
  const W = 500, H = 300;
  let o = '';
  const R = (c, x, y, w, h, op = 1) => `<div style="position:absolute;left:${x}px;top:${y}px;width:${w}px;height:${h}px;background:${c};opacity:${op}"></div>`;
  const rivet = (x, y) => R('rgba(0,0,0,.5)', x - 3, y - 2, 7, 7) + R(l.dim, x - 3, y - 3, 6, 6) + R(l.line, x - 2, y - 2, 2, 2);
  if (l.n === 'combine') {
    o += `<div style="position:absolute;inset:0;border:1px solid ${l.dim}"></div>` + R(l.line, 0, 22, W, 2) + R(l.line, 0, 0, 16, 2) + R(l.line, 0, 0, 2, 16) + R(l.line, W - 16, H - 2, 16, 2) + R(l.line, W - 2, H - 16, 2, 16);
    for (let i = 0; i < 6; i++) o += R(i % 2 ? l.dim : l.line, 8 + i * 7, H - 7, 5, 3);
  } else if (l.n === 'rebel') {
    o += `<div style="position:absolute;inset:0;border:3px solid rgba(0,0,0,.47)"></div>` + R(l.line, 0, 22, W, 2) + R('rgba(0,0,0,.47)', 3, 24, W - 6, 3);
    for (const x of [W - 124, W - 108]) o += `<div style="position:absolute;left:${x}px;top:3px;width:6px;height:18px;background:${l.accent};transform:skewX(-24deg);opacity:.9"></div>`;
    o += rivet(9, 33) + rivet(W - 9, 33) + rivet(9, H - 9) + rivet(W - 9, H - 9) + rivet(90, H - 9) + rivet(210, H - 9) + rivet(330, H - 9);
  } else if (l.n === 'custody') {
    for (let i = 0; i < 10; i++) o += R('#fff', 0, 24 + i * 5, W, 5, (22 - i * 2) / 255);
    o += `<div style="position:absolute;inset:0;border:1px solid ${l.line}"></div>` + R(l.accent, 0, 24, W, 2) + R(l.accent, 0, H - 4, W, 4);
  } else {
    o += R(l.dim, 0, 23, W, 1) + R(l.dim, 0, H - 3, W, 3) + R(l.dim, W - 2, 0, 2, H) + R(l.accent, 0, 24, 4, H - 27) + `<div style="position:absolute;right:10px;bottom:6px;font:800 11px 'Liberation Sans';color:${l.line}">FORM 27-B</div>`;
  }
  const btn = (t, i) => {
    let b = `<div style="position:absolute;left:16px;top:${150 + i * 34}px;width:${W - 32}px;height:28px;background:${i === 0 ? l.hot : l.plate};color:${l.text};font:14px 'Liberation Sans';line-height:28px;text-align:center;box-sizing:border-box;`;
    if (l.n === 'combine') b += `border-left:3px solid ${l.line};${i === 0 ? `outline:1px solid ${l.line};outline-offset:-1px;` : ''}`;
    if (l.n === 'rebel') b += `border-top:1px solid rgba(255,255,255,.1);border-bottom:2px solid rgba(0,0,0,.47);${i === 0 ? `outline:1px solid ${l.line};outline-offset:-1px;` : ''}`;
    if (l.n === 'custody') b += `border:1px solid ${l.dim};${i === 0 ? `border-bottom:2px solid ${l.accent};` : ''}`;
    if (l.n === 'citizen') b += `border-top:1px solid rgba(255,255,255,.1);border-bottom:2px solid ${l.dim};${i === 0 ? `border-left:3px solid ${l.accent};` : ''}`;
    return b + `">${t}</div>`;
  };
  return `<div style="margin:0 0 6px 0;font:700 15px 'Liberation Sans';color:#ddd">${l.who}</div><div style="position:relative;width:${W}px;height:${H}px;background:url(file://${dir}/${l.tex}.png);background-size:${W}px ${H}px;${l.n === 'custody' ? 'filter:saturate(.3) brightness(.62);' : ''}overflow:hidden"></div>
<div style="position:relative;width:${W}px;height:${H}px;margin-top:-${H}px;overflow:hidden">${R(l.head, 0, 0, W, 24)}${o}
<div style="position:absolute;left:8px;top:4px;font:700 13px 'Liberation Sans';color:${l.text}">${l.title}</div>
<div style="position:absolute;right:${l.n === 'rebel' ? 136 : 112}px;top:6px;font:800 11px 'Liberation Sans';color:${l.n === 'custody' ? l.text : l.line}">${l.label}</div>
<div style="position:absolute;right:8px;top:3px;font:700 14px 'Liberation Sans';color:${l.text}">x</div>
<div style="position:absolute;left:18px;top:44px;width:${W - 36}px;font:15px 'Liberation Sans';line-height:21px;color:${l.text}">${l.body}</div>
${l.btn.map(btn).join('')}</div>`;
}
(async () => {
  const out = path.resolve(process.argv[2] || path.join(__dirname, 'out'));
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const pg = await browser.newPage({ viewport: { width: S, height: S }, deviceScaleFactor: 1 });
  for (const [name, f] of Object.entries(TEX)) { await pg.setContent(`<body style="margin:0">${f()}</body>`); await pg.screenshot({ path: path.join(out, name + '.png') }); }
  await pg.setViewportSize({ width: 1080, height: 720 });
  const html = `<body style="margin:0;background:#1a1a1a;padding:20px;display:grid;grid-template-columns:500px 500px;gap:28px 40px">${LOOKS.map(l => `<div>${win(l, out)}</div>`).join('')}</body>`;
  fs.writeFileSync(path.join(out, 'ui.html'), html);
  await pg.goto('file://' + path.join(out, 'ui.html')); await pg.waitForLoadState('networkidle');
  await pg.screenshot({ path: path.join(out, 'ui_preview.png') });
  await browser.close();
})();
