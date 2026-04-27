# Transform Ordering

The Keyframe, Sub, and WAAPI engines expose a `transformOrder` function which takes a list of `TransformProperty`s:

- Translate
- Rotate
- Skew
- Scale

Use these to change the transform order that is applied to your animations.

## Default Order

Elm Animate uses **Translate → Rotate → Skew → Scale** as the default order when no order is specified with the `transformOrder` function.

All transforms are applied simultaneously - the order controls how they compose mathematically. This default works well for most animations because:

- Translation is unaffected by rotation or scale
- Rotation happens around the translated position, not the origin
- Skew distorts axes relative to the already-rotated orientation, keeping the visual shear consistent with the element's current facing
- Scaling is relative to the already-rotated axes

For most animations, the default transform order works well and you won't need to change it. However, certain scenarios benefit from a different order — for example, a game character that rotates to face a direction and then moves forward (rotate → translate), so the movement follows the character's facing direction rather than the world axes.

So, changing the order, changes the result - as can be seen in the following example.

## Example

There are 6 boxes in the center, each one is triggered with the **same** animation, the only difference is the transform order.

=== "Keyframe"

    <iframe src="../../../../examples/src/Animation/Keyframe/TransformOrder/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "Sub"

    <iframe src="../../../../examples/src/Animation/Sub/TransformOrder/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

=== "WAAPI"

    <iframe src="../../../../examples/src/Animation/WAAPI/TransformOrder/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    === "Keyframe"

        ```elm
        --8<-- "docs/examples/src/Animation/Keyframe/TransformOrder/Main.elm"
        ```

    === "Sub"

        ```elm
        --8<-- "docs/examples/src/Animation/Sub/TransformOrder/Main.elm"
        ```

    === "WAAPI"

        ```elm
        --8<-- "docs/examples/src/Animation/WAAPI/TransformOrder/Main.elm"
        ```

## Usage

??? example "View Source Code"

    === "Keyframe"

        ```elm
        import Anim.Engine.CSS.Keyframe as Keyframe exposing (TransformProperty(..))

        Keyframe.animate model.animState <|
            Keyframe.transformOrder [ Rotate, Translate, Scale ]
                >> ... -- animations
        ```

    === "Sub"

        ```elm
        import Anim.Engine.Sub as Sub exposing (TransformProperty(..))

        Sub.animate model.animState <|
            Sub.transformOrder [ Rotate, Translate, Scale ]
                >> ... -- animations
        ```

    === "WAAPI"

        ```elm
        import Anim.Engine.WAAPI as WAAPI exposing (TransformProperty(..))

        WAAPI.animate model.animState <|
            WAAPI.transformOrder [ Rotate, Translate, Scale ]
                >> ... -- animations
        ```

### Autofill

The Engine will autofill any missing variants from the list in the default order; `Translate`, `Rotate`, `Skew`, `Scale`.

#### Examples

- `[]` -> `[Translate, Rotate, Skew, Scale]`
- `[Rotate]` -> `[Rotate, Translate, Skew, Scale]`
- `[Scale]` -> `[Scale, Translate, Rotate, Skew]`
- `[Scale, Translate]` -> `[Scale, Translate, Rotate, Skew]`


## Next Steps

Dive into 3D animations.

[3D Animations →](3d.md){ .md-button .md-button--primary }
