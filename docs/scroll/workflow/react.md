# React

After triggering a scroll, you'll want to react to its outcome - update UI state, handle errors, chain follow-up actions, or track live progress.

??? example "View Source Code"

    === "Cmd"

        The Cmd Engine delivers a single completion message when the scroll finishes. The message carries no result information - it is purely a signal that the scroll has ended:

        ```elm
        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    ( model
                    , Scroll.animate ScrollComplete <| 
                        scrollToSection targetId
                    )

                ScrollComplete ->
                    -- The scroll has finished - update UI state, trigger a follow-up, etc.
                    ( { model | status = Arrived }, Cmd.none )
        ```

    === "Task"

        `Scroll.animate` returns a `Task ScrollError (List ScrollOk)`. Handle both outcomes in your `update` function:


        ```elm
        type Msg 
            = GotScrollResult (Result ScrollError (List ScrollOk))
            | ...

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    ( { model | status = Scrolling }
                    , Scroll.animate (scrollToSection targetId)
                        |> Task.attempt GotScrollResult
                    )

                GotScrollResult (Ok scrollsOk) ->
                    ( { model | status = Arrived }, Cmd.none )

                GotScrollResult (Err (Scroll.ScrollError err)) ->
                    ( { model | status = Failed err.containerId }, Cmd.none )
        ```

        For full `ScrollOk`/`ScrollError` field reference and Task composition patterns,
        see the [Scroll Task Engine docs](../engines/task.md#3-handle-the-result)
        and [Task Composition](../engines/task.md#task-composition).

    === "Sub"

        The Sub Engine returns a list of events from `Scroll.update`. Each event represents something that happened during that animation frame:

        ```elm
        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                GotScrollMsg scrollMsg ->
                    let
                        ( newScrollState, events, scrollCmd ) =
                            Scroll.update GotScrollMsg scrollMsg model.scrollState

                        updatedModel =
                            handleEvents { model | scrollState = newScrollState } events
                    in
                    ( updatedModel, scrollCmd )


        handleEvents : Model -> List Scroll.ScrollEvent -> Model
        handleEvents =
            List.foldl handleEvent


        handleEvent : Scroll.ScrollEvent -> Model -> Model
        handleEvent event model =
            { model
                | status =
                    case event of
                        Scroll.Started _ ->
                            Scrolling

                        Scroll.Ended _ ->
                            Arrived

                        Scroll.Progress _ position progress ->
                            ShowingProgress position progress

                        _ ->
                            model.status
            }

        subscriptions : Model -> Sub Msg
        subscriptions model =
            Scroll.subscriptions GotScrollMsg model.scrollState
        ```

        **`update` returns a list** because multiple scrolls can produce events in the same frame. Use `List.foldl` to process them all.

        For full `AnimEvent` payload reference and live progress patterns,
        see [Events](../engines/sub.md#events),
        [AnimEvent Reference](../engines/sub.md#animevent-reference),
        and [Tracking Live Progress](../engines/sub.md#tracking-live-progress)
        in the Scroll Sub Engine docs.

## Next Steps

Now that you understand the full scroll workflow, learn about the different Scroll Engines and what they can do.

[Engines Overview →](../engines/overview.md){ .md-button .md-button--primary }
