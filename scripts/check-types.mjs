/* eslint-env node */
/* global process */
/**
 * Drift checker: verifies that named exports in js/src/index.js
 * are declared in js/src/index.d.ts, and that every member of the
 * default-export interface is actually exported from the JS source.
 *
 * Exit code 0 = no drift, 1 = drift detected.
 * Run via: npm run check-types
 */

import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const __dirname = dirname(fileURLToPath(import.meta.url));
const root = join(__dirname, '..');

const JS_SRC = join(root, 'js/src/index.js');
const DTS_SRC = join(root, 'js/src/index.d.ts');

// ---------------------------------------------------------------------------
// Parsers
// ---------------------------------------------------------------------------

/**
 * Extract every name that is a named (non-default) export from a JS source file.
 * Handles:
 *   export { a, b, c }
 *   export function foo (...)
 *   export async function foo (...)
 *   export const foo = ...
 */
function jsNamedExports(src) {
    const names = new Set();

    // export { a, b as alias, c }
    for (const block of src.matchAll(/^export\s*\{([^}]+)\}/gm)) {
        for (const entry of block[1].split(',')) {
            const base = entry.trim().split(/\s+as\s+/)[0].trim();
            if (base) names.add(base);
        }
    }

    // export [async] function foo
    for (const m of src.matchAll(/^export\s+(?:async\s+)?function\s+(\w+)/gm)) {
        names.add(m[1]);
    }

    // export const foo
    for (const m of src.matchAll(/^export\s+const\s+(\w+)/gm)) {
        names.add(m[1]);
    }

    return names;
}

/**
 * Extract names from a `.d.ts` source, split into:
 *   - valueNames: names backed by a runtime export
 *     (export function / const / let / class)
 *   - typeNames:  names declared only at the type level
 *     (export interface / type)
 *
 * Also collects members of the default-export interface (for the back-compat
 * check that the default object exposes the same surface as the named exports).
 */
function dtsKnownNames(src) {
    const valueNames = new Set();
    const typeNames = new Set();

    for (const m of src.matchAll(/^export\s+(?:declare\s+)?(function|const|let|class|interface|type)\s+(\w+)/gm)) {
        const kind = m[1];
        const name = m[2];
        if (kind === 'interface' || kind === 'type') {
            typeNames.add(name);
        } else {
            valueNames.add(name);
        }
    }

    // Members of the default-export interface
    const defaultMembers = new Set();
    const defaultMatch = src.match(/^export\s+default\s+(\w+)\s*;/m);
    if (defaultMatch) {
        let ifaceName = defaultMatch[1];

        // Follow `declare const NAME: TypeName;` aliases so the default export
        // can be a typed const rather than the interface directly.
        const aliasRegex = new RegExp(`declare\\s+const\\s+${ifaceName}\\s*:\\s*(\\w+)\\s*;`);
        const aliasMatch = src.match(aliasRegex);
        if (aliasMatch) {
            ifaceName = aliasMatch[1];
        }
        const lines = src.split('\n');
        let inInterface = false;
        let depth = 0;
        const ifaceStart = new RegExp(`interface\\s+${ifaceName}\\s*\\{`);

        for (const line of lines) {
            if (!inInterface) {
                if (ifaceStart.test(line)) {
                    inInterface = true;
                    depth = 1;
                }
                continue;
            }

            for (const ch of line) {
                if (ch === '{') depth++;
                else if (ch === '}') depth--;
            }
            if (depth <= 0) break;

            const memberMatch = line.match(/^ {4}(\w+)\s*[(?:]/);
            if (memberMatch) defaultMembers.add(memberMatch[1]);
        }
    }

    return { valueNames, typeNames, defaultMembers };
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const jsSource = readFileSync(JS_SRC, 'utf8');
const dtsSource = readFileSync(DTS_SRC, 'utf8');

const jsExports = jsNamedExports(jsSource);
const { valueNames, typeNames, defaultMembers } = dtsKnownNames(dtsSource);

// Drift A: every JS named export must have a matching `.d.ts` value declaration
// (export function / const / let / class) AND be a member of the default-export
// interface so consumers can use either import style.
const missingValueDecls = [...jsExports].filter(n => !valueNames.has(n));
const missingDefaultMembers = [...jsExports].filter(n => !defaultMembers.has(n));

// Drift B: every value declaration in `.d.ts` must have a matching JS export.
const phantomValues = [...valueNames].filter(n => !jsExports.has(n));

let hasDrift = false;

if (missingValueDecls.length > 0) {
    hasDrift = true;
    process.stderr.write('\n[check-types] JS exports missing a value declaration in index.d.ts:\n');
    for (const name of missingValueDecls) {
        process.stderr.write(`  - ${name}  (need: export function ${name}(...) or export const ${name}: ...)\n`);
    }
}

if (missingDefaultMembers.length > 0) {
    hasDrift = true;
    process.stderr.write('\n[check-types] JS exports missing from the default-export interface in index.d.ts:\n');
    for (const name of missingDefaultMembers) {
        process.stderr.write(`  - ${name}\n`);
    }
}

if (phantomValues.length > 0) {
    hasDrift = true;
    process.stderr.write('\n[check-types] index.d.ts declares value exports not found in JS exports:\n');
    for (const name of phantomValues) {
        process.stderr.write(`  - ${name}\n`);
    }
}

if (hasDrift) {
    process.stderr.write('\nDrift detected. Update js/src/index.d.ts to match js/src/index.js.\n\n');
    process.exit(1);
} else {
    process.stdout.write(
        `[check-types] OK - ${jsExports.size} named exports verified ` +
        `(${valueNames.size} value decls, ${typeNames.size} type decls)\n`
    );
}

