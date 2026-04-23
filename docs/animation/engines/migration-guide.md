# Migration Guide

This guide helps you switch between animation engines. Because all engines share the same builder API, your animation definitions remain unchanged - only the engine integration code needs updating.


## Quick Reference Matrix

This table shows what changes when migrating between engines:

| Component | Transition | Keyframe | Sub | WAAPI |
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

- [Transition → Keyframe](#transitions-keyframes) - Add pause/resume & restart controls, looping
- [Transition → Sub](#transitions-sub) - Add pause/resume & restart controls, looping, mid-flight access
- [Transition → WAAPI](#transitions-waapi) - Add pause/resume & restart controls, looping, mid-flight access
- [Keyframe → Sub](#keyframes-sub) - Add mid-flight access, dynamic redirects
- [Keyframe → WAAPI](#keyframes-waapi) - Add mid-flight access, dynamic redirects
- [Sub → WAAPI](#sub-waapi) - Add browser-native interpolation, `fireAndForget` option

### Migrating Down (simplifying)

- [WAAPI → Sub](#waapi-sub) - Regain pure Elm (no JavaScript/ports)
- [WAAPI → Keyframe](#waapi-keyframes) - Regain pure Elm (no JavaScript/ports)
- [WAAPI → Transition](#waapi-transitions) - Regain pure Elm (no JavaScript/ports)
- [Sub → Keyframe](#sub-keyframes) - Regain browser-native interpolation
- [Sub → Transition](#sub-transitions) - Regain browser-native interpolation
- [Keyframe → Transition](#keyframes-transitions) - Regain mid-flight redirections


---

## Migrating Up

### Transition → Keyframe

- **Adds**: pause/resume & restart controls, looping
- **Loses**: mid-flight redirections

**Changes required:**

- Change types from `Transition.*` to `Keyframe.*` (AnimState, AnimMsg, AnimEvent)
- Add `Keyframe.styleNode model.animState` to your view
- Update pattern matching for events (Keyframe has `Iteration` event)

??? example "Before & After"

    **Before (Transition):**
    --8<-- "do../engines/migration-guide/transition.md:code"

    **After (Keyframe):**
    --8<-- "do../engines/migration-guide/keyframe.md:code"

---

### Transition → Sub

- **Adds**: pause/resume & restart controls, looping, mid-flight access
- **Loses**: browser-native interpolation

**Changes required:**

- Change types from `Transition.*` to `Sub.*` (AnimState, AnimMsg, AnimEvent)
- Add subscriptions function
- Update `update` function - events come from `Sub.update` as a `List`, not from DOM
- Remove event listeners from view (events come via subscription now)

??? example "Before & After"

    **Before (Transition):**
    --8<-- "do../engines/migration-guide/transition.md:code"

    **After (Sub):**
    --8<-- "do../engines/migration-guide/sub.md:code"
    
---

### Transition → WAAPI

- **Adds**: pause/resume & restart controls, looping, mid-flight access
- **Loses**: pure Elm (requires JavaScript/ports)

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change types from `Transition.*` to `WAAPI.*` (AnimState, AnimMsg, AnimEvent)
- Define port functions and pass to `init`
- Add subscriptions function
- Update `animate` calls to handle returned `Cmd`
- Replace `fireAndForget` - WAAPI's `fireAndForget` returns `Cmd` only, unlike `animate` which returns `( AnimState, Cmd )`
- Update event handling - events have additional parameters
- Remove event listeners from view

??? example "Before & After"

    **Before (Transition):**
    --8<-- "do../engines/migration-guide/transition.md:code"

    **After (WAAPI):**
    --8<-- "do../engines/migration-guide/waapi.md:page"
    

---

### Keyframe → Sub

- **Adds**: mid-flight access, dynamic redirects
- **Loses**: browser-native interpolation

**Changes required:**

- Change types from `Keyframe.*` to `Sub.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframe.styleNode` from view
- Add subscriptions function
- Update `update` function - events come as a `List` now
- Remove event listeners from view

??? example "Before & After"

    **Before (Keyframe):**
    --8<-- "do../engines/migration-guide/keyframe.md:code"

    **After (Sub):**
    --8<-- "do../engines/migration-guide/sub.md:code"
---

### Keyframe → WAAPI

- **Adds**: mid-flight access, dynamic redirects
- **Loses**: pure Elm (requires JavaScript/ports)

**Changes required:**

- Add JavaScript setup (ports and WAAPI runtime)
- Change types from `Keyframe.*` to `WAAPI.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframe.styleNode` from view
- Define port functions and pass to `init`
- Add subscriptions function
- Update `animate` calls to handle returned `Cmd`
- Update `fireAndForget` - WAAPI's `fireAndForget` returns `Cmd` only
- Update event handling - events have additional parameters
- Remove event listeners from view

??? example "Before & After"

    **Before (Keyframe):**
    --8<-- "do../engines/migration-guide/keyframe.md:code"

    **After (WAAPI):**
    --8<-- "do../engines/migration-guide/waapi.md:page"

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
    --8<-- "do../engines/migration-guide/sub.md:code"

    **After (WAAPI):**
    --8<-- "do../engines/migration-guide/waapi.md:page"


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
    --8<-- "do../engines/migration-guide/waapi.md:code"

    **After (Sub):**
    --8<-- "do../engines/migration-guide/sub.md:code"

---

### WAAPI → Keyframe

- **Adds**: pure Elm (no JavaScript/ports)
- **Loses**: mid-flight access, dynamic redirects

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change types from `WAAPI.*` to `Keyframe.*` (AnimState, AnimMsg, AnimEvent)
- Remove port functions from `init`
- Remove subscriptions (or set to `Sub.none`)
- Add `Keyframe.styleNode model.animState` to view
- Add event listeners to view
- Update `animate` calls - no longer returns `Cmd`
- Update event handling - events come from DOM, not ports

??? example "Before & After"

    **Before (WAAPI):**
    --8<-- "do../engines/migration-guide/waapi.md:code"

    **After (Keyframe):**
    --8<-- "do../engines/migration-guide/keyframe.md:code"

---

### WAAPI → Transition

- **Adds**: pure Elm (no JavaScript/ports)
- **Loses**: pause/resume & restart controls, looping, mid-flight access

**Changes required:**

- Remove JavaScript setup (ports and WAAPI runtime)
- Change types from `WAAPI.*` to `Transition.*` (AnimState, AnimMsg, AnimEvent)
- Remove port functions from `init`
- Remove subscriptions (or set to `Sub.none`)
- Add event listeners to view
- Update `animate` calls - no longer returns `Cmd`
- Update event handling - events come from DOM, not ports

??? example "Before & After"

    **Before (WAAPI):**
    --8<-- "do../engines/migration-guide/waapi.md:code"

    **After (Transition):**
    --8<-- "do../engines/migration-guide/transition.md:code"

---

### Sub → Keyframe

- **Adds**: browser-native interpolation
- **Loses**: mid-flight access, dynamic redirects

**Changes required:**

- Change types from `Sub.*` to `Keyframe.*` (AnimState, AnimMsg, AnimEvent)
- Remove subscriptions (or set to `Sub.none`)
- Add `Keyframe.styleNode model.animState` to view
- Add event listeners to view
- Update `update` function - single event instead of list

??? example "Before & After"

    **Before (Sub):**
    --8<-- "do../engines/migration-guide/sub.md:code"

    **After (Keyframe):**
    --8<-- "do../engines/migration-guide/keyframe.md:code"

---

### Sub → Transition

- **Adds**: browser-native interpolation
- **Loses**: pause/resume & restart controls, looping, mid-flight access

**Changes required:**

- Change types from `Sub.*` to `Transition.*` (AnimState, AnimMsg, AnimEvent)
- Remove subscriptions (or set to `Sub.none`)
- Add event listeners to view
- Update `update` function - single event instead of list

??? example "Before & After"

    **Before (Sub):**
    --8<-- "do../engines/migration-guide/sub.md:code"

    **After (Transition):**
    --8<-- "do../engines/migration-guide/transition.md:code"

---

### Keyframe → Transition

- **Adds**: mid-flight redirections
- **Loses**: pause/resume & restart controls, looping
**Changes required:**

- Change types from `Keyframe.*` to `Transition.*` (AnimState, AnimMsg, AnimEvent)
- Remove `Keyframe.styleNode` from view
- Update pattern matching - remove `Iteration` event handling

??? example "Before & After"

    **Before (Keyframe):**
    --8<-- "do../engines/migration-guide/keyframe.md:code"

    **After (Transition):**
    --8<-- "do../engines/migration-guide/transition.md:code"

---

## Need Help?

If you run into issues during migration, check:

1. The compiler errors - Elm will catch most type mismatches
2. The individual engine documentation for detailed API reference
3. The examples on the [examples page](../examples.md) for working code

If you have a problem you just can't solve, you can <a href="https://discourse.elm-lang.org/new-message?username=paulh" target="_blank">PM me on Discourse</a>.

## Next Steps

Now that you've learned all about the Engines, learn more about the Properties you can animate.

[Properties →](../properties/getting-started.md){ .md-button .md-button--primary }
