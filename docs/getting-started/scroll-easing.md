# Scroll Easing

Easing controls how scrolling accelerates and settles across a scroll path.

## Scroll Example

??? example "View Source Code"

    ```elm
    ScrollTo.forDocument
        >> ScrollTo.toElement "features"
        >> ScrollTo.speed 800
        >> ScrollTo.easing QuintOut
        >> ScrollTo.build
    ```

!!! tip "Default pick"
    For most scroll interactions, start with `CubicOut` or `QuintOut`.

--8<-- "docs/getting-started/shared/easing-reference.md"

## Choosing an Easing for Scroll

| Use Case | Recommended Easing | Why |
| -------- | ------------------ | --- |
| Short scroll jumps | `CubicOut` | Smooth but not over-pronounced |
| Long scroll jumps | `QuintOut` | Feels deliberate and controlled |
| Focused destination jumps | `SineOut` / `CubicOut` | Gentle settle without visual noise |
| Playful interactions | `BackOut` / `ElasticOut` / `BounceOut` | Expressive, but should be used sparingly |

!!! note "Practical guidance"
    Reserve `Elastic` and `Bounce` for intentional playful interactions. For navigation-heavy flows, `Out` variants are usually clearer and less distracting.

## Next Steps

Continue with scroll examples.

[Examples →](../scroll-examples.md){ .md-button .md-button--primary }
