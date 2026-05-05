# Example

--8<-- [start:page]

--8<-- [start:desc]
Rotating cube with expanding sides.
--8<-- [end:desc]

--8<-- [start:examples]

??? example "View Examples"

    === "Transition"

        <iframe src="../../../../examples/src/Animation/Transition/Animate3D/index.html" style="width: 100%; height: 400px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Keyframe"

        <iframe src="../../../../examples/src/Animation/Keyframe/Animate3D/index.html" style="width: 100%; height: 400px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "Sub"

        <iframe src="../../../../examples/src/Animation/Sub/Animate3D/index.html" style="width: 100%; height: 400px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

    === "WAAPI"

        --8<-- "docs/animation/concepts/3d/rotating-cube/waapi.md:example"

--8<-- [end:examples]

--8<-- [start:code]
??? example "View Source Code"

    === "Transition"

        ```elm
        --8<-- "docs/examples/src/Animation/Transition/Animate3D/Main.elm"
        ```

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/Animate3D/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/Animate3D/Main.elm"
        ```

    === "WAAPI"

        --8<-- "docs/animation/concepts/3d/rotating-cube/waapi.md:code"

--8<-- [end:code]
--8<-- [start:breaking-it-down]

??? example "Breaking It Down"

    ### 1. Build The Animations

    Each animation is built using the builder pattern. The `rotateCube` function rotates the entire cube,
    while `moveSidesOut` and `moveSidesIn` translate each face along its respective axis.

    Note how function composition (`>>`) chains multiple animations together.

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Animation/Transition/Animate3D/Main.elm:animationFunctions"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Animation/Keyframe/Animate3D/Main.elm:animationFunctions"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Animation/Sub/Animate3D/Main.elm:animationFunctions"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Animation/WAAPI/Animate3D/Main.elm:animationFunctions"
            ```

    ### 2. Select An Animation

    A simple state machine selects which animation to run based on the current `State`.

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Animation/Transition/Animate3D/Main.elm:selectAnimation"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Animation/Keyframe/Animate3D/Main.elm:selectAnimation"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Animation/Sub/Animate3D/Main.elm:selectAnimation"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Animation/WAAPI/Animate3D/Main.elm:selectAnimation"
            ```


    ### 3. Initialize And Trigger

    We use the `init*` functions to initialize the starting positions for the cube and the sides.
    This builds the cube - with these settings used in the view on first render.

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Animation/Transition/Animate3D/Main.elm:initializeAndTrigger"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Animation/Keyframe/Animate3D/Main.elm:initializeAndTrigger"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Animation/Sub/Animate3D/Main.elm:initializeAndTrigger"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Animation/WAAPI/Animate3D/Main.elm:initializeAndTrigger"
            ```

    ### 4. Render The Cube

    The cube container uses `View3D.transformStyle Preserve3D` so child faces maintain their 3D positions.

    Each face is positioned absolutely and applies `Keyframe.attributes` to get its current transform from the animation state.

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Animation/Transition/Animate3D/Main.elm:render"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Animation/Keyframe/Animate3D/Main.elm:render"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Animation/Sub/Animate3D/Main.elm:render"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Animation/WAAPI/Animate3D/Main.elm:render"
            ```

    ### 5. Handle Animation Events

    The `update` function receives `AnimMsg` and returns the updated `AnimState` and an
    `AnimEvent` which is then handled by `handleKeyframeEvent`.

    We listen for the `Keyframe.Ended` event and filter by animation group name to only respond to the relevant animation's completion.

    ??? example "View Source Code"

        === "Transition"

            ```elm
            --8<-- "docs/examples/src/Animation/Transition/Animate3D/Main.elm:handleAnimationEvents"
            ```

        === "Keyframe"

            ```elm
            --8<-- "docs/examples/src/Animation/Keyframe/Animate3D/Main.elm:handleAnimationEvents"
            ```

        === "Sub"

            ```elm
            --8<-- "docs/examples/src/Animation/Sub/Animate3D/Main.elm:handleAnimationEvents"
            ```

        === "WAAPI"

            ```elm
            --8<-- "docs/examples/src/Animation/WAAPI/Animate3D/Main.elm:handleAnimationEvents"
            ```
--8<-- [end:breaking-it-down]

--8<-- [end:page]
