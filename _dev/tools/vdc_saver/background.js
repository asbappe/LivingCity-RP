importScripts('db.js', 'filter.js');

async function updateBadge() {
  const { total } = await fileStats();
  const text = total === 0 ? '' : total < 1000 ? String(total) : (total / 1000).toFixed(total < 10000 ? 1 : 0) + 'k';
  await chrome.action.setBadgeText({ text });
  await chrome.action.setBadgeBackgroundColor({ color: '#c46a1a' });
}

async function handle(msg, sender) {
  switch (msg.type) {
    case 'hello': {
      // A wiki tab just loaded: should it carry on with the whole-wiki save?
      const { crawl } = await chrome.storage.local.get('crawl');
      const tabId = sender.tab ? sender.tab.id : -1;
      return { tabId, resume: !!(crawl && crawl.running && crawl.tabId === tabId) };
    }
    case 'save':
      await putFiles(msg.files);
      await updateBadge();
      return { ok: true };
    case 'missing': {
      // Not saved, and not already found to be from another game.
      const { skippedPaths = [] } = await chrome.storage.local.get('skippedPaths');
      const skipped = new Set(skippedPaths);
      return { missing: (await missingPaths(msg.paths || [])).filter((p) => !skipped.has(p)) };
    }
    case 'skipped': {
      const { skippedPaths = [] } = await chrome.storage.local.get('skippedPaths');
      const all = new Set(skippedPaths);
      for (const p of msg.paths || []) all.add(p);
      await chrome.storage.local.set({ skippedPaths: [...all] });
      return { ok: true };
    }
    case 'cleanLocal': {
      const s = await chrome.storage.local.get(Object.assign({ englishOnly: true }, VDC_FILTER_DEFAULTS));
      const judge = vdcJudge(s);
      const r = await cleanByName(judge, s.englishOnly);
      await updateBadge();
      return r;
    }
    case 'clean':
      await applyClean(msg.remove || [], msg.cats || []);
      await updateBadge();
      return { ok: true };
    case 'stats':
      return fileStats();
    case 'clear':
      await clearFiles();
      await updateBadge();
      return { ok: true };
    default:
      return { error: 'unknown message ' + msg.type };
  }
}

chrome.runtime.onMessage.addListener((msg, sender, reply) => {
  handle(msg, sender).then(reply, (e) => reply({ error: String(e) }));
  return true;
});

// The tab doing the whole-wiki save was closed: pause, so Resume can pick it up in another tab.
chrome.tabs.onRemoved.addListener(async (tabId) => {
  const { crawl } = await chrome.storage.local.get('crawl');
  if (crawl && crawl.running && crawl.tabId === tabId) {
    crawl.running = false;
    crawl.status = 'Paused: its tab was closed. Press Resume with a wiki page open.';
    await chrome.storage.local.set({ crawl });
  }
});

chrome.runtime.onStartup.addListener(updateBadge);
chrome.runtime.onInstalled.addListener(updateBadge);
