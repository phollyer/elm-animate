# Transform Ordering

The Keyframes, Sub, and WAAPI engines expose a `TransformOrder` type with 3 variants:

- Translate
- Rotate
- Scale

## Default Order

Elm Animate uses **Translate → Rotate → Scale** as the default order, which is the order the transforms are applied by the standard `animate` function.

This order works well for most animations because:

- Elements move to their destination first
- Rotation happens around the element's center at that position
- Scaling applies last, relative to the rotated element

## Example

All 6 permutations are shown layered on top of each other. Trigger individual permutations or all at once to see how transform order affects the final position.

=== "Keyframes"

    <iframe src="../../examples/src/Engines/Keyframes/TransformOrder/index.html" style="width: 100%; height: 570px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="../../examples/src/Engines/Sub/TransformOrder/index.html" style="width: 100%; height: 570px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="../../examples/src/Engines/WAAPI/TransformOrder/index.html" style="width: 100%; height: 570px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    === "Keyframes"

        ```elm
        --8<-- "docs/examples/src/Engines/Keyframes/TransformOrder/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Engines/Sub/TransformOrder/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Engines/WAAPI/TransformOrder/Main.elm"
        ```

## Usage

All engines (except Transitions) provide a `transformOrder` function that sets the transform order on the `AnimState`. Once set, the order persists across all subsequent animations. It takes a list of `TransformOrder`s, with duplicates being removed (first in wins):

!!! note "Transitions engine"
    The Transitions engine uses individual CSS `translate` and `scale` properties for per-property independent timing and easing. This means the browser enforces a fixed order of **translate → scale → rotate**, and `transformOrder` is not available. See [Transitions — Interrupting Animations](../engines/transitions.md#interrupting-animations) for details.

??? example "View Source Code"

    === "Keyframes"

        ```elm
        import Anim.Engine.CSS.Keyframes as Keyframes exposing (TransformOrder(..))

        model.animState
            |> Keyframes.transformOrder [ Rotate, Translate ]
            |> Keyframes.animate myAnimation
        ```

    === "Sub"

        ```elm
        import Anim.Engine.Sub as Sub exposing (TransformOrder(..))

        model.animState
            |> Sub.transformOrder [ Rotate, Translate ]
            |> Sub.animate myAnimation
        ```

    === "WAAPI"

        ```elm
        import Anim.Engine.WAAPI as WAAPI exposing (TransformOrder(..))

        model.animState
            |> WAAPI.transformOrder [ Rotate, Translate ]
            |> WAAPI.animate myAnimation
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
