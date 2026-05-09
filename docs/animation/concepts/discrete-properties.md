# Discrete Properties

Most CSS properties like `opacity`, `transform`, and `background-color` can have intermediate values, so the browser can smoothly interpolate between start and end. In CSS terms, these are **interpolable** values.

Some properties or value pairs animate with **discrete** behavior, which means there are no in between states and values snap at defined points. For example, there is no halfway point between `display: none` and `display: flex`.

In this documentation, "discrete properties" refers to CSS properties and values that use discrete animation behavior, typically keyword based values such as `display`, `visibility`, `content-visibility`, or `height: auto`.

This matters for animations because you often want to show or hide an element with a smooth fade, but the `display` property change happens instantly. Without discrete property support, the element either disappears before the fade completes, or appears without any transition at all.

All four animation engines support discrete properties through a unified API.

## Example

All four examples use `display` as a discrete property combined with an opacity fade. Click **Show** to fade in (setting `display: flex` on the first frame), and **Hide** to fade out (setting `display: none` on the last frame).

--8<-- "docs/animation/concepts/discrete-properties/discrete-properties.md:examples"

??? example "View Source Code"

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Animation/Transition/DiscreteProperties/Main.elm"
        ```

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/DiscreteProperties/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/DiscreteProperties/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/DiscreteProperties/Main.elm"
        ```


## `discreteEntry`

Sets a CSS property value when the animation **starts**. Use this when an element is appearing — for example, going from `display: none` to `display: flex` while fading in.

??? example "View Source Code"

    === "Transition"
    
        ```elm
        fadeIn =
            Transition.discreteEntry "display" "flex"
                >> Opacity.for "box"
                >> Opacity.to 1
                >> Opacity.duration 800
                >> Opacity.build
        ```
    === "Keyfram"
    
        ```elm
        fadeIn =
            Keyframe.discreteEntry "display" "flex"
                >> Opacity.for "box"
                >> Opacity.to 1
                >> Opacity.duration 800
                >> Opacity.build
        ```
    === "Sub"
    
        ```elm
        fadeIn =
            Sub.discreteEntry "display" "flex"
                >> Opacity.for "box"
                >> Opacity.to 1
                >> Opacity.duration 800
                >> Opacity.build
        ```
    === "WAAPI"
    
        ```elm
        fadeIn =
            WAAPI.discreteEntry "display" "flex"
                >> Opacity.for "box"
                >> Opacity.to 1
                >> Opacity.duration 800
                >> Opacity.build
        ```

The value is applied from the first frame and held throughout the animation.

### In `init`

To set a discrete property as part of the initial state, include `discreteEntry` in your `init` pipeline:

??? example "View Source Code"

    === "Transition"
        ```elm
        init =
            ( { animState =
                    Transition.init
                        [ Transition.discreteEntry "display" "flex"
                            >> Opacity.init "box" 1
                        ]
            }
            , Cmd.none
            )
        ```

    === "Keyframe"
        ```elm
        init =
            ( { animState =
                    Keyframe.init
                        [ Keyframe.discreteEntry "display" "flex"
                            >> Opacity.init "box" 1
                        ]
            }
            , Cmd.none
            )
        ```

    === "Sub"
        ```elm
        init =
            ( { animState =
                    Sub.init
                        [ Sub.discreteEntry "display" "flex"
                            >> Opacity.init "box" 1
                        ]
            }
            , Cmd.none
            )
        ```

    === "WAAPI"
        ```elm
        init =
            ( { animState =
                    WAAPI.init motionCmd motionMsg <|
                        [ WAAPI.discreteEntry "display" "flex"
                            >> Opacity.init "box" 1
                        ]
            }
            , Cmd.none
            )
        ```

    This tells the engine what value to apply at the initial render and at the start of entry animations. Here, the element will render with `display: flex` and `opacity: 1` as its initial visible state.


## `discreteExit`

Sets a CSS property value for exit animations. It holds the `from` value during the animation and flips to the `to` value when the animation **ends**. Use this when an element is disappearing — for example, fading out and then setting `display: none`.

??? example "View Source Code"

    === "Transition"

        ```elm
        fadeOut =
            Transition.discreteExit "display" "flex" "none"
                >> Opacity.for "box"
                >> Opacity.to 0
                >> Opacity.duration 800
                >> Opacity.build
        ```

    === "Keyframe"

        ```elm
        fadeOut =
            Keyframe.discreteExit "display" "flex" "none"
                >> Opacity.for "box"
                >> Opacity.to 0
                >> Opacity.duration 800
                >> Opacity.build
        ```

    === "Sub"

        ```elm
        fadeOut =
            Sub.discreteExit "display" "flex" "none"
                >> Opacity.for "box"
                >> Opacity.to 0
                >> Opacity.duration 800
                >> Opacity.build
        ```

    === "WAAPI"

        ```elm
        fadeOut =
            WAAPI.discreteExit "display" "flex" "none"
                >> Opacity.for "box"
                >> Opacity.to 0
                >> Opacity.duration 800
                >> Opacity.build
        ```

The three arguments are: property name, value during animation, value after animation ends.


## API Reference

| Function | Type | Description |
| -------- | ---- | ----------- |
| `discreteEntry` | `String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a CSS property value when the animation starts |
| `discreteExit` | `String -> String -> String -> AnimBuilder mode -> AnimBuilder mode` | Set a CSS property value during and after the animation |

These functions are available on the state-tracked animation engines: `Transition`, `Keyframe`, `Sub`, and `WAAPI`.

The timeline engines (`ScrollTimeline` and `ViewTimeline`) use the same property builders, but do not expose `discreteEntry` or `discreteExit` on their module API.

For engine-specific details on how discrete properties are implemented under the hood, see the individual engine pages:

- [Transition](../engines/transition.md#discrete-properties)
- [Keyframe](../engines/keyframes.md#discrete-properties)
- [Sub](../engines/sub.md#discrete-properties)
- [WAAPI](../engines/waapi.md#discrete-properties)


## Next Steps

Now that you've learnt about the Engines and Properties, learn about Interrupting Animations mid-flight.

[Interrupting Animations →](../concepts/interrupting-animations.md){ .md-button .md-button--primary }
