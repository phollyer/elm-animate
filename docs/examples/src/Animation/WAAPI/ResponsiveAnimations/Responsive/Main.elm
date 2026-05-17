port module Animation.WAAPI.ResponsiveAnimations.Responsive.Main exposing (..)

import Anim.Engine.WAAPI as WAAPI exposing (AnimGroupName)
import Anim.Property.Translate as Translate
import Anim.Resize as Resize
import Browser
import Browser.Dom as Dom
import Browser.Events
import Html exposing (Html, div, text)
import Html.Attributes exposing (class, id, style)
import Html.Events exposing (onClick)
import Json.Encode as Encode
import Motion.Easing exposing (Easing(..))
import Process
import Task



-- PORTS


port motionCmd : Encode.Value -> Cmd msg


port motionMsg : (Encode.Value -> msg) -> Sub msg



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { animState : WAAPI.AnimState Msg
    , widthPct : WidthPct
    , trackPx : Float
    , animPlayState : AnimPlayState
    }


type AnimPlayState
    = NotStarted
    | Playing
    | Paused


type WidthPct
    = Narrow
    | Normal
    | Widen


widthPctToFloat : WidthPct -> Float
widthPctToFloat pct =
    case pct of
        Narrow ->
            50

        Normal ->
            75

        Widen ->
            100


topBoxAnim : String
topBoxAnim =
    "topBoxAnim"


bottomBoxAnim : String
bottomBoxAnim =
    "bottomBoxAnim"


{-| One id is enough — both rows share the same inner width because they
sit in the same fixed-width stage. Whichever row we measure tells us the
runway available to both boxes.
-}
trackId : String
trackId =
    "proportional-track"


boxSize : Float
boxSize =
    60


speedPxPerSec : Float
speedPxPerSec =
    200


init : () -> ( Model, Cmd Msg )
init _ =
    ( { animState =
            WAAPI.init motionCmd motionMsg <|
                [ Translate.initX topBoxAnim 0
                , Translate.initX bottomBoxAnim 0
                ]
      , widthPct = Normal
      , trackPx = 0
      , animPlayState = NotStarted
      }
    , Process.sleep 100
        |> Task.perform (\_ -> OnResize)
    )


animate : AnimGroupName -> Float -> WAAPI.AnimBuilder mode -> WAAPI.AnimBuilder mode
animate animGroupName endTarget =
    WAAPI.loopForever
        >> WAAPI.alternate
        >> Translate.for animGroupName
        >> Translate.clampX 0 endTarget
        >> Translate.toX endTarget
        >> Translate.easing Linear
        >> Translate.speed speedPxPerSec
        >> Translate.build


setResizePolicy : AnimGroupName -> WAAPI.AnimBuilder mode -> WAAPI.AnimBuilder mode
setResizePolicy animGroupName =
    if animGroupName == topBoxAnim then
        Translate.resizePolicy animGroupName Resize.proportional

    else
        Translate.resizePolicy animGroupName Resize.retarget



-- UPDATE


type Msg
    = GotAnimUpdate WAAPI.AnimMsg
    | Start
    | Stop
    | SetWidth WidthPct
    | OnResize
    | GotTrack (Result Dom.Error Dom.Element)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotAnimUpdate animMsg ->
            let
                ( newState, _ ) =
                    WAAPI.update animMsg model.animState
            in
            ( { model | animState = newState }, Cmd.none )

        Start ->
            case model.animPlayState of
                NotStarted ->
                    startAnimation model

                Paused ->
                    resumeAnimation model

                Playing ->
                    ( model, Cmd.none )

        Stop ->
            case model.animPlayState of
                Playing ->
                    let
                        ( s1, c1 ) =
                            WAAPI.pause topBoxAnim model.animState

                        ( s2, c2 ) =
                            WAAPI.pause bottomBoxAnim s1
                    in
                    ( { model | animPlayState = Paused, animState = s2 }
                    , Cmd.batch [ c1, c2 ]
                    )

                _ ->
                    ( model, Cmd.none )

        SetWidth pct ->
            ( { model | widthPct = pct }
              -- mimic Browser.onResize event by setting the new width and then dispatching the OnResize msg after a short delay.
            , Process.sleep 100
                |> Task.perform (\_ -> OnResize)
            )

        OnResize ->
            ( model
            , Task.attempt GotTrack <|
                Dom.getElement trackId
            )

        GotTrack (Ok element) ->
            handleResize { model | trackPx = element.element.width }

        GotTrack (Err _) ->
            ( model, Cmd.none )


