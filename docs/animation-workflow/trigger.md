# Triggering Animations

Once you've [built an animation](build.md), you need to trigger it. This is where the engine processes your configuration — computing styles, interpolation values, and keyframes — and stores the results in `AnimState`. Rendering then simply applies the pre-computed data.

## Two Ways to Trigger

| Function | State Tracking | Use When |
| -------- | -------------- | -------- |
| `animate` | Yes — engine tracks positions | Sequencing, redirecting, or controlling animations |
| `fireAndForget` | No — starts fresh each time | Simple one-shot animations |

With `animate`, you maintain an `AnimState` in your model that the engine updates. With `fireAndForget`, every call creates a new state — there's no continuity between triggers.

### When to Choose Each

| Scenario | Transitions | Keyframes | Sub | WAAPI |
| -------- | :---------: | :-------: | :-: | :---: |
| Animation runs once, no control needed | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Simple entry animations | `fireAndForget` | `fireAndForget` | `animate` | `fireAndForget` |
| Stop/reset controls | `animate` | `animate` | `animate` | `animate` |
| Pause/resume controls | | `animate` | `animate` | `animate` |
| Sequencing animations | `animate` | `animate` | `animate` | `animate` |
| Redirecting mid-flight | `animate`/`fireAndForget` | | `animate` | `animate` |

## Using `animate`

The `animate` function processes your animation configuration and merges the computed data into your existing `AnimState`:

??? example "View Source Code"

    ```elm
    update msg model =
        case msg of
            GotStartAnimation ->
                ( { model | animState = Transitions.animate model.animState fadeIn }
                , Cmd.none
                )
    ```

    The pattern is the same across all engines:

    ```elm
    -- CSS Transitions
    Transitions.animate model.animState myAnimation

    -- CSS Keyframes
    Keyframes.animate model.animState myAnimation

    -- Sub
    Sub.animate model.animState myAnimation

    -- WAAPI (also requires the element ID)
    WAAPI.animate model.animState <|
        WAAPI.forElement "element-id" >> myAnimation
    ```

### WAAPI Returns a Cmd

WAAPI uses JavaScript ports, so `animate` returns both the updated state and a command. It also requires `forElement` to specify which DOM element to animate:

??? example "WAAPI Pattern"

    ```elm
    update msg model =
        case msg of
            GotStartAnimation ->
                let
                    ( newAnimState, cmd ) =
                        WAAPI.animate model.animState <|
                            WAAPI.forElement "header" 
                                >> fadeIn
                                >> slideDown
                                >> WAAPI.forElement "sidebar"
                                >> fadeIn
                                >> slideRight
                in
                ( { model | animState = newAnimState }
                , cmd
                )
    ```

    The "header" element will `fadeIn` and `slideDown` and the "sidebar" element will `fadeIn` and `slideRight`.

## Using `fireAndForget`

For simple animations that don't need state tracking:

??? example "View Source Code"

    ```elm
    -- In init
    init _ =
        ( { animState = Keyframes.fireAndForget (fadeIn >> slideIn) }
        , Cmd.none
        )

    -- Or in update
    update msg model =
        case msg of
            GotShowBox ->
                ( { model | animState = Keyframes.fireAndForget (fadeIn >> slideIn) }
                , Cmd.none
                )
    ```

Fire-and-forget is ideal for entry animations, simple hover effects, and animations where you don't need control functions.

## Where to Trigger

### In `update` (Most Common)

Trigger in response to messages — user interactions, page events, or external data:

??? example "Common Trigger Points"

    ```elm
    update msg model =
        case msg of
            GotButtonClick ->
                ( { model | animState = Transitions.animate model.animState buttonPress }
                , Cmd.none
                )

            GotDataReceived data ->
                ( { model 
                    | data = data
                    , animState = Transitions.animate model.animState dataFadeIn 
                  }
                , Cmd.none
                )
    ```

### In `init`

For animations that should start immediately, use **Keyframes**, **Sub**, or **WAAPI**:

