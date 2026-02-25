# Initialize

Before building and triggering animations, you need to initialize your animation state. 

## Why Initialize?

Initialization sets the starting property values so that:

- your elements render correctly on first load - before any animation runs
- the Engine knows where to start the element's animation from

Without initialization:

- your fade-in elements might briefly flash at full opacity
- your slide-in elements might appear in their final position first

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
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initXY "slideBox" -100 0 
                ]
        ```

    === "Keyframes"

        ```elm
        initialAnimState : Keyframes.AnimState
        initialAnimState =
            Keyframes.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initXY "slideBox" -100 0 
                ]
        ```

    === "Sub"

        ```elm
        initialAnimState : Sub.AnimState
        initialAnimState =
            Sub.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initXY "slideBox" -100 0 
                ]
        ```

    === "WAAPI"

        ```elm
        initialAnimState : WAAPI.AnimState
        initialAnimState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initXY "slideBox" -100 0 
                ]
        ```

        The WAAPI Engine also requires it's port functions [`waapiCommand` & `waapiEvent`] so that it can talk to JS. 
        [More on these](../engines/waapi.md#3-define-ports-in-elm) later.

## Property Init Functions

Each animatable property module provides `init` functions for setting initial values, the range of functions depends on the property:

- Opacity only has `init` - there is only one value to set
- Size has `init`, `initH`, `initW` & `initHW` - Size has height and width

Refer to each property's documentation for specifics.

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

## Next Steps

Once initialized, you're ready to:

1. [Build](build.md) - Define your animation configurations
2. [Trigger](trigger.md) - Start animations with `animate` or `fireAndForget`
3. [Apply](apply.md) - Connect animations to your view elements
