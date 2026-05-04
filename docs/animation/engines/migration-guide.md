# Migration Guide

This page focuses on the fastest way to switch engines. For shared behavior and feature tradeoffs, read [Engine Overview](overview.md).

All engines share the same builder API, so animation definitions usually stay the same. Most migration work is in integration points like `init`, `update`, `subscriptions`, view wiring, and WAAPI JavaScript setup.

## How To Use This Page

Most migrations follow this flow:

1. Change the engine import.
2. Recompile.
3. Follow compiler errors in order.
4. Apply the target engine checklist below.

You are usually moving between:

- State tracked engines: `Transition`, `Keyframe`, `Sub`, `WAAPI`
- Timeline engines: `ScrollTimeline`, `ViewTimeline`

Timeline engines are command based and do not use `AnimState`, `update`, or `subscriptions`.

## Compiler First Workflow

Use this sequence for any migration:

1. Change import and module alias.
2. Update `init` signature and call shape.
3. Update trigger calls (`animate` and optional `fireAndForget`).
4. Update `update` handling and event shape.
5. Add or remove `subscriptions`.
6. Add or remove engine specific view wiring (`styleNode`, event listeners, timeline attributes).
7. Add or remove WAAPI JavaScript and ports.

This order usually gives the cleanest compiler guided path.

## Target Engine Checklists

Pick the engine you are migrating to and apply that checklist.

### To Transition

Use this when you want the simplest pure Elm setup with CSS transitions.

Required changes:

- Use `Transition.init`.
- `animate` returns `AnimState`.
- No `subscriptions` required for animation flow.
- Use DOM event listener pattern for events.
- Remove `Keyframe.styleNode` if coming from Keyframe.
- Remove WAAPI ports and JavaScript if coming from WAAPI.

### To Keyframe

Use this when you want pure Elm setup plus pause, resume, restart, and looping support.

Required changes:

- Use `Keyframe.init`.
- `animate` returns `AnimState`.
- Add `Keyframe.styleNode model.animState` in view.
- No `subscriptions` required for animation flow.
- Use DOM event listener pattern for events.
- Remove WAAPI ports and JavaScript if coming from WAAPI.

### To Sub

Use this when you want full Elm side control and frame based updates.

Required changes:

- Use `Sub.init`.
- `animate` returns `AnimState`.
- Add `subscriptions` with `Sub.subscriptions`.
- `Sub.update` returns `( AnimState, List AnimEvent )`.
- Remove DOM event listener pattern (events come from `Sub.update`).
- Remove WAAPI ports and JavaScript if coming from WAAPI.

### To WAAPI

Use this when you want browser native interpolation with state tracked control and optional command only triggering.

Required changes:

- Add WAAPI JavaScript companion and ports.
- Use `WAAPI.init waapiCommand waapiEvent ...`.
- Add `subscriptions` with `WAAPI.subscriptions`.
- `WAAPI.animate` returns `( AnimState, Cmd msg )`.
- `WAAPI.update` returns `( AnimState, AnimEvent )`.
- `WAAPI.fireAndForget` returns only `Cmd msg`.
- Remove DOM event listener pattern (events come via ports).

### To Scroll Timeline

Use this when animation progress should follow container or document scroll.

Required changes:

- Remove `AnimState` based flow (`init`, `update`, `subscriptions`).
- Use `ScrollTimeline.animate waapiCommand container buildFn`.
- Keep WAAPI JavaScript companion and outgoing port.
- Use `ScrollTimeline.attributes animGroup` in view.

### To View Timeline

Use this when animation progress should follow an element position in the viewport.

Required changes:

- Remove `AnimState` based flow (`init`, `update`, `subscriptions`).
- Use `ViewTimeline.animate waapiCommand buildFn`.
- Use `rangeStart` and `rangeEnd` when needed.
- Keep WAAPI JavaScript companion and outgoing port.
- Use `ViewTimeline.attributes animGroup` in view.

## Common Migration Traps

- Subscriptions missing after moving to `Sub` or `WAAPI`.
- Missing `Keyframe.styleNode` when moving to `Keyframe`.
- Forgetting WAAPI JavaScript setup when moving to `WAAPI`, `ScrollTimeline`, or `ViewTimeline`.

## Need Full API Details?

Use engine specific pages for complete references:

- [Transition](transition.md)
- [Keyframe](keyframes.md)
- [Sub](sub.md)
- [WAAPI](waapi.md)
- [Scroll Timeline](scroll-timeline.md)
- [View Timeline](view-timeline.md)

For end to end code, see [Examples](../examples.md).

## Next Steps

Now that you know how to migrate engine integration, continue with property APIs.

[Properties →](../properties/getting-started.md){ .md-button .md-button--primary }
