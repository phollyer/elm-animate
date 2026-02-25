# Initialize

Before building and triggering animations, you need to initialize your animation state. Initialization sets the starting property values so your elements render correctly on first load - before any animation runs.

## Why Initialize?

Without initialization, animated elements may flash or jump when the page loads:

- An element meant to fade in might briefly appear at full opacity
- An element meant to slide in might appear in its final position first
- Transform properties might not apply until the first animation triggers

Initialization ensures your elements start in the correct state immediately.

## The Init Pattern

Every animation engine provides an `init` function that creates an `AnimState` with initial property values:

??? example "View Source Code"

    === "Transitions"

        ```elm
        initialAnimState : Transitions.AnimState
        initialAnimState =
            Transitions.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" ( 0.5, 0.5 )
                , Translate.initXY "slideBox" ( -100, 0 )
                ]
        ```

    === "Keyframes"

        ```elm
        initialAnimState : Keyframes.AnimState
        initialAnimState =
            Keyframes.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" ( 0.5, 0.5 )
                , Translate.initXY "slideBox" ( -100, 0 )
                ]
        ```

    === "Sub"

        ```elm
        initialAnimState : Sub.AnimState
        initialAnimState =
            Sub.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" ( 0.5, 0.5 )
                , Translate.initXY "slideBox" ( -100, 0 )
                ]
        ```

    === "WAAPI"

        ```elm
        initialAnimState : WAAPI.AnimState
        initialAnimState =
            WAAPI.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" ( 0.5, 0.5 )
                , Translate.initXY "slideBox" ( -100, 0 )
                ]
        ```

## Property Init Functions

Each animatable property module provides init functions for setting initial values:

| Property | Init Functions |
| -------- | -------------- |
| `Opacity` | `init` |
| `Translate` | `init`, `initX`, `initY`, `initZ`, `initXY`, `initXYZ` |
| `Scale` | `init`, `initX`, `initY`, `initZ`, `initXY`, `initXYZ` |
| `Rotate` | `init`, `initX`, `initY`, `initZ` |
| `BackgroundColor` | `init` |
| `FontColor` | `init` |

??? example "View Source Code"

    ```elm
    -- Single value inits
    Opacity.init "myGroup" 0.5              -- opacity: 0.5
    Scale.init "myGroup" 2                  -- scale: 2
    Rotate.init "myGroup" 45                -- rotate: 45deg
    
    -- Axis-specific inits
    Translate.initX "myGroup" 100           -- translateX: 100px
    Translate.initY "myGroup" -50           -- translateY: -50px
    Scale.initX "myGroup" 0.8               -- scaleX: 0.8
    
    -- Combined inits
    Translate.initXY "myGroup" ( 100, 50 )  -- translate: 100px, 50px
    Scale.initXYZ "myGroup" ( 1, 1, 0.5 )   -- scale3d: 1, 1, 0.5
    
    -- Color inits
    BackgroundColor.init "myGroup" (Color.rgba 0 0.5 1 0.8)
    FontColor.init "myGroup" Color.white
    ```

## Using Initialized State in Your Model

Store the initialized `AnimState` in your model:

??? example "View Source Code"

    ```elm
    type alias Model =
        { animState : Transitions.AnimState
        , -- other fields
        }

    init : Model
    init =
        { animState =
            Transitions.init
                [ Opacity.init "content" 0
                , Translate.initY "content" 20
                ]
        , -- other initializations
        }
    ```

## When to Skip Initialization

You can skip initialization when:

- Using `fireAndForget` for simple one-shot animations
- The element's initial state matches the default (e.g., opacity 1, no transform)
- You want the element visible immediately, then animate it later

For these cases, use `Engine.empty` instead:

??? example "View Source Code"

    === "Transitions"

        ```elm
        { animState = Transitions.empty }
        ```

    === "Keyframes"

        ```elm
        { animState = Keyframes.empty }
        ```

    === "Sub"

        ```elm
        { animState = Sub.empty }
        ```

    === "WAAPI"

        ```elm
        { animState = WAAPI.empty }
        ```

## Next Steps

Once initialized, you're ready to:

1. [Build](build.md) - Define your animation configurations
2. [Trigger](trigger.md) - Start animations with `animate` or `fireAndForget`
3. [Apply](apply.md) - Connect animations to your view elements
