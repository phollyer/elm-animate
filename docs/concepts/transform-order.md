# Transform Ordering

The Keyframes, Sub, and WAAPI engines expose a `transformOrder` function which takes a `TransformOrder` type with 3 variants:

- Translate
- Rotate
- Scale

Use these to change the transform order that is applied to your animations.

## Default Order

Elm Animate uses **Translate → Rotate → Scale** as the default order, unless otherwise specified with the `transformOrder` function.

All transforms are applied simultaneously - the order controls how they compose mathematically. This default works well for most animations because:

- Translation is unaffected by rotation or scale
- Rotation happens around the translated position, not the origin
- Scaling is relative to the already-rotated axes

Changing the order, changes the result - as can be seen in the following example.

## Example

There are 6 boxes in the center, each one is triggered with the **same** animation, the only difference is the transform order.

=== "Keyframes"

    <iframe src="../../examples/src/Engines/Keyframes/TransformOrder/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="../../examples/src/Engines/Sub/TransformOrder/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="../../examples/src/Engines/WAAPI/TransformOrder/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

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

Transforms compose in the order you specify - all happening at the same time. The order determines how they interact, not when they happen. With `[ Translate, Rotate ]`:

- Translation is independent of rotation
- The element ends up at the translated position, rotated in place

With `[ Rotate, Translate ]`:

- Rotation changes the element's local axes
- Translation moves along the **rotated** axes, not the original ones

Same values, different order, different result.


## Visual Comparison

Consider an element at (0, 0) animated to translate (100, 0) and rotate 45° (around the Z axis):

**Translate → Rotate (default):**
Translation is unaffected by the rotation, so the element ends up at (100, 0), rotated 45° in place.

**Rotate → Translate:**  
Rotation applies before translation, so the 100px movement follows the rotated axes (diagonally down-right) - the element ends up at approximately (70.7, 70.7).

The end rotation is the same, but the final position differs significantly.




## Tips

- **Card flip:** Use default order - translation is unaffected by rotation, so the element flips at its destination
- **Pulsing button:** Use `[ Scale ]` alone - no ordering concerns
- **Scale at origin:** Use `[ Scale, Translate ]` - scaling applies relative to the origin, not the translated position

When in doubt, stick with the default. Only specify custom ordering when the visual result requires it.

## Next Steps

Dive into 3D animations.

[3D Animations →](3d.md){ .md-button .md-button--primary }
