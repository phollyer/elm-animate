# Trigger

Once you've [built](build.md) your scroll, you need to trigger it. The three scroll engines use different `animate` functions, each suited to a different trade-off between simplicity and control.

## Cmd Engine

`Scroll.animate` takes a completion message and the scroll builder, and returns a `Cmd`:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll.Cmd as Scroll

    type Msg
        = ScrollTo String
        | ScrollComplete

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                ( model
                , Scroll.animate ScrollComplete <| scrollToSection targetId
                )

            ScrollComplete ->
                ( model, Cmd.none )
    ```

- No model state is needed - the engine manages everything internally.
- `ScrollComplete` fires when the scroll finishes, regardless of success or failure.
- The completion message carries no information about the outcome. Use the Task Engine if you need to know whether the scroll succeeded.

## Task Engine

`Scroll.animate` returns a `Task ScrollError ScrollOk`. Use `Task.attempt` to convert it into a `Cmd`:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll.Task as Scroll
    import Task

    type Msg
        = ScrollTo String
        | GotScrollResult (Result Scroll.ScrollError Scroll.ScrollOk)

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                ( model
                , Scroll.animate (scrollToSection targetId)
                    |> Task.attempt GotScrollResult
                )

            GotScrollResult result ->
                ...
    ```

- Returns a `Task` so you can compose multiple scrolls with `Task.andThen`.
- The result delivers `ScrollOk` on success or `ScrollError` on failure. See [React - Task Engine](react.md#task-engine) for handling both.

## Sub Engine

`Scroll.animate` takes a message wrapper, the current `AnimState`, and the scroll builder. It returns the updated state and a `Cmd` together:

??? example "View Source Code"

    ```elm
    import Anim.Engine.Scroll.Sub as Scroll

    type Msg
        = ScrollTo String
        | GotScrollMsg Scroll.AnimMsg

    update : Msg -> Model -> ( Model, Cmd Msg )
    update msg model =
        case msg of
            ScrollTo targetId ->
                let
                    ( newScrollState, scrollCmd ) =
                        Scroll.animate GotScrollMsg model.scrollState <|
                            scrollToSection targetId
                in
                ( { model | scrollState = newScrollState }, scrollCmd )

            GotScrollMsg scrollMsg ->
                ...
    ```

- Store `Scroll.AnimState` in your model and initialize it with `Scroll.init`.
- Triggering a new scroll while one is in flight safely replaces the running animation.
- The Sub Engine requires [subscriptions](subscribe.md) to drive the animation frame-by-frame.

## Triggering on Page Load

All three engines can trigger a scroll in `init`:

??? example "View Source Code"

    === "Cmd"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( {}
            , Scroll.animate ScrollComplete <| scrollToSection "intro"
            )
        ```

    === "Task"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { status = Scrolling }
            , Scroll.animate (scrollToSection "intro")
                |> Task.attempt GotScrollResult
            )
        ```

    === "Sub"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            let
                ( scrollState, scrollCmd ) =
                    Scroll.animate GotScrollMsg Scroll.init <|
                        scrollToSection "intro"
            in
            ( { scrollState = scrollState }
            , scrollCmd
            )
        ```

## Next Steps

Handle scroll completion and errors in your update function.

[React →](react.md){ .md-button .md-button--primary }
