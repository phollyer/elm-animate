/* eslint-env node */
/**
 * Prepare dist/ for npm publishing.
 *
 * Builds a self-contained, publishable package directory at dist/:
 *   - dist/package.json   (paths flattened, dev-only fields stripped)
 *   - dist/LICENSE        (copied from root)
 *   - dist/README.md      (copied from README.npm.md - the npm-facing README)
 *
 * Rollup output (elm-motion.js, elm-motion.mjs) and sync-types.mjs output
 * (elm-motion.d.ts) already live in dist/.
 *
 * Publish with:  npm publish dist/
 */

import { copyFile, readFile, writeFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const root = resolve(scriptDir, '..');
const dist = resolve(root, 'dist');

await mkdir(dist, { recursive: true });

// --- package.json -----------------------------------------------------------
const pkg = JSON.parse(await readFile(resolve(root, 'package.json'), 'utf8'));

const distPkg = {
    name: pkg.name,
    version: pkg.version,
    description: pkg.description,
    type: pkg.type,
    main: 'elm-motion.js',
    module: 'elm-motion.mjs',
    types: 'elm-motion.d.ts',
    exports: {
        '.': {
            types: './elm-motion.d.ts',
            import: './elm-motion.mjs',
            require: './elm-motion.js'
        }
    },
    keywords: pkg.keywords,
    author: pkg.author,
    license: pkg.license,
    repository: pkg.repository,
    homepage: pkg.homepage,
    bugs: pkg.bugs,
    dependencies: pkg.dependencies,
    peerDependencies: pkg.peerDependencies
};

// Drop empty/undefined fields
for (const [k, v] of Object.entries(distPkg)) {
    if (v === undefined) delete distPkg[k];
    else if (typeof v === 'object' && !Array.isArray(v) && Object.keys(v).length === 0) delete distPkg[k];
}

await writeFile(
    resolve(dist, 'package.json'),
    JSON.stringify(distPkg, null, 2) + '\n'
);

// --- LICENSE & README -------------------------------------------------------
await copyFile(resolve(root, 'LICENSE'), resolve(dist, 'LICENSE'));
await copyFile(resolve(root, 'README.npm.md'), resolve(dist, 'README.md'));

globalThis.console.log('Prepared dist/ for publishing (package.json, LICENSE, README.md)');
