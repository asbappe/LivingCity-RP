// Checks the VDC Saver extension (vdc_saver/) in Chromium against a fake wiki: nothing reaches the
// real site. A visit saves the page, "linked pages" and the whole-wiki save list and save pages (with
// the wiki's bot check asking once mid-way), other games are left out by name and by category, the
// cleaner removes them from pages saved before (and goes back to the save it interrupted), and the
// zip comes out right.
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
  0: ['Env fire', 'Func door', 'Func door/de', 'Func door/zh-cn', 'Prop physics', 'Half-Life 2: Episode One',
    'Info player teamspawn', 'Left 4 Dead 2 level design', 'Es/Create a Mod', 'Pure Servers'],
  10: ['Template:KV'],
  14: ['Category:Entities'],
};
// Categories the wiki gives each page (what decides "other games" when the name does not).
const CATS = {
  'Func door': ['Half-Life 2 Entities', 'Team Fortress 2 Entities'],
  'Info player teamspawn': ['Team Fortress 2 Entities'],
  'Npc combine s': ['Half-Life 2 Entities'],
  'Pure Servers': ['Source', 'Source 2', 'Dedicated Server'],
  'Point viewcontrol survivor': ['Left 4 Dead 2 Entities'],
  'Env sprite': ['Half-Life 2 Entities', 'Portal 2 Entities'],
};
let challengeLeft = 1;
const log = [];

// An open category page: every kind of link, and members only the API lists (the page shows 200 at most).
const CATEGORY_LINKS = `<p><a href="/wiki/Func_door">already saved</a> <a href="/wiki/Func_door/de">translation</a>
<a href="/wiki/Env_fire">fire</a> <a href="/wiki/Prop_physics#Keyvalues">a section</a> <a href="/wiki/Template:KV">template</a>
<a href="/w/index.php?title=Missing_page&action=edit&redlink=1" class="new">red link</a> <a href="/wiki/Special:RecentChanges">special</a>
<a href="/wiki/File:Door.png">image</a> <a href="https://en.wikipedia.org/wiki/Door">outside</a> <a href="/wiki/Category:HL2_entities">itself</a>
<a href="/wiki/Info_player_teamspawn">TF2 by category</a> <a href="/wiki/Team_Fortress_2_level_design">TF2 by name</a>
<a href="/wiki/Ko/Making_a_Mod">old-style translation</a> <a href="/wiki/Pure_Servers">Source and Source 2</a></p>`;
const MEMBERS = [{ title: 'Npc combine s', ns: 0 }, { title: 'Category:HL2 NPCs', ns: 14 }, { title: 'File:Combine.jpg', ns: 6 }];
const requested = [];

function articleHtml(name) {
  const ns = name.startsWith('Category:') ? 14 : 0;
  return `<!doctype html><html><head><title>${name}</title>
<link rel="EditURI" type="application/rsd+xml" href="${WIKI}/w/api.php?action=rsd">
<script>RLCONF={"wgPageName":${JSON.stringify(name)},"wgNamespaceNumber":${ns},"wgAction":"view","wgArticleId":12};</script>
</head><body><div id="mw-content-text"><div class="mw-parser-output">
<p>A door that moves.</p><h2>Keyvalues<span class="mw-editsection">[edit]</span></h2><p>Speed</p>
${ns === 14 ? CATEGORY_LINKS : ''}
</div></div><div id="catlinks"><ul>${(CATS[name.replace(/_/g, ' ')] || []).map((c) => `<li><a href="/wiki/Category:${c}">${c}</a></li>`).join('')}
<li><a href="/wiki/Category:TF2_entities">not in the body</a></li></ul></div></body></html>`;
}

