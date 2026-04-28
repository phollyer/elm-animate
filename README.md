# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## 🎯 Why Elm Animate?

**One API. Multiple engines.**

You've learned an Elm package for CSS transitions. Now the team wants the Web Animations API. Another package, another API, another mental model. Elm Animate solves this — define your animations once, run them with any engine.

```elm
-- Define once
fadeIn : AnimBuilder -> AnimBuilder
fadeIn =
    Opacity.for "entranceAnim"
        >> Opacity.from 0
        >> Opacity.to 1
        >> Opacity.duration 300
        >> Opacity.build

-- Use with any engine
Transition.animate model.animState fadeIn

Keyframe.animate model.animState fadeIn

Sub.animate model.animState fadeIn

WAAPI.animate model.animState fadeIn
```

The same philosophy applies to scrolling — define once, use with any scroll engine.

```elm
-- Define once
scrollToSection : AnimBuilder -> AnimBuilder
scrollToSection =
    Scroll.forDocument
        >> Scroll.toElement "section-id"
        >> Scroll.speed 500
        >> Scroll.build

-- Use with any scroll engine
Cmd.animate ScrollDone scrollToSection

Task.animate scrollToSection

Sub.animate ScrollMsg model.scrollState scrollToSection
```

---

## ✨ Features

- **Multiple Engines** — 4 Animation Engines, 3 Scroll Engines

### **Animation**

- **Hardware-Accelerated** — GPU-powered transforms (translate, rotate, scale, opacity)
- **Full 3D Support** — XYZ positioning, multi-axis rotation, perspective
- **Composable & Type-Safe** — Chain animations, reuse everywhere

### **Scroll**

- **Smooth Scrolling** — Document and container scrolling
- **Flexible Targets** — Scroll to elements, percentages, edges, corners, or relative deltas
- **Configurable** — Speed, duration, easing, delay, axis control, and offsets

---


## 🚦 Engines at a Glance

### **Animation**

- **Transition** — Browser-native; simple state-to-state animations, minimal control, minimal setup
- **Keyframe** — Browser-native; looping, full control
- **Sub** — Pure Elm; looping, full control, real-time mid-flight queries/diversions
- **WAAPI** — Browser-native via JS; looping, full control, real-time mid-flight queries/diversions

### **Scroll**

- **Cmd** — Simple fire-and-forget scrolls, minimal setup
- **Task** - Composable scrolls with error handling
- **Sub** - Stateful scrolling with events and mid-scroll queries and control

---

## 📚 Documentation

Full documentation at **[phollyer.github.io/elm-animate](https://phollyer.github.io/elm-animate)**

- Getting started guide
- Engine deep-dives
- Property reference (Translate, Rotate, Scale, etc)
- Live examples with source code

---

## 🚀 Quick Start

```bash
elm install phollyer/elm-animate
```

For WAAPI support:

```bash
npm install elm-animate-waapi
```

### Your First Animation

```elm
import Anim.Builder as Builder exposing (AnimBuilder)
import Anim.Engine.Transition as Transition
import Anim.Property.Translate as Translate


-- 1. Define your animation
slideRight : AnimBuilder -> AnimBuilder
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
        (Transition.attributes  "sidebarAnim" model.animState)
        [ Html.text "Slide me!" ]
```

See the [full documentation](https://phollyer.github.io/elm-animate) for all engines, properties, and examples.

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

## 📋 Roadmap - in no particular order or timeframe

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
