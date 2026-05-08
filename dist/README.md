# @phollyer/elm-motion

JavaScript companion for the [`phollyer/elm-motion`](https://package.elm-lang.org/packages/phollyer/elm-motion/latest/) Elm package. Provides Web Animations API integration via Elm ports, enabling hardware-accelerated animations and scroll-driven animations (ScrollTimeline, ViewTimeline) from Elm.

## Installation

```bash
npm install @phollyer/elm-motion
```

## Usage

### 1. Install the Elm package

```bash
elm install phollyer/elm-motion
```

### 2. Add the JavaScript companion to your app

**ES module (bundler)**

```javascript
import ElmMotion from '@phollyer/elm-motion'
```

**CommonJS**

```javascript
const ElmMotion = require('@phollyer/elm-motion')
```

**Script tag (CDN)**

```html
<script src="https://unpkg.com/@phollyer/elm-motion/dist/elm-motion.js"></script>
```

### 3. Initialize after your Elm app starts

```javascript
const app = Elm.Main.init({ node: document.getElementById('app') })

ElmMotion.init(app.ports)
```

### 4. Define ports in your Elm module

```elm
port module Main exposing (..)

port waapiCommand : Json.Encode.Value -> Cmd msg
port waapiEvent : (Json.Encode.Value -> msg) -> Sub msg
```

Pass these ports to the engine:

```elm
import Anim.Engine.WAAPI as WAAPI

animState =
    WAAPI.init waapiCommand waapiEvent [ Opacity.init "box" 0 ]
```

## What this companion does

`ElmMotion.init(ports)` subscribes to the `waapiCommand` port and drives animations using the browser's Web Animations API. It sends animation events (started, ended, progress) back to Elm via the `waapiEvent` port.

The same companion handles all three WAAPI-based engines:

| Elm Engine | Use case |
| ---------- | -------- |
| `Anim.Engine.WAAPI` | State-tracked animations with full control |
| `Anim.Engine.ScrollTimeline` | Animation progress tied to scroll position |
| `Anim.Engine.ViewTimeline` | Animation progress tied to element viewport position |

## Error reporting

The companion is **silent by default**. Opt in to receive reports via `onError` (your own subscriber) or the built-in console adapter `useConsoleReporter`.

```javascript
import ElmMotion from '@phollyer/elm-motion';

// Development
if (process.env.NODE_ENV !== 'production') {
    ElmMotion.useConsoleReporter();
}

// Production
ElmMotion.onError((error, context) => {
    Sentry.captureException(error, { extra: context });
});

ElmMotion.init(app.ports);
```

Each subscriber receives `(error, context)`. The context object always contains a `source`, a `severity` (`'error'` or `'warning'`) and usually a stable `code` you can route on (e.g. `TARGET_NOT_FOUND`, `API_UNSUPPORTED`, `POLYFILL_LOAD_FAILED`).

See the **[full Error Reporting guide](https://phollyer.github.io/elm-motion/shared/error-reporting/)** for the API reference, the complete list of error codes, and routing patterns.

## TypeScript

Type definitions are included at `dist/elm-motion.d.ts`.

## Documentation

Full documentation, guides, and live examples at **[phollyer.github.io/elm-motion](https://phollyer.github.io/elm-motion)**.

## License

BSD-3-Clause — see LICENSE file for details.

## Author

Created by [Paul Hollyer](https://github.com/phollyer)
