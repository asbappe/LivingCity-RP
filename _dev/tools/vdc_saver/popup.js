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
    running: true, tabId, phase: 'list', nsIndex: 0, apcontinue: null, fetchPos: 0, listed: 0,
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
  try {
    await chrome.tabs.sendMessage(tab.id, { type: 'crawl:go' });
  } catch (e) {
    // The tab was open before the extension: reload it and it carries on by itself.
    await chrome.tabs.reload(tab.id);
  }
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
  $('pause').onclick = pause;
  $('restart').onclick = restart;
  $('clear').onclick = clearAll;
  $('download').onclick = () => chrome.tabs.create({ url: chrome.runtime.getURL('export.html') });

  refresh();
  setInterval(refresh, 1000);
}

init();
