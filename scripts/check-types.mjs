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
 * Extract every name listed inside `export { ... }` blocks, following any
 * `as` aliases back to the original local binding.
 */
function exportListNames(src) {
    const names = new Set();
    for (const block of src.matchAll(/^export\s*\{([^}]+)\}/gm)) {
        for (const entry of block[1].split(',')) {
            const base = entry.trim().split(/\s+as\s+/)[0].trim();
            if (base) names.add(base);
        }
    }
    return names;
}

/**
 * Patterns whose first capture group is the exported name for declaration-style
 * exports (function / const). Used by `jsNamedExports` to avoid duplicating
 * the matchAll/add loop body for each pattern.
 */
const DECL_EXPORT_PATTERNS = [
    /^export\s+(?:async\s+)?function\s+(\w+)/gm,
    /^export\s+const\s+(\w+)/gm
];

/**
 * Extract every name that is a named (non-default) export from a JS source file.
 * Handles:
 *   export { a, b, c }
 *   export function foo (...)
 *   export async function foo (...)
 *   export const foo = ...
 */
function jsNamedExports(src) {
    const names = exportListNames(src);
    for (const pattern of DECL_EXPORT_PATTERNS) {
        for (const m of src.matchAll(pattern)) names.add(m[1]);
    }
    return names;
}

/**
 * Resolve the interface name backing the file's `export default NAME;` line,
 * following one level of `declare const NAME: TypeName;` aliasing so the
 * default export can be a typed const rather than the interface directly.
 * Returns null if the file has no default export.
 */
function resolveDefaultInterfaceName(src) {
    const defaultMatch = src.match(/^export\s+default\s+(\w+)\s*;/m);
    if (!defaultMatch) return null;

    const ifaceName = defaultMatch[1];
    const aliasRegex = new RegExp(`declare\\s+const\\s+${ifaceName}\\s*:\\s*(\\w+)\\s*;`);
    const aliasMatch = src.match(aliasRegex);
    return aliasMatch ? aliasMatch[1] : ifaceName;
}

/**
 * Collect the member names declared inside `interface NAME { ... }` in `src`.
 * Walks line-by-line tracking brace depth so nested object literals don't
 * terminate the scan early.
 */
function collectInterfaceMembers(src, ifaceName) {
    const members = new Set();
    if (!ifaceName) return members;

    const ifaceStart = new RegExp(`interface\\s+${ifaceName}\\s*\\{`);
    let inInterface = false;
    let depth = 0;

    for (const line of src.split('\n')) {
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
        if (memberMatch) members.add(memberMatch[1]);
    }
    return members;
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

    const defaultMembers = collectInterfaceMembers(src, resolveDefaultInterfaceName(src));
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

