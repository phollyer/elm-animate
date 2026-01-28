# Installation

## Elm Package

Install the Elm package:

```bash
elm install phollyer/elm-animate
```

This gives you access to all animation engines and properties.

## WAAPI JavaScript (Optional)

If you plan to use the [WAAPI Engine](../engines/waapi.md), you'll also need the JavaScript companion:

=== "npm"

    ```bash
    npm install elm-animate-waapi
    ```

=== "yarn"

    ```bash
    yarn add elm-animate-waapi
    ```

Then include it in your JavaScript:

```javascript
import ElmAnimateWaapi from 'elm-animate-waapi';

const app = Elm.Main.init({
    node: document.getElementById('app')
});

ElmAnimateWaapi.init(app.ports);
```

!!! note "WAAPI is optional"
    The CSS and Sub engines work without any JavaScript. Only add the WAAPI package if you need its specific features.

## Next Steps

Now that you have the package installed, let's create your first animation:

[Your First Animation →](first-animation.md){ .md-button .md-button--primary }
