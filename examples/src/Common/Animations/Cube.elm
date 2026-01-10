module Common.Animations.Cube exposing
    ( setCubeTransform
    )

{-| Common 3D Cube animations that work across all animation engines.

This function provides the common pattern for updating a 3D cube's position and rotation
simultaneously, which is needed for proper 3D cube manipulation with immediate updates.

FEATURES:
- ✅ Combined Position Z and Rotation XYZ updates
- ✅ Instant application (duration 0) for real-time cube manipulation
- ✅ Consistent element targeting

USAGE:
- **setCubeTransform**: Updates both position Z and rotation XYZ values instantly

-}

import Anim.Internal.Builder as Builder
import Anim.Property.Position as Position
import Anim.Property.Rotate as Rotate


{-| Set both the Z position and XYZ rotation for a 3D cube element
This is used for real-time cube manipulation with sliders or controls
-}
setCubeTransform : String -> Float -> Float -> Float -> Float -> Builder.AnimBuilder -> Builder.AnimBuilder
setCubeTransform elementId zPos rotateX rotateY rotateZ builder =
    builder
        |> Position.for elementId
        |> Position.duration 0
        |> Position.toZ zPos
        |> Position.build
        |> Rotate.for elementId
        |> Rotate.duration 0
        |> Rotate.toXYZ rotateX rotateY rotateZ
        |> Rotate.build