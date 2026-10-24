const fs = require('fs');
const path = require('path');

const SRC_DIR = path.resolve(__dirname, '../src');

// Prohibited styling patterns (CSS properties, Tailwind classes, CSS functions)
const FORBIDDEN_PATTERNS = [
  { name: 'gradient', regex: /gradient/i },
  { name: 'backdrop-filter', regex: /backdrop-filter/i },
  { name: 'backdrop-blur', regex: /backdrop-blur/i },
];

let violations = [];

function isFalsePositive(line, fullPath) {
  const trimmed = line.trim();

  // 1. Comments (full line or common comment prefixes)
  if (
    trimmed.startsWith('//') ||
    trimmed.startsWith('/*') ||
    trimmed.startsWith('*') ||
    trimmed.startsWith('<!--')
  ) {
    return true;
  }

  // 2. Test descriptions and assertions in test files
  const isTestFile =
    fullPath.includes('.test.') ||
    fullPath.includes('.spec.') ||
    fullPath.includes(`${path.sep}test${path.sep}`);

  if (isTestFile) {
    if (
      trimmed.startsWith('it(') ||
      trimmed.startsWith('it.skip(') ||
      trimmed.startsWith('test(') ||
      trimmed.startsWith('test.skip(') ||
      trimmed.startsWith('describe(') ||
      trimmed.includes('expect(') ||
      trimmed.includes('.not.toContain(') ||
      trimmed.includes('.toContain(') ||
      trimmed.includes('.toBe(')
    ) {
      return true;
    }
  }

  // 3. Rule explanations and documentation strings
  if (
    trimmed.includes('ZERO GRADIENT') ||
    trimmed.includes('ZERO GLASS') ||
    trimmed.includes('NO shimmer gradients') ||
    trimmed.includes('no backdrop-filter') ||
    trimmed.includes('forbid backdrop-filter') ||
    trimmed.includes('prohibited')
  ) {
    return true;
  }

  return false;
}

function scanDirectory(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);

    if (entry.isDirectory()) {
      scanDirectory(fullPath);
    } else if (/\.(js|jsx|ts|tsx|css|scss|html)$/.test(entry.name)) {
      const content = fs.readFileSync(fullPath, 'utf8');
      const lines = content.split('\n');

      lines.forEach((line, index) => {
        // Strip trailing single-line comments for checking actual code
        const codeOnly = line.replace(/\/\/.*$/, '');

        for (const pattern of FORBIDDEN_PATTERNS) {
          if (pattern.regex.test(codeOnly)) {
            if (!isFalsePositive(line, fullPath)) {
              violations.push({
                file: path.relative(path.resolve(__dirname, '..'), fullPath),
                line: index + 1,
                pattern: pattern.name,
                code: line.trim(),
              });
            }
          }
        }
      });
    }
  }
}

console.log('[Design Check] Scanning web/src for forbidden gradient and glassmorphism rules...');
scanDirectory(SRC_DIR);

if (violations.length > 0) {
  console.error('\n❌ Design constraint check FAILED! Violations detected:\n');
  violations.forEach((v) => {
    console.error(`  - ${v.file}:${v.line} matches forbidden "${v.pattern}":`);
    console.error(`      ${v.code}`);
  });
  console.error('\nRule #1: ZERO GRADIENTS anywhere (solid colors only).');
  console.error('Rule #2: ZERO GLASSMORPHISM (no backdrop-filter or blur).\n');
  process.exit(1);
} else {
  console.log('✅ Design constraint check PASSED: 0 gradients, 0 glassmorphism in web/src.\n');
  process.exit(0);
}
