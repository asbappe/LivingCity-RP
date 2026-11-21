const WIKI = 'https://developer.valvesoftware.com/';
const $ = (id) => document.getElementById(id);
const DEFAULTS = Object.assign({ saveVisits: true, englishOnly: true, namespaces: [0, 10, 14], delaySec: 1.5 }, VDC_FILTER_DEFAULTS);
const note = (t) => { $('note').textContent = t; };

async function settings() {
  return chrome.storage.local.get(DEFAULTS);
}

async function wikiTab() {
  const [active] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (active && active.url && active.url.startsWith(WIKI)) return active;
  const tabs = await chrome.tabs.query({ url: WIKI + '*' });
  return tabs.find((t) => !(t.url || '').includes('/.within.website')) || tabs[0] || null;
}

async function go(tabId) {
  try {
    await chrome.tabs.sendMessage(tabId, { type: 'crawl:go', tabId });
  } catch (e) {
    // The tab was open before the extension: reload it and it carries on by itself.
    await chrome.tabs.reload(tabId);
  }
}

async function refresh() {
  const { crawl } = await chrome.storage.local.get('crawl');
  const stats = await chrome.runtime.sendMessage({ type: 'stats' });
  $('count').textContent = stats && stats.total != null ? stats.total : '?';
  $('status').textContent = crawl ? crawl.status : 'Not started.';
  const running = !!(crawl && crawl.running);
  $('start').textContent = crawl && !running && crawl.phase !== 'done' ? 'Resume' : 'Save the whole wiki';
  $('start').disabled = running;
  $('pause').disabled = !running;
}

async function start() {
  note('');
  const tab = await wikiTab();
  if (!tab) return note('Open any developer.valvesoftware.com page first, then press this again.');
  const s = await settings();
  let { crawl } = await chrome.storage.local.get('crawl');
  if (!crawl || crawl.phase === 'done') {
    crawl = {
      running: true, tabId: tab.id, mode: 'whole', jobId: Date.now(), phase: 'list', nsIndex: 0, apcontinue: null,
      fetchPos: 0, listed: 0, namespaces: s.namespaces, skipTranslations: s.englishOnly,
      delayMs: Math.round(s.delaySec * 1000), challengeReloads: [], status: 'Starting...', startedAt: new Date().toISOString(),
    };
    await chrome.storage.local.set({ crawlTitles: [] });
  } else {
    Object.assign(crawl, { running: true, tabId: tab.id, challengeReloads: [], delayMs: Math.round(s.delaySec * 1000), status: 'Resuming...' });
  }
  await chrome.storage.local.set({ crawl });
  await go(tab.id);
  refresh();
}

async function pause() {
  const { crawl } = await chrome.storage.local.get('crawl');
  if (crawl) {
    crawl.running = false;
    crawl.status = 'Paused. Press Resume to carry on where it stopped.';
    await chrome.storage.local.set({ crawl });
  }
  refresh();
}

// Queue every page the open wiki tabs link to (and every member of an open category).
async function saveLinked() {
  note('');
  const tabs = (await chrome.tabs.query({ url: WIKI + '*' })).filter((t) => !(t.url || '').includes('/.within.website'));
  if (!tabs.length) return note('Open the wiki pages whose links you want, then press this again.');
  const s = await settings();
  $('linked').disabled = true;
  note('Reading the open tabs...');
  const found = new Map();
  let silent = 0;
  let left = 0;
  for (const t of tabs) {
    let r = null;
    try { r = await chrome.tabs.sendMessage(t.id, { type: 'links:collect', skipTranslations: s.englishOnly }); } catch (e) { /* no answer */ }
    if (!r || !r.titles) { silent++; continue; }
    left += r.left || 0;
    for (const f of r.titles) if (!found.has(f[0])) found.set(f[0], f);
  }
  $('linked').disabled = false;
  const extra = (left ? ' ' + left + ' from other games left out.' : '') +
    (silent ? ' ' + silent + ' tab(s) did not answer: reload them and press this again.' : '');
  const all = [...found.values()];
  const { missing } = await chrome.runtime.sendMessage({ type: 'missing', paths: all.map((f) => f[2]) });
  const missingSet = new Set(missing || []);
  const fresh = all.filter((f) => missingSet.has(f[2]));

  let { crawl, crawlTitles = [] } = await chrome.storage.local.get(['crawl', 'crawlTitles']);
  const unfinished = crawl && crawl.phase !== 'done';
  if (unfinished && crawl.mode !== 'links') {
    if (!confirm('This replaces the unfinished job (pages already saved are kept). OK?')) return note('');
    crawl = null;
  }
  const pending = crawl && unfinished ? crawlTitles.slice(crawl.fetchPos || 0) : [];
  const queued = new Set(pending.map((p) => p[0]));
  const added = fresh.filter((f) => !queued.has(f[0])).map((f) => [f[0], f[1]]);
  const queue = pending.concat(added);
  if (!queue.length) return note('Nothing new: all ' + all.length + ' linked pages are saved or left out.' + extra);
  let tabId = crawl && crawl.running ? crawl.tabId : null;
  if (tabId == null || !tabs.some((t) => t.id === tabId)) tabId = (await wikiTab()).id;
  crawl = {
    running: true, tabId, mode: 'links', jobId: Date.now(), phase: 'fetch', fetchPos: 0,
    delayMs: Math.round(s.delaySec * 1000), challengeReloads: [],
    status: 'Linked pages: ' + queue.length + ' to save', startedAt: new Date().toISOString(),
  };
  await chrome.storage.local.set({ crawlTitles: queue, crawl });
  await go(tabId);
  note(added.length + ' new pages queued from ' + (tabs.length - silent) + ' tab(s).' + extra);
  refresh();
}

