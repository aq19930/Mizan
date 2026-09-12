const fs = require('fs');
const path = require('path');
const target = process.argv[2];
let data = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => data += chunk);
process.stdin.on('end', () => {
  const full = path.resolve(target);
  fs.mkdirSync(path.dirname(full), { recursive: true });
  fs.writeFileSync(full, data, 'utf8');
  console.log('Saved: ' + target);
});
