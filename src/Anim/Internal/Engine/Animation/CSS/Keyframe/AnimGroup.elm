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
    , mergeStyles
    , setAnimation
    , setIterationCount
    , setRestartCounter
    , setStyles
    )

import Anim.Internal.Engine.Animation.CSS.Keyframe.Animation exposing (Animation)
import Anim.Internal.Engine.Animation.CSS.Styles as Styles exposing (Styles)


type AnimGroup
    = AnimGroup
        { styles : Styles
        , restartCounter : Int
        , iterationCount : Int
        , maybeAnimation : Maybe Animation
        }


init : AnimGroup
init =
    AnimGroup
        { styles = Styles.empty
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
mergeStyles (AnimGroup animGroup1) (AnimGroup animGroup2) =
    AnimGroup { animGroup2 | styles = Styles.merge animGroup2.styles animGroup1.styles }


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
