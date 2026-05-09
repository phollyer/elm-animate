# Pre-Publication Code Review — `elm-motion` / `@phollyer/elm-motion` 1.0.0

I read every JS source file, the TypeScript declarations, build/test config, license/packaging, and sampled the public Elm engine + property modules and a representative slice of `Internal/`. Comments are grouped by severity, with the "must-fix before publishing" items first.

## 1. Release Blockers

### 1.1 ✅ DONE (commit b00d395d) — LICENSE strips third-party attribution — **legal risk**

LICENSE credits derivative work from SmoothScroll (Linus Schoemaker, Ruben Lie King, 2019) for parts of `SmoothMoveScroll.elm` and `Internal/AnimationCore.elm`. LICENSE drops that paragraph entirely and shows only `Copyright (c) 2026, Paul Hollyer`. The npm tarball ships **both** files, but the BSD-3 clause requires the original authors' notice be retained in any redistribution. Either:
- Make LICENSE identical to root LICENSE, or
- Verify the derivative code is no longer present in the shipped JS (it isn't — JS is original — but the package still depends on Elm modules that may include it).

Right now the package is not BSD-3 compliant.

### 1.2 ✅ DONE (commit b00d395d) — npm ships the wrong README

`npm pack --dry-run` shows the tarball includes both root README.md (5.9 kB, GitHub-targeted) **and** README.md (3.2 kB, npm-targeted). npm always renders the root README.md on the package page, so the carefully-written npm-specific README in README.md is dead weight, and npm users see the GitHub README that points back to the Elm package and assumes the reader is an Elm developer. Either:
- Move npm-specific content into root README.md (and keep a copy or move the GitHub-specific content elsewhere), or
- Use package.json `"files"` with a publish-time README swap.

### 1.3 ✅ DONE — `window.app` is silently overwritten — single-app limit, global pollution

index.js previously did `window.app = { ports: ports };` unconditionally, and ports.js / animationEvents.js read the same global to send events back to Elm. This polluted the global namespace, silently clobbered any host code already using `window.app` (a near-universal Elm convention), and made it impossible to host two Elm apps on one page.

Resolution: introduced a module-scoped `portsRef` in [state.js](js/src/state.js). `init()` now sets `portsRef.ports` instead of `window.app`, and ports.js / animationEvents.js read from `portsRef`. The companion no longer touches `window.app` at all — the host app's `window.app` (if any) is left untouched. A second `init()` call with a different ports object emits a `PORTS_REINITIALIZED` warning so collisions are surfaced rather than silent.

Outcome: zero global pollution, no collision with host code, predictable single-app semantics with an explicit warning if the contract is violated. The documented public API (`ElmMotion.init(app.ports)`) is unchanged.

### 1.4 ✅ DONE — Polyfill loaded from hard-coded `unpkg` URL with no SRI

scroll.js previously lazy-loaded `https://unpkg.com/scroll-timeline-polyfill/dist/scroll-timeline.js` at runtime via `<script>` tag injection.

Resolution: `loadTimelinePolyfill` now uses `await import('scroll-timeline-polyfill/dist/scroll-timeline.js')`. Rollup is configured with `inlineDynamicImports: true`, so the polyfill (~60 KB) is bundled into both `dist/elm-motion.mjs` and `dist/elm-motion.js`. The polyfill IIFE only runs when a ScrollTimeline / ViewTimeline command first arrives, gated by the dynamic-import call site. The package was moved from `dependencies` to `devDependencies` since it is bundled.

Outcome: zero runtime CDN fetches, no SRI hash to maintain, no CSP impact for consumers, no version drift between npm dep and runtime fetch. Bundle grew from ~108 KB to ~165 KB (IIFE) / ~156 KB (ESM).

### 1.5 ✅ DONE — Stale TypeScript public API

index.d.ts has multiple defects despite check-types.mjs:

- `AnimationUpdate` describes a flat `{ positionX, positionY, rotationX, scaleX, ... }` shape that no longer matches the actual `propertyUpdate` payload produced in ports.js (`buildAnimatedPropertyData` emits nested `translate.x`, `rotate.x`, etc.).
- `TransformState` mixes `rotationX/Y/Z` (interface) vs `rotateX/Y/Z` (runtime).
- Named exports `init`, `onError`, `useConsoleReporter` are exported from index.js but only declared on the default-export `ElmMotion` interface — TS users doing `import { init } from '@phollyer/elm-motion'` (the tree-shakeable form your ESM build encourages) get no types.
- `ElmPorts` uses `data: any` for the subscribe callback. Acceptable for now but worth a `WaapiCommand` union once the API is documented.

The drift checker doesn't catch any of these — it only checks name presence, not shape. Tighten the checker or use `tsc --emitDeclarationOnly` from the JS source with JSDoc-typed exports (you already have JSDoc in errors.js and `index.js`).

### 1.6 ✅ DONE (commit b00d395d) — Dead/commented-out exposing entry in a public engine module

WAAPI.elm ends the exposing list with `--, onResize`. This violates the project's own rule (copilot-instructions.md: "Always remove deprecated functions and comments when refactoring") and is the kind of commented-out hint that suggests an unfinished feature. Remove it before publishing or commit to building it.

## 2. High Priority

### 2.1 ✅ DONE — Test coverage raised; thresholds tightened

Two new test suites land the lowest-hanging wins:

- `js/tests/transform.test.js` — replaces the old 2-test stub with 43 tests covering `getDefaultTransformState`, `normalizeTransformState`, `buildTransformString`, `parseTransformString`, `interpolateSubProperty`, and `computeTransformFromResolved`. transform.js lines: **34.23% → 68.76%**, funcs: **30% → 72.72%**.
- `js/tests/properties.test.js` — 30 new tests for `interpolateColor`, `buildSimplePropertyKeyframes`, `buildComplexPropertyKeyframes`, `buildPropertyKeyframes`, and `resolveScrollDrivenTransformValues`. properties.js lines: **53.22% → 79.30%**, funcs: **28.57% → 66.66%**.

All-files coverage moves from 58.98% → **68.63% lines**, 64.28% → **77.62% funcs**. vitest.config.js thresholds are bumped to 65/65/75/65 (lines/statements/funcs/branches), close to the new floor with a small headroom margin so coverage can't silently regress.

The remaining low-coverage modules — animations.js (36.91%), scroll.js (60.16%), parts of transform.js (matrix decomposition in `getCurrentTransform`) — are heavily DOM-bound. Pushing them above 80% requires switching the vitest environment to jsdom and writing fixture-based integration tests, which is left as a follow-up rather than blocking 1.0.0.

### 2.2 ✅ DONE — Empty catch blocks bypass the new error-reporting bridge

Three swallowed failures now route through `reportError`:
- animationEvents.js iteration-tracking `getComputedTiming()` failure → `ITERATION_TIMING_READ_FAILED`.
- animationEvents.js `commitStyles()` failure on finish → `COMMIT_STYLES_FAILED`, with the inner cancel fallback reporting `ANIMATION_CANCEL_FAILED` if it also throws.
- scroll.js `getScrollAnimationProgress` `getComputedTiming()` failure → `SCROLL_PROGRESS_READ_FAILED`.

All four new codes documented in [docs/shared/error-reporting.md](docs/shared/error-reporting.md).

### 2.3 ✅ DONE — Inconsistent port-presence guarding in ports.js

The port-presence check now lives in exactly one place: `sendToElm`. If the `waapiEvent` port is missing or not subscribeable, we report once via `WAAPI_EVENT_PORT_MISSING` (warning) and then silently drop subsequent events for the rest of the session. The flag is reset by `init()` so re-initializing gives a fresh chance to warn. The redundant `hasWaapiEventPort` and `getUpdatePort` helpers (and all the `if (updatePort)` guards in animationEvents.js) have been removed.

### 2.4 ✅ DONE — Unbounded module-level `Map`s — leak risk in long-running SPAs

state.js held six per-`animGroup` `Map`s but only two (`activeAnimations`, `animationGroups`) were ever evicted. The other four (`lastKnownTransforms`, `lastKnownPerspectiveOrigins`, `scrollDrivenIterationCounts`, `elementTransformOrders`) grew without bound, retaining detached DOM references via animation handles for the lifetime of the page.

Fixed by introducing two helpers in state.js:

- `cleanupAnimGroup(animGroup)` — drops the entry from all six maps. Called from every existing lifecycle endpoint: `finalizeAnimationTracking` on completion, `clearTrackedAnimations` (direct property update path), `stopAnimation`, `resetAnimation`, `restartAnimation`, the cancel branch in animations.js, and the `finish`/`cancel` listeners in scroll.js (which previously did no cleanup at all).
- `clearAllState()` — clears every map. Backs the new public `dispose()` exported from index.js, which also nulls `portsRef.ports` and resets the port-missing warning flag so the host Elm app can be torn down and re-initialised cleanly (typical SPA / hot-reload scenario).

`dispose()` is added to the TypeScript declarations and the default export.

### 2.5 ✅ DONE — Duplicated default transform order

scroll.js and animationControls.js both inlined the literal `['translate', 'rotate', 'skew', 'scale']` as a fallback. Both now import `DEFAULT_TRANSFORM_ORDER` from utils.js, so the canonical order has a single source of truth.

### 2.6 ✅ DONE — Dead public export — `addEasingFunction`

utils.js exported `addEasingFunction` but it was unreachable from the public entry, untested, and undocumented. Removed entirely. Easing is fully covered by the Elm-side `Easing` module, which already produces the CSS strings the WAAPI engine consumes — no JS-side registration API is needed.

## 3. Medium Priority

### 3.1 ✅ DONE — Engine exposing-list ordering aligned

- WAAPI.elm: `unfreeze*` exposing list and `@docs` line reordered from alphabetical (`X, XY, XYZ, XZ, Y, YZ, Z`) to logical single-→-multi (`X, Y, Z, XY, XZ, YZ, XYZ`), matching Sub.elm and the existing `freeze*` order. Function definitions were already in this order.
- Sub.elm: `getSkew*` exposing list and `@docs` reordered from alphabetical (`Current, End, Range, Start`) to logical (`Range, Start, End, Current`), matching every other `get*` group in both Sub and WAAPI.

### 3.2 ✅ DONE (partial) — Property module asymmetries

- **`CustomColor.ColorProperty` → `CustomColor.Property`** (constructor `CustomColorProperty` → `CustomProperty`). Both `Custom` and `CustomColor` now expose `Property(..)` with a `CustomProperty` escape hatch — symmetric, mechanically consistent with `import as` qualified usage. Two consumers updated (`docs/examples/src/Animation/ScrollTimeline/Main.elm`, `tests/Anim/Internal/Builder/TestProperty.elm`).
- **`Size.from` added** for parity with `Scale.from` and `Size.init`. Sets width and height to the same value (delegates to `fromHW v v`).
- **Plain `init` / `from` deliberately NOT added to Translate, Rotate, Skew.** A uniform single-value initializer is unambiguous for `Scale` (uniform scaling is a common operation) and `Size` (square dimensions are common), but for translate / rotate / skew the same call would mean "translate by N on X *and* Y *and* Z" or "rotate N degrees around X *and* Y *and* Z simultaneously" — almost never the user's intent. The explicit-axis variants (`initX`, `initXY`, `initXYZ`, etc.) remain the only way to set these properties. Documented here rather than papering over with a confusing convenience.

### 3.3 ✅ DONE — `parseColor` hoisted to module level

properties.js: the inner arrow `const parseColor = (str) => ...` inside `interpolateColor` is now a module-level named function, matching the dispatch-table style used everywhere else in the file. Added a JSDoc block that explicitly documents the silent fallback to opaque black for unrecognised input (named colors, 3-digit hex, `hsl(...)`) and points users at `Anim.Extra.Color` to pre-resolve. The 7 existing color tests in [js/tests/properties.test.js](js/tests/properties.test.js) (rgb, rgba, hex, fallback, rounding) cover the hoisted function with no source-test changes needed.

### 3.4 ✅ DONE — Doc comment style drift trimmed

- Size.elm: removed `(what else is there 🤷‍♂️)` aside and emoji from the **Default** line.
- PerspectiveOrigin.elm: capitalised "engines" → "Engines" in the "track end value" paragraph for consistency with the other 6 property modules.

The "Engines track end value" paragraph audit confirmed the note is already present in all 7 property modules with sensible-default semantics — code-review's claim that it was missing from multi-axis modules was incorrect.

### 3.5 ✅ DONE — Empty `peerDependencies` removed

package.json: dropped `"peerDependencies": {}`. The polyfill is bundled (1.4) so there's no peer to declare.

## 4. Low Priority / Polish

### 4.1 - animationEvents.js hardcodes a 16 ms rAF throttle — make it a constant near the top of the file with a comment explaining the choice (60 fps cap)

### 4.2 properties.js complex-easing path bakes 30 keyframes with no constant — same treatment

### 4.3 Per-frame `getComputedStyle` calls in `buildAnimatedPropertyData` (ports.js) are a known perf footgun for many simultaneous animations; document the cost or memoize per (element, frame)

### 4.4 rollup.config.js builds without sourcemaps. For a 100 kB shipped artifact, sourcemaps in dist (gitignored from npm via `files`) would massively help integrators debug

### 4.5 package.json has `"prepare": "npm run build"`. Standard, but means every consumer's `npm install` runs Rollup. Consider `prepublishOnly` for the same effect without the install-time cost (tarball is already built)

✅ **DONE** (different fix). The reviewer's `prepublishOnly` suggestion doesn't apply: this is a Pattern B publish (`npm publish dist/`), so the root `prepare` only ever fires for contributors, never for downstream consumers, and a root-level `prepublishOnly` would not fire on `npm publish dist/` either. Instead removed `prepare` entirely and surfaced the build steps as discoverable npm scripts: added `build:docs` (chains `npm run build` → `bash scripts/build-docs-examples.sh`) and `docs:serve`. Contributor flow is now `npm install` (fast, deps + Elm tools only) → `npm test` / `npm run build` / `npm run build:docs` / `npm run docs:serve` as needed. CI updated to call `npm run build:docs` instead of invoking the script directly. Validated: `npm run build:docs` produces 65 successful builds, all formatting clean.

### 4.6 elm-doc-preview is in `devDependencies` but no script wires it up — remove if unused

✅ **DONE.** Removed `elm-doc-preview` from npm `devDependencies`. Migrated Elm-native tooling to `elm-tooling.json` (`elm` 0.19.1, `elm-format` 0.8.8, `elm-json` 0.2.13) managed by the `elm-tooling` CLI. Added `postinstall: elm-tooling install` so a fresh `npm install` provisions all Elm binaries into `node_modules/.bin/`. Updated `scripts/format.sh`, `scripts/build-docs-examples.sh`, and `scripts/build-example.sh` to prepend `node_modules/.bin` to `PATH`. Validated: 65 docs examples, 526 Elm tests, 102 JS tests — all green. For local API docs preview, run `npx elm-doc-preview` (no devDep needed).

### 4.7 coverage directory is checked into the workspace root (`coverage/js/...`) — confirm it's gitignored (it is, per .gitignore) but the existing committed js files in your tree should be removed

✅ **DONE.** Verified: `git ls-files coverage/` returned no tracked files. The `coverage/` tree shown in the workspace is purely generated and already untracked. No-op.

### 4.8 `mcp_codacy_mcp_se_codacy_cli_analyze` was not run this turn (Codacy CLI not invoked); recommend running it as a final gate. The Codacy ESLint+PMD+Lizard pass will likely flag a couple of CCN > 10 functions in transform.js (matrix decomposition) and animations.js (`processElementAnimation`) — these are inherent complexity but should be either annotated or extracted

## 5. What's Genuinely Good

- Internal Property modules (`src/Anim/Internal/Property/*.elm`) follow a consistent `default / distance / duration / ...` pattern.
- errors.js is excellent — fully JSDoc-typed, 100% line coverage, proper subscriber semantics with handler-error isolation.
- targets.js, state.js, utils.js are tight, single-purpose, and well-tested where applicable.
- The transform decomposition in transform.js is mathematically sound and well-commented (gimbal-lock branches handled).
- npm tarball is a reasonable 48.5 kB packed.
- `0` npm audit vulnerabilities.
- Builder API is a real architectural achievement — engine swap really is just a module import change.
- The recently flattened `Anim.Engine.{ScrollTimeline,ViewTimeline}` namespace is cleaner than what it replaced.

## 6. Recommended Pre-Publish Sequence

1. Fix LICENSE attribution (1.1) and README shipping (1.2) — **legal/UX must-fix**.
2. Remove the `--, onResize` line (1.6) — one-line diff.
3. Remove polyfill CDN load or add SRI + version pin (1.4).
4. Repair index.d.ts `AnimationUpdate` / `TransformState` shapes and expose `init`/`onError`/`useConsoleReporter` as named declarations (1.5).
5. Address `window.app` collision (1.3) — either accept a handle or warn loudly.
6. Wire empty catches to `reportError` (2.2).
7. Add `dispose`/cleanup to state.js (2.4).
8. Align `unfreeze*` and `getSkew*` ordering between `Sub` and `WAAPI` (3.1).
9. Add a test pass on transform.js and animations.js, raise coverage thresholds (2.1).
10. Run Codacy CLI as a final gate.

Items 1–4 and 6 are mechanical; items 5, 7, 8 may be breaking-API and should land in 1.0.0 since you've stated 1.x doesn't yet promise stability.

Want me to start applying any of these?
