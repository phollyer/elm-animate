module HTML.SmoothMoveCSS.Multiple exposing (main)

import Browser
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import SmoothMoveCSS


type alias Model =
    { animations : SmoothMoveCSS.Model
    }


type Msg
    = ScatterElements
    | ResetPositions
    | CircleFormation
    | StopAll


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting positions to prevent jump to (0,0)
        initialAnimations =
            SmoothMoveCSS.init
                |> SmoothMoveCSS.setInitialPosition "element-a" 150 100
                |> SmoothMoveCSS.setInitialPosition "element-b" 200 150
                |> SmoothMoveCSS.setInitialPosition "element-c" 100 200
    in
    ( { animations = initialAnimations
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ScatterElements ->
            let
                animations1 =
                    SmoothMoveCSS.animateTo "box1" 50 50 model.animations

                animations2 =
                    SmoothMoveCSS.animateTo "box2" 350 50 animations1

                animations3 =
                    SmoothMoveCSS.animateTo "box3" 50 250 animations2

                animations4 =
                    SmoothMoveCSS.animateTo "box4" 350 250 animations3
            in
            ( { model | animations = animations4 }, Cmd.none )

        ResetPositions ->
            let
                animations1 =
                    SmoothMoveCSS.animateTo "box1" 150 100 model.animations

                animations2 =
                    SmoothMoveCSS.animateTo "box2" 200 100 animations1

                animations3 =
                    SmoothMoveCSS.animateTo "box3" 150 150 animations2

                animations4 =
                    SmoothMoveCSS.animateTo "box4" 200 150 animations3
            in
            ( { model | animations = animations4 }, Cmd.none )

        CircleFormation ->
            let
                -- Create a circular formation using custom slow config for dramatic effect
                slowConfig =
                    { axis = SmoothMoveCSS.Both
                    , duration = 1500 -- 1.5 seconds
                    , easing = "cubic-bezier(0.68, -0.55, 0.265, 1.55)" -- Bouncy easing
                    }

                centerX =
                    200

                centerY =
                    150

                radius =
                    80

                animations1 =
                    SmoothMoveCSS.animateToWithConfig slowConfig "box1" (centerX + radius) centerY model.animations

                animations2 =
                    SmoothMoveCSS.animateToWithConfig slowConfig "box2" centerX (centerY - radius) animations1

                animations3 =
                    SmoothMoveCSS.animateToWithConfig slowConfig "box3" (centerX - radius) centerY animations2

                animations4 =
                    SmoothMoveCSS.animateToWithConfig slowConfig "box4" centerX (centerY + radius) animations3
            in
            ( { model | animations = animations4 }, Cmd.none )

        StopAll ->
            let
                animations1 =
                    SmoothMoveCSS.stopAnimation "box1" model.animations

                animations2 =
                    SmoothMoveCSS.stopAnimation "box2" animations1

                animations3 =
                    SmoothMoveCSS.stopAnimation "box3" animations2

                animations4 =
                    SmoothMoveCSS.stopAnimation "box4" animations3
            in
            ( { model | animations = animations4 }, Cmd.none )


viewBox : String -> String -> SmoothMoveCSS.Model -> Html Msg
viewBox elementId emoji animations =
    div
        [ style "position" "absolute"
        , style "width" "40px"
        , style "height" "40px"
        , style "background-color" "#2196F3"
        , style "border-radius" "50%"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "font-size" "20px"
        , style "transform" (SmoothMoveCSS.transformElement elementId animations)
        , style "transition" (SmoothMoveCSS.cssTransitionStyle elementId animations)
        , style "user-select" "none"
        ]
        [ text emoji ]


view : Model -> Html Msg
view model =
    let
        animatingText =
            if SmoothMoveCSS.isAnimating model.animations then
                "Animating with CSS transitions..."

            else
                "All animations complete"
    in
    div [ style "padding" "20px" ]
        [ h1 [] [ text "Multiple CSS Animations - Native Browser Performance" ]
        , div [] [ text ("Status: " ++ animatingText) ]
        , div [ style "margin" "20px 0" ]
            [ button [ onClick ScatterElements ] [ text "Scatter" ]
            , button [ onClick ResetPositions, style "margin-left" "10px" ] [ text "Reset" ]
            , button [ onClick CircleFormation, style "margin-left" "10px" ] [ text "Circle (Bouncy)" ]
            , button [ onClick StopAll, style "margin-left" "10px" ] [ text "Stop All" ]
            ]
        , div
            [ style "position" "relative"
            , style "width" "400px"
            , style "height" "300px"
            , style "border" "2px solid #ccc"
            , style "margin-top" "20px"
            , style "background-color" "#f9f9f9"
            ]
            [ viewBox "box1" "📦" model.animations
            , viewBox "box2" "🎯" model.animations
            , viewBox "box3" "⭐" model.animations
            , viewBox "box4" "🚀" model.animations
            ]
        , div [ style "margin-top" "20px", style "font-size" "14px", style "color" "#666" ]
            [ text "✅ Uses native CSS transitions for optimal performance"
            , Html.br [] []
            , text "✅ No JavaScript animation frames needed"
            , Html.br [] []
            , text "✅ Browser handles all easing and optimization automatically"
            , Html.br [] []
            , text "✅ Smooth animations even when JavaScript is busy"
            ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    -- No subscriptions needed! CSS handles everything
    Sub.none


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
