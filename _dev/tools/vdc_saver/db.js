// Saved pages live in the extension's own IndexedDB: one record per file of the zip.
const DB_NAME = 'vdc_saver';
const STORE = 'files';
let dbPromise = null;

function openDb() {
  if (!dbPromise) {
    dbPromise = new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, 1);
      req.onupgradeneeded = () => {
        const store = req.result.createObjectStore(STORE, { keyPath: 'path' });
        store.createIndex('kind', 'kind');
      };
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }
  return dbPromise;
}

function done(tx) {
  return new Promise((resolve, reject) => {
    tx.oncomplete = () => resolve();
    tx.onerror = () => reject(tx.error);
    tx.onabort = () => reject(tx.error);
  });
}

function result(req) {
  return new Promise((resolve, reject) => {
    req.onsuccess = () => resolve(req.result);
    req.onerror = () => reject(req.error);
  });
}

async function putFiles(files) {
  const db = await openDb();
  const tx = db.transaction(STORE, 'readwrite');
  const store = tx.objectStore(STORE);
  for (const f of files) store.put(f);
  await done(tx);
}

async function fileStats() {
  const db = await openDb();
  const tx = db.transaction(STORE, 'readonly');
  const store = tx.objectStore(STORE);
  const kind = store.index('kind');
  const [total, wikitext, text] = await Promise.all([
    result(store.count()),
    result(kind.count(IDBKeyRange.only('wikitext'))),
    result(kind.count(IDBKeyRange.only('text'))),
  ]);
  return { total, wikitext, text };
}

async function clearFiles() {
  const db = await openDb();
  const tx = db.transaction(STORE, 'readwrite');
  tx.objectStore(STORE).clear();
  await done(tx);
}

async function allKeys() {
  const db = await openDb();
  return result(db.transaction(STORE, 'readonly').objectStore(STORE).getAllKeys());
}

// Keys come back sorted, so a run of them is exactly one key range.
async function filesBetween(first, last) {
  const db = await openDb();
  const store = db.transaction(STORE, 'readonly').objectStore(STORE);
  return result(store.getAll(IDBKeyRange.bound(first, last)));
}

// Which of these files are not saved yet.
async function missingPaths(paths) {
  const db = await openDb();
  const store = db.transaction(STORE, 'readonly').objectStore(STORE);
  const found = await Promise.all(paths.map((p) => result(store.getKey(p))));
  return paths.filter((p, i) => found[i] === undefined);
}

// Drop every saved file the filter rules out by its name and stored categories (and translations, when
// English only). Files saved before the filter have no categories: those come back to be checked on the wiki.
async function cleanByName(judge, englishOnly) {
  const db = await openDb();
  const tx = db.transaction(STORE, 'readwrite');
  const removed = new Set();
  const need = new Map();
  tx.objectStore(STORE).openCursor().onsuccess = (ev) => {
    const cur = ev.target.result;
    if (!cur) return;
    const r = cur.value;
    const title = r.title || '';
    if ((englishOnly && vdcIsTranslation(title)) || (judge && judge(title, r.cats || []))) {
      removed.add(r.title);
      cur.delete();
    } else if (judge && !r.cats && r.title) {
      need.set(r.title, [r.title, r.ns]);
    }
    cur.continue();
  };
  await done(tx);
  return { removed: removed.size, needCats: [...need.values()] };
}

async function applyClean(remove, cats) {
  const db = await openDb();
  const tx = db.transaction(STORE, 'readwrite');
  const store = tx.objectStore(STORE);
  for (const p of remove) store.delete(p);
  for (const c of cats) {
    const req = store.get(c.path);
    req.onsuccess = () => {
      if (req.result) {
        req.result.cats = c.cats;
        store.put(req.result);
      }
    };
  }
  await done(tx);
}
