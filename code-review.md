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

### 1.3 `window.app` is silently overwritten — single-app limit, global pollution

index.js does `window.app = { ports: ports };` unconditionally, and the rest of the code (ports.js, animationEvents.js) depends on that single global. Consequences:
- Multiple Elm apps on the same page collide.
- Any host app already using `window.app` (extremely common Elm convention) is silently clobbered.
- No way for the user to opt out.

For 1.0.0 this is an architectural smell that will surface in real-world integrations. At minimum: warn (via `reportError`) when overwriting an existing `window.app`, and accept an opaque app handle so the library doesn't need a global.

### 1.4 Polyfill loaded from hard-coded `unpkg` URL with no SRI

scroll.js lazy-loads `https://unpkg.com/scroll-timeline-polyfill/dist/scroll-timeline.js` at runtime even though the same package is a runtime dependency in package.json. Issues:
- **Supply-chain risk**: no `integrity=` hash, no version pin, no fallback. A future unpkg compromise or registry takeover affects every user.
- **Privacy/CSP**: loading from a third-party CDN forces every consumer's CSP to allow `unpkg.com`.
- **Duplication**: the npm dependency is unused at runtime — bundlers won't tree-shake it because it's not statically imported.

Either bundle it via Rollup as a normal dependency, or remove it from package.json and document the polyfill as something the integrator must provide.

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

### 2.1 Test coverage is far below what an enterprise release expects

Actual coverage from `npm run test:js:coverage`:

| File | Lines | Funcs |
| --- | --- | --- |
| animations.js | **36.91%** | 27.27% |
| transform.js | **34.23%** | 30% |
| properties.js | 53.22% | 28.57% |
| scroll.js | 57.34% | 81.25% |
| ports.js | 61.82% | 71.42% |
| `index.js` | 70.22% | 100% |
| animationEvents.js | 84.25% | 91.66% |
| animationControls.js | 89.10% | 100% |
| **All files** | **58.98%** | **64.28%** |

vitest.config.js thresholds are 44% / 56% — set artificially low so CI passes. The largest, math-heaviest modules (animations.js, transform.js) — which are the ones most likely to regress silently — have the **worst** coverage. Five of the twelve JS modules (`animations`, `properties`, `scroll`, `ports`, `targets`) have no dedicated test file; coverage comes only from incidental hits via `publicApi.test.js`.

Recommendation before 1.0.0: target ≥80% lines on transform.js, animations.js, properties.js, scroll.js, then raise thresholds to match.

### 2.2 Empty catch blocks bypass the new error-reporting bridge

You just shipped opt-in error reporting via `reportError` in errors.js, but several caught failures never reach it:
- animationEvents.js: `commitStyles()` failure swallowed.
- animationEvents.js: nested cancel-on-error swallowed.
- scroll.js: `getComputedTiming()` failure swallowed.

Each should call `reportError(err, { source, severity: 'warning', code, ... })`. Otherwise users running with `useConsoleReporter()` get a partial picture, defeating the feature.

### 2.3 Inconsistent port-presence guarding in ports.js

ports.js:
- `sendLifecycleEvent` checks `hasWaapiEventPort()` first.
- `sendIterationEvent`, `sendScrollLifecycleEvent`, `sendPropertyUpdate` go straight through `sendToElm`, which silently no-ops if the port is missing.

Either always check (and report a single warning once when missing) or never check. Current state is the worst of both worlds: half the events are silently dropped, half log nothing.

### 2.4 Unbounded module-level `Map`s — leak risk in long-running SPAs

state.js holds five `Map`s with no eviction. Every animation, every scroll, every iteration is retained for the lifetime of the page. There is no `clear` API exposed in index.js. For SPAs that mount/unmount many components this will leak DOM references via animation handles and prevent GC of detached nodes.

Add at minimum a `disposeElement(elementId)` (or wire it to a `cancel`/`finish` cleanup that deletes the map entries) and expose a `dispose()` that clears everything when the host Elm app is torn down.

### 2.5 Duplicated default transform order

utils.js exports `DEFAULT_TRANSFORM_ORDER`. animationControls.js re-declares the literal `['translate', 'rotate', 'skew', 'scale']` instead of importing it. If the canonical order ever changes, controls will silently use the wrong fallback.

### 2.6 Dead public export — `addEasingFunction`

utils.js exports `addEasingFunction` but index.js doesn't re-export it, so external callers can't reach it via the public entry. Either expose it through `index.js` (and document/test it) or delete it.

## 3. Medium Priority

### 3.1 Public Elm API — engine exposing-list inconsistencies

