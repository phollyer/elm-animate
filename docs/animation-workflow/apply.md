# Applying Animations

Once you've defined an animation and triggered it with an engine, you need to apply the animation to your element. All engines use the same pattern: the `attributes` function.

## The Attributes Pattern

Every animation engine provides an `attributes` function that generates HTML attributes for your element:

??? example "View Source Code"

    ```elm
    -- Transitions
    div (Transitions.attributes "boxAnim" model.animState) [ text "I animate!" ]

    -- Keyframes
    div (Keyframes.attributes "boxAnim" model.animState) [ text "I animate!" ]

    -- Sub
    div (Sub.attributes "boxAnim" model.animState) [ text "I animate!" ]

    -- WAAPI
    div (WAAPI.attributes "boxAnim" model.animState) [ text "I animate!" ]
    ```

    The first argument is the **animation group name** - this tells the engine which group's animation data to look up from the `AnimState`.

## What Attributes Produces

The `attributes` function generates inline CSS styles based on your animation configuration:

| Property | CSS Output |
| -------- | ---------- |
| Translate | `transform: translate3d(x, y, z)` |
| Rotate | `transform: rotate3d(...)` |
| Scale | `transform: scale3d(x, y, z)` |
| Opacity | `opacity: value` |
| BackgroundColor | `background-color: rgba(...)` |
| FontColor | `color: rgba(...)` |
| Size | `width: ...px; height: ...px` |

For transform properties, the values are combined into a single `transform` property in the order: Translate → Rotate → Scale (or your custom order if specified).

## Animation Group Names

The **animation group name** is the key that connects your animation definition to your view.

??? example "View Source Code"

    ```elm
    -- Define an animation for group "boxAnim"
    fadeIn =
        Opacity.for "boxAnim"
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

    -- Add fadeIn to your Engine
    Transitions.animate model.animState fadeIn

    -- Then apply it to your element
    view model =
        div (Transitions.attributes "boxAnim" model.animState) [ ... ]
    ```

    Use the group name to group multiple property animations together so that they can all be applied to the same element.

    ```elm
    -- Define another animation for group "boxAnim"
    slideIn =
        Translate.for "boxAnim"
            >> Translate.Xfrom -100
            >> Translate.toX 50
            >> Translate.build

    -- Add slideIn to your Engine too
    Transitions.animate model.animState <|
        fadeIn >> slideIn

    -- Then apply the `boxAnim` group of animations to your element (slideIn & fadeIn)
    view model =
        div (Transitions.attributes "boxAnim" model.animState) [ ... ]
    ```

### Reusing Animations Across Elements

To apply the same animation logic to different elements, parameterize the group name:

??? example "Parameterized Animation"

    ```elm
    fadeIn : String -> AnimBuilder -> AnimBuilder
    fadeIn group =
        Opacity.for group
            >> Opacity.from 0
            >> Opacity.to 1
            >> Opacity.build

    -- Apply to different elements
    GotShowHeader ->
        ( { model | animState = Transitions.animate model.animState (fadeIn "headerAnim") }
        , Cmd.none
        )

    GotShowSidebar ->
        ( { model | animState = Transitions.animate model.animState (fadeIn "sidebarAnim") }
        , Cmd.none
        )

    view model =
        div []
            [ div (Transitions.attributes "headerAnim" model.animState) [ text "Header" ]
            , div (Transitions.attributes "sidebarAnim" model.animState) [ text "Sidebar" ]
            ]
    ```

### Building Complex Animations

Use the group name to build up animations from smaller pieces.

??? example "View Source Code"

    ```elm
    GotShowHeader ->
        let
            animGroup =
                "headerAnim"
        in
        ( { model | animState = Transitions.animate model.animState <|
                fadeIn animGroup >> slideDown animGroup
          }
        , Cmd.none
        )

    GotShowSidebar ->
        let
            animGroup =
                "sideBarAnim"
        in
        ( { model | animState = Transitions.animate model.animState <|
                fadeIn animGroup >> slideRight animGroup
          }
        , Cmd.none
        )

    ```

## Engine-Specific Requirements

