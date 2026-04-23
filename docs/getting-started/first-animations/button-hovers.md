
# Button Hovers Example

--8<-- [start:page]

--8<-- [start:desc]
Three different hover techniques.
--8<-- [end:desc]

--8<-- [start:examples]

??? example "View Examples"

    === "Transition"

        <iframe src="../../../examples/src/Engines/Animation/Transition/ButtonHovers/index.html" style="width: 100%; height: 230px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Keyframe"

        <iframe src="../../../examples/src/Engines/Animation/Keyframe/ButtonHovers/index.html" style="width: 100%; height: 230px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../examples/src/Engines/Animation/Sub/ButtonHovers/index.html" style="width: 100%; height: 230px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "WAAPI"

        <iframe src="../../../examples/src/Engines/Animation/WAAPI/ButtonHovers/index.html" style="width: 100%; height: 230px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

--8<-- [end:examples]

--8<-- [start:code]

??? example "View Source Code"

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Engines/Animation/Transition/ButtonHovers/Main.elm"
        ```

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Engines/Animation/Keyframe/ButtonHovers/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Animation/Sub/ButtonHovers/Main.elm"
        ```
    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/Animation/WAAPI/ButtonHovers/Main.elm"
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
            --8<-- "docs/examples/src/Engines/Animation/Transition/ButtonHovers/Main.elm:build"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Keyframe/ButtonHovers/Main.elm:build"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Sub/ButtonHovers/Main.elm:build"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/WAAPI/ButtonHovers/Main.elm:build"
            ```

    ### 2. Initialize

    Set up the initial state for your animated properties. This ensures elements render with the correct starting values before any animation runs:

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Transition/ButtonHovers/Main.elm:model"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Keyframe/ButtonHovers/Main.elm:model"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Sub/ButtonHovers/Main.elm:model"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/WAAPI/ButtonHovers/Main.elm:model"
            ```

    ### 3. Render

    Use the `attributes` function to apply the animation's attributes to your element:

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Transition/ButtonHovers/Main.elm:render"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Keyframe/ButtonHovers/Main.elm:render"
            ```

            Keyframe animations also need a `style` node with the keyframe rules. 
            
            📖 See [Keyframe Style Node](/animation/engines/keyframes.md#keyframes-style-node) for more info.

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Sub/ButtonHovers/Main.elm:render"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/WAAPI/ButtonHovers/Main.elm:render"
            ```

        Exactly what `attributes` returns depends on the Engine being used, the animation configuration and the current animation state.

    ### 4. Trigger

    Engines trigger their animations with their `animate` function.

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Transition/ButtonHovers/Main.elm:trigger"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Keyframe/ButtonHovers/Main.elm:trigger"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Sub/ButtonHovers/Main.elm:trigger"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/WAAPI/ButtonHovers/Main.elm:trigger"
            ```


    ### 5. Update

    Keep the Engine's state updated to make use of state-tracked features.

    For the Transition, Keyframe and WAAPI Engines, `update` is not required for this example; for the Sub Engine, `update` is always required.


    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Transition/ButtonHovers/Main.elm:update"
            ```

            Not required for this animation.

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Keyframe/ButtonHovers/Main.elm:update"
            ```

            Not required for this animation.

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/Sub/ButtonHovers/Main.elm:Msg"
            --8<-- "docs/examples/src/Engines/Animation/Sub/ButtonHovers/Main.elm:update"
            ```

            Always required.

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Engines/Animation/WAAPI/ButtonHovers/Main.elm:Msg"
            --8<-- "docs/examples/src/Engines/Animation/WAAPI/ButtonHovers/Main.elm:update"
            ```

            Not required for this animation.

--8<-- [end:breaking-it-down]

--8<-- [end:page]
