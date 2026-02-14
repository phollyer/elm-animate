# Elm Animate

A comprehensive Elm package for smooth, high-performance DOM animations and scrolling.

## 🎯 Why Elm Animate?

**One animation API. Multiple rendering engines.**

Define your animations once using a composable builder pattern, then run them with any engine — CSS transitions, CSS keyframes, subscriptions, or the Web Animations API. Switch engines without rewriting your animations.

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
Transitions.animate model.animState fadeIn
Keyframes.animate model.animState fadeIn
Sub.animate model.animState fadeIn
WAAPI.animate model.animState <|
    WAAPI.forElement "my-element-id" >> fadeIn
```

---

## ✨ Features

- **Multiple Engines** — Choose CSS, subscriptions, or WAAPI based on your needs
- **Hardware-Accelerated** — GPU-powered transforms (translate, rotate, scale, opacity)
- **Full 3D Support** — XYZ positioning, multi-axis rotation, perspective
- **Smooth Scrolling** — Document and container scrolling with the same builder API
- **Composable & Type-Safe** — Chain animations, reuse everywhere

---


## 🚦 Engines at a Glance

- **CSS Transitions** — Simple state-to-state animations, minimal setup
- **CSS Keyframes** — Multi-step sequences with looping support
- **Sub** — Query mid-flight values, dynamically redirect animations
- **WAAPI** — Browser-native with playback control (pause/resume/reverse)
- **Scroll** — Smooth document and container scrolling

---

## 📚 Documentation

Full documentation at **[phollyer.github.io/elm-animate](https://phollyer.github.io/elm-animate)**

- Getting started guide
- Engine deep-dives
- Property reference (Translate, Scale, Rotate, Opacity, Colors, Size)
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

## Roadmap

- Animation sequencing & reverse control
- FLIP animations
- Full CSS property coverage
- Canvas & WebGL support

---

## 🙏 Credits

Uses code from [`linuss/smooth-scroll`](https://package.elm-lang.org/packages/linuss/smooth-scroll/latest/).

---

## 📄 License

BSD-3-Clause
