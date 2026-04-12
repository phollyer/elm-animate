module Anim.Internal.Engine.Animation.CSS.PlayStates exposing (..)

import Anim.Internal.Engine.Animation.AnimGroups as AnimGroups exposing (AnimGroups)


type PlayStates
    = PlayStates (AnimGroups State)


type State
    = NotStarted
    | Running
    | Paused
    | Reset
    | Complete
    | Cancelled


type alias AnimGroupName =
    String


setAll : State -> PlayStates -> PlayStates
setAll state (PlayStates groups) =
    PlayStates <|
        AnimGroups.map (\_ _ -> state) groups


fromNames : List AnimGroupName -> PlayStates
fromNames names =
    PlayStates <|
        AnimGroups.fromList (List.map (\name -> ( name, NotStarted )) names)


init : PlayStates
init =
    PlayStates AnimGroups.init


add : AnimGroupName -> State -> PlayStates -> PlayStates
add name state (PlayStates groups) =
    PlayStates (AnimGroups.insert name state groups)


allComplete : PlayStates -> Maybe Bool
allComplete ((PlayStates groups) as playStates) =
    if isEmpty playStates then
        Nothing

    else
        Just <|
            (AnimGroups.groups groups
                |> List.all ((==) Complete)
            )


anyRunning : State -> PlayStates -> Maybe Bool
anyRunning state (PlayStates groups) =
    case list (PlayStates groups) of
        [] ->
            Nothing

        _ ->
            Just <|
                (AnimGroups.groups groups
                    |> List.any ((==) state)
                )


isActive : AnimGroupName -> PlayStates -> Maybe Bool
isActive name (PlayStates groups) =
    AnimGroups.get name groups
        |> Maybe.map
            (\playState ->
                case playState of
                    Running ->
                        True

                    Paused ->
                        True

                    _ ->
                        False
            )


isCancelled : AnimGroupName -> PlayStates -> Maybe Bool
isCancelled name (PlayStates groups) =
    AnimGroups.get name groups
        |> Maybe.map ((==) Cancelled)


isComplete : AnimGroupName -> PlayStates -> Maybe Bool
isComplete name (PlayStates groups) =
    AnimGroups.get name groups
        |> Maybe.map ((==) Complete)


isEmpty : PlayStates -> Bool
isEmpty (PlayStates groups) =
    AnimGroups.isEmpty groups


isPaused : AnimGroupName -> PlayStates -> Maybe Bool
isPaused name (PlayStates groups) =
    AnimGroups.get name groups
        |> Maybe.map ((==) Paused)


isRunning : AnimGroupName -> PlayStates -> Maybe Bool
isRunning name (PlayStates groups) =
    AnimGroups.get name groups
        |> Maybe.map ((==) Running)


get : AnimGroupName -> PlayStates -> Maybe State
get name (PlayStates groups) =
    AnimGroups.get name groups


list : PlayStates -> List State
list (PlayStates groups) =
    AnimGroups.groups groups


union : PlayStates -> PlayStates -> PlayStates
union (PlayStates additional) (PlayStates existing) =
    PlayStates (AnimGroups.union additional existing)
