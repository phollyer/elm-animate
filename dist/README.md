# elm-smooth-move JavaScript Companion

JavaScript companion library for the `elm-smooth-move` Elm package, providing Web Animations API integration via ports.

## Installation

```bash
npm install elm-smooth-move
```

## Quick Start

### 1. Include the JavaScript file

**Option A: Import from node_modules**
```javascript
import 'elm-smooth-move'
// or
const SmoothMovePorts = require('elm-smooth-move')
```

**Option B: CDN**
```html
<script src="https://unpkg.com/elm-smooth-move@1.0.0/dist/smooth-move-ports.js"></script>
```

### 2. Initialize in your Elm app

```javascript
// Initialize your Elm app
const app = Elm.Main.init({ node: document.getElementById('app') })

// Initialize SmoothMovePorts
SmoothMovePorts.init(app.ports)
```

### 3. Use in your Elm code

```elm
port module Main exposing (..)

import SmoothMovePorts

-- Your ports will be automatically connected
main =
    SmoothMovePorts.program { init = init, update = update, view = view }
```

## Features

- **Hardware Accelerated**: Uses Web Animations API for optimal performance
- **TypeScript Support**: Complete type definitions included
- **Easy Integration**: Simple port-based communication with Elm
- **Modern Browsers**: Supports all modern browsers with Web Animations API

## Elm Package

This JavaScript library is designed to work with the [`phollyer/elm-smooth-move`](https://package.elm-lang.org/packages/phollyer/elm-smooth-move/latest/) Elm package.

## API Documentation

See the [full documentation](https://package.elm-lang.org/packages/phollyer/elm-smooth-move/latest/SmoothMovePorts) for the Elm package.

## License

BSD-3-Clause - see LICENSE file for details.

## Author

Created by [Paul Hollyer](https://github.com/phollyer)