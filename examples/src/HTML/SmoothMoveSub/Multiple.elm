module HTML.SmoothMoveSub.Multiple exposing (main)

{-| This example demonstrates MULTIPLE SIMULTANEOUS ANIMATIONS!

🎉 NEW FEATURES:

  - ✅ Multiple elements can animate at the same time
  - ✅ Each element has independent animation state
  - ✅ No blocking between different animations
  - ✅ Single subscription handles all animations efficiently
  - ✅ Clean API - same functions work for single or multiple

ARCHITECTURE:

  - Model tracks multiple activeAnimations: List AnimationState
  - animateTo adds new animations without stopping existing ones
  - update processes all active animations each frame
  - transform with getPosition works for any number of elements

-}

import Browser exposing (Document)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import SmoothMoveSub exposing (animateTo, getPosition, isAnimating, setInitialPosition, transform)


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
    = StartElementA
    | StartElementB
    | StartElementC
    | StartAll
    | AnimationFrame Float
    | NoOp


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting positions to prevent jump to (0,0)
        initialSmoothMove =
            SmoothMoveSub.init
                |> setInitialPosition "element-a" 300 120
                |> setInitialPosition "element-b" 400 180
                |> setInitialPosition "element-c" 500 120
    in
    ( { smoothMove = initialSmoothMove }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        StartElementA ->
            let
                newSmoothMove =
                    animateTo "element-a" 600 180 model.smoothMove
            in
            ( { model | smoothMove = newSmoothMove }, Cmd.none )

        StartElementB ->
            let
                newSmoothMove =
                    animateTo "element-b" 300 350 model.smoothMove
            in
            ( { model | smoothMove = newSmoothMove }, Cmd.none )

        StartElementC ->
            let
                newSmoothMove =
                    animateTo "element-c" 200 280 model.smoothMove
            in
            ( { model | smoothMove = newSmoothMove }, Cmd.none )

        StartAll ->
            let
                -- Chain multiple animations - all start simultaneously!
                newSmoothMove =
                    model.smoothMove
                        |> animateTo "element-a" 500 300
                        |> animateTo "element-b" 300 150
                        |> animateTo "element-c" 700 250
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
    SmoothMoveSub.subscriptions model.smoothMove AnimationFrame


view : Model -> Document Msg
view model =
    let
        getTransform elementId defaultX defaultY =
            case getPosition elementId model.smoothMove of
                Just pos ->
                    transform pos.x pos.y

                Nothing ->
                    transform defaultX defaultY
    in
    { title = "SmoothMoveSub Multiple Example"
    , body =
        -- Full-screen background
        [ div [ style "position" "fixed", style "top" "0", style "left" "0", style "width" "100vw", style "height" "100vh", style "background" "linear-gradient(135deg, #667eea 0%, #764ba2 100%)", style "z-index" "-1" ] []

        -- Back button on top
        , a [ href "index.html", style "position" "fixed", style "top" "10px", style "left" "10px", style "background" "#666", style "color" "white", style "padding" "10px 15px", style "text-decoration" "none", style "border-radius" "5px", style "font-size" "14px", style "z-index" "1000" ] [ text "← Back" ]

        -- Main content area
        , div [ style "position" "relative", style "width" "100vw", style "height" "100vh", style "padding-top" "60px", style "box-sizing" "border-box" ]
            [ -- Element A (Red) - moved away from top-left corner
              div
                [ id "element-a"
                , style "position" "absolute"
                , style "width" "60px"
                , style "height" "60px"
                , style "background-color" "#ff6b6b"
                , style "border-radius" "50%"
                , style "transform" (getTransform "element-a" 300 120)
                , style "box-shadow" "0 4px 8px rgba(0,0,0,0.2)"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                ]
                [ div [ style "color" "white", style "font-weight" "bold", style "font-size" "18px" ]
                    [ text "A" ]
                ]

            -- Element B (Blue)
            , div
                [ id "element-b"
                , style "position" "absolute"
                , style "width" "60px"
                , style "height" "60px"
                , style "background-color" "#4ecdc4"
                , style "border-radius" "50%"
                , style "transform" (getTransform "element-b" 400 180)
                , style "box-shadow" "0 4px 8px rgba(0,0,0,0.2)"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                ]
                [ div [ style "color" "white", style "font-weight" "bold", style "font-size" "18px" ]
                    [ text "B" ]
                ]

            -- Element C (Green)
            , div
                [ id "element-c"
                , style "position" "absolute"
                , style "width" "60px"
                , style "height" "60px"
                , style "background-color" "#95e1d3"
                , style "border-radius" "50%"
                , style "transform" (getTransform "element-c" 500 120)
                , style "box-shadow" "0 4px 8px rgba(0,0,0,0.2)"
                , style "display" "flex"
                , style "align-items" "center"
                , style "justify-content" "center"
                ]
                [ div [ style "color" "white", style "font-weight" "bold", style "font-size" "18px" ]
                    [ text "C" ]
                ]

            -- Control Panel - moved to right side to avoid back button
            , div
                [ style "position" "fixed"
                , style "top" "60px"
                , style "right" "20px"
                , style "background" "rgba(255,255,255,0.9)"
                , style "padding" "20px"
                , style "border-radius" "10px"
                , style "box-shadow" "0 4px 12px rgba(0,0,0,0.15)"
                ]
                [ h3 [ style "margin-top" "0", style "color" "#333" ] [ text "🎮 Animation Controls" ]
                , div [ style "display" "flex", style "flex-direction" "column", style "gap" "10px" ]
                    [ button
                        [ onClick StartElementA
                        , style "padding" "10px 15px"
                        , style "background" "#ff6b6b"
                        , style "color" "white"
                        , style "border" "none"
                        , style "border-radius" "5px"
                        , style "cursor" "pointer"
                        ]
                        [ text "🔴 Move A" ]
                    , button
                        [ onClick StartElementB
                        , style "padding" "10px 15px"
                        , style "background" "#4ecdc4"
                        , style "color" "white"
                        , style "border" "none"
                        , style "border-radius" "5px"
                        , style "cursor" "pointer"
                        ]
                        [ text "🔵 Move B" ]
                    , button
                        [ onClick StartElementC
                        , style "padding" "10px 15px"
                        , style "background" "#95e1d3"
                        , style "color" "white"
                        , style "border" "none"
                        , style "border-radius" "5px"
                        , style "cursor" "pointer"
                        ]
                        [ text "🟢 Move C" ]
                    , button
                        [ onClick StartAll
                        , style "padding" "12px 20px"
                        , style "background" "linear-gradient(45deg, #667eea, #764ba2)"
                        , style "color" "white"
                        , style "border" "none"
                        , style "border-radius" "5px"
                        , style "cursor" "pointer"
                        , style "font-weight" "bold"
                        ]
                        [ text "🎉 Move ALL Simultaneously!" ]
                    ]
                ]

            -- Status Panel - moved to right side
            , div
                [ style "position" "fixed"
                , style "bottom" "20px"
                , style "right" "20px"
                , style "background" "rgba(255,255,255,0.9)"
                , style "padding" "15px"
                , style "border-radius" "10px"
                , style "box-shadow" "0 4px 12px rgba(0,0,0,0.15)"
                , style "font-family" "monospace"
                ]
                [ div [ style "color" "#333", style "font-weight" "bold" ]
                    [ text "📊 Animation Status:" ]
                , div
                    [ style "margin-top" "5px"
                    , style "color"
                        (if isAnimating model.smoothMove then
                            "#27ae60"

                         else
                            "#e74c3c"
                        )
                    ]
                    [ text
                        (if isAnimating model.smoothMove then
                            "🟢 RUNNING"

                         else
                            "🔴 IDLE"
                        )
                    ]
                ]
            ]
        ]
    }
