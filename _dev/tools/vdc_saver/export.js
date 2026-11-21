// Builds vdc_wiki.zip from everything saved. A plain zip (deflate, no zip64), so it is
// split into parts if it ever goes past 60000 files.
const enc = new TextEncoder();
const MAX_FILES = 60000;
const MAX_BYTES = 3.5e9;

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = CRC_TABLE[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

async function deflate(buf) {
  const stream = new Blob([buf]).stream().pipeThrough(new CompressionStream('deflate-raw'));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

function dosTime(d) {
  if (isNaN(d.getTime()) || d.getFullYear() < 1980) d = new Date();
  return {
    time: (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1),
    date: ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate(),
  };
}

class ZipWriter {
  constructor() { this.chunks = []; this.central = []; this.offset = 0; this.count = 0; }

  async add(name, data, when) {
    const nameBytes = enc.encode(name);
    const crc = crc32(data);
    let body = await deflate(data);
    let method = 8;
    if (body.length >= data.length) { body = data; method = 0; }
    const { time, date } = dosTime(when);

    const h = new DataView(new ArrayBuffer(30));
    h.setUint32(0, 0x04034b50, true);
    h.setUint16(4, 20, true);
    h.setUint16(6, 0x0800, true); // names are UTF-8
    h.setUint16(8, method, true);
    h.setUint16(10, time, true);
    h.setUint16(12, date, true);
    h.setUint32(14, crc, true);
    h.setUint32(18, body.length, true);
    h.setUint32(22, data.length, true);
    h.setUint16(26, nameBytes.length, true);
    h.setUint16(28, 0, true);
    this.chunks.push(new Uint8Array(h.buffer), nameBytes, body);

    const c = new DataView(new ArrayBuffer(46));
    c.setUint32(0, 0x02014b50, true);
    c.setUint16(4, 0x0314, true); // made on Unix, zip 2.0
    c.setUint16(6, 20, true);
    c.setUint16(8, 0x0800, true);
    c.setUint16(10, method, true);
    c.setUint16(12, time, true);
    c.setUint16(14, date, true);
    c.setUint32(16, crc, true);
    c.setUint32(20, body.length, true);
    c.setUint32(24, data.length, true);
    c.setUint16(28, nameBytes.length, true);
    c.setUint32(38, (0o100644 << 16) >>> 0, true); // rw-r--r--
    c.setUint32(42, this.offset, true);
    this.central.push(new Uint8Array(c.buffer), nameBytes);

    this.offset += 30 + nameBytes.length + body.length;
    this.count++;
  }

  finish() {
    let cdSize = 0;
    for (const b of this.central) cdSize += b.length;
    const e = new DataView(new ArrayBuffer(22));
    e.setUint32(0, 0x06054b50, true);
    e.setUint16(8, this.count, true);
    e.setUint16(10, this.count, true);
    e.setUint32(12, cdSize, true);
    e.setUint32(16, this.offset, true);
    return new Blob([...this.chunks, ...this.central, new Uint8Array(e.buffer)], { type: 'application/zip' });
  }
}

function download(blob, name) {
  const a = document.createElement('a');
  a.href = URL.createObjectURL(blob);
  a.download = name;
  document.body.appendChild(a);
  a.click();
}

const msg = (t) => { document.getElementById('msg').textContent = t; };
const bar = (f) => { document.getElementById('fill').style.width = Math.round(f * 100) + '%'; };
const tsv = (v) => String(v == null ? '' : v).replace(/[\t\r\n]/g, ' ');

async function main() {
  const keys = await allKeys();
  if (!keys.length) {
    msg('Nothing saved yet. Visit some wiki pages, or press "Save the whole wiki" first.');
    return;
  }
  const stamp = new Date().toISOString().slice(0, 10);
  const names = [];
  const blobs = [];
  const index = ['path\ttitle\tnamespace\tkind\trevision\ttimestamp'];
  let zip = new ZipWriter();
  let done = 0;
  let bytes = 0;

  const cut = () => { blobs.push(zip.finish()); zip = new ZipWriter(); };

  for (let i = 0; i < keys.length; i += 500) {
    const slice = keys.slice(i, i + 500);
    const recs = await filesBetween(slice[0], slice[slice.length - 1]);
    for (const r of recs) {
      if (zip.count >= MAX_FILES || zip.offset >= MAX_BYTES) cut();
      const data = enc.encode(r.text || '');
      bytes += data.length;
      await zip.add('vdc/' + r.path, data, new Date(r.ts || Date.now()));
      index.push([r.path, r.title, r.ns, r.kind, r.rev, r.ts].map(tsv).join('\t'));
      done++;
    }
    msg('Packing ' + done + ' of ' + keys.length + ' files...');
    bar(done / keys.length);
  }

  const readme = [
    'Valve Developer Community pages saved by VDC Saver on ' + stamp + '.',
    'Source: https://developer.valvesoftware.com/ (see the site for its license).',
    '',
    'wikitext/  the source of each page (.wiki), from the wiki\'s API',
    'text/      the page as it was shown (.txt), for pages you visited',
    'index.tsv  one row per file: path, title, namespace, kind, revision, timestamp',
    '',
    'Files: ' + done + ', text: ' + (bytes / 1e6).toFixed(1) + ' MB.',
    '',
  ].join('\n');
  await zip.add('vdc/index.tsv', enc.encode(index.join('\n') + '\n'), new Date());
  await zip.add('vdc/README.txt', enc.encode(readme), new Date());
  blobs.push(zip.finish());

  blobs.forEach((b, i) => {
    const name = blobs.length === 1 ? 'vdc_wiki.zip' : 'vdc_wiki_part' + (i + 1) + '.zip';
    names.push(name + ' (' + (b.size / 1e6).toFixed(1) + ' MB)');
    download(b, name);
  });
  bar(1);
  msg('Done: ' + done + ' files in ' + names.join(', ') + '. It is in your Downloads folder.');
}

main().catch((e) => msg('Could not build the zip: ' + (e.message || e)));
