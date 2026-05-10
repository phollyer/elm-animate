module Motion.Internal.Spring exposing (Spring(..), unwrap)

{-| Internal definition of the opaque `Motion.Spring.Spring` type.

Lives in its own internal module so engine code can `unwrap` a
`Spring` to access the underlying `Shared.Spring.SpringConfig`
without exposing the constructor through the public `Motion.Spring`
module.

-}

import Shared.Spring


{-| Opaque wrapper around the solver's `SpringConfig`. The constructor
is intentionally inaccessible from `Motion.Spring`'s public surface so
all `Spring` values come from the validated presets or `custom`.
-}
type Spring
    = Spring Shared.Spring.SpringConfig


{-| Extract the underlying `SpringConfig` for use by the solver and
engine code. Internal-only.
-}
unwrap : Spring -> Shared.Spring.SpringConfig
unwrap (Spring config) =
    config
