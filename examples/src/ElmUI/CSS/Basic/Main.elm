module ElmUI.CSS.Basic.Main exposing (main)

{-| SmoothMoveCSS Basic Example using ElmUI - Native browser CSS transitions for optimal performance

This approach uses browser-native CSS transitions for hardware acceleration and battery efficiency.
Perfect for simple transitions where you want maximum performance with minimal JavaScript overhead.

BENEFITS:

  - ✅ Hardware acceleration via native CSS transitions
  - ✅ Battery efficient (browser optimizes automatically)
  - ✅ Simple API - just apply CSS styles directly
  - ✅ No animation frame subscriptions needed
  - ✅ Smooth 60fps animations with browser optimization
  - ✅ Automatic performance scaling based on device capabilities

USAGE:

  - Call SmoothMoveCSS.animateTo to get transition styles
  - Apply the returned CSS directly to elements
  - Browser handles all animation timing and optimization

-}

import Browser exposing (Document)
import Common.Colors as Colors
import Common.UI as UI
import Element exposing (Element, centerX, column, el, fill, height, htmlAttribute, maximum, padding, paddingXY, paragraph, px, rgb255, spacing, text, width)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html.Attributes
import SmoothMoveCSS



-- MAIN


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animations : SmoothMoveCSS.Model
    }



-- INIT


init : () -> ( Model, Cmd Msg )
init _ =
    let
        -- Initialize with starting position to prevent jump to (0,0)
        initialAnimations =
            SmoothMoveCSS.init
                |> SmoothMoveCSS.setInitialPosition "moving-box" 0 0
    in
    ( { animations = initialAnimations }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MoveToCorner
    | MoveToCenter
    | StopAnimation


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MoveToCorner ->
            ( { model | animations = SmoothMoveCSS.animateTo "moving-box" 100 100 model.animations }
            , Cmd.none
            )

        MoveToCenter ->
            ( { model | animations = SmoothMoveCSS.animateTo "moving-box" 300 200 model.animations }
            , Cmd.none
            )

        StopAnimation ->
            ( { model | animations = SmoothMoveCSS.animateTo "moving-box" 0 0 model.animations }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- No subscriptions needed for CSS transitions!
-- VIEW


view : Model -> Document Msg
view model =
    UI.createDocument "SmoothMoveCSS Basic ElmUI Example" UI.Basic (viewContent model)


viewContent : Model -> List (Element Msg)
viewContent model =
    let
        position =
            SmoothMoveCSS.getPosition "moving-box" model.animations
                |> Maybe.withDefault { x = 0, y = 0 }

        cssStyles =
            SmoothMoveCSS.cssTransitionStyle "moving-box" model.animations
    in
    [ UI.backButton
    , UI.pageHeader "SmoothMoveCSS Basic Example"
    , -- Position display
      el
        [ Font.size 14
        , Font.color Colors.textMedium
        , centerX
        ]
        (text ("Position: (" ++ String.fromInt (round position.x) ++ ", " ++ String.fromInt (round position.y) ++ ")"))
    , -- Buttons for predefined moves
      UI.htmlActionButtons
        [ ( UI.Primary, MoveToCorner, "Move to (100, 100)" )
        , ( UI.Success, MoveToCenter, "Move to (300, 200)" )
        , ( UI.Purple, StopAnimation, "Return to Origin" )
        ]
    , -- Animation area with moving box
      el
        [ width (fill |> maximum 500)
        , height (px 400)
        , Background.color Colors.backgroundWhite
        , Border.rounded 12
        , Border.shadow
            { offset = ( 0, 4 )
            , size = 0
            , blur = 8
            , color = Element.rgba 0 0 0 0.1
            }
        , centerX
        , htmlAttribute (Html.Attributes.style "position" "relative")
        , htmlAttribute (Html.Attributes.style "overflow" "hidden")
        ]
        (el
            [ width (px 50)
            , height (px 50)
            , Background.color Colors.primary
            , Border.rounded 8
            , htmlAttribute (Html.Attributes.id "moving-box")
            , htmlAttribute (Html.Attributes.style "position" "absolute")

            -- Apply CSS transition styles directly - browser handles the animation!
            , htmlAttribute (Html.Attributes.style "transform" ("translate(" ++ String.fromFloat position.x ++ "px, " ++ String.fromFloat position.y ++ "px)"))
            , htmlAttribute (Html.Attributes.style "transition" cssStyles)
            ]
            (text "")
        )
    ]
