module HTML.SmoothMoveScroll.Container exposing (main)

import Browser exposing (Document)
import Common.UI as UI
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import SmoothMoveScroll exposing (animateToCmdWithConfig, defaultConfig, setContainer)


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }


type alias Model =
    {}


init : () -> ( Model, Cmd Msg )
init _ =
    ( {}, Cmd.none )


type Msg
    = NoOp
    | ScrollToTop
    | ScrollToMiddle
    | ScrollToBottom


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ScrollToTop ->
            ( model
            , animateToCmdWithConfig NoOp (setContainer "scroll-container" defaultConfig) "top-element"
            )

        ScrollToMiddle ->
            ( model
            , animateToCmdWithConfig NoOp (setContainer "scroll-container" defaultConfig) "middle-element"
            )

        ScrollToBottom ->
            ( model
            , animateToCmdWithConfig NoOp (setContainer "scroll-container" defaultConfig) "bottom-element"
            )


view : Model -> Document Msg
view model =
    { title = "SmoothMoveScroll - Container Scrolling"
    , body =
        [ -- Navigation
          a [ href "../../index.html", class "back-button" ] [ text "← Back to Dashboard" ]
        , -- Main content
          div [ class "main-content" ]
            [ h1 [] [ text "Container Scrolling Example" ]
            , p [] [ text "This demonstrates smooth scrolling within a scrollable container (not the document itself)." ]
            , -- Control buttons
              div [ class "controls" ]
                [ button [ onClick ScrollToTop, class "control-btn top-btn" ] [ text "Scroll to Top" ]
                , button [ onClick ScrollToMiddle, class "control-btn middle-btn" ] [ text "Scroll to Middle" ]
                , button [ onClick ScrollToBottom, class "control-btn bottom-btn" ] [ text "Scroll to Bottom" ]
                ]
            , -- The scrollable container
              div [ id "scroll-container", class "scroll-container" ]
                [ div [ class "scroll-content" ]
                    [ div [ id "top-element", class "content-block top-block" ]
                        [ h2 [] [ text "� Top of Container" ]
                        , p [] [ text "This is the top of the scrollable container content. The background gradient helps visualize scroll position." ]
                        , p [] [ text "Click 'Scroll to Top' to smoothly scroll to this position." ]
                        ]
                    , UI.contentBlockHtml 1 "This is content block 1. Each block has enough content to make scrolling meaningful."
                    , UI.contentBlockHtml 2 "Content block 2 continues the gradient transition from white to dark."
                    , UI.contentBlockHtml 3 "Content block 3 shows the middle section of our scrollable content."
                    , div [ id "middle-element", class "content-block" ]
                        [ h3 [] [ text "🎯 Content Block 4 - Middle Target" ]
                        , p [] [ text "This is the middle target of our scrollable content - Content block 4 demonstrates the progression through the gradient." ]
                        , p [] [ text "Click 'Scroll to Middle' to smoothly scroll to this position." ]
                        , ul []
                            [ li [] [ text "This block serves as the middle anchor point" ]
                            , li [] [ text "The gradient background shows scroll position" ]
                            , li [] [ text "Smooth scrolling animates between positions" ]
                            ]
                        ]
                    , UI.contentBlockHtml 5 "Content block 5 continues toward the bottom of the container."
                    , UI.contentBlockHtml 6 "Content block 6 shows we're getting closer to the bottom."
                    , UI.contentBlockHtml 7 "Content block 7 is near the end with darker background colors."
                    , UI.contentBlockHtml 8 "Content block 8 is almost at the bottom of the scrollable content."
                    , div [ id "bottom-element", class "content-block bottom-block" ]
                        [ h2 [] [ text "🔻 Bottom of Container" ]
                        , p [] [ text "This is the bottom of the scrollable container content. Notice the dark background." ]
                        , p [] [ text "Click 'Scroll to Bottom' to smoothly scroll to this position." ]
                        , p [] [ text "The smooth animation should work reliably using the new SmoothMoveScroll API." ]
                        ]
                    ]
                ]
            ]
        , -- Styles
          node "style" [] [ text css ]
        ]
    }



