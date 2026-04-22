# React

After triggering a scroll, you'll want to react to its outcome - update UI state, handle errors, chain follow-up actions, or track live progress.

## Cmd Engine

The Cmd Engine delivers a single completion message when the scroll finishes. The message carries no result information - it is purely a signal that the scroll has ended:

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                ( model
                , Scroll.animate ScrollComplete <| scrollToSection targetId
                )

            ScrollComplete ->
                -- The scroll has finished - update UI state, trigger a follow-up, etc.
                ( { model | status = Arrived }, Cmd.none )
    ```

!!! note "No error information"
    The Cmd Engine fires `ScrollComplete` regardless of whether the scroll succeeded or failed. If you need to distinguish between success and failure, use the Task Engine instead.

## Task Engine

`Scroll.animate` returns a `Task ScrollError ScrollOk`. Handle both outcomes in your `Result` branch:

??? example "View Source Code"

    ```elm
    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                ( { model | status = Scrolling }
                , Scroll.animate (scrollToSection targetId)
                    |> Task.attempt GotScrollResult
                )

            GotScrollResult (Ok scrollOk) ->
                ( { model | status = Arrived }, Cmd.none )

            GotScrollResult (Err (Scroll.ScrollError err)) ->
                ( { model | status = Failed err.containerId }, Cmd.none )
    ```

### ScrollOk

`ScrollOk` is delivered when the scroll completes successfully:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `containerId` | `String` | ID of the element that was scrolled |
| `targetElementId` | `Maybe String` | ID of the target element, if scrolled to an element |

### ScrollError

`ScrollError` is delivered when the scroll fails - for example, when an element ID does not exist in the DOM:

| Field | Type | Description |
| ----- | ---- | ----------- |
| `containerId` | `String` | ID of the container that was being scrolled |
| `targetElementId` | `Maybe String` | ID of the target element, if one was specified |
| `domError` | `Dom.Error` | The underlying [Dom.Error](https://package.elm-lang.org/packages/elm/browser/latest/Browser-Dom#Error) |

### Composing Tasks

Because `animate` returns a `Task`, you can chain multiple scrolls or combine them with other Tasks:

??? example "View Source Code"

    ```elm
    -- Chain two scrolls in sequence
    Scroll.animate (scrollToSection "chapter-2")
        |> Task.andThen (\_ -> Scroll.animate (scrollToSection "first-paragraph"))
        |> Task.attempt GotScrollResult

    -- Combine with a data fetch
    fetchData "article-123"
        |> Task.andThen
            (\article ->
                Scroll.animate (scrollToSection article.anchorId)
            )
        |> Task.attempt GotResult
    ```

## Sub Engine

The Sub Engine returns a list of events from `Scroll.update`. Each event represents something that happened during that animation frame:

??? example "View Source Code"

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


    handleEvents : Model -> List Scroll.AnimEvent -> Model
    handleEvents =
        List.foldl handleEvent


    handleEvent : Scroll.AnimEvent -> Model -> Model
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
    ```

**`update` returns a list** because multiple animations can produce events in the same frame. Use `List.foldl` to process them all.

### AnimEvent Reference

| Event | Payload | Description |
| ----- | ------- | ----------- |
| `Started` | `String` | The scroll has begun. Payload is the container ID. |
| `Ended` | `String` | The scroll completed naturally. Payload is the container ID. |
| `Stopped` | `String` | The scroll was stopped before completion. Payload is the container ID. |
| `Restarted` | `String` | The scroll was restarted from the beginning. Payload is the container ID. |
| `Paused` | `String` | The scroll was paused. Payload is the container ID. |
| `Resumed` | `String` | The scroll was resumed after a pause. Payload is the container ID. |
| `Progress` | `String`, `{ x : Float, y : Float }`, `Float` | Live scroll position update. Payloads are the container ID, the current scroll coordinates, and overall progress from `0.0` to `1.0`. |

### Tracking Live Progress

The `Progress` event makes it straightforward to build position indicators, scrollbars, or percentage readouts:

??? example "View Source Code"

    ```elm
    handleEvent event model =
        { model
            | status =
                case event of
                    Scroll.Progress _ position progress ->
                        -- position.x and position.y are the current scroll coordinates
                        -- progress goes from 0.0 to 1.0
                        ShowingProgress position (round (progress * 100))

                    _ ->
                        model.status
        }
    ```

## Next Steps

The Sub Engine needs subscriptions to receive animation frame updates.

[Subscribe →](subscribe.md){ .md-button .md-button--primary }
