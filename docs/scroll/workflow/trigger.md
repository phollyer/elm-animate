# Trigger

Once you've [built](build.md) your scroll, you need to trigger it. Triggering is where the engine processes your configuration and computes the scroll data.

## Using `scroll`

??? example "View Source Code"
    === "Cmd"

        `Scroll.scroll` takes a completion message and the scroll builder, and returns a `Cmd`:

        ```elm
        import Scroll.Engine.Cmd as Scroll

        type Msg
            = ScrollTo String
            | ScrollComplete

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    ( model
                    , Scroll.scroll ScrollComplete <|
                        scrollToSection targetId
                    )

                ScrollComplete ->
                    ( model, Cmd.none )
        ```

        - No model state is needed - the engine manages everything internally.
        - `ScrollComplete` fires when the scroll finishes, regardless of success or failure.
        - The completion message carries no information about the outcome. Use the Task Engine if you need to know whether the scroll succeeded.

    === "Task"

        `Scroll.scroll` returns a `Task ScrollError (List ScrollOk)`. Use `Task.attempt` to convert it into a `Cmd`:

        ```elm
        import Scroll.Engine.Task as Scroll
        import Task

        type Msg
            = ScrollTo String
            | GotScrollResult (Result Scroll.ScrollError (List Scroll.ScrollOk))

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    ( model
                    , Task.attempt GotScrollResult <|
                        Scroll.scroll <|
                            scrollToSection targetId
                        
                    )

                GotScrollResult result ->
                    ...
        ```

        - Returns a `Task` so you can compose multiple scrolls with `Task.andThen`.
        - The result delivers all completed `ScrollOk` values on success or a `ScrollError` on failure. See [React - Task Engine](react.md#task-engine) for handling both.

    === "Sub"

        `Sub.scroll` takes a message wrapper, the current `ScrollState`, and the scroll builder. It returns the updated state and a `Cmd` together:

        ```elm
        import Scroll.Engine.Sub as Sub

        type Msg
            = ScrollTo String
            | GotScrollMsg Sub.ScrollMsg

        update : Msg -> Model -> ( Model, Cmd Msg )
        update msg model =
            case msg of
                ScrollTo targetId ->
                    let
                        ( newScrollState, scrollCmd ) =
                            Sub.scroll GotScrollMsg model.scrollState <|
                                scrollToSection targetId
                    in
                    ( { model | scrollState = newScrollState }, scrollCmd )

                GotScrollMsg scrollMsg ->
                    ...
        ```

        - Store `Sub.ScrollState` in your model and initialize it with `Sub.init`.
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
            , Scroll.scroll ScrollComplete <|
                scrollToSection "intro"
            )
        ```

    === "Task"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            ( { status = Scrolling }
            , Task.attempt GotScrollResult <|
                Scroll.scroll <|
                    scrollToSection "intro"
                
            )
        ```

    === "Sub"

        ```elm
        init : () -> ( Model, Cmd Msg )
        init _ =
            let
                ( scrollState, scrollCmd ) =
                    Sub.scroll GotScrollMsg Sub.init <|
                        scrollToSection "intro"
            in
            ( { scrollState = scrollState }
            , scrollCmd
            )
        ```

## Next Steps

Handle scroll completion and errors in your update function.

[React →](react.md){ .md-button .md-button--primary }
