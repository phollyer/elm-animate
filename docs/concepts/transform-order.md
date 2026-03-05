# Transform Ordering

All Engines expose a `TransformOrder` type with 3 variants:

- Translate
- Rotate
- Scale

## Default Order

Elm Animate uses **Translate → Rotate → Scale** as the default order, which is the order the transforms are applied by the standard `animate` and `fireAndForget` functions.

This order works well for most animations because:

- Elements move to their destination first
- Rotation happens around the element's center at that position
- Scaling applies last, relative to the rotated element


## Usage

All engines provide transform ordering counterparts to their `animate` and `fireAndForget` functions via `animateOrder` and `fireAndForgetOrder`. Both take a list of `TransformOrder`s, with duplicates being removed (first in wins):

??? example "View Source Code"

    === "Transitions"

        ```elm
        import Anim.Engine.CSS.Transitions as Transitions exposing (TransformOrder(..))

        Transitions.animateOrder [ Rotate, Translate ] model.animState myAnimation

        Transitions.fireAndForgetOrder [ Scale, Rotate, Translate ] myAnimation
        ```

    === "Keyframes"

        ```elm
        import Anim.Engine.CSS.Keyframes as Keyframes exposing (TransformOrder(..))

        Keyframes.animateOrder [ Rotate, Translate ] model.animState myAnimation

        Keyframes.fireAndForgetOrder [ Scale, Rotate, Translate ] myAnimation
        ```

    === "Sub"

        ```elm
        import Anim.Engine.Sub as Sub exposing (TransformOrder(..))

        Sub.animateOrder [ Rotate, Translate ] model.animState myAnimation
        ```

    === "WAAPI"

        ```elm
        import Anim.Engine.WAAPI as WAAPI exposing (TransformOrder(..))

        WAAPI.animateOrder [ Rotate, Translate ] model.animState myAnimation

        WAAPI.fireAndForgetOrder [ Scale, Rotate, Translate ] waapiCommand myAnimation
        ```

### Autofill

The Engine will autofill any missing variants from the list in the default order; `Translate`, `Rotate`, `Scale`.

#### Examples

- `[]` -> `[Translate, Rotate, Scale]`
- `[Rotate]` -> `[Rotate, Translate, Scale]`
- `[Scale]` -> `[Scale, Translate, Rotate]`
- `[Scale, Translate]` -> `[Scale, Translate, Rotate]`


## Why Order Matters

Transform order determines how translate, rotate, and scale combine when rendering. The same values with different orders produce different visual results.

Transforms are applied in the order you specify. With `[ Translate, Rotate ]`:

1. Element translates to a new position
2. Element rotates in place at that position

With `[ Rotate, Translate ]`:

1. Element rotates, changing its local axes  
2. Element translates along its **rotated** axes

Same values, different order, different result.


## Visual Comparison

Consider an element at (0, 0) animated to translate (100, 0) and rotate 45° (around the Z axis):

**Translate → Rotate (default):**
The element moves 100px right, then rotates 45° at that position - finishing at (100, 0).

**Rotate → Translate:**  
The element rotates 45°, then moves 100px along the rotated x-axis (diagonally down-right) - finishing at approximately (70.7, 70.7).

The end rotation is the same, but the final position differs significantly.



## Tips

- **Card flip:** Use default order - element moves to position, then flips
- **Pulsing button:** Use `[ Scale ]` alone - no ordering concerns
- **Scale at origin:** Use `[ Scale, Translate ]` - scales before repositioning

When in doubt, stick with the default. Only specify custom ordering when the visual result requires it.

## Next Steps

Dive into 3D animations.

[3D Animations →](3d.md){ .md-button .md-button--primary }
