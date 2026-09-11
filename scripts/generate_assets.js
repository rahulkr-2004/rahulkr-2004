const fs = require('fs');
const path = require('path');

const assetsDir = path.join(__dirname, '..', 'assets');

// 1. Update card-stats SVGs
function updateCardStats(theme, bg, stroke, textTitle, textPrimary, textSub, border) {
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 480 159" width="480" height="159" role="img" aria-label="rahulkr-2004 GitHub statistics" font-family="ui-sans-serif,-apple-system,Segoe UI,Helvetica,Arial,sans-serif"><rect x="0.5" y="0.5" width="479" height="158" rx="10" fill="${bg}" stroke="${border}"/><text x="22" y="36" font-size="15" font-weight="700" fill="${textTitle}">rahulkr-2004</text><text x="458" y="36" font-size="11" text-anchor="end" fill="${textSub}">at a glance</text><line x1="22" y1="48" x2="458" y2="48" stroke="${border}"/><text x="22" y="74" font-size="23" font-weight="700" fill="${textPrimary}">5+</text><text x="22" y="91" font-size="10.5" fill="${textSub}">Total stars</text><text x="167" y="74" font-size="23" font-weight="700" fill="${textPrimary}">12</text><text x="167" y="91" font-size="10.5" fill="${textSub}">Public repos</text><text x="313" y="74" font-size="23" font-weight="700" fill="${textPrimary}">15+</text><text x="313" y="91" font-size="10.5" fill="${textSub}">Followers</text><text x="22" y="120" font-size="23" font-weight="700" fill="${textPrimary}">250+</text><text x="22" y="137" font-size="10.5" fill="${textSub}">Contributions (1y)</text><text x="167" y="120" font-size="23" font-weight="700" fill="${textPrimary}">Active</text><text x="167" y="137" font-size="10.5" fill="${textSub}">Current streak</text><text x="313" y="120" font-size="23" font-weight="700" fill="${textPrimary}">100+</text><text x="313" y="137" font-size="10.5" fill="${textSub}">Problems solved</text></svg>`;
}

fs.writeFileSync(path.join(assetsDir, 'card-stats-dark.svg'), updateCardStats('dark', '#0d1117', '#30363d', '#39d353', '#e6edf3', '#8b949e', '#30363d'));
fs.writeFileSync(path.join(assetsDir, 'card-stats-light.svg'), updateCardStats('light', '#ffffff', '#d0d7de', '#216e39', '#1f2328', '#656d76', '#d0d7de'));

// 2. Generate Repo Card SVGs (AquaTrack & Snipify)
function generateRepoCard(repoName, desc, lang, langColor, stars, forks, isDark) {
  const bg = isDark ? '#0d1117' : '#ffffff';
  const border = isDark ? '#30363d' : '#d0d7de';
  const titleColor = isDark ? '#39d353' : '#216e39';
  const descColor = isDark ? '#8b949e' : '#57606a';
  const subColor = isDark ? '#c9d1d9' : '#24292f';

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 420 120" width="420" height="120" role="img" aria-label="${repoName}" font-family="ui-sans-serif,-apple-system,Segoe UI,Helvetica,Arial,sans-serif"><rect x="0.5" y="0.5" width="419" height="119" rx="10" fill="${bg}" stroke="${border}"/><text x="20" y="32" font-size="14.5" font-weight="700" fill="${titleColor}">${repoName}</text><text x="20" y="56" font-size="11" fill="${descColor}">${desc.slice(0, 52)}...</text><text x="20" y="74" font-size="11" fill="${descColor}">${desc.slice(52, 105)}</text><circle cx="26" cy="98" r="4.5" fill="${langColor}"/><text x="36" y="102" font-size="11" fill="${subColor}">${lang}</text><text x="140" y="102" font-size="11" fill="${subColor}">★ ${stars}</text><text x="190" y="102" font-size="11" fill="${subColor}">⑂ ${forks}</text></svg>`;
}

fs.writeFileSync(path.join(assetsDir, 'card-AquaTrack---Water-Management-System-dark.svg'), generateRepoCard('AquaTrack', 'Smart water utility platform for tracking real-time consumption, analytics, and alerts.', 'Java', '#b07219', '2', '0', true));
fs.writeFileSync(path.join(assetsDir, 'card-AquaTrack---Water-Management-System-light.svg'), generateRepoCard('AquaTrack', 'Smart water utility platform for tracking real-time consumption, analytics, and alerts.', 'Java', '#b07219', '2', '0', false));

fs.writeFileSync(path.join(assetsDir, 'card-Snipify-dark.svg'), generateRepoCard('Snipify', 'Developer productivity platform for code snippet management and quick search.', 'JavaScript', '#f1e05a', '1', '0', true));
fs.writeFileSync(path.join(assetsDir, 'card-Snipify-light.svg'), generateRepoCard('Snipify', 'Developer productivity platform for code snippet management and quick search.', 'JavaScript', '#f1e05a', '1', '0', false));

