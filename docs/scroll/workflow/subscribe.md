# Subscribe

## Sub Engine Only

The Cmd and Task engines manage their own internal timing and do not need subscriptions. The Sub Engine drives animation frame-by-frame, so it relies on subscriptions to receive the updates that keep the scroll moving.

## Wiring Up Subscriptions

Pass your `AnimMsg` wrapper and the current `AnimState` to `Scroll.subscriptions`:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll.Sub as Scroll

    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions GotScrollMsg model.scrollState
    ```

This produces a `Sub` that fires on every animation frame while a scroll is running, and is idle when nothing is animating - so there is no unnecessary overhead when no scroll is active.

## Connecting to Your App

Wire it in via `Browser.element` or `Browser.application`:

??? example "View Source Code"

    ```elm
    main : Program () Model Msg
    main =
        Browser.element
            { init = init
            , view = view
            , update = update
            , subscriptions = subscriptions
            }


    subscriptions : Model -> Sub Msg
    subscriptions model =
        Scroll.subscriptions GotScrollMsg model.scrollState
    ```

## Multiple Scroll States

If you have more than one `AnimState` in your model, combine their subscriptions with `Sub.batch`:

??? example "View Source Code"

    ```elm
    subscriptions : Model -> Sub Msg
    subscriptions model =
        Sub.batch
            [ Scroll.subscriptions GotMainScrollMsg model.mainScrollState
            , Scroll.subscriptions GotSidebarScrollMsg model.sidebarScrollState
            ]
    ```

!!! tip "Each AnimState is independent"
    Each `AnimState` tracks its own scroll and fires its own events. Use separate states and message wrappers when you need to scroll multiple containers independently.
