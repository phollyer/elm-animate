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
Scroll.Cmd.animate ScrollDone scrollToSection

Scroll.Task.animate scrollToSection

Scroll.Sub.animate ScrollMsg model.scrollState scrollToSection
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

---

## Roadmap - in no particular order or timeframe

- Animation sequencing & reverse control
- Full CSS property coverage
- FLIP animations
- Canvas & WebGL support

---

## 🙏 Credits

Uses code from [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/).

---

## 📄 License

BSD-3-Clause
