// Runs in every developer.valvesoftware.com tab. It uses the tab's own pass through the
// wiki's bot check, so its requests look like the page's own.
(() => {
  if (window.vdcSaverLoaded) return;
  window.vdcSaverLoaded = true;

  // Translated copies are subpages named after a language ("Func_door/de").
  const LANGS = new Set(('ar bg ca cs da de el eo es et fa fi fr he hi hr hu id it ja ka ko lt lv ms nl no ' +
    'pl pt pt-br pt-pt ro ru sk sl sr sv th tr uk vi zh zh-cn zh-hans zh-hant zh-hk zh-tw').split(' '));
  const NS_FOLDER = { 0: 'Main', 2: 'User', 4: 'Project', 6: 'File', 10: 'Template', 12: 'Help', 14: 'Category' };
  const BATCH = 50;

  class Challenge extends Error {}
  class Busy extends Error {
    constructor(why, waitSec) { super(why); this.waitSec = waitSec; }
  }

  const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
  const send = (msg) => chrome.runtime.sendMessage(msg);

  function pageConfig() {
    for (const s of document.querySelectorAll('script')) {
      const t = s.textContent;
      if (!t.includes('"wgPageName"')) continue;
      const get = (key) => {
        const m = t.match(new RegExp('"' + key + '":("(?:[^"\\\\]|\\\\.)*"|-?\\d+|true|false|null)'));
        return m ? JSON.parse(m[1]) : undefined;
      };
      return {
        pageName: get('wgPageName'),
        ns: get('wgNamespaceNumber'),
        action: get('wgAction'),
        articleId: get('wgArticleId'),
      };
    }
    return null;
  }

  function apiPath() {
    const link = document.querySelector('link[rel="EditURI"]');
    try {
      if (link) return new URL(link.href, location.origin).pathname;
    } catch (e) { /* fall through */ }
    return '/w/api.php';
  }

  function isTranslation(title) {
    const i = title.lastIndexOf('/');
    return i > 0 && LANGS.has(title.slice(i + 1));
  }

  // Namespace of a linked title; null for ones not worth saving (special pages, images, talk, users).
  const NS_BY_PREFIX = { template: 10, category: 14, help: 12 };
  const SKIP_PREFIX = new Set(['special', 'file', 'image', 'media', 'user', 'talk', 'mediawiki', 'module',
    'project', 'valve developer community', 'gadget', 'gadget definition']);
  function nsOf(title) {
    const i = title.indexOf(':');
    if (i < 0) return 0;
    const p = title.slice(0, i).trim().toLowerCase();
    if (p in NS_BY_PREFIX) return NS_BY_PREFIX[p];
    if (SKIP_PREFIX.has(p) || p.endsWith(' talk')) return null;
    return 0; // "Half-Life 2: Episode One" is an article
  }

  function titleFromHref(href) {
    let u;
    try { u = new URL(href, location.href); } catch (e) { return null; }
    if (u.origin !== location.origin || !u.pathname.startsWith('/wiki/') || u.search) return null;
    let t;
    try { t = decodeURIComponent(u.pathname.slice(6)); } catch (e) { return null; }
    t = t.replace(/_/g, ' ').trim();
    return t ? t.charAt(0).toUpperCase() + t.slice(1) : null;
  }

  // Every page this tab links to from its article body, and every member when it is a category.
  async function collectLinks(skipTranslations) {
    const cfg = pageConfig();
    if (!cfg) return { titles: [] };
    const self = String(cfg.pageName).replace(/_/g, ' ');
    const out = new Map();
    const add = (title, ns) => {
      if (ns === null || title === self || out.has(title)) return;
      if (skipTranslations && isTranslation(title)) return;
      out.set(title, [title, ns, pathFor('wikitext', title, ns)]);
    };
    const body = document.querySelector('#mw-content-text');
    for (const a of body ? body.querySelectorAll('a[href]') : []) {
      if (a.classList.contains('new')) continue; // red link: no such page yet
      const t = titleFromHref(a.getAttribute('href'));
      if (t) add(t, nsOf(t));
    }
    if (cfg.ns === 14) {
      try {
        let cont = {};
        for (let round = 0; round < 50; round++) {
          const j = await api(Object.assign({ action: 'query', list: 'categorymembers', cmtitle: self, cmtype: 'page|subcat', cmlimit: 'max' }, cont));
          for (const m of (j.query && j.query.categorymembers) || []) {
            if ([0, 10, 12, 14].includes(m.ns)) add(m.title, m.ns);
          }
          if (!(j.continue && j.continue.cmcontinue)) break;
          cont = j.continue;
          await sleep(500);
        }
      } catch (e) {
        // The links shown on the page are still there.
      }
    }
    return { page: self, titles: [...out.values()] };
  }

  function pathFor(kind, title, ns) {
    let name = title;
    if (ns !== 0) {
      const i = name.indexOf(':');
      if (i >= 0) name = name.slice(i + 1);
    }
    name = name.replace(/ /g, '_').replace(/[\x00-\x1f\\]/g, '_');
    name = name.split('/').map((p) => {
      if (p === '' || p === '.' || p === '..') return '_' + p.replace(/\./g, '_');
      return p.length > 180 ? p.slice(0, 180) : p;
    }).join('/');
    const folder = NS_FOLDER[ns] || 'ns' + ns;
    return kind + '/' + folder + '/' + name + (kind === 'wikitext' ? '.wiki' : '.txt');
  }

  async function api(params) {
    const url = new URL(apiPath(), location.origin);
    const all = Object.assign({ format: 'json', formatversion: '2', maxlag: '5' }, params);
    for (const [k, v] of Object.entries(all)) url.searchParams.set(k, String(v));
    let r;
    try {
      r = await fetch(url, { credentials: 'same-origin', headers: { Accept: 'application/json' } });
    } catch (e) {
      throw new Busy('network: ' + e.message, 30);
    }
    if (r.url.includes('/.within.website')) throw new Challenge('check');
    const retry = parseInt(r.headers.get('retry-after') || '', 10);
    if (r.status === 429 || r.status >= 500) throw new Busy('HTTP ' + r.status, retry || 0);
    if (!(r.headers.get('content-type') || '').includes('json')) throw new Challenge('not json');
    const j = await r.json();
    if (j.error) {
      if (j.error.code === 'maxlag') throw new Busy('the wiki is lagging', retry || 5);
      throw new Error(j.error.code + ': ' + j.error.info);
    }
    return j;
  }

  // Wikitext for up to 50 titles. The wiki may answer in pieces (rvcontinue) when the pages are big.
  async function fetchWikitext(titles) {
    const out = [];
    let cont = {};
    for (let round = 0; round < 60; round++) {
      const j = await api(Object.assign({
        action: 'query', prop: 'revisions', rvprop: 'content|timestamp|ids', rvslots: 'main',
        redirects: 1, titles: titles.join('|'),
      }, cont));
      for (const p of (j.query && j.query.pages) || []) {
        if (p.missing || p.invalid || !p.revisions || !p.revisions.length) continue;
        const rev = p.revisions[0];
        const text = rev.slots && rev.slots.main ? rev.slots.main.content : rev.content;
        if (typeof text !== 'string') continue;
        out.push({
          path: pathFor('wikitext', p.title, p.ns), title: p.title, ns: p.ns, kind: 'wikitext',
          text, rev: rev.revid, ts: rev.timestamp,
        });
      }
      if (j.continue && j.continue.rvcontinue) cont = j.continue;
      else break;
    }
    return out;
  }

  // ---- The page you are looking at ----

  async function saveThisPage(cfg) {
    const { saveVisits } = await chrome.storage.local.get({ saveVisits: true });
    if (!saveVisits) return;
    if (cfg.action !== 'view' || !(cfg.articleId > 0) || cfg.ns < 0) return;
    const q = new URLSearchParams(location.search);
    if (q.has('oldid') || q.has('diff')) return;
    const title = String(cfg.pageName).replace(/_/g, ' ');
    const files = [];
    const body = document.querySelector('#mw-content-text');
    if (body) {
      const shown = body.innerText.replace(/\[edit(?: \| edit source)?\]/g, '').replace(/\n{3,}/g, '\n\n').trim();
      files.push({
        path: pathFor('text', title, cfg.ns), title, ns: cfg.ns, kind: 'text',
        text: title + '\n' + location.href.split('#')[0] + '\n\n' + shown + '\n',
        ts: new Date().toISOString(),
      });
    }
    try {
      files.push(...await fetchWikitext([title]));
    } catch (e) {
      // The page as shown is still saved; the whole-wiki save sorts out the check.
    }
    if (files.length) await send({ type: 'save', files });
  }

  // ---- The whole wiki ----

  let crawling = false;
  let titlesCache = null;
  let titlesJob = null;
  let myTabId = null;

  async function getCrawl() {
    return (await chrome.storage.local.get('crawl')).crawl;
  }

  // Merge into the stored state, so a Pause pressed meanwhile is not overwritten.
  async function update(patch) {
    const cur = (await getCrawl()) || {};
    Object.assign(cur, patch);
    await chrome.storage.local.set({ crawl: cur });
    return cur;
  }

  async function listStep(st) {
    const ns = st.namespaces[st.nsIndex];
    if (ns === undefined) {
      await update({ phase: 'fetch', fetchPos: 0, status: 'Listed ' + (st.listed || 0) + ' pages. Saving them...' });
      return;
    }
    const params = { action: 'query', list: 'allpages', apnamespace: ns, aplimit: 'max', apfilterredir: 'nonredirects' };
    if (st.apcontinue) params.apcontinue = st.apcontinue;
    const j = await api(params);
    const pages = (j.query && j.query.allpages) || [];
    const keep = pages.filter((p) => !(st.skipTranslations && isTranslation(p.title))).map((p) => [p.title, p.ns]);
    if (((await getCrawl()) || {}).jobId !== st.jobId) return; // replaced meanwhile
    const { crawlTitles = [] } = await chrome.storage.local.get('crawlTitles');
    crawlTitles.push(...keep);
    const more = j.continue && j.continue.apcontinue;
    await chrome.storage.local.set({ crawlTitles });
    await update({
      apcontinue: more || null,
      nsIndex: more ? st.nsIndex : st.nsIndex + 1,
      listed: crawlTitles.length,
      status: 'Listing pages: ' + crawlTitles.length + ' found so far',
    });
  }

  async function fetchStep(st) {
    if (!titlesCache || titlesJob !== st.jobId) {
      titlesCache = (await chrome.storage.local.get('crawlTitles')).crawlTitles || [];
      titlesJob = st.jobId;
    }
    const pos = st.fetchPos || 0;
    if (pos >= titlesCache.length) {
      await update({ phase: 'done', running: false, status: 'Done: all ' + titlesCache.length + ' pages saved. Press Download zip.' });
      return;
    }
    const batch = titlesCache.slice(pos, pos + BATCH);
    const files = await fetchWikitext(batch.map((b) => b[0]));
    if (files.length) await send({ type: 'save', files });
    if (((await getCrawl()) || {}).jobId !== st.jobId) return; // the queue changed: start on the new one
    const next = pos + batch.length;
    await update({ fetchPos: next, status: 'Saving pages: ' + next + ' of ' + titlesCache.length });
  }

  async function crawl() {
    if (crawling) return;
    crawling = true;
    titlesCache = null;
    let failures = 0;
    let backoff = 15;
    try {
      for (;;) {
        const st = await getCrawl();
        if (!st || !st.running || st.tabId !== myTabId) break;
        try {
          if (st.phase === 'list') await listStep(st);
          else if (st.phase === 'fetch') await fetchStep(st);
          else break;
          failures = 0;
          backoff = 15;
        } catch (e) {
          if (e instanceof Challenge) {
            const now = Date.now();
            const recent = (st.challengeReloads || []).filter((t) => now - t < 10 * 60 * 1000);
            if (recent.length >= 3) {
              await update({ running: false, status: 'Paused: the wiki keeps asking for its check. Reload this page, wait for it, then press Resume.' });
              break;
            }
            recent.push(now);
            await update({ challengeReloads: recent, status: 'The wiki asked for its check again: reloading the page, the save carries on by itself.' });
            location.reload();
            return;
          }
          if (e instanceof Busy) {
            const wait = Math.max(e.waitSec || 0, backoff);
            backoff = Math.min(600, backoff * 2);
            await update({ status: 'The wiki is busy (' + e.message + '): waiting ' + wait + ' s' });
            await sleep(wait * 1000);
            continue;
          }
          failures++;
          await update({ lastError: String(e.message || e), status: 'Error: ' + (e.message || e) + ' (try ' + failures + ' of 5)' });
          if (failures >= 5) {
            await update({ running: false, status: 'Paused after 5 errors in a row: ' + (e.message || e) });
            break;
          }
          await sleep(10000);
          continue;
        }
        const now = await getCrawl();
        await sleep(Math.max(500, (now && now.delayMs) || 1500));
      }
    } finally {
      crawling = false;
    }
  }

  chrome.runtime.onMessage.addListener((msg, sender, reply) => {
    if (msg && msg.type === 'crawl:go') {
      myTabId = msg.tabId;
      crawl();
      reply({ ok: true });
    } else if (msg && msg.type === 'links:collect') {
      collectLinks(!!msg.skipTranslations).then(reply, () => reply({ titles: [] }));
      return true;
    }
  });

  (async () => {
    if (location.pathname.startsWith('/.within.website')) return; // the check page itself
    const cfg = pageConfig();
    if (!cfg) return;
    saveThisPage(cfg).catch(() => {});
    const r = await send({ type: 'hello' }).catch(() => null);
    if (r && r.tabId != null) myTabId = r.tabId;
    if (r && r.resume) crawl();
  })();
})();
