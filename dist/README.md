# elm-animate-waapi

JavaScript companion for the [`phollyer/elm-animate`](https://package.elm-lang.org/packages/phollyer/elm-animate/latest/) Elm package. Provides Web Animations API integration via Elm ports, enabling hardware-accelerated animations and scroll-driven animations (ScrollTimeline, ViewTimeline) from Elm.

## Installation

```bash
npm install elm-animate-waapi
```

## Usage

### 1. Install the Elm package

```bash
elm install phollyer/elm-animate
```

### 2. Add the JavaScript companion to your app

**ES module (bundler)**

```javascript
import ElmAnimateWAAPI from 'elm-animate-waapi'
```

**CommonJS**

```javascript
const ElmAnimateWAAPI = require('elm-animate-waapi')
```

**Script tag (CDN)**

```html
<script src="https://unpkg.com/elm-animate-waapi/dist/elm-animate-waapi.js"></script>
```

### 3. Initialize after your Elm app starts

```javascript
const app = Elm.Main.init({ node: document.getElementById('app') })

ElmAnimateWAAPI.init(app.ports)
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

`ElmAnimateWAAPI.init(ports)` subscribes to the `waapiCommand` port and drives animations using the browser's Web Animations API. It sends animation events (started, ended, progress) back to Elm via the `waapiEvent` port.

The same companion handles all three WAAPI-based engines:

| Elm Engine | Use case |
| ---------- | -------- |
| `Anim.Engine.WAAPI` | State-tracked animations with full control |
| `Anim.Engine.WAAPI.ScrollTimeline` | Animation progress tied to scroll position |
| `Anim.Engine.WAAPI.ViewTimeline` | Animation progress tied to element viewport position |

## TypeScript

Type definitions are included at `dist/elm-animate-waapi.d.ts`.

## Documentation

Full documentation, guides, and live examples at **[phollyer.github.io/elm-animate](https://phollyer.github.io/elm-animate)**.

## License

BSD-3-Clause — see LICENSE file for details.

## Author

Created by [Paul Hollyer](https://github.com/phollyer)
