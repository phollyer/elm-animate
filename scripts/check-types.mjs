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
 * Extract every member name from the interface that is the default export,
 * plus every top-level named export from a d.ts source.
 *
 * The default export interface is found by:
 *   1. Locating `export default InterfaceName`
 *   2. Finding the `interface InterfaceName { ... }` body using brace-depth
 *      tracking (so nested braces in generic types don't confuse the parser)
 *   3. Collecting all method/property names
 *
 * Top-level named exports cover:
 *   export function foo ...
 *   export const foo ...
 *   export interface Foo ...
 *   export type Foo = ...
 */
function dtsKnownNames(src) {
    const names = new Set();

    // Top-level named exports
    for (const m of src.matchAll(/^export\s+(?:declare\s+)?(?:function|const|let|class|interface|type)\s+(\w+)/gm)) {
        names.add(m[1]);
    }

    // Members of the default-export interface.
    // Use line-by-line brace-depth counting to handle members like:
    //   activeAnimations: Map<string, Map<string, { ... }>>
    const defaultMatch = src.match(/^export\s+default\s+(\w+)\s*;/m);
    if (defaultMatch) {
        const ifaceName = defaultMatch[1];
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

            // Track brace depth across the line
            for (const ch of line) {
                if (ch === '{') depth++;
                else if (ch === '}') depth--;
            }
            if (depth <= 0) break;

            // Interface members are indented by 4 spaces at depth 1
            const memberMatch = line.match(/^ {4}(\w+)\s*[(?:]/);
            if (memberMatch) names.add(memberMatch[1]);
        }
    }

    return names;
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

const jsSource = readFileSync(JS_SRC, 'utf8');
const dtsSource = readFileSync(DTS_SRC, 'utf8');

const jsExports = jsNamedExports(jsSource);
const dtsNames = dtsKnownNames(dtsSource);

const undeclared = [...jsExports].filter(n => !dtsNames.has(n));
const phantom = [...dtsNames].filter(n => !jsExports.has(n) && !['ElmPorts', 'ElmApp', 'AnimationData', 'PerspectiveConfig', 'ElementConfig', 'PropertyAnimation', 'AnimationUpdate', 'TransformState', 'ElmMotion'].includes(n));

let hasDrift = false;

if (undeclared.length > 0) {
    hasDrift = true;
    process.stderr.write('\n[check-types] JS exports missing from index.d.ts:\n');
    for (const name of undeclared) {
        process.stderr.write(`  - ${name}\n`);
    }
}

if (phantom.length > 0) {
    hasDrift = true;
    process.stderr.write('\n[check-types] index.d.ts declares names not found in JS exports:\n');
    for (const name of phantom) {
        process.stderr.write(`  - ${name}\n`);
    }
}

if (hasDrift) {
    process.stderr.write('\nDrift detected. Update js/src/index.d.ts to match js/src/index.js.\n\n');
    process.exit(1);
} else {
    process.stdout.write('[check-types] OK - no drift between index.js exports and index.d.ts\n');
}
