# Hello Text Example

--8<-- [start:page]

--8<-- [start:desc]
Fades in text when the page loads. The obligatory "Hello" example.
--8<-- [end:desc]

--8<-- [start:examples]


??? example "View Example"

    === "Transition"

        <iframe src="../../../examples/src/Engines/Transition/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Keyframe"

        <iframe src="../../../examples/src/Engines/Keyframe/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Engines/Sub/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "WAAPI"

        <iframe src="../../../examples/src/Engines/WAAPI/HelloText/index.html" style="width: 100%; height: 300px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Engines/Transition/HelloText/Main.elm"
        ```

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframe/HelloText/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm"
        ```
    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm"
        ```

--8<-- [end:code]
--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    There are four simple steps to animating with Elm Animate - five for the Sub Engine.

    ### 1. Build

    Animations are defined as functions that transform an `AnimBuilder`:

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Transition/HelloText/Main.elm:build"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Keyframe/HelloText/Main.elm:build"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:build"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:build"
            ```


    ### 2. Initialize

    Set up the initial state for your animated properties. This ensures elements render with the correct starting values before any animation runs:

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Transition/HelloText/Main.elm:model"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Keyframe/HelloText/Main.elm:model"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:model"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:model"
            ```

            The WAAPI Engine also requires both it's `port` functions (`waapiCommand` & `waapiEvent`). 
            
            📖 See [WAAPI Engine - Define Ports in Elm](../../engines/waapi/#3-define-ports-in-elm) for more info.

    ### 3. Render

    Use the `attributes` function to apply the animation's attributes to your element:

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Transition/HelloText/Main.elm:render"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Keyframe/HelloText/Main.elm:render"
            ```

            Keyframe animations also need a `style` node with the keyframe rules. 
            
            📖 See [Keyframe Style Node](../../engines/animation/keyframes.md#keyframes-style-node) for more info.

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:render"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:render"
            ```

        Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state.

    ### 4. Trigger

    Engines trigger their animations with their `animate` function.

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Transition/HelloText/Main.elm:trigger-cmd"
            ```

            `Process.sleep 50` is used to trigger the animation 50ms after first render; this allows the browser to compute the starting values for the transition. 

            The animation is then triggered in `update`.

            ```elm
            --8<-- "docs/examples/src/Engines/Transition/HelloText/Main.elm:trigger"
            ```
            📖 See [Transition Engine - How CSS Transition Work](../../engines/transitions/#how-css-transitions-work) for more info.

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Keyframe/HelloText/Main.elm:trigger"
            ```

            Keyframe animations can be triggered in your module's `init` function - the `@keyframes` rules are added to the DOM ready for first render when you add the `style` node in your view:

            ```elm
            --8<-- "docs/examples/src/Engines/Keyframe/HelloText/Main.elm:render"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:trigger"
            ```

            The Sub Engine can be triggered from your module's `init` function - the animation starts immediately.

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:trigger"
            ```

            The WAAPI Engine also returns a `Cmd` from `animate` that sends the animation data to the [Javascript Companion](../../engines/waapi/#1-install-the-javascript-package).

    ### 5. Update

    Keep the Engine's state updated to make use of state-tracked features.

    For the Transition, Keyframe and WAAPI Engines, `update` is not required for this example; for the Sub Engine, `update` is always required.

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Transition/HelloText/Main.elm:update"
            ```

            Not required for this animation.

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Keyframe/HelloText/Main.elm:update"
            ```

            Not required for this animation.

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Sub/HelloText/Main.elm:update"
            ```

            Always required.

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:Msg"
            --8<-- "docs/examples/src/Engines/WAAPI/HelloText/Main.elm:update"
            ```

            Not required for this animation.
--8<-- [end:breaking-it-down]


--8<-- [end:page]
