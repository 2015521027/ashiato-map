// アプリアイコン生成スクリプト
//
// 使い方:
//   node tool/gen_icons.js            → tool/out/ に SVG を出力
//   その後 headless Chrome で PNG 化:
//     chrome --headless --disable-gpu --window-size=1024,1024 --screenshot=<out.png> <in.svg>
//     (前景版は --default-background-color=00000000 を付けて透過で出力)
//   PNG を assets/icon/ と store_assets/ に配置し、
//   flutter pub run flutter_launcher_icons で全サイズ展開する。
//
// デザイン:
//   main   = 本採用: 日本地図全面+中央に大足跡1つ(ベタ塗り)+足跡上に暗オレンジの県境線
//   backup = 予備:   日本地図全面+足跡2つ(左足前・右足後ろ)
//
// クレジット: 足跡 = Material Design Icons "foot-print"(Apache License 2.0)
//             地図 = geolonia/japanese-prefectures(MIT License)
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, '..');
const outDir = path.join(__dirname, 'out');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir);

let map = fs.readFileSync(path.join(root, 'assets/japan.svg'), 'utf8');
map = map.replace(/<\?xml[^>]*\?>/, '');
map = map.replace(/<g class="boundary-line"[\s\S]*?<\/g>/, '');
map = map.replace(/<svg[^>]*>/, '').replace(/<\/svg>\s*$/, '');
map = map.replace(/<title>[^<]*<\/title>/g, '');

const teal = map
  .replace(/fill="#EEEEEE"/g, 'fill="#26A69A"')
  .replace(/stroke="#000000"/g, 'stroke="#00695C"')
  .replace(/stroke-width="1\.0"/g, 'stroke-width="3"');

const outline = map
  .replace(/fill="#EEEEEE"/g, 'fill="none"')
  .replace(/stroke="#000000"/g, 'stroke="#451605"')
  .replace(/stroke-width="1\.0"/g, 'stroke-width="3"');

const mdiFoot = 'M16 2A2 2 0 1 1 14 4A2 2 0 0 1 16 2M12.04 3A1.5 1.5 0 1 1 10.54 4.5A1.5 1.5 0 0 1 12.04 3M9.09 4.5A1 1 0 1 1 8.09 5.5A1 1 0 0 1 9.09 4.5M7.04 6A1 1 0 1 1 6.04 7A1 1 0 0 1 7.04 6M14.53 12A2.5 2.5 0 0 0 17 9.24A2.6 2.6 0 0 0 14.39 7H11.91A6 6 0 0 0 6.12 11.4A2 2 0 0 0 6.23 12.8A6.8 6.8 0 0 1 6.91 15.76A6.89 6.89 0 0 1 6.22 18.55A1.92 1.92 0 0 0 6.3 20.31A3.62 3.62 0 0 0 10.19 21.91A3.5 3.5 0 0 0 12.36 16.63A2.82 2.82 0 0 1 11.91 15S11.68 12 14.53 12Z';
const mapTransform = 'translate(4,21) scale(1.02)';

// ---- 本採用: 1足+輪郭線オーバーレイ ----
const fpTransform = 'translate(512,512) scale(38) translate(-11.7,-12)';
const mainContent = `
  <g transform="${mapTransform}">${teal}</g>
  <path d="${mdiFoot}" fill="#F4511E" transform="${fpTransform}"/>
  <g clip-path="url(#fpclip)">
    <g transform="${mapTransform}">${outline}</g>
  </g>`;
const mainDefs = `
  <defs>
    <clipPath id="fpclip">
      <path d="${mdiFoot}" transform="${fpTransform}"/>
    </clipPath>
  </defs>`;

const mainFull = `<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  ${mainDefs}
  <rect width="1024" height="1024" fill="#F6F9F8"/>
  ${mainContent}
</svg>`;

const mainFg = `<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  ${mainDefs}
  <g transform="translate(512,512) scale(0.62) translate(-512,-512)">${mainContent}</g>
</svg>`;

// ---- 予備: 足跡2つ(左足前) ----
const backupFull = `<svg viewBox="0 0 1024 1024" xmlns="http://www.w3.org/2000/svg">
  <rect width="1024" height="1024" fill="#F6F9F8"/>
  <g transform="${mapTransform}">${teal}</g>
  <g fill="#F4511E" opacity="0.95">
    <path d="${mdiFoot}" transform="translate(300,330) rotate(-10) scale(26) translate(-12,-12)"/>
    <path d="${mdiFoot}" transform="translate(620,785) rotate(14) scale(-26,26) translate(-12,-12)"/>
  </g>
</svg>`;

fs.writeFileSync(path.join(outDir, 'icon_main_full.svg'), mainFull);
fs.writeFileSync(path.join(outDir, 'icon_main_fg.svg'), mainFg);
fs.writeFileSync(path.join(outDir, 'icon_backup_full.svg'), backupFull);
console.log('SVGs written to tool/out/');
