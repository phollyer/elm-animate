# Timeline Animations

--8<-- [start:page]

--8<-- [start:scroll-timeline]

### Scroll Timeline

A `ScrollTimeline` ties animation progress to the scroll position of a container element. When the scroller is at the top, progress is 0%; at the bottom, 100%.

Use `ScrollTimeline.animate` from the `Anim.Engine.WAAPI.ScrollTimeline` module. Pass the port function, a `Container` value (`Document` or `Container "element-id"`), and the animation pipeline:

--8<-- [start:scroll-timeline-example]

??? example "View Example"

    <iframe src="../../../examples/src/Animation/WAAPI/ScrollTimeline/index.html" style="width: 100%; height: 350px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Animation/WAAPI/ScrollTimeline/Main.elm"
    ```
--8<-- [end:scroll-timeline-example]

--8<-- [end:scroll-timeline]

---

--8<-- [start:view-timeline]

### View Timeline

A `ViewTimeline` ties animation progress to an element's position within the viewport — each element animates as it scrolls into (or out of) view.

Use `ViewTimeline.animate` from the `Anim.Engine.WAAPI.ViewTimeline` module. The subject of the timeline is the element being animated. Use `rangeStart` and `rangeEnd` with the typed constructor functions to control exactly when in the element's scroll lifecycle the animation plays:

--8<-- [start:view-timeline-example]

??? example "View Example"

    <iframe src="../../../examples/src/Animation/WAAPI/ViewTimeline/index.html" style="width: 100%; height: 450px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Animation/WAAPI/ViewTimeline/Main.elm"
    ```

--8<-- [end:view-timeline-example]

--8<-- [end:view-timeline]

--8<-- [end:page]