css : String
css =
    """
body {
    margin: 0;
    padding: 0;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
    background: #f5f7fa;
    color: #333;
}

.back-button {
    position: fixed;
    top: 20px;
    left: 20px;
    background: #6c757d;
    color: white;
    padding: 12px 20px;
    text-decoration: none;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 500;
    z-index: 1000;
    box-shadow: 0 2px 8px rgba(0,0,0,0.15);
    transition: background-color 0.2s ease;
}

.back-button:hover {
    background: #5a6268;
}

.main-content {
    max-width: 1000px;
    margin: 0 auto;
    padding: 80px 20px 40px;
    text-align: center;
}

h1 {
    color: #2c3e50;
    margin-bottom: 20px;
    font-size: 2.5em;
    font-weight: 300;
}

p {
    font-size: 1.1em;
    line-height: 1.6;
    margin-bottom: 20px;
    color: #666;
}

.status {
    background: #e8f4fd;
    color: #0066cc;
    padding: 15px 25px;
    border-radius: 25px;
    font-weight: 500;
    margin: 30px 0;
    display: inline-block;
    border-left: 4px solid #0066cc;
}

.controls {
    margin: 40px 0;
}

.control-btn {
    padding: 15px 30px;
    font-size: 16px;
    font-weight: 600;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    margin: 0 10px 10px;
    transition: all 0.3s ease;
    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.top-btn {
    background: linear-gradient(135deg, #74b9ff, #0984e3);
    color: white;
}

.top-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(116, 185, 255, 0.4);
}

.middle-btn {
    background: linear-gradient(135deg, #00b894, #00a085);
    color: white;
}

.middle-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(0, 184, 148, 0.4);
}

.bottom-btn {
    background: linear-gradient(135deg, #fd79a8, #e84393);
    color: white;
}

.bottom-btn:hover {
    transform: translateY(-2px);
    box-shadow: 0 4px 15px rgba(253, 121, 168, 0.4);
}

.scroll-container {
    width: 100%;
    height: 600px;
    border: 2px solid #dee2e6;
    border-radius: 12px;
    overflow-y: auto;
    overflow-x: hidden;
    background: white;
    box-shadow: 0 4px 20px rgba(0,0,0,0.1);
    margin-top: 30px;
    text-align: left;
}

.scroll-content {
    background: linear-gradient(to bottom, 
        #ffffff 0%,
        #f8f9fa 15%,
        #e9ecef 30%,
        #dee2e6 45%,
        #ced4da 60%,
        #adb5bd 75%,
        #6c757d 90%,
        #495057 100%
    );
    min-height: 2000px;
    padding: 0;
}

.content-block {
    padding: 40px;
    margin: 0;
    border-bottom: 1px solid rgba(0,0,0,0.1);
}

.content-block h2, .content-block h3 {
    margin-top: 0;
    color: #2c3e50;
}

.content-block h2 {
    font-size: 2em;
    margin-bottom: 20px;
}

.content-block h3 {
    font-size: 1.5em;
    margin-bottom: 15px;
    color: #34495e;
}

.content-block p {
    color: #555;
    line-height: 1.6;
    margin-bottom: 15px;
}

.content-block ul {
    margin: 20px 0;
    padding-left: 30px;
}

.content-block li {
    margin: 8px 0;
    color: #666;
}

.top-block {
    background: rgba(255,255,255,0.8);
    border-bottom: 3px solid #74b9ff;
}

.bottom-block {
    background: rgba(0,0,0,0.1);
    border-top: 3px solid #fd79a8;
    color: #2c3e50;
}

.bottom-block h2 {
    color: #2c3e50;
}

/* Smooth scrolling disabled - we handle it programmatically */
.scroll-container {
    scroll-behavior: auto;
}

/* Responsive design */
@media (max-width: 768px) {
    .main-content {
        padding: 60px 15px 20px;
    }
    
    h1 {
        font-size: 2em;
    }
    
    .scroll-container {
        height: 500px;
    }
    
    .control-btn {
        display: block;
        width: 200px;
        margin: 10px auto;
    }
    
    .content-block {
        padding: 30px 20px;
    }
}
"""