While the `attributes` pattern is consistent, some engines have additional view requirements:

### CSS Keyframes Engine

Keyframes animations require a `<style>` node in the DOM containing the generated `@keyframes` rules:

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ Keyframes.styleNode model.animState  -- Required!
            , div
                (Keyframes.attributes "boxAnim" model.animState)
                [ text "I animate!" ]
            ]
    ```

    The `styleNode` should be placed once in your view, typically at the top level. It contains all keyframe definitions for all animation groups in that `AnimState`.

    For a more targeted `style` node, use `styleNodeFor animGroup` which only applies the keyframes for that animation group. You can add multiple `styleNodeFor`s to your DOM if so required.

    ```elm
    view model =
        div []
            [ Keyframes.styleNodeFor "headerAnim" model.animState 
            , Keyframes.styleNodeFor "sidebarAnim" model.animstate
            , div
                (Keyframes.attributes "headerAnim" model.animState)
                [ text "I am a header!" ]
            , div
                (Keyframes.attributes "sidebarAnim" model.animState)
                [ text "I am a sidebar!" ]
            ]
    ```

### WAAPI Engine

The WAAPI Engine is slightly different to the CSS and Sub engines due to using the Web Animations API. WAAPI applies the animation in JS and so requires the element id to know which element to apply the animation group to.

WAAPI uses the `forElement` builder to specify which DOM element to animate:

??? example "Show Source Code"

    ```elm
    ( newAnimState, cmd ) =
        WAAPI.animate model.animState <|
            WAAPI.forElement "header"  -- Required!
                >> fadeIn "headerAnim"
                >> slideDown "headerAnim"
                -- Add another element animation
                >> WAAPI.forElement "sidebar"
                >> fadeIn "sidebarAnim"
                >> slideRight "sidebarAnim"
    ```

#### WAAPI `attributes`

The `attributes` function for the WAAPI Engine works slightly differently to the CSS and Sub Engines.

Since WAAPI applies keyframe effects via JavaScript, the animation itself isn't driven by the CSS from `attributes`. Instead, `attributes` serves two purposes:

1. **Initial state** — Renders the starting CSS immediately, preventing a flash of unstyled content before JavaScript processes the port command
2. **Final state** — Keeps the element in its final position after the animation completes

??? example "View Source Code"

    ```elm
    view model =
        div []
            [ div
                ([ id "header" ] ++ WAAPI.attributes "headerAnim" model.animState)
                [ text "I animate via WAAPI!" ]
            ]
    ```

    Note: WAAPI elements also need an `id` attribute so JavaScript can find the element to apply the keyframe effects to.

### CSS Transitions Engine

No additional requirements — just use `attributes`.

### Sub Engine

No additional requirements — just use `attributes`.

## Initial Values

When you initialize an `AnimState` with property values, those values appear immediately via `attributes`:

??? example "View Source Code"

    ```elm
    init _ =
        ( { animState =
                Transitions.init
                    [ Opacity.init "box" 0
                    , Translate.initXY "box" -100 0
                    ]
        }
        , Cmd.none
        )

    view model =
        -- Element starts invisible and offset left
        div (Transitions.attributes "box" model.animState) [ text "I'll animate in!" ]
    ```

This is useful for entry animations where you want the element to start in a specific state before animating to its final position.

## Multiple Elements

You can animate multiple elements from the same `AnimState`. Each element needs its own animation group:

??? example "View Source Code"

    ```elm
    -- Define animations for each element
    animateAll =
        fadeIn "header"
            >> fadeIn "content"
            >> fadeIn "footer"

    view model =
        div []
            [ div (Transitions.attributes "header" model.animState) [ text "Header" ]
            , div (Transitions.attributes "content" model.animState) [ text "Content" ]
            , div (Transitions.attributes "footer" model.animState) [ text "Footer" ]
            ]
    ```

Each animation group gets its own data within the shared `AnimState`.

## Next Steps

Now that you understand how to apply animations, let's learn how to control them.

[Controlling Animations →](../concepts/controlling-animations.md){ .md-button .md-button--primary }
