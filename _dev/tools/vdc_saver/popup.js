const WIKI = 'https://developer.valvesoftware.com/';
const $ = (id) => document.getElementById(id);
const DEFAULTS = { saveVisits: true, englishOnly: true, namespaces: [0, 10, 14], delaySec: 1.5 };

async function settings() {
  return chrome.storage.local.get(DEFAULTS);
}

async function wikiTab() {
  const [active] = await chrome.tabs.query({ active: true, currentWindow: true });
  if (active && active.url && active.url.startsWith(WIKI)) return active;
  const tabs = await chrome.tabs.query({ url: WIKI + '*' });
  return tabs.find((t) => !(t.url || '').includes('/.within.website')) || tabs[0] || null;
}

function freshCrawl(s, tabId) {
  return {
    running: true, tabId, mode: 'whole', jobId: Date.now(), phase: 'list', nsIndex: 0, apcontinue: null, fetchPos: 0, listed: 0,
    namespaces: s.namespaces, skipTranslations: s.englishOnly, delayMs: Math.round(s.delaySec * 1000),
    challengeReloads: [], status: 'Starting...', startedAt: new Date().toISOString(),
  };
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
  $('note').textContent = '';
  const tab = await wikiTab();
  if (!tab) {
    $('note').textContent = 'Open any developer.valvesoftware.com page first, then press this again.';
    return;
  }
  const s = await settings();
  let { crawl } = await chrome.storage.local.get('crawl');
  if (!crawl || crawl.phase === 'done') {
    crawl = freshCrawl(s, tab.id);
    await chrome.storage.local.set({ crawlTitles: [] });
  } else {
    crawl.running = true;
    crawl.tabId = tab.id;
    crawl.challengeReloads = [];
    crawl.delayMs = Math.round(s.delaySec * 1000);
    crawl.status = 'Resuming...';
  }
  await chrome.storage.local.set({ crawl });
  await go(tab.id);
  refresh();
}

async function go(tabId) {
  try {
    await chrome.tabs.sendMessage(tabId, { type: 'crawl:go', tabId });
  } catch (e) {
    // The tab was open before the extension: reload it and it carries on by itself.
    await chrome.tabs.reload(tabId);
  }
}

// Queue every page the open wiki tabs link to (and every member of an open category).
async function saveLinked() {
  $('note').textContent = '';
  const tabs = (await chrome.tabs.query({ url: WIKI + '*' })).filter((t) => !(t.url || '').includes('/.within.website'));
  if (!tabs.length) {
    $('note').textContent = 'Open the wiki pages whose links you want, then press this again.';
    return;
  }
  const s = await settings();
  $('linked').disabled = true;
  $('note').textContent = 'Reading the open tabs...';
  const found = new Map();
  let silent = 0;
  for (const t of tabs) {
    let r = null;
    try { r = await chrome.tabs.sendMessage(t.id, { type: 'links:collect', skipTranslations: s.englishOnly }); } catch (e) { /* no answer */ }
    if (!r || !r.titles) { silent++; continue; }
    for (const f of r.titles) if (!found.has(f[0])) found.set(f[0], f);
  }
  $('linked').disabled = false;
  const reloadNote = silent ? ' ' + silent + ' tab(s) did not answer: reload them and press this again.' : '';
  const all = [...found.values()];
  const { missing } = await chrome.runtime.sendMessage({ type: 'missing', paths: all.map((f) => f[2]) });
  const missingSet = new Set(missing || []);
  const fresh = all.filter((f) => missingSet.has(f[2]));

  let { crawl, crawlTitles = [] } = await chrome.storage.local.get(['crawl', 'crawlTitles']);
  const unfinished = crawl && crawl.phase !== 'done';
  if (unfinished && crawl.mode !== 'links') {
    if (!confirm('This replaces the unfinished whole-wiki save (pages already saved are kept). OK?')) return;
    crawl = null;
  }
  const pending = crawl && unfinished ? crawlTitles.slice(crawl.fetchPos || 0) : [];
  const queued = new Set(pending.map((p) => p[0]));
  const added = fresh.filter((f) => !queued.has(f[0])).map((f) => [f[0], f[1]]);
  const queue = pending.concat(added);
  if (!queue.length) {
    $('note').textContent = 'All ' + all.length + ' linked pages are saved already.' + reloadNote;
    return;
  }
  let tabId = crawl && crawl.running ? crawl.tabId : null;
  if (tabId == null || !tabs.some((t) => t.id === tabId)) tabId = (await wikiTab()).id;
  crawl = {
    running: true, tabId, mode: 'links', jobId: Date.now(), phase: 'fetch', fetchPos: 0,
    delayMs: Math.round(s.delaySec * 1000), challengeReloads: [],
    status: 'Linked pages: ' + queue.length + ' to save', startedAt: new Date().toISOString(),
  };
  await chrome.storage.local.set({ crawlTitles: queue, crawl });
  await go(tabId);
  $('note').textContent = added.length + ' new pages queued from ' + (tabs.length - silent) + ' tab(s).' + reloadNote;
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

async function restart() {
  if (!confirm('Start the whole-wiki save over from the beginning? Pages already saved are kept.')) return;
  await chrome.storage.local.set({ crawlTitles: [] });
  await chrome.storage.local.remove('crawl');
  refresh();
}

async function clearAll() {
  if (!confirm('Delete every saved page and the whole-wiki progress?')) return;
  await chrome.runtime.sendMessage({ type: 'clear' });
  await chrome.storage.local.remove(['crawl', 'crawlTitles']);
  refresh();
}

async function init() {
  const s = await settings();
  $('saveVisits').checked = s.saveVisits;
  $('englishOnly').checked = s.englishOnly;
  $('delay').value = s.delaySec;
  for (const box of document.querySelectorAll('.ns')) box.checked = s.namespaces.includes(Number(box.value));

  $('saveVisits').onchange = () => chrome.storage.local.set({ saveVisits: $('saveVisits').checked });
  $('englishOnly').onchange = () => chrome.storage.local.set({ englishOnly: $('englishOnly').checked });
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
  $('linked').onclick = saveLinked;
  $('pause').onclick = pause;
  $('restart').onclick = restart;
  $('clear').onclick = clearAll;
  $('download').onclick = () => chrome.tabs.create({ url: chrome.runtime.getURL('export.html') });

  refresh();
  setInterval(refresh, 1000);
}

init();
