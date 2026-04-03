# Migration Guide

This guide helps you switch between animation engines. Because all engines share the same builder API, your animation definitions remain unchanged - only the engine integration code needs updating.


## Quick Reference Matrix

This table shows what changes when migrating between engines:

| Component | Transitions | Keyframes | Sub | WAAPI |
| --------- | :---------: | :-------: | :-: | :---: |
| **Init** | `init []` | `init []` | `init []` | `init cmd sub []` |
| **Animate** | returns `AnimState` | returns `AnimState` | returns `AnimState` | returns `(AnimState, Cmd)` |
| **Subscriptions** | None | None | Required | Required |
| **Update** | returns `(AnimState, AnimEvent)` | returns `(AnimState, AnimEvent)` | returns `(AnimState, List AnimEvent)` | returns `(AnimState, AnimEvent)` |
| **Event listeners** | Required to receive Events | Required to receive Events | None | None |
| **View: styleNode** | No | Required | No | No |
| **JavaScript** | None | None | None | Required |

## Migration Index

If you need to migrate, you can use the quick guides below, just select your migration path from one of the lists:

### Migrating Up (adding features)

- [Transitions → Keyframes](#transitions-keyframes) - Add pause/resume & restart controls, looping
- [Transitions → Sub](#transitions-sub) - Add pause/resume & restart controls, looping, mid-flight access
- [Transitions → WAAPI](#transitions-waapi) - Add pause/resume & restart controls, looping, mid-flight access
- [Keyframes → Sub](#keyframes-sub) - Add mid-flight access, dynamic redirects
- [Keyframes → WAAPI](#keyframes-waapi) - Add mid-flight access, dynamic redirects
- [Sub → WAAPI](#sub-waapi) - Add browser-native interpolation, `fireAndForget` option

### Migrating Down (simplifying)

- [WAAPI → Sub](#waapi-sub) - Regain pure Elm (no JavaScript/ports)
- [WAAPI → Keyframes](#waapi-keyframes) - Regain pure Elm (no JavaScript/ports)
- [WAAPI → Transitions](#waapi-transitions) - Regain pure Elm (no JavaScript/ports)
- [Sub → Keyframes](#sub-keyframes) - Regain browser-native interpolation
- [Sub → Transitions](#sub-transitions) - Regain browser-native interpolation
- [Keyframes → Transitions](#keyframes-transitions) - Regain mid-flight redirections


---

## Migrating Up

### Transitions → Keyframes

- **Adds**: pause/resume & restart controls, looping
- **Loses**: mid-flight redirections

**Changes required:**

- Change types from `Transitions.*` to `Keyframes.*` (AnimState, AnimMsg, AnimEvent)
- Add `Keyframes.styleNode model.animState` to your view
- Update pattern matching for events (Keyframes has `Iteration` event)

??? example "Before & After"

    **Before (Transitions):**
    --8<-- "docs/engines/animation/migration-guide/transition.md:code"

    **After (Keyframes):**
    --8<-- "docs/engines/animation/migration-guide/keyframe.md:code"

---

### Transitions → Sub

- **Adds**: pause/resume & restart controls, looping, mid-flight access
- **Loses**: browser-native interpolation

**Changes required:**

- Change types from `Transitions.*` to `Sub.*` (AnimState, AnimMsg, AnimEvent)
- Add subscriptions function
- Update `update` function - events come from `Sub.update` as a `List`, not from DOM
- Remove event listeners from view (events come via subscription now)

??? example "Before & After"

    **Before (Transitions):**
    --8<-- "docs/engines/animation/migration-guide/transition.md:code"

    **After (Sub):**
    --8<-- "docs/engines/animation/migration-guide/sub.md:code"
    
---

### Transitions → WAAPI

- **Adds**: pause/resume & restart controls, looping, mid-flight access
- **Loses**: pure Elm (requires JavaScript/ports)

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change types from `Transitions.*` to `WAAPI.*` (AnimState, AnimMsg, AnimEvent)
- Define port functions and pass to `init`
- Add subscriptions function
- Update `animate` calls to handle returned `Cmd`
- Replace `fireAndForget` - WAAPI's `fireAndForget` returns `Cmd` only, unlike `animate` which returns `( AnimState, Cmd )`
- Update event handling - events have additional parameters
- Remove event listeners from view

??? example "Before & After"

    **Before (Transitions):**
    --8<-- "docs/engines/animation/migration-guide/transition.md:code"

    **After (WAAPI):**
    --8<-- "docs/engines/animation/migration-guide/waapi.md:page"
    

---

### Keyframes → Sub

- **Adds**: mid-flight access, dynamic redirects
- **Loses**: browser-native interpolation

**Changes required:**

- Change types from `Keyframes.*` to `Sub.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframes.styleNode` from view
- Add subscriptions function
- Update `update` function - events come as a `List` now
- Remove event listeners from view

??? example "Before & After"

    **Before (Keyframes):**
    --8<-- "docs/engines/animation/migration-guide/keyframe.md:code"

    **After (Sub):**
    --8<-- "docs/engines/animation/migration-guide/sub.md:code"
---

### Keyframes → WAAPI

- **Adds**: mid-flight access, dynamic redirects
- **Loses**: pure Elm (requires JavaScript/ports)

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change types from `Keyframes.*` to `WAAPI.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframes.styleNode` from view
- Define port functions and pass to `init`
- Add subscriptions function
- Update `animate` calls to handle returned `Cmd`
- Update `fireAndForget` - WAAPI's `fireAndForget` returns `Cmd` only
- Update event handling - events have additional parameters
- Remove event listeners from view

??? example "Before & After"

    **Before (Keyframes):**
    --8<-- "docs/engines/animation/migration-guide/keyframe.md:code"

    **After (WAAPI):**
    --8<-- "docs/engines/animation/migration-guide/waapi.md:page"

---

### Sub → WAAPI

- **Adds**: browser-native interpolation, `fireAndForget` option

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change types from `Sub.*` to `WAAPI.*` (AnimState, AnimMsg, AnimEvent)
- Define port functions and update `init`
- Update subscriptions to use `WAAPI.subscriptions`
- Update `animate` calls to handle returned `Cmd`
- Update `update` function - `WAAPI.update` returns single event, not list

??? example "Before & After"

    **Before (Sub):**
    --8<-- "docs/engines/animation/migration-guide/sub.md:code"

    **After (WAAPI):**
    --8<-- "docs/engines/animation/migration-guide/waapi.md:page"


---

## Migrating Down

### WAAPI → Sub

- **Adds**: pure Elm (no JavaScript/ports)
- **Loses**: browser-native interpolation, `fireAndForget` option

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change types from `WAAPI.*` to `Sub.*` (AnimState, AnimMsg, AnimEvent)
- Remove port functions from `init`
- Update subscriptions to use `Sub.subscriptions`
- Update `animate` calls - no longer returns `Cmd`
- Update `update` function - `Sub.update` returns `List AnimEvent`
- Replace `fireAndForget` calls with `animate` - `fireAndForget` is not available in Sub

??? example "Before & After"

    **Before (WAAPI):**
    --8<-- "docs/engines/animation/migration-guide/waapi.md:code"

    **After (Sub):**
    --8<-- "docs/engines/animation/migration-guide/sub.md:code"

---

### WAAPI → Keyframes

- **Adds**: pure Elm (no JavaScript/ports)
- **Loses**: mid-flight access, dynamic redirects

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change types from `WAAPI.*` to `Keyframes.*` (AnimState, AnimMsg, AnimEvent)
- Remove port functions from `init`
- Remove subscriptions (or set to `Sub.none`)
- Add `Keyframes.styleNode model.animState` to view
- Add event listeners to view
- Update `animate` calls - no longer returns `Cmd`
- Update event handling - events come from DOM, not ports

??? example "Before & After"

    **Before (WAAPI):**
    --8<-- "docs/engines/animation/migration-guide/waapi.md:code"

    **After (Keyframes):**
    --8<-- "docs/engines/animation/migration-guide/keyframe.md:code"

---

### WAAPI → Transitions

- **Adds**: pure Elm (no JavaScript/ports)
- **Loses**: pause/resume & restart controls, looping, mid-flight access

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change types from `WAAPI.*` to `Transitions.*` (AnimState, AnimMsg, AnimEvent)
- Remove port functions from `init`
- Remove subscriptions (or set to `Sub.none`)
- Add event listeners to view
- Update `animate` calls - no longer returns `Cmd`
- Update event handling - events come from DOM, not ports

??? example "Before & After"

    **Before (WAAPI):**
    --8<-- "docs/engines/animation/migration-guide/waapi.md:code"

    **After (Transitions):**
    --8<-- "docs/engines/animation/migration-guide/transition.md:code"

---

### Sub → Keyframes

- **Adds**: browser-native interpolation
- **Loses**: mid-flight access, dynamic redirects

**Changes required:**

- Change types from `Sub.*` to `Keyframes.*` (AnimState, AnimMsg, AnimEvent)
- Remove subscriptions (or set to `Sub.none`)
- Add `Keyframes.styleNode model.animState` to view
- Add event listeners to view
- Update `update` function - single event instead of list

??? example "Before & After"

    **Before (Sub):**
    --8<-- "docs/engines/animation/migration-guide/sub.md:code"

    **After (Keyframes):**
    --8<-- "docs/engines/animation/migration-guide/keyframe.md:code"

---

### Sub → Transitions

- **Adds**: browser-native interpolation
- **Loses**: pause/resume & restart controls, looping, mid-flight access

**Changes required:**

- Change types from `Sub.*` to `Transitions.*` (AnimState, AnimMsg, AnimEvent)
- Remove subscriptions (or set to `Sub.none`)
- Add event listeners to view
- Update `update` function - single event instead of list

??? example "Before & After"

    **Before (Sub):**
    --8<-- "docs/engines/animation/migration-guide/sub.md:code"

    **After (Transitions):**
    --8<-- "docs/engines/animation/migration-guide/transition.md:code"

---

### Keyframes → Transitions

- **Adds**: mid-flight redirections
- **Loses**: pause/resume & restart controls, looping
**Changes required:**

- Change types from `Keyframes.*` to `Transitions.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframes.styleNode` from view
- Update pattern matching - remove `Iteration` event handling

??? example "Before & After"

    **Before (Keyframes):**
    --8<-- "docs/engines/animation/migration-guide/keyframe.md:code"

    **After (Transitions):**
    --8<-- "docs/engines/animation/migration-guide/transition.md:code"

---

## Need Help?

If you run into issues during migration, check:

1. The compiler errors - Elm will catch most type mismatches
2. The individual engine documentation for detailed API reference
3. The examples on the [examples page](../../examples.md) for working code

If you have a problem you just can't solve, you can <a href="https://discourse.elm-lang.org/new-message?username=paulh" target="_blank">PM me on Discourse</a>.