// 3. Update radar charts with Rahul's actual skills
function generateRadarSVG(title, axes, isDark) {
  const bg = isDark ? '#0d1117' : '#ffffff';
  const textColor = isDark ? '#e6edf3' : '#1f2328';
  const labelColor = isDark ? '#c9d1d9' : '#57606a';
  const gridColor = isDark ? '#30363d' : '#d0d7de';
  const spokeColor = isDark ? '#21262d' : '#e6e8eb';
  const accent = isDark ? '#39d353' : '#216e39';
  const pointColor = isDark ? '#7ee787' : '#2da44e';

  const N = axes.length;
  const R = 212;
  const cx = 284.5;
  const cy = 289.0;

  // Grid levels
  const levels = [1.0, 0.75, 0.5, 0.25];
  let gridPolys = levels.map(scale => {
    let pts = [];
    for (let i = 0; i < N; i++) {
      let angle = (i * 2 * Math.PI / N) - Math.PI / 2;
      let x = (R * scale * Math.cos(angle)).toFixed(1);
      let y = (R * scale * Math.sin(angle)).toFixed(1);
      pts.push(`${x},${y}`);
    }
    return `<polygon points="${pts.join(' ')}" fill="none" stroke="${gridColor}" stroke-width="1" opacity="${scale + 0.1}"/>`;
  }).join('');

  let spokes = [];
  let labels = [];
  let polyPts = [];
  let circles = [];

  for (let i = 0; i < N; i++) {
    let angle = (i * 2 * Math.PI / N) - Math.PI / 2;
    let xMax = (R * Math.cos(angle)).toFixed(1);
    let yMax = (R * Math.sin(angle)).toFixed(1);
    spokes.push(`<line x1="0" y1="0" x2="${xMax}" y2="${yMax}" stroke="${spokeColor}" stroke-width="1"/>`);

    let valR = R * (axes[i].val / 100);
    let vx = (valR * Math.cos(angle)).toFixed(1);
    let vy = (valR * Math.sin(angle)).toFixed(1);
    polyPts.push(`${vx},${vy}`);
    circles.push(`<circle cx="${vx}" cy="${vy}" r="3.6" fill="${pointColor}" stroke="${accent}" stroke-width="1.2"/>`);

    let labelR = R + 26;
    let lx = (labelR * Math.cos(angle)).toFixed(1);
    let ly = (labelR * Math.sin(angle)).toFixed(1);
    let anchor = Math.abs(Math.cos(angle)) < 0.2 ? 'middle' : (Math.cos(angle) > 0 ? 'start' : 'end');
    labels.push(`<text x="${lx}" y="${ly}" text-anchor="${anchor}" font-size="13" font-weight="600" fill="${labelColor}">${axes[i].name}</text>`);
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 561 526" width="561" height="526" role="img" aria-label="${title}" font-family="ui-sans-serif,-apple-system,Segoe UI,Helvetica,Arial,sans-serif"><text x="280.5" y="25" text-anchor="middle" font-size="15" font-weight="700" fill="${textColor}">${title}</text><g transform="translate(${cx},${cy})">${gridPolys}${spokes.join('')}<g><polygon points="${polyPts.join(' ')}" fill="${accent}" fill-opacity="0.22" stroke="${accent}" stroke-width="2.5" stroke-linejoin="round"/>${circles.join('')}</g>${labels.join('')}</g></svg>`;
}

const skillsAxes = [
  { name: "Java", val: 92 },
  { name: "Cyber Security", val: 86 },
  { name: "Spring Boot", val: 82 },
  { name: "SQL & DB", val: 84 },
  { name: "DSA", val: 88 },
  { name: "Web & JS", val: 78 },
  { name: "Linux & Tools", val: 84 }
];

const langAxes = [
  { name: "Java", val: 95 },
  { name: "SQL", val: 84 },
  { name: "JavaScript", val: 80 },
  { name: "HTML/CSS", val: 82 },
  { name: "Shell/Bash", val: 75 }
];

fs.writeFileSync(path.join(assetsDir, 'radar-dark.svg'), generateRadarSVG("Skill Radar", skillsAxes, true));
fs.writeFileSync(path.join(assetsDir, 'radar-light.svg'), generateRadarSVG("Skill Radar", skillsAxes, false));
fs.writeFileSync(path.join(assetsDir, 'radar-langs-dark.svg'), generateRadarSVG("Language Radar", langAxes, true));
fs.writeFileSync(path.join(assetsDir, 'radar-langs-light.svg'), generateRadarSVG("Language Radar", langAxes, false));

console.log("All SVGs created successfully!");
