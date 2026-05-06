# Interrupting Scrolls

When a scroll animation is running and you trigger another scroll to the same container, the result depends on which engine is handling the scroll.

## Engine Summary

| Engine | Interrupted Scroll |
| ------ | ------------------ |
| Cmd | ⚠️ Runs in parallel — later scroll does not replace earlier scroll |
| Task | ⚠️ Runs in parallel — later scroll does not replace earlier scroll |
| Sub | ✅ Replaces the running scroll from current position |

## Scroll.Cmd

`Scroll.Cmd` is fire-and-forget. Each call to `animate` pre-calculates all its frame steps from the DOM scroll position at the moment the `Cmd` runs, then sequences them as a `Task` chain.

If you call `animate` again while the first scroll is still running, both `Task` chains execute independently. The new scroll does not cancel or replace the old one, so both chains can keep writing viewport positions until they finish.

If the second scroll is a duplicate of the first, they will both finish correctly. If the second scroll is to a different target in the same element, both scrolls will compete - with the longest scroll winning.

??? example "View Source Code"
    ```elm
    -- First scroll starts
    ( model, Scroll.scroll ScrollComplete scrollToSection )

    -- User clicks again before it finishes — the second scroll
    -- starts as well, but does not replace the first one
    ( model, Scroll.scroll ScrollComplete scrollToSection )
    ```

There is no way to cancel a `Cmd` scroll once it has been dispatched.

### Can You Combat This in Cmd?

You can avoid this if you:

- ignore new triggers while a scroll is active
- debounce rapid input before starting a scroll
- queue the latest target and only dispatch it after `ScrollComplete`

If you need a second trigger to immediately replace the running scroll and still finish correctly, use `Scroll.Sub`.

## Scroll.Task

`Scroll.Task` has the same pre-calculation behaviour as `Scroll.Cmd`. If a second task is dispatched mid-flight, it starts another independent scroll sequence rather than replacing the one that is already running.

??? example "View Source Code"
    ```elm
    -- First scroll dispatched
    ( model
    , Scroll.scroll scrollToSection
        |> Task.attempt ScrollResult
    )

    -- Dispatching again before it finishes starts another
    -- scroll sequence instead of replacing the first
    ```

There is no way to cancel a `Task` scroll once it has been dispatched.

### Can You Combat This in Task?

You can make `Task` flows safe if you do not allow overlap:

- Serialize requests: start the next scroll only after the previous `Task` resolves.
- Keep a `pendingTarget` in the model and launch it when the current scroll completes.
- Throttle, debounce, or coalesce repeated triggers before launching the next `Task`.

Like `Cmd`, `Task` cannot replace an already-running scroll once it has been triggered.

## Scroll.Sub

`Scroll.Sub` is stateful. Each call to `scroll` replaces the running animation in the `ScrollState`. On the next frame, the engine reads the current DOM scroll position and re-calculates toward the new target from wherever the container actually is.

This means the scroll redirects smoothly from its current position, regardless of how far through the previous animation it was:

??? example "View Source Code"
    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                -- Calling this while a scroll is running safely
                -- redirects from the current scroll position
                let
                    ( newState, cmd ) =
                        Sub.scroll ScrollMsg model.scrollState <|
                            Scroll.forContainer "scroll-container"
                                >> Scroll.toElement targetId
                                >> Scroll.build
                in
                ( { model | scrollState = newState }, cmd )
    ```

The replaced scroll fires a `Stopped` event for the interrupted container before the new scroll begins.

## Next Steps

Now that you understand how scrolls handle interruptions, learn how to control them.

[Controlling Scrolls →](controlling-scroll.md){ .md-button .md-button--primary }
