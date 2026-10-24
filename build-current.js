const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

const root = __dirname;
const manifest = JSON.parse(fs.readFileSync(path.join(root, 'manifest.json'), 'utf8'));

function arg(name, fallback = '') {
  const i = process.argv.indexOf(name);
  return i >= 0 && process.argv[i + 1] ? process.argv[i + 1] : fallback;
}
const srcPath = arg('--src', path.join(__dirname, 'app.asar-3.23.2'));
const outPath = arg('--out', path.join(root, 'out', 'app.asar'));

function sha256(buf) {
  return crypto.createHash('sha256').update(buf).digest('hex');
}
function integrity(buf) {
  const blocks = [];
  for (let i = 0; i < buf.length; i += 4194304) blocks.push(sha256(buf.subarray(i, i + 4194304)));
  return { algorithm: 'SHA256', hash: sha256(buf), blockSize: 4194304, blocks };
}

const src = fs.readFileSync(srcPath);
const srcHash = sha256(src);
if (srcHash !== manifest.original.sha256) {
  throw new Error('source asar is not the expected original build\n  expected: ' + manifest.original.sha256 + '\n  actual:   ' + srcHash);
}
const headerSize = src.readUInt32LE(4);
const jsonLen = src.readUInt32LE(12);
const dataOffset = 8 + headerSize;
const header = JSON.parse(src.subarray(16, 16 + jsonLen).toString('utf8'));

const overrideMap = new Map(manifest.files.map(f => [f.path, path.join(root, 'files', f.path.replace(/^dist\//, ''))]));
const chunks = [];
let cursor = 0;

function walk(node, rel) {
  if (node.files) {
    for (const key of Object.keys(node.files)) walk(node.files[key], rel ? rel + '/' + key : key);
    return;
  }
  if (node.link || node.unpacked) return;
  let content;
  if (overrideMap.has(rel)) {
    content = fs.readFileSync(overrideMap.get(rel));
  } else {
    const off = dataOffset + Number(node.offset);
    content = src.subarray(off, off + node.size);
  }
  node.size = content.length;
  node.offset = String(cursor);
  node.integrity = integrity(content);
  chunks.push(content);
  cursor += content.length;
}
walk(header, '');

let json = JSON.stringify(header);
const pad = (4 - (Buffer.byteLength(json) % 4)) % 4;
if (pad) json += ' '.repeat(pad);
const outJsonLen = Buffer.byteLength(json);
const out = Buffer.alloc(16 + outJsonLen + cursor);
out.writeUInt32LE(4, 0);
out.writeUInt32LE(outJsonLen + 8, 4);
out.writeUInt32LE(outJsonLen + 4, 8);
out.writeUInt32LE(outJsonLen, 12);
Buffer.from(json, 'utf8').copy(out, 16);
let pos = 16 + outJsonLen;
for (const c of chunks) { c.copy(out, pos); pos += c.length; }

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, out);
const outHash = sha256(out);
if (outHash !== manifest.current.sha256) {
  throw new Error('rebuilt asar hash mismatch\n  expected: ' + manifest.current.sha256 + '\n  actual:   ' + outHash);
}
console.log(JSON.stringify({
  source: srcPath,
  sourceHash: srcHash,
  output: outPath,
  outputSize: out.length,
  outputHash: outHash,
  files: manifest.files.map(f => f.path),
}, null, 2));
