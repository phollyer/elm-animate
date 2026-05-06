# Start Here

## Timelines

Animations need a timeline to animate on, and modern Browsers have three: Document, Scroll and Viewport.

The Document timeline is the one most folks use and maybe do so without knowing about it. If you've ever done CSS transition, keyframe or `subscriptions` (`requestAnimationFrame`) animations, you've used the Document timeline. Perhaps unsurprisingly then, the Transition, Keyframe, Sub and WAAPI Engines all animate on the Document timeline.

Introduced around July 2023 are the more recent additions of the Scroll and Viewport timelines. These tie animations to scroll position and viewport position respectively, allowing animations to run in relation to scroll position as the user scrolls the document or container. The ScrollTimeline and ViewTimeline Engines target these new timelines.

Due to the Scroll and Viewport timelines being fairly recent additions, not all browsers may support them. At the time of writing, Firefox doesn't. This is not a problem though, because the JS companion automatically falls back to  [scroll-timeline-polyfill](https://www.npmjs.com/package/scroll-timeline-polyfill) so your users always get the intended experience regardless of browser support.

## Coding Style

The library codebase, and all the examples use function composition wherever possible.

??? note "New to function composition (`>>`)?"

    If you are more used to Elm's pipeline operator (`|>`), here's how they compare:

    ```elm
    -- Using pipelines (|>)
    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn animBuilder =
        animBuilder
            |> Opacity.for groupName
            |> Opacity.to 1
            |> Opacity.duration 5000
            |> Opacity.build

    -- Using function composition (>>)
    fadeIn : AnimBuilder -> AnimBuilder
    fadeIn =
        Opacity.for groupName
            >> Opacity.to 1
            >> Opacity.duration 5000
            >> Opacity.build
    ```

    Both produce identical results. Because these builders are all functions of type `AnimBuilder -> AnimBuilder`, they compose naturally with `>>`. This codebase prefers the composition style because it keeps builder definitions concise and usually reads more cleanly than threading an explicit `animBuilder` through a pipeline.

## Examples

Throughout the documentation you will find examples demonstrating features or concepts. The vast majority are for animations on the Document timeline, therefore all these examples will show the exact same animation for each of the Document timeline Engines.

Here's a few examples to get started with.

### 1. Hello Text

--8<-- "docs/animation/first-animations/hello-text.md:desc"

--8<-- "docs/animation/first-animations/hello-text.md:examples"

--8<-- "docs/animation/first-animations/hello-text.md:code"

--8<-- "docs/animation/first-animations/hello-text.md:breaking-it-down"

---

### 2. Toggle Visibility

--8<-- "docs/animation/first-animations/fade-in-out.md:desc"

--8<-- "docs/animation/first-animations/fade-in-out.md:examples"

--8<-- "docs/animation/first-animations/fade-in-out.md:code"

--8<-- "docs/animation/first-animations/fade-in-out.md:breaking-it-down"

---

### 3. Interactive Hover Effects

--8<-- "docs/animation/first-animations/button-hovers.md:desc"

--8<-- "docs/animation/first-animations/button-hovers.md:examples"

--8<-- "docs/animation/first-animations/button-hovers.md:code"

--8<-- "docs/animation/first-animations/button-hovers.md:breaking-it-down"


## Next Steps

Now that you can create a simple animation, continue with the animation workflow.

[Animation Workflow →](workflow/build.md){ .md-button .md-button--primary }

