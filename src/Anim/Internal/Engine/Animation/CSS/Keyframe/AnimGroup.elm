module Anim.Internal.Engine.Animation.CSS.Keyframe.AnimGroup exposing
    ( AnimGroup
    , addStyle
    , clearAnimation
    , getAnimation
    , getIterationCount
    , getRestartCounter
    , getStyles
    , incrementIterationCount
    , init
    , isActive
    , isCancelled
    , isComplete
    , isPaused
    , isRunning
    , mergeStyles
    , setAnimation
    , setIterationCount
    , setPlayState
    , setRestartCounter
    , setStyles
    )

import Anim.Internal.Engine.Animation.CSS.Keyframe.Animation exposing (Animation)
import Anim.Internal.Engine.Animation.CSS.Styles as Styles exposing (Styles)
import Anim.Internal.Engine.Animation.PlayState as PlayState exposing (PlayState)


type AnimGroup
    = AnimGroup
        { styles : Styles
        , playState : PlayState
        , restartCounter : Int
        , iterationCount : Int
        , maybeAnimation : Maybe Animation
        }


init : AnimGroup
init =
    AnimGroup
        { styles = Styles.empty
        , playState = PlayState.NotStarted
        , restartCounter = 0
        , iterationCount = 0
        , maybeAnimation = Nothing
        }



{- ******** ANIMATION ******** -}


clearAnimation : AnimGroup -> AnimGroup
clearAnimation (AnimGroup animGroup) =
    AnimGroup { animGroup | maybeAnimation = Nothing }


getAnimation : AnimGroup -> Maybe Animation
getAnimation (AnimGroup animGroup) =
    animGroup.maybeAnimation


setAnimation : Animation -> AnimGroup -> AnimGroup
setAnimation animation (AnimGroup animGroup) =
    AnimGroup { animGroup | maybeAnimation = Just animation }



{- ******** STYLES ******** -}


addStyle : String -> String -> AnimGroup -> AnimGroup
addStyle key value (AnimGroup animGroup) =
    AnimGroup
        { animGroup
            | styles =
                Styles.insert key value animGroup.styles
        }


getStyles : AnimGroup -> Styles
getStyles (AnimGroup animGroup) =
    animGroup.styles


mergeStyles : AnimGroup -> AnimGroup -> AnimGroup
mergeStyles (AnimGroup new) (AnimGroup existing) =
    AnimGroup { new | styles = Styles.merge new.styles existing.styles }


setStyles : Styles -> AnimGroup -> AnimGroup
setStyles styles (AnimGroup animGroup) =
    AnimGroup { animGroup | styles = styles }



{- ******** RESTART COUNTER ******** -}


getRestartCounter : AnimGroup -> Int
getRestartCounter (AnimGroup animGroup) =
    animGroup.restartCounter


setRestartCounter : Int -> AnimGroup -> AnimGroup
setRestartCounter restartCounter (AnimGroup animGroup) =
    AnimGroup { animGroup | restartCounter = restartCounter }



{- ******** ITERATION COUNT ******** -}


getIterationCount : AnimGroup -> Int
getIterationCount (AnimGroup animGroup) =
    animGroup.iterationCount


incrementIterationCount : AnimGroup -> AnimGroup
incrementIterationCount (AnimGroup animGroup) =
    AnimGroup { animGroup | iterationCount = animGroup.iterationCount + 1 }


setIterationCount : Int -> AnimGroup -> AnimGroup
setIterationCount iterationCount (AnimGroup animGroup) =
    AnimGroup { animGroup | iterationCount = iterationCount }



{- ******** PLAY STATE ******** -}


setPlayState : PlayState -> AnimGroup -> AnimGroup
setPlayState state (AnimGroup animGroup) =
    AnimGroup { animGroup | playState = state }


isActive : AnimGroup -> Bool
isActive (AnimGroup animGroup) =
    PlayState.isActive animGroup.playState


isCancelled : AnimGroup -> Bool
isCancelled (AnimGroup animGroup) =
    PlayState.isCancelled animGroup.playState


isComplete : AnimGroup -> Bool
isComplete (AnimGroup animGroup) =
    PlayState.isComplete animGroup.playState


isPaused : AnimGroup -> Bool
isPaused (AnimGroup animGroup) =
    PlayState.isPaused animGroup.playState


isRunning : AnimGroup -> Bool
isRunning (AnimGroup animGroup) =
    PlayState.isRunning animGroup.playState
