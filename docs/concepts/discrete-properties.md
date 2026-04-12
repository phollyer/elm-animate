# Discrete Properties

Most CSS properties like `opacity`, `transform`, and `background-color` can have intermediate values — the browser smoothly interpolates between start and end. These are called **continuous** properties.

**Discrete** properties like `display`, `visibility`, and `content-visibility` have no in-between states — they snap instantly from one value to the next. For example, there is no halfway point between `display: none` and `display: flex`.

This matters for animations because you often want to show or hide an element with a smooth fade, but the `display` property change happens instantly. Without discrete property support, the element either disappears before the fade completes, or appears without any transition at all.

All four animation engines support discrete properties through a unified `discreteEntry` / `discreteExit` API. The Transitions engine additionally requires `startingStyleNode` for entry animations.

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

## How It Works

All four engines share the same two functions for discrete properties:

- `discreteEntry` — sets a CSS property value when the animation **starts** (e.g., `display: flex` for a fade-in)
- `discreteExit` — holds a value during the animation and flips to a different value when it **ends** (e.g., `display: flex` during fade-out, then `display: none`)

Calling either function automatically enables discrete transition support in the Transitions engine.

!!! info "Browser Support (Transitions only)"
    The Transitions engine uses `transition-behavior: allow-discrete` under the hood, which requires modern browsers (Chrome 117+, Firefox 129+, Safari 18+). In older browsers, discrete property transitions won't animate — the property will snap immediately. If you need broader browser support, consider using Keyframes, Sub, or WAAPI instead.


## Entry Animations (Showing)

Entry animations make an element appear — for example, going from `display: none` to `display: flex` while fading in.

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

### Transitions: `startingStyleNode`

The Transitions engine additionally requires `startingStyleNode` in your view. This generates `@starting-style` CSS rules so the browser knows what continuous property values to animate FROM when an element first appears. Without it, entry animations are skipped.

```elm
view model =
    div []
        [ Transitions.startingStyleNode model.animState
        , div
            (Transitions.attributes "box" model.animState
                ++ Transitions.events GotAnimMsg
                ++ [ style "display" "none" ]
            )
            [ text "Hello!" ]
        ]
```

The element's base `display: none` acts as the hidden state; the engine overrides it with the `discreteEntry` value during animation.


## Exit Animations (Hiding)

Exit animations hide an element — for example, fading out and then setting `display: none`.

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


## API Summary

| Engine | Entry | Exit | Extra |
| ------ | ----- | ---- | ----- |
| Keyframes | `discreteEntry` | `discreteExit` | — |
| Sub | `discreteEntry` | `discreteExit` | — |
| WAAPI | `discreteEntry` | `discreteExit` | — |
| Transitions | `discreteEntry` | `discreteExit` | `startingStyleNode` |


## Next Steps

Learn about how animations handle transform ordering.

[Transform Order →](transform-order.md){ .md-button .md-button--primary }