function api(q) {
  if (q.get('list') === 'categorymembers') {
    const from = Number(q.get('cmcontinue') || 0);
    const res = { query: { categorymembers: MEMBERS.slice(from, from + 2) } };
    if (from + 2 < MEMBERS.length) res.continue = { cmcontinue: String(from + 2), continue: '-||' };
    return res;
  }
  if (q.get('prop') === 'categories') {
    const titles = q.get('titles').split('|');
    const second = q.has('clcontinue');
    const pages = titles.map((t, i) => {
      const p = { pageid: i + 1, ns: t.startsWith('Template:') ? 10 : t.startsWith('Category:') ? 14 : 0, title: t };
      const inThisPiece = titles.length <= 2 || (second ? i >= 2 : i < 2);
      if (inThisPiece && CATS[t]) p.categories = CATS[t].map((c) => ({ ns: 14, title: 'Category:' + c }));
      return p;
    });
    const res = { query: { pages } };
    if (titles.length > 2 && !second) res.continue = { clcontinue: '3|x', continue: '||' };
    return res;
  }
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
      if (q.get('prop') === 'revisions' && !q.has('rvcontinue')) requested.push(...q.get('titles').split('|'));
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

  const status = () => popup.textContent('#status');
  const waitStatus = (fn, timeout = 60000) => popup.waitForFunction(fn, null, { timeout });
  const wiki = await ctx.newPage();
  await wiki.goto(WIKI + '/wiki/Func_door');
  const popup = await ctx.newPage();
  await popup.goto(`chrome-extension://${id}/popup.html`);
  await popup.waitForFunction(() => Number(document.getElementById('count').textContent) >= 2, null, { timeout: 15000 });
  console.log('visit saved:', await popup.textContent('#count'), 'files');
  const tf2 = await ctx.newPage();
  await tf2.goto(WIKI + '/wiki/Info_player_teamspawn'); // another game's page: not saved

  const category = await ctx.newPage();
  await category.goto(WIKI + '/wiki/Category:HL2_entities');
  await popup.waitForFunction(() => Number(document.getElementById('count').textContent) >= 4, null, { timeout: 15000 });
  await popup.click('summary');
  await popup.fill('#delay', '0.5');
  await popup.dispatchEvent('#delay', 'change');
  await popup.click('#linked');
  await waitStatus(() => document.getElementById('status').textContent.startsWith('Done'));
  console.log('linked:', await popup.textContent('#note'), '|', await status());
  const linkedNote = await popup.textContent('#note');
  const linkedAsked = [...requested];
  await popup.click('#linked');
  await waitStatus(() => document.getElementById('note').textContent.includes('Nothing new'), 15000);
  console.log('linked again:', await popup.textContent('#note'));

  // Pages saved before the filter (no categories), then a whole-wiki save paused while listing.
  await sw.evaluate(() => putFiles([
    { path: 'wikitext/Main/Point_viewcontrol_survivor.wiki', title: 'Point viewcontrol survivor', ns: 0, kind: 'wikitext', text: 'old' },
    { path: 'text/Main/Point_viewcontrol_survivor.txt', title: 'Point viewcontrol survivor', ns: 0, kind: 'text', text: 'old' },
    { path: 'wikitext/Main/Env_sprite.wiki', title: 'Env sprite', ns: 0, kind: 'wikitext', text: 'old sprite' },
    { path: 'wikitext/Main/Team_Fortress_2_level_design.wiki', title: 'Team Fortress 2 level design', ns: 0, kind: 'wikitext', text: 'old' },
    { path: 'wikitext/Main/Ko/Making_a_Mod.wiki', title: 'Ko/Making a Mod', ns: 0, kind: 'wikitext', text: 'old' },
  ]));
  const delay = async (sec) => { await popup.fill('#delay', String(sec)); await popup.dispatchEvent('#delay', 'change'); };
  await delay(3); // slow enough to pause it mid-way
  await popup.click('#start');
  await waitStatus(() => document.getElementById('status').textContent.startsWith('Listing'), 30000);
  await popup.click('#pause');
  await waitStatus(() => document.getElementById('start').textContent === 'Resume', 15000);
  await popup.click('#clean');
  await waitStatus(() => document.getElementById('status').textContent.startsWith('Removed'), 30000);
  const cleanNote = await popup.textContent('#note');
  const cleanStatus = await status();
  console.log('clean:', cleanNote, '|', cleanStatus);
  await delay(0.5);
  await popup.click('#start');
  await waitStatus(() => document.getElementById('status').textContent.startsWith('Done:'));
  const wholeStatus = await status();
  console.log('whole wiki:', wholeStatus);
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
    ['linked: pages, sections, templates, members', ['Env fire', 'Prop physics', 'Template:KV', 'Npc combine s', 'Category:HL2 NPCs', 'Pure Servers'].every((t) => linkedAsked.includes(t))],
    ['linked: already saved not asked again', linkedAsked.filter((t) => t === 'Func door').length === 1],
    ['linked: no red links, special pages, images, outside, footer, translations',
      !linkedAsked.some((t) => /Missing|Special|File:|^Door$|TF2|\/de$|Wikipedia|^Ko\//i.test(t))],
    ['other game by name: never asked for', !requested.includes('Team Fortress 2 level design') && !requested.includes('Left 4 Dead 2 level design')],
    ['other game by category: categories asked, page not', !requested.includes('Info player teamspawn') && linkedNote.includes('1 from other games left out')],
    ['other game visited: not saved', !exists('text/Main/Info_player_teamspawn.txt') && !exists('wikitext/Main/Info_player_teamspawn.wiki')],
    ['shared page kept (Half-Life 2 and TF2)', exists('wikitext/Main/Func_door.wiki')],
    ['Source and Source 2 page kept', exists('wikitext/Main/Pure_Servers.wiki')],
    ['clean: by name and by category', cleanStatus.startsWith('Removed 3 pages') && cleanNote.startsWith('Removed 2 by their names')],
    ['clean: removed', !exists('wikitext/Main/Point_viewcontrol_survivor.wiki') && !exists('text/Main/Point_viewcontrol_survivor.txt') &&
      !exists('wikitext/Main/Team_Fortress_2_level_design.wiki') && !exists('wikitext/Main/Ko/Making_a_Mod.wiki')],
    ['clean: kept and given categories', exists('wikitext/Main/Env_sprite.wiki') && /Env sprite\t.*Half-Life 2 Entities/.test(read('index.tsv'))],
    ['clean: back to the paused save, which finishes', cleanStatus.includes('press Resume') && wholeStatus.includes('from other games left out')],
    ['old-style translations skipped', !exists('wikitext/Main/Es/Create_a_Mod.wiki')],
    ['linked: members saved', exists('wikitext/Main/Npc_combine_s.wiki') && exists('wikitext/Category/HL2_NPCs.wiki')],
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
