module Shared.Easing.Keyframes exposing
    ( defaultKeyframeCount
    , generateKeyframes
    )

{-| Keyframe sample generation for easings the WAAPI engine cannot
represent with a single CSS easing string.

The Web Animations API's `easing` field accepts CSS easing keywords or a
`cubic-bezier(...)`. Bounce and Elastic curves cannot be approximated by
a single cubic bezier, so the WAAPI engine falls back to a pre-computed
`easingKeyframes` array. The Keyframe engine samples its `@keyframes`
stops at the same density to keep the two engines visually consistent.

-}

import Ease as E
import Motion.Easing as Easing exposing (Easing(..))



-- ============================================================
-- KEYFRAME COUNT
-- ============================================================


{-| Default number of keyframe samples used by both the WAAPI engine
(per-property `easingKeyframes` arrays) and the Keyframe engine
(`@keyframes` stop count).

This describes curve shape, not playback frame rate — the browser still
animates at its native refresh rate and interpolates linearly between
the samples.

-}
defaultKeyframeCount : Int
defaultKeyframeCount =
    60



-- ============================================================
-- KEYFRAME GENERATION
-- ============================================================


{-| Generate keyframe progress values for an `Easing` over a given duration.

Returns a list of progress values (0.0 to 1.0) sampled densely enough to
reproduce complex easings via linear interpolation between samples.

For non-complex easings the WAAPI encoder routes through CSS `easing`
strings instead of calling this function; a defensive 2-point linear
ramp is returned if anything else falls through.

-}
generateKeyframes : Easing -> Float -> List Float
generateKeyframes easing _ =
    case easing of
        BounceIn ->
            uniformSamples E.inBounce defaultKeyframeCount

        BounceOut ->
            uniformSamples E.outBounce defaultKeyframeCount

        BounceInOut ->
            uniformSamples E.inOutBounce defaultKeyframeCount

        ElasticIn ->
            uniformSamples E.inElastic defaultKeyframeCount

        ElasticOut ->
            uniformSamples E.outElastic defaultKeyframeCount

        ElasticInOut ->
            uniformSamples E.inOutElastic defaultKeyframeCount

        _ ->
            [ 0.0, 1.0 ]


{-| Sample a `0..1 -> Float` function at `n` evenly spaced points across
[0, 1] (inclusive on both ends).
-}
uniformSamples : (Float -> Float) -> Int -> List Float
uniformSamples f n =
    if n <= 1 then
        if n == 1 then
            [ f 0 ]

        else
            []

    else
        List.range 0 (n - 1)
            |> List.map (\i -> f (toFloat i / toFloat (n - 1)))
