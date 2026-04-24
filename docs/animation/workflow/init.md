# Initialize

All animations should be initialized ready for rendering and triggering.

## Why Initialize?

Initialization sets the starting property values so that:

- your elements render correctly on first load - before any animation runs
- the Engine knows where to start the element's first animation from

## The Init Pattern

### Property Init Functions

Each Property module provides `init` functions for setting initial values, the range of functions depends on the property:

- Opacity only has `init` - there is only one value to set
- Size has `init`, `initH`, `initW` & `initHW` - Size has height and width

Refer to each property's documentation for specifics.

### Engine Init Functions

Every animation Engine provides an `init` function that creates an `AnimState` with initial property values:

??? example "View Source Code"

    === "Transition"

        ```elm
        initialAnimState : Transition.AnimState
        initialAnimState =
            Transition.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initX "slideBox" -100 
                ]
        ```

    === "Keyframe"

        ```elm
        initialAnimState : Keyframe.AnimState
        initialAnimState =
            Keyframe.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initX "slideBox" -100 
                ]
        ```

    === "Sub"

        ```elm
        initialAnimState : Sub.AnimState
        initialAnimState =
            Sub.init
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initX "slideBox" -100 
                ]
        ```

    === "WAAPI"

        ```elm
        initialAnimState : WAAPI.AnimState
        initialAnimState =
            WAAPI.init waapiCommand waapiEvent <|
                [ Opacity.init "fadeBox" 0
                , Scale.initXY "growBox" 0.5 0.5
                , Translate.initX "slideBox" -100 
                ]
        ```

        The WAAPI Engine also requires it's port functions [`waapiCommand` & `waapiEvent`] so that it can talk to JS. 
        [More on these](../engines/waapi.md#3-define-ports-in-elm) later.

### Store it in Your Model

Store the initialized `AnimState` in your model:

??? example "View Source Code"

    === "Transition"
        ```elm
        type alias Model =
            { animState : Transition.AnimState
            , -- other fields
            }

        init : Model
        init =
            { animState =
                Transition.init
                    [ Opacity.init "content" 0
                    , Translate.initY "content" 20
                    ]
            , -- other initializations
            }
        ```

    === "Keyframe"
        ```elm
        type alias Model =
            { animState : Keyframe.AnimState
            , -- other fields
            }

        init : Model
        init =
            { animState =
                Keyframe.init
                    [ Opacity.init "content" 0
                    , Translate.initY "content" 20
                    ]
            , -- other initializations
            }
        ```

    === "Sub"
        ```elm
        type alias Model =
            { animState : Sub.AnimState
            , -- other fields
            }

        init : Model
        init =
            { animState =
                Sub.init
                    [ Opacity.init "content" 0
                    , Translate.initY "content" 20
                    ]
            , -- other initializations
            }
        ```

    === "WAAPI"
        ```elm
        type alias Model =
            { animState : WAAPI.AnimState Msg
            , -- other fields
            }

        init : Model
        init =
            { animState =
                WAAPI.init waapiCommand waapiEvent <|
                    [ Opacity.init "content" 0
                    , Translate.initY "content" 20
                    ]
            , -- other initializations
            }
        ```

        The WAAPI Engine also requires it's port functions [`waapiCommand` & `waapiEvent`] so that it can talk to JS. 
        [More on these](../engines/waapi.md#3-define-ports-in-elm) later.

## Next Steps

Once you have initialized your `AnimState`, the next step is to render your animations.

[Render →](render.md){ .md-button .md-button--primary }
