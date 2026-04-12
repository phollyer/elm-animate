# Discrete Properties

Most CSS properties like `opacity`, `transform`, and `background-color` can have intermediate values — the browser smoothly interpolates between start and end. These are called **continuous** properties.

**Discrete** properties like `display`, `visibility`, and `content-visibility` have no in-between states — they snap instantly from one value to the next. For example, there is no halfway point between `display: none` and `display: flex`.

This matters for animations because you often want to show or hide an element with a smooth fade, but the `display` property change happens instantly. Without discrete property support, the element either disappears before the fade completes, or appears without any transition at all.

All four animation engines support discrete properties, though the API differs between Transitions and the other engines.

## Example

All four examples use `display` as a discrete property combined with an opacity fade. Click **Show** to fade in (setting `display: flex` on the first frame), and **Hide** to fade out (setting `display: none` on the last frame).

=== "Transitions"

    <iframe src="../../examples/src/Engines/Transitions/DiscreteProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Keyframes"

    <iframe src="../../examples/src/Engines/Keyframes/DiscreteProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="../../examples/src/Engines/Sub/DiscreteProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="../../examples/src/Engines/WAAPI/DiscreteProperties/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    === "Transitions"

        ```elm
        --8<-- "docs/examples/src/Engines/Transitions/DiscreteProperties/Main.elm"
        ```

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/DiscreteProperties/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/DiscreteProperties/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/DiscreteProperties/Main.elm"
        ```

## Two Approaches

The engines use two different strategies for handling discrete properties:

### Elm-Managed (Keyframes, Sub, WAAPI)

These engines manage discrete properties directly in Elm via inline styles. The engine applies the entry value on the first animation frame and the exit value on the last frame.

- `discreteEntry` — sets a CSS property value when the animation **starts**
- `discreteExit` — sets a CSS property value when the animation **ends**, with a different value while animating

This approach works in all browsers that support the engine itself — no additional browser feature requirements.

### CSS-Native (Transitions)

The Transitions engine uses the browser's native `transition-behavior: allow-discrete` CSS feature with `@starting-style` rules.

- `allowDiscrete` — enables discrete transition behaviour
- `startingStyleNode` — generates `@starting-style` CSS rules for entry animations

!!! info "Browser Support"
    `allowDiscrete` requires modern browsers (Chrome 117+, Firefox 129+, Safari 18+). In older browsers, discrete property transitions won't animate — the property will snap immediately. If you need broader browser support, consider using Keyframes, Sub, or WAAPI instead.


## Entry Animations (Showing)

Entry animations make an element appear — for example, going from `display: none` to `display: flex` while fading in.

=== "Keyframes / Sub / WAAPI"

    Use `discreteEntry` to set the visible state when the animation starts:

    ```elm
    fadeIn =
        Keyframes.discreteEntry "display" "flex"
            >> Opacity.for "box"
            >> Opacity.to 1
            >> Opacity.duration 800
            >> Opacity.build
    ```

    Set the initial hidden state in `init`:

    ```elm
    init =
        ( { animState =
                Keyframes.init
                    [ Keyframes.discreteEntry "display" "flex"
                        >> Opacity.init "box" 1
                    ]
          }
        , Cmd.none
        )
    ```

    !!! tip
        The `discreteEntry` call in `init` tells the engine what value to apply at the start of future animations. Here, the element renders with `display: flex` and `opacity: 1` as its initial visible state.

=== "Transitions"

    Use `allowDiscrete` and include `startingStyleNode` in your view:

    ```elm
    fadeIn =
        Transitions.allowDiscrete
            >> Opacity.for "box"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.duration 800
            >> Opacity.build
    ```

    The view must include `startingStyleNode` and conditionally set `display`:

    ```elm
    view model =
        div []
            [ Transitions.startingStyleNode model.animState
            , div
                (Transitions.attributes "box" model.animState
                    ++ Transitions.events GotAnimMsg
                    ++ [ style "display"
                            (if model.isVisible then "flex" else "none")
                       ]
                )
                [ text "Hello!" ]
            ]
    ```

    `startingStyleNode` generates `@starting-style` CSS rules so the browser knows what values to animate FROM when the element first appears. Without it, entry animations are skipped.


## Exit Animations (Hiding)

Exit animations hide an element — for example, fading out and then setting `display: none`.

=== "Keyframes / Sub / WAAPI"

    Use `discreteExit` to set both the visible value (used during the animation) and the final hidden value (applied on the last frame):

    ```elm
    fadeOut =
        Keyframes.discreteExit "display" "flex" "none"
            >> Opacity.for "box"
            >> Opacity.to 0
            >> Opacity.duration 800
            >> Opacity.build
    ```

    The three arguments are: property name, value during animation, value after animation ends.

=== "Transitions"

    Exit animations work automatically with just `allowDiscrete`. The browser keeps the element visible during the transition, then hides it at the end:

    ```elm
    fadeOut =
        Transitions.allowDiscrete
            >> Opacity.for "box"
            >> Opacity.from 1
            >> Opacity.to 0
            >> Opacity.duration 800
            >> Opacity.build
    ```

    Conditionally set `display` in the view based on your model state — when you set it to `none`, the browser will animate the transition before hiding.


## API Summary

| Engine | Entry | Exit |
| ------ | ----- | ---- |
| Keyframes | `discreteEntry` | `discreteExit` |
| Sub | `discreteEntry` | `discreteExit` |
| WAAPI | `discreteEntry` | `discreteExit` |
| Transitions | `allowDiscrete` + `startingStyleNode` | `allowDiscrete` |


## Next Steps

Learn about how animations handle transform ordering.

[Transform Order →](transform-order.md){ .md-button .md-button--primary }
