# Elm Motion

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## 👀 At a Glance

- **6 Animation Engines** — Keyframe, ScrollTimeline, Sub, Transition, ViewTimeline, WAAPI
- **3 Scroll Engines** — Cmd, Sub, Task
- **Three timelines, one API** — drive animations by time, scroll progress or viewport position
- **Mid-flight control** — query, divert, pause, resume, restart and stop animations and scrolls in motion
- **Hardware-accelerated** — GPU transforms with full 3D support

---

## 🚦 Engines at a Glance

### **Animation**

- **Transition** — Browser-native; simple state-to-state animations, minimal control, minimal setup
- **Keyframe** — Browser-native; looping, full control
- **Sub** — Pure Elm; looping, full control, real-time mid-flight queries/diversions
- **WAAPI** — Browser-native via JS; looping, full control, real-time mid-flight queries/diversions
- **ScrollTimeline** — Browser-native via JS; scroll-driven, tied to a scroll container's progress
- **ViewTimeline** — Browser-native via JS; viewport-driven, tied to an element entering and leaving view

### **Scroll**

- **Cmd** — Simple fire-and-forget scrolls, minimal setup
- **Task** — Composable scrolls with error handling
- **Sub** — Stateful scrolling with events and mid-scroll queries and control

---

## 🎯 Why Elm Motion?

**One API. Multiple Engines.**

Elm Motion gives you a consistent builder API for configuring animations and scrolls across
multiple Engines.

Define your animations once, then run them with any Animation Engine.

```elm
-- Define once
fadeIn : AnimBuilder (ForDocumentTimeline engine) -> AnimBuilder (ForDocumentTimeline engine)
fadeIn =
    Opacity.for "entranceAnim"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.duration 300
        >> Opacity.build

-- Use with any Engine
Transition.animate model.animState fadeIn

Keyframe.animate model.animState fadeIn

Sub.animate model.animState fadeIn

WAAPI.animate model.animState fadeIn
```

The same philosophy applies to scrolling — define once, use with any Scroll Engine.

```elm
-- Define once
scrollToSection : ScrollBuilder -> ScrollBuilder
scrollToSection =
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.speed 500
        >> Scroll.build

-- Use with any Scroll Engine
Cmd.scroll ScrollDone scrollToSection

Task.scroll scrollToSection

Sub.scroll ScrollMsg model.scrollState scrollToSection
```

---

## ✨ Features

**Animation**

- **Hardware-Accelerated** — GPU-powered transforms (translate, rotate, scale, opacity)
- **Full 3D Support** — XYZ positioning, multi-axis rotation, perspective
- **Per-Property Choreography** — Animate opacity, position, rotation and more on a single element in parallel, with independent duration, delay and easing per property — no master timeline to orchestrate
- **Time, Scroll & Viewport Driven** — Drive animations by elapsed time, page scroll progress or an element's position in the viewport — same builder API, three different timelines

**Scroll**

- **Smooth Scrolling** — Document and container
- **Flexible Targets** — Scroll to elements, percentages, edges, corners, or relative deltas
- **Axis Control** — Scroll horizontally, vertically or both

---

## 🚀 Quick Start

```bash
elm install phollyer/elm-motion
```

For WAAPI support:

```bash
npm install @phollyer/elm-motion
```

### Your First Animation

```elm
import Anim.Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Property.Translate as Translate


-- 1. Define your animation
slideRight : AnimBuilder mode -> AnimBuilder mode
slideRight =
    Translate.for "sidebarAnim"
        >> Translate.toX 200
        >> Translate.duration 400
        >> Translate.build


-- 2. Initialize state
type alias Model =
    { animState : Transition.AnimState }

init : ( Model, Cmd Msg )
init =
    ( { animState =
            Transition.init <|
                [ Translate.initX "sidebarAnim" 100 ]
      }
    , Cmd.none
    )


-- 3. Trigger it
type Msg
    = Animate

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Animate ->
            ( { model | animState = Transition.animate model.animState slideRight }
            , Cmd.none
            )


-- 4. Render
view : Model -> Html Msg
view model =
    Html.div
        (Transition.attributes "sidebarAnim" model.animState)
        [ Html.text "Slide me!" ]
```

### Your First Scroll

```elm
import Scroll.Builder as Scroll
import Scroll.Engine.Cmd as Cmd exposing (ScrollBuilder)


-- 1. Define your scroll
scrollToSection : String -> ScrollBuilder -> ScrollBuilder
scrollToSection targetId =
    Scroll.forDocument
        >> Scroll.toElement targetId
        >> Scroll.speed 400
        >> Scroll.build


-- 2. Trigger it
type Msg
    = ScrollTo String
    | ScrollComplete

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScrollTo targetId ->
            ( model
            , Cmd.scroll ScrollComplete <|
                scrollToSection targetId
            )

        ScrollComplete ->
            ( model, Cmd.none )


-- 3. Render
view : Model -> Html Msg
view _ =
    -- Your scrollable content
```

---

## 🧩 JavaScript Companion

The `WAAPI`, `ScrollTimeline` and `ViewTimeline` engines require the
[`@phollyer/elm-motion`](https://www.npmjs.com/package/@phollyer/elm-motion)
JavaScript companion. The CSS and `Sub` engines do not.

```bash
npm install @phollyer/elm-motion
```

See the [npm package README](https://www.npmjs.com/package/@phollyer/elm-motion)
for setup, port wiring and error reporting.

---

## 📚 Documentation

Full documentation at **[phollyer.github.io/elm-motion](https://phollyer.github.io/elm-motion)**

- Getting started guide
- Engine deep-dives
- Property reference (Translate, Rotate, Scale, etc)
- Live examples with source code

---

## 📋 Roadmap — in no particular order or timeframe

- Full WAAPI coverage
- FLIP Engine
- Canvas Engine
- WebGL Engine
- Any other user suggested features

---

## 🙏 Credits

Uses code from [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/).

---

## 📄 License

BSD-3-Clause
