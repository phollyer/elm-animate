module HTML.SmoothMoveSub.Basic exposing (main)

{-| This example demonstrate AnimationFrame deltaMs ->
let
updatedSmoothMove =
SmoothMoveSub.step deltaMs model.smoothMovee fully managed approach - no position tracking needed!

BENEFITS:

  - ✅ No need to track AnimationState in your model
  - ✅ No need to track element positions in your model
  - ✅ No need to handle animation completion manually
  - ✅ No need to pass Position data around in messages
  - ✅ Library manages ALL state automatically
  - ✅ Simple animateTo and subscriptions calls
  - ✅ Get positions with transform when needed

DEVELOPER EXPERIENCE:

  - Keep only a SmoothMoveSub.Model in your model
  - Call animateTo to begin animations (automatic current position)
  - Subscribe with SmoothMoveSub.subscriptions for smooth updates (just deltaMs!)
  - Use transform for CSS transforms with getPosition!
  - Use getPosition when you need the actual position values
  - Library handles everything else automatically!

-}

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import SmoothMoveSub exposing (animateTo, defaultConfig, getPosition, isAnimating, setPosition, transform)


main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


type alias Model =
    { smoothMove : SmoothMoveSub.Model
    }


type Msg
    = StartMove Float Float
    | AnimationFrame Float
    | NoOp


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting position to prevent jump to (0,0)
        initialSmoothMove =
            SmoothMoveSub.init
                |> setPosition "moving-element" 200 150
    in
    ( { smoothMove = initialSmoothMove }
    , Cmd.none
    )


elementId =
    "moving-element"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartMove targetX targetY ->
            let
                newSmoothMove =
                    animateTo elementId targetX targetY model.smoothMove
            in
            ( { model | smoothMove = newSmoothMove }, Cmd.none )

        AnimationFrame deltaMs ->
            let
                newSmoothMove =
                    SmoothMoveSub.step deltaMs model.smoothMove
            in
            ( { model | smoothMove = newSmoothMove }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    SmoothMoveSub.subscriptions AnimationFrame model.smoothMove


view : Model -> Document Msg
view model =
    let
        currentPos =
            getPosition "moving-element" model.smoothMove
                |> Maybe.withDefault { x = 200, y = 150 }
    in
    { title = "SmoothMoveSub Basic Example"
    , body =
        [ a [ href "index.html", style "position" "fixed", style "top" "10px", style "left" "10px", style "background" "#666", style "color" "white", style "padding" "10px 15px", style "text-decoration" "none", style "border-radius" "5px", style "font-size" "14px", style "z-index" "1000" ] [ text "← Back" ]
        , div [ style "display" "flex", style "flex-direction" "column", style "align-items" "center", style "padding" "60px 40px", style "min-height" "100vh", style "background" "linear-gradient(to bottom, #f8fafc, #e2e8f0)", style "font-family" "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif" ]
            [ div [ style "text-align" "center", style "margin-bottom" "40px" ]
                [ h1 [ style "font-size" "32px", style "font-weight" "600", style "color" "#1e293b", style "margin" "0 0 20px 0" ] [ text "SmoothMoveSub Basic Example" ]
                , p [ style "font-size" "18px", style "color" "#475569", style "margin" "0 0 20px 0" ] [ text "HTML Version - Use buttons to move the blue box" ]
                , p
                    [ style "font-size" "16px"
                    , style "color"
                        (if isAnimating model.smoothMove then
                            "#10b981"

                         else
                            "#475569"
                        )
                    , style "margin" "0 0 10px 0"
                    ]
                    [ text
                        (if isAnimating model.smoothMove then
                            "Animating..."

                         else
                            "Ready"
                        )
                    ]
                , p [ style "font-size" "14px", style "color" "#6b7280", style "margin" "0" ]
                    [ text ("Position: (" ++ String.fromFloat currentPos.x ++ ", " ++ String.fromFloat currentPos.y ++ ")") ]
                ]
            , div [ style "display" "flex", style "gap" "20px", style "margin-bottom" "40px", style "flex-wrap" "wrap", style "justify-content" "center" ]
                [ button [ onClick (StartMove 100 100), style "background" "linear-gradient(to right, #3b82f6, #2563eb)", style "color" "white", style "padding" "12px 24px", style "border" "none", style "border-radius" "8px", style "font-weight" "500", style "cursor" "pointer" ] [ text "Move to (100, 100)" ]
                , button [ onClick (StartMove 300 150), style "background" "linear-gradient(to right, #10b981, #059669)", style "color" "white", style "padding" "12px 24px", style "border" "none", style "border-radius" "8px", style "font-weight" "500", style "cursor" "pointer" ] [ text "Move to (300, 150)" ]
                , button [ onClick (StartMove 200 250), style "background" "linear-gradient(to right, #f59e0b, #d97706)", style "color" "white", style "padding" "12px 24px", style "border" "none", style "border-radius" "8px", style "font-weight" "500", style "cursor" "pointer" ] [ text "Move to (200, 250)" ]
                , button [ onClick (StartMove 0 0), style "background" "linear-gradient(to right, #a855f7, #9333ea)", style "color" "white", style "padding" "12px 24px", style "border" "none", style "border-radius" "8px", style "font-weight" "500", style "cursor" "pointer" ] [ text "Return to Origin" ]
                ]
            , div [ style "position" "relative", style "width" "500px", style "height" "400px", style "background" "white", style "border-radius" "12px", style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)", style "overflow" "hidden" ]
                [ div
                    [ id "moving-element"
                    , style "position" "absolute"
                    , style "width" "50px"
                    , style "height" "50px"
                    , style "background-color" "#3b82f6"
                    , style "border-radius" "8px"
                    , style "transform" (transform currentPos.x currentPos.y)
                    , style "transition" "none"
                    ]
                    []
                ]
            ]
        ]
    }
