/* eslint-env node */
import { copyFile, mkdir } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(scriptDir, '..');
const source = resolve(projectRoot, 'js/src/index.d.ts');
const target = resolve(projectRoot, 'dist/elm-motion.d.ts');

await mkdir(dirname(target), { recursive: true });
await copyFile(source, target);

globalThis.console.log('Synced TypeScript definitions to dist/elm-motion.d.ts');