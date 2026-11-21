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
