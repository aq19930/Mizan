const fs = require('fs');
const path = require('path');

const [,, targetPath, base64Content] = process.argv;
if (!targetPath || !base64Content) {
  console.error('Usage: node setup.js <targetPath> <base64Content>');
  process.exit(1);
}
const fullPath = path.resolve(targetPath);
fs.mkdirSync(path.dirname(fullPath), { recursive: true });
fs.writeFileSync(fullPath, Buffer.from(base64Content, 'base64'));
console.log('Saved: ' + targetPath);