??? example "Init Triggering"

    ```elm
    -- Keyframes
    init _ =
        ( { animState = Keyframes.fireAndForget fadeIn }, Cmd.none )

    -- Sub
    init _ =
        let
            animState =
                Sub.init
                    [ Opacity.init 0 ]
        in
        ( { animState = Sub.animate animState fadeIn }, Cmd.none )

    -- WAAPI
    init _ =
        let
            ( animState, cmd ) =
                WAAPI.fireAndForget waapiCommand <|
                    WAAPI.forElement "element-id" >> fadeIn
        in
        ( { animState = animState }, cmd )
    ```

!!! warning "CSS Transitions can't animate on init"
    CSS Transitions require a state change between renders. Triggering in `init` means no transition — the element appears at the final state immediately. To animate with Transitions on page load, trigger in a subsequent message after the first view renders.

### Avoid Triggering in `view`

??? warning "Why not in view?"
    You might be tempted to call `fireAndForget` directly in your view:

    ```elm
    view model =
        let
            boxAnimState = Transitions.fireAndForget (fadeIn >> slideIn)
        in
        ...
    ```

    This works, but the builder functions run on **every render**, creating unnecessary GC pressure. The view should be a pure function of model state. Prefer triggering in `init` or `update`.

!!! warning "Avoid defining all animations upfront"
    Don't define every animation in a single `fireAndForget` call in `init`, then selectively apply them in your view. This allocates memory for unused animations, and with Sub/WAAPI causes unnecessary computation. Trigger animations when they're needed.

## Multiple Animations

Compose animations together and trigger once:

??? example "Multiple Animations"

    ```elm
    update msg model =
        case msg of
            GotShowAll ->
                ( { model | animState = 
                        Transitions.animate model.animState <|
                            fadeIn "header"
                                >> slideIn "sidebar"
                                >> fadeIn "content"
                  }
                , Cmd.none
                )
    ```

## Sequencing Animations

### State Continuity with `animate`

The engine remembers where each animation ended, using that as the starting point for the next:

??? example "Cumulative Movement"

    ```elm
    moveRight : AnimBuilder -> AnimBuilder
    moveRight =
        Translate.for "box"
            >> Translate.toX 100  -- No 'from' needed
            >> Translate.build

    -- First trigger:  0 → 100
    -- Second trigger: 100 → 200  
    -- Third trigger:  200 → 300
    ```

    You only need to specify `to`. The `from` value comes from the previous end state. 
    
    To set the initial values to use on first trigger, use the Engine's `init` function. If nothing is set the property's start value will be a sensible default - see each property for details of what their defaults are. 

### Manual Tracking with `fireAndForget`

Each call starts fresh — you must specify both `from` and `to`:

??? example "Explicit Positions"

    ```elm
    moveRight : Float -> AnimBuilder -> AnimBuilder
    moveRight currentX =
        Translate.for "box"
            >> Translate.fromX currentX
            >> Translate.toX (currentX + 100)
            >> Translate.build
    ```

### Callback-Based Sequencing

Trigger the next animation when the previous one ends using [animation events](../concepts/events.md):

??? example "Sequential Triggering"

    ```elm
    update msg model =
        case msg of
            GotStartSequence ->
                ( { model | animState = Transitions.animate model.animState (fadeIn "header") }
                , Cmd.none
                )

            GotAnimationMsg (Transitions.Ended "header") ->
                ( { model | animState = Transitions.animate model.animState (slideIn "sidebar") }
                , Cmd.none
                )
    ```

## Redirecting Mid-Flight

With **Transitions**, **Sub**, and **WAAPI**, calling `animate` while an animation is running smoothly redirects to the new target — the engine knows the current position.

**Keyframes** don't support mid-flight redirection — once started, they run to completion.

With `fireAndForget`, you'd need to manually track positions yourself.

## Next Steps

Now that you've triggered an animation, you need to apply it to your elements.

[Apply Animations →](apply.md){ .md-button .md-button--primary }
