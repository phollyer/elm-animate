#!/usr/bin/env python3
"""Generate elm-animate-waapi.mjs from elm-animate-waapi.js by converting IIFE to ES module."""

import os

script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
js_path = os.path.join(project_root, 'dist', 'elm-animate-waapi.js')
mjs_path = os.path.join(project_root, 'dist', 'elm-animate-waapi.mjs')

with open(js_path, 'r') as f:
    lines = f.readlines()

# Find IIFE boundaries
iife_start = None
iife_end = None
for i, line in enumerate(lines):
    if 'window.ElmAnimateWAAPI = (function ()' in line:
        iife_start = i
    if line.strip() == '})();':
        iife_end = i

assert iife_start is not None, "Could not find IIFE start"
assert iife_end is not None, "Could not find IIFE end"

# Find the return block (public API exports)
return_start = None
for i in range(iife_end - 1, iife_start, -1):
    if lines[i].strip().startswith('return {'):
        return_start = i
        break

assert return_start is not None, "Could not find return block"

# ES module header
header = '''\
/**
 * ElmAnimateWAAPI JavaScript Integration (ES Module)
 *
 * This file provides the JavaScript side of port-based animations for the
 * ElmAnimateWAAPI Elm module. It uses the Web Animations API for high-performance
 * hardware-accelerated animations supporting all animation properties.
 *
 * Usage:
 * import ElmAnimateWAAPI from 'elm-animate-waapi';
 *
 * const app = Elm.Main.init({ node: document.getElementById('app') });
 * ElmAnimateWAAPI.init(app.ports);
 */

'''

# Extract body: lines between 'use strict' and the return block, dedented by 4 spaces
body_lines = []
# Skip iife_start (window.ElmAnimate...) and iife_start+1 ('use strict';)
body_start = iife_start + 2
for i in range(body_start, return_start):
    line = lines[i]
    # Dedent by 4 spaces
    if line.startswith('    '):
        body_lines.append(line[4:])
    elif line.strip() == '':
        body_lines.append('\n')
    else:
        body_lines.append(line)

# ES module footer with exports
footer = '''
/**
 * Add custom easing function
 */
export function addEasingFunction(name, cssValue) {
    easingFunctions[name] = cssValue;
}

// Export the activeAnimations map for advanced usage
export { activeAnimations };

// Default export for simpler imports
export default {
    init,
    getCurrentTransform,
    stopAnimation,
    resetAnimation,
    restartAnimation,
    pauseAnimation,
    resumeAnimation,
    addEasingFunction,
    activeAnimations
};
'''

with open(mjs_path, 'w') as f:
    f.write(header)
    f.writelines(body_lines)
    f.write(footer)

# Count lines for verification
with open(mjs_path, 'r') as f:
    mjs_line_count = len(f.readlines())

print(f"Generated {mjs_path}")
print(f"  JS lines: {len(lines)}, IIFE body: {body_start}-{return_start}, MJS lines: {mjs_line_count}")