// Remove other games (and translations, when English only) from what is saved already.
async function cleanSaved() {
  const s = await settings();
  if (!s.skipOtherGames && !s.englishOnly) return note('Turn on "Skip other games" in Options first.');
  note('Checking saved pages...');
  const r = await chrome.runtime.sendMessage({ type: 'cleanLocal' });
  const byName = 'Removed ' + r.removed + ' by their names.';
  if (!r.needCats.length) { note(byName); return refresh(); }
  const tab = await wikiTab();
  if (!tab) {
    note(byName + ' Open any wiki page and press this again to check the other ' + r.needCats.length + ' by their categories.');
    return refresh();
  }
  const { crawl, crawlTitles = [] } = await chrome.storage.local.get(['crawl', 'crawlTitles']);
  if (crawl && crawl.phase !== 'done' && crawl.mode !== 'clean') await chrome.storage.local.set({ suspended: { crawl, crawlTitles } });
  await chrome.storage.local.set({
    crawlTitles: r.needCats,
    crawl: {
      running: true, tabId: tab.id, mode: 'clean', jobId: Date.now(), phase: 'clean', fetchPos: 0, removed: r.removed,
      delayMs: Math.round(s.delaySec * 1000), challengeReloads: [],
      status: 'Checking ' + r.needCats.length + ' saved pages by their categories...',
    },
  });
  await go(tab.id);
  note(byName + ' Checking the other ' + r.needCats.length + ' by their categories' +
    (crawl && crawl.phase !== 'done' && crawl.mode !== 'clean' ? '; the save it interrupts carries on after.' : '.'));
  refresh();
}

async function restart() {
  if (!confirm('Start over from the beginning? Pages already saved are kept.')) return;
  await chrome.storage.local.set({ crawlTitles: [] });
  await chrome.storage.local.remove(['crawl', 'suspended']);
  refresh();
}

async function clearAll() {
  if (!confirm('Delete every saved page and all progress?')) return;
  await chrome.runtime.sendMessage({ type: 'clear' });
  await chrome.storage.local.remove(['crawl', 'crawlTitles', 'suspended', 'skippedPaths']);
  refresh();
}

// A changed filter forgets which pages it left out before, so they get another look.
async function setFilter(patch) {
  await chrome.storage.local.set(patch);
  await chrome.storage.local.remove('skippedPaths');
}

async function init() {
  const s = await settings();
  $('saveVisits').checked = s.saveVisits;
  $('englishOnly').checked = s.englishOnly;
  $('skipOtherGames').checked = s.skipOtherGames;
  $('skipWords').value = s.skipWords;
  $('keepWords').value = s.keepWords;
  $('delay').value = s.delaySec;
  for (const box of document.querySelectorAll('.ns')) box.checked = s.namespaces.includes(Number(box.value));

  $('saveVisits').onchange = () => chrome.storage.local.set({ saveVisits: $('saveVisits').checked });
  $('englishOnly').onchange = () => chrome.storage.local.set({ englishOnly: $('englishOnly').checked });
  $('skipOtherGames').onchange = () => setFilter({ skipOtherGames: $('skipOtherGames').checked });
  $('skipWords').onchange = () => setFilter({ skipWords: $('skipWords').value });
  $('keepWords').onchange = () => setFilter({ keepWords: $('keepWords').value });
  $('resetLists').onclick = async () => {
    $('skipWords').value = VDC_SKIP_DEFAULT;
    $('keepWords').value = VDC_KEEP_DEFAULT;
    await setFilter({ skipWords: VDC_SKIP_DEFAULT, keepWords: VDC_KEEP_DEFAULT });
  };
  $('delay').onchange = async () => {
    const delaySec = Math.max(0.5, Number($('delay').value) || 1.5);
    $('delay').value = delaySec;
    await chrome.storage.local.set({ delaySec });
    const { crawl } = await chrome.storage.local.get('crawl');
    if (crawl) { crawl.delayMs = Math.round(delaySec * 1000); await chrome.storage.local.set({ crawl }); }
  };
  for (const box of document.querySelectorAll('.ns')) {
    box.onchange = () => {
      const namespaces = [...document.querySelectorAll('.ns')].filter((b) => b.checked).map((b) => Number(b.value));
      chrome.storage.local.set({ namespaces });
    };
  }
  $('start').onclick = start;
  $('pause').onclick = pause;
  $('restart').onclick = restart;
  $('linked').onclick = saveLinked;
  $('clean').onclick = cleanSaved;
  $('clear').onclick = clearAll;
  $('download').onclick = () => chrome.tabs.create({ url: chrome.runtime.getURL('export.html') });

  refresh();
  setInterval(refresh, 1000);
}

init();
