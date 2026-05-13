# Responsive Animations

When the viewport changes — a window resize, an orientation flip, a sidebar opening, a drag handle moving — animations that depend on layout-derived targets need to be re-anchored to the new geometry. Otherwise, an element animating to "the right edge" finishes at the *old* right edge.

Use `retarget` to update the destination of an animation that's already running, without restarting it.

## How `retarget` Behaves

| Engine | Behaviour |
| ------ | --------- |
| Transition | Snaps to the new target. |
| Keyframe | Snaps to the new target. |
| Sub | Continues smoothly from the current position to the new target. |
| WAAPI | Continues smoothly from the current position to the new target. |

The builder API is identical across engines — only the runtime behaviour changes.

## When to Use It

- Resize handlers that recompute animation targets on viewport change.
- Drag interactions that re-anchor a mid-flight animation as the pointer moves.
- After measuring a container with `Browser.Dom.getElement`.

## Choosing an Engine

- **Need smooth continuation while the user is actively interacting?** Use [Sub](../engines/sub.md) or [WAAPI](../engines/waapi.md).
- **Need a deterministic landing position after a resize storm?** [Transition](../engines/transition.md) and [Keyframe](../engines/keyframes.md) snap directly to the new target — no overshoot, no stutter, regardless of how many times the resize handler fires.

## Example

```elm
subscriptions : Model -> Sub Msg
subscriptions _ =
    Browser.Events.onResize (\_ _ -> Resize)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Resize ->
            ( model, measureCanvas )

        GotCanvas (Ok element) ->
            let
                w = element.element.width
                h = element.element.height
            in
            ( { model
                | canvasW = w
                , canvasH = h
                , animState =
                    Engine.retarget model.animState <|
                        retargetBoxXY (targetX model.xPos w) (targetY h)
              }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )


retargetBoxXY : Float -> Float -> AnimBuilder mode -> AnimBuilder mode
retargetBoxXY x y =
    Translate.continueFor "movingBox"
        >> Translate.toXY x y
        >> Translate.build
```

Swap `Engine` for `Transition`, `Keyframe`, `Sub`, or `WAAPI`. The builder is portable; only the engine call site changes.

## See Also

- [Mid-Flight Interruptions](interrupting-animations.md) — what happens when a second `animate` is triggered.
- [Engines Overview](../engines/overview.md#feature-comparison) — full feature comparison.