startAnimation : Model -> ( Model, Cmd Msg )
startAnimation model =
    let
        target =
            model.trackPx - boxSize

        ( s1, c1 ) =
            WAAPI.animate model.animState (setResizePolicy topBoxAnim >> animate topBoxAnim target)

        ( s2, c2 ) =
            WAAPI.animate s1 (setResizePolicy bottomBoxAnim >> animate bottomBoxAnim target)
    in
    ( { model | animPlayState = Playing, animState = s2 }
    , Cmd.batch [ c1, c2 ]
    )


resumeAnimation : Model -> ( Model, Cmd Msg )
resumeAnimation model =
    let
        ( s1, c1 ) =
            WAAPI.resume topBoxAnim model.animState

        ( s2, c2 ) =
            WAAPI.resume bottomBoxAnim s1
    in
    ( { model | animPlayState = Playing, animState = s2 }
    , Cmd.batch [ c1, c2 ]
    )


{-| The two rows demonstrate the two `WAAPI.onResize` strategies.

  - `topBoxAnim` uses `Proportional` - the box's progress along the
    track is preserved, so the rhythm of the animation continues to feel
    natural even as the track changes width.
      - `bottomBoxAnim` uses `Retarget` - the box keeps its current pixel
        position, but the leg endpoint follows the new bounds so the
        animation remains edge-to-edge as the track grows or shrinks.

-}
handleResize : Model -> ( Model, Cmd Msg )
handleResize model =
    case model.animPlayState of
        NotStarted ->
            ( model, Cmd.none )

        _ ->
            let
                bounds =
                    { x = Just { min = 0, max = model.trackPx - boxSize }
                    , y = Nothing
                    , z = Nothing
                    }

                ( newAnimState, cmd ) =
                    WAAPI.onResize model.animState <|
                        Translate.bounds topBoxAnim bounds
                            >> Translate.bounds bottomBoxAnim bounds
            in
            ( { model | animState = newAnimState }
            , cmd
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ WAAPI.subscriptions GotAnimUpdate model.animState
        , Browser.Events.onResize (\_ _ -> OnResize)
        ]



-- VIEW


view : Model -> Html Msg
view model =
    let
        ctrlBtn label cls msg =
            Html.button
                [ onClick msg
                , class ("ui-action-button " ++ cls)
                , style "background-color" "blue"
                , style "color" "white"
                ]
                [ text label ]
    in
    div
        [ style "text-align" "center" ]
        [ div
            [ class "example-controls"
            , style "margin-top" "5px"
            ]
            [ ctrlBtn "Start" "success" Start
            , ctrlBtn "Stop" "warning" Stop
            ]
        , div
            [ class "example-controls"
            , style "margin-top" "5px"
            ]
            [ ctrlBtn "Narrow" "" (SetWidth Narrow)
            , ctrlBtn "Normal" "" (SetWidth Normal)
            , ctrlBtn "Widen" "" (SetWidth Widen)
            ]
        , div
            [ class "responsive-stage"
            , style "width" (String.fromFloat (widthPctToFloat model.widthPct) ++ "%")
            ]
            [ trackRow "Proportional" trackId topBoxAnim proportionalColor model
            , trackRow "Retarget" "" bottomBoxAnim clampColor model
            ]
        ]


trackRow : String -> String -> String -> String -> Model -> Html Msg
trackRow label rowId group color model =
    div [ class "responsive-row" ]
        [ div [ class "responsive-row__label" ] [ text label ]
        , div
            ([ class "responsive-row__track"
             , style "background-color" "#f9de10"
             ]
                ++ (if String.isEmpty rowId then
                        []

                    else
                        [ id rowId ]
                   )
            )
            [ div
                (WAAPI.attributes group model.animState
                    ++ [ style "width" (String.fromFloat boxSize ++ "px")
                       , style "height" (String.fromFloat boxSize ++ "px")
                       , style "background-color" color
                       , style "position" "absolute"
                       , style "top" "0"
                       , style "left" "0"
                       , style "border-radius" "8px"
                       ]
                )
                []
            ]
        ]


proportionalColor : String
proportionalColor =
    "#28a745"


clampColor : String
clampColor =
    "#dc3545"