Reading every engine module side-by-side, three are worth fixing for symmetry:

- **`Sub.elm` vs `WAAPI.elm` — `unfreeze*` ordering**:
  - Sub.elm: `unfreezeX, unfreezeY, unfreezeZ, unfreezeXY, unfreezeXZ, unfreezeYZ, unfreezeXYZ` (logical: single → multi)
  - WAAPI.elm: `unfreezeX, unfreezeXY, unfreezeXYZ, unfreezeXZ, unfreezeY, unfreezeYZ, unfreezeZ` (alphabetical)

  Pick one. The `freeze*` lists are identical between them — `unfreeze*` must match.

- **`Sub.elm` vs `WAAPI.elm` — `getSkew*` ordering**:
  - `Sub`: `getSkewCurrent, getSkewEnd, getSkewRange, getSkewStart`
  - `WAAPI`: `getSkewRange, getSkewStart, getSkewEnd, getSkewCurrent` (matches the other `get*` groups in WAAPI)

  Sub puts Skew alphabetical; every other Sub `get*` group is `Range, Start, End, Current`. Unify.

### 3.2 Public Elm API — Property module asymmetries

From the exposing lists:

| Module | `init` | `from` |
| --- | --- | --- |
| `Opacity`, `Custom`, `CustomColor` | yes | yes |
| `Rotate`, `Skew` | **no plain `init`** | **no plain `from`** |
| `Scale`, `Translate`, `Size` | yes (+ axis variants) | yes (+ axis variants) |
| `PerspectiveOrigin` | `initPx`, `initPercent` (no plain `init`) | yes |

`Rotate` and `Skew` are the only multi-axis properties without a plain `init` / `from`. Either add them or document the deliberate omission. As-is, users transferring code between `Translate` and `Rotate` hit a confusing API gap.

`Custom` exposes the constructor as `Property(..)` while `CustomColor` exposes `ColorProperty(..)`. Either rename to `CustomProperty` / `CustomColor.Property` or align both names. The current pair is mildly confusing in import-explicit code.

### 3.3 properties.js — outlier code style

properties.js is 403 lines of named-function builders for each property type, except `interpolateColor`, which uses an inner arrow `parseColor` const. Hoist to a named module-level function (matches the dispatch-table style used everywhere else in the file) and add a unit test — a silent fallback to `{r:0,g:0,b:0,a:1}` on parse failure can produce baffling visual bugs that never reach the error reporter.

### 3.4 Doc comment style drift across Property modules

The `Opacity`, `Rotate`, `Scale`, `Translate`, `Skew`, `Size` modules all have a "sensible default" paragraph but the wording varies subtly. Size.elm contains `(what else is there 🤷‍♂️)` — an emoji and an aside that doesn't fit the otherwise formal tone of public Elm docs. `Opacity` mentions "Engines track the end value" — a useful note that's missing from the multi-axis modules. Consider standardizing a one-paragraph "Defaults & continuation" block in every property module's header doc.

### 3.5 `peerDependencies: {}` is a literal empty object

package.json declares `"peerDependencies": {}`. Either remove the key or list the actual peer if you intend to ask consumers to provide their own polyfill.

## 4. Low Priority / Polish

- animationEvents.js hardcodes a 16 ms rAF throttle — make it a constant near the top of the file with a comment explaining the choice (60 fps cap).
- properties.js complex-easing path bakes 30 keyframes with no constant — same treatment.
- Per-frame `getComputedStyle` calls in `buildAnimatedPropertyData` (ports.js) are a known perf footgun for many simultaneous animations; document the cost or memoize per (element, frame).
- rollup.config.js builds without sourcemaps. For a 100 kB shipped artifact, sourcemaps in dist (gitignored from npm via `files`) would massively help integrators debug.
- package.json has `"prepare": "npm run build"`. Standard, but means every consumer's `npm install` runs Rollup. Consider `prepublishOnly` for the same effect without the install-time cost (tarball is already built).
- elm-doc-preview is in `devDependencies` but no script wires it up — remove if unused.
- coverage directory is checked into the workspace root (`coverage/js/...`) — confirm it's gitignored (it is, per .gitignore) but the existing committed js files in your tree should be removed.
- `mcp_codacy_mcp_se_codacy_cli_analyze` was not run this turn (Codacy CLI not invoked); recommend running it as a final gate. The Codacy ESLint+PMD+Lizard pass will likely flag a couple of CCN > 10 functions in transform.js (matrix decomposition) and animations.js (`processElementAnimation`) — these are inherent complexity but should be either annotated or extracted.

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
