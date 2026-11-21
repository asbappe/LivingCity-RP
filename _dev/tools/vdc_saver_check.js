// Checks the VDC Saver extension (vdc_saver/) in Chromium against a fake wiki: nothing reaches the
// real site. A visit saves the page, the whole-wiki save lists and saves pages (with the wiki's
// bot check asking once mid-way), and the zip comes out right.
//   node _dev/tools/vdc_saver_check.js [OUT_DIR]
// Ends "VDC SAVER CHECK PASS". Needs Playwright with Chromium.
const { chromium } = require('playwright');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { execFileSync } = require('child_process');

const EXT = path.join(__dirname, 'vdc_saver');
const OUT = process.argv[2] || fs.mkdtempSync(path.join(os.tmpdir(), 'vdc_check_'));
const WIKI = 'https://developer.valvesoftware.com';

const PAGES = {
  0: ['Env fire', 'Func door', 'Func door/de', 'Func door/zh-cn', 'Prop physics', 'Half-Life 2: Episode One'],
  10: ['Template:KV'],
  14: ['Category:Entities'],
};
let challengeLeft = 1;
const log = [];

function articleHtml(name) {
  return `<!doctype html><html><head><title>${name}</title>
<link rel="EditURI" type="application/rsd+xml" href="${WIKI}/w/api.php?action=rsd">
<script>RLCONF={"wgPageName":${JSON.stringify(name)},"wgNamespaceNumber":0,"wgAction":"view","wgArticleId":12};</script>
</head><body><div id="mw-content-text"><div class="mw-parser-output">
<p>A door that moves.</p><h2>Keyvalues<span class="mw-editsection">[edit]</span></h2><p>Speed</p>
</div></div></body></html>`;
}

function api(q) {
  if (q.get('list') === 'allpages') {
    const all = PAGES[q.get('apnamespace')] || [];
    const from = Number(q.get('apcontinue') || 0);
    const res = { query: { allpages: all.slice(from, from + 2).map((t) => ({ title: t, ns: Number(q.get('apnamespace')) })) } };
    if (from + 2 < all.length) res.continue = { apcontinue: String(from + 2), continue: '-||' };
    return res;
  }
  if (q.get('prop') === 'revisions') {
    const titles = q.get('titles').split('|');
    const first = q.has('rvcontinue') ? 2 : 0;
    const pages = titles.map((t, i) => {
      const ns = t.startsWith('Template:') ? 10 : t.startsWith('Category:') ? 14 : 0;
      const p = { pageid: i + 1, ns, title: t };
      const inThisPiece = titles.length <= 2 || (first === 0 ? i < 2 : i >= 2);
      if (inThisPiece) p.revisions = [{ revid: 100 + i, timestamp: '2025-01-02T03:04:05Z', slots: { main: { content: `== ${t} ==\nwikitext of ${t}` } } }];
      return p;
    });
    const res = { query: { pages } };
    if (titles.length > 2 && first === 0) res.continue = { rvcontinue: '3|x', continue: '||' };
    return res;
  }
  return { error: { code: 'badparams', info: 'unknown' } };
}

(async () => {
  const profile = fs.mkdtempSync(path.join(os.tmpdir(), 'vdc_profile_'));
  const ctx = await chromium.launchPersistentContext(profile, {
    headless: true,
    channel: 'chromium',
    args: [`--disable-extensions-except=${EXT}`, `--load-extension=${EXT}`],
    acceptDownloads: true,
  });
  await ctx.route(WIKI + '/**', async (route) => {
    const url = new URL(route.request().url());
    if (url.pathname === '/w/api.php') {
      const q = url.searchParams;
      log.push(q.get('list') || q.get('prop'));
      if (q.get('prop') === 'revisions' && q.get('titles').includes('|') && challengeLeft > 0) {
        challengeLeft--;
        log.push('challenge');
        return route.fulfill({ status: 200, contentType: 'text/html', body: '<html>Making sure you are not a bot</html>' });
      }
      return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify(api(q)) });
    }
    const m = url.pathname.match(/^\/wiki\/(.+)$/);
    if (m) return route.fulfill({ status: 200, contentType: 'text/html', body: articleHtml(decodeURIComponent(m[1])) });
    return route.fulfill({ status: 404, body: 'no' });
  });

  let [sw] = ctx.serviceWorkers();
  if (!sw) sw = await ctx.waitForEvent('serviceworker');
  const id = sw.url().split('/')[2];

  const wiki = await ctx.newPage();
  await wiki.goto(WIKI + '/wiki/Func_door');
  const popup = await ctx.newPage();
  await popup.goto(`chrome-extension://${id}/popup.html`);
  await popup.waitForFunction(() => Number(document.getElementById('count').textContent) >= 2, null, { timeout: 15000 });
  console.log('visit saved:', await popup.textContent('#count'), 'files');

  await popup.click('summary');
  await popup.fill('#delay', '0.5');
  await popup.dispatchEvent('#delay', 'change');
  await popup.click('#start');
  await popup.waitForFunction(() => document.getElementById('status').textContent.startsWith('Done'), null, { timeout: 60000 });
  console.log('whole wiki:', await popup.textContent('#status'));
  console.log('requests:', log.join(' '));

  const [exportPage] = await Promise.all([ctx.waitForEvent('page'), popup.click('#download')]);
  const dl = await exportPage.waitForEvent('download', { timeout: 30000 });
  const zipPath = path.join(OUT, dl.suggestedFilename());
  await dl.saveAs(zipPath);
  await exportPage.waitForFunction(() => document.getElementById('msg').textContent.startsWith('Done'));
  console.log('export:', await exportPage.textContent('#msg'));
  await ctx.close();

  execFileSync('unzip', ['-tq', zipPath], { stdio: 'inherit' });
  const dir = path.join(OUT, 'unzipped');
  execFileSync('unzip', ['-oq', zipPath, '-d', dir]);
  const read = (p) => fs.readFileSync(path.join(dir, 'vdc', p), 'utf8');
  const exists = (p) => fs.existsSync(path.join(dir, 'vdc', p));
  const checks = [
    ['visited page as shown', read('text/Main/Func_door.txt').includes('A door that moves.')],
    ['edit links dropped', !read('text/Main/Func_door.txt').includes('[edit]')],
    ['wikitext of an article', read('wikitext/Main/Func_door.wiki').includes('wikitext of Func door')],
    ['answer in pieces joined', exists('wikitext/Main/Prop_physics.wiki') && exists('wikitext/Main/Half-Life_2:_Episode_One.wiki')],
    ['template', read('wikitext/Template/KV.wiki').includes('Template:KV')],
    ['category', exists('wikitext/Category/Entities.wiki')],
    ['translations skipped', !exists('wikitext/Main/Func_door/de.wiki') && !exists('wikitext/Main/Func_door/zh-cn.wiki')],
    ['bot check reloaded and carried on', log.includes('challenge')],
    ['index', read('index.tsv').split('\n').length >= 9],
    ['readme', read('README.txt').startsWith('Valve Developer Community pages')],
  ];
  let bad = 0;
  for (const [name, ok] of checks) { console.log((ok ? 'ok   ' : 'FAIL ') + name); if (!ok) bad++; }
  console.log(bad ? `VDC SAVER CHECK FAIL (${bad})` : 'VDC SAVER CHECK PASS');
  process.exit(bad ? 1 : 0);
})().catch((e) => { console.error(e); console.log('VDC SAVER CHECK FAIL'); process.exit(1); });
