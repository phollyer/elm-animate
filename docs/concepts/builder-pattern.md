# Builder Pattern

Elm Animate uses a fluent builder pattern for defining animations. This approach provides a consistent, composable API across all engines and properties.

## Basic Structure

Every animation follows this pattern:

```elm
animationFunction : AnimBuilder -> AnimBuilder
animationFunction builder =
    builder
        |> Property.for "element-id"    -- Target element
        |> Property.from startValue     -- Starting value (optional)
        |> Property.to endValue         -- Ending value
        |> Property.duration 500        -- Timing
        |> Property.build               -- Finalize
```

## Why Builders?

### 1. Composability

Small animations combine into larger ones:

```elm
fadeIn : AnimBuilder -> AnimBuilder
fadeIn builder =
    builder
        |> Opacity.for "box"
        |> Opacity.from 0
        |> Opacity.to 1
        |> Opacity.build

slideUp : AnimBuilder -> AnimBuilder
slideUp builder =
    builder
        |> Translate.for "box"
        |> Translate.fromY 50
        |> Translate.toY 0
        |> Translate.build

-- Compose them
enterAnimation : AnimBuilder -> AnimBuilder
enterAnimation =
    fadeIn >> slideUp
```

### 2. Reusability

Define once, use everywhere:

```elm
-- Define a standard fade-in transition
standardFadeIn : String -> AnimBuilder -> AnimBuilder
standardFadeIn elementId builder =
    builder
        |> Opacity.for elementId
        |> Opacity.from 0
        |> Opacity.to 1
        |> Opacity.duration 300
        |> Opacity.easing QuintOut
        |> Opacity.build

-- Reuse for different elements
entranceAnimation : AnimBuilder -> AnimBuilder
entranceAnimation builder =
    builder
        |> standardFadeIn "card-1"
        |> standardFadeIn "card-2"
        |> standardFadeIn "card-3"
```

### 3. Engine Independence

The same animation works with any engine:

```elm
myAnimation : AnimBuilder -> AnimBuilder
myAnimation builder =
    builder
        |> Translate.for "box"
        |> Translate.toXY 100 200
        |> Translate.build

-- Works with CSS
CSS.init |> CSS.builder |> myAnimation |> CSS.animate

-- Works with Sub
Sub.init |> Sub.builder |> myAnimation |> Sub.animate

-- Works with WAAPI
WAAPI.init |> WAAPI.builder |> myAnimation |> WAAPI.animate
```

## Global Settings

Set defaults that apply to all properties:

```elm
CSS.init
    |> CSS.builder
    |> CSS.duration 500           -- Default duration
    |> CSS.easing QuintOut        -- Default easing
    |> myAnimation                -- Properties can override
    |> CSS.animate
```

Properties can override global settings:

```elm
myAnimation builder =
    builder
        |> Opacity.for "box"
        |> Opacity.duration 1000  -- Overrides global 500ms
        |> Opacity.build
```

## Multiple Elements

Animate multiple elements in a single animation:

```elm
multiElementAnimation : AnimBuilder -> AnimBuilder
multiElementAnimation builder =
    builder
        -- First element
        |> Translate.for "box-1"
        |> Translate.toX 100
        |> Translate.build
        -- Second element
        |> Translate.for "box-2"
        |> Translate.toX 200
        |> Translate.build
        -- Third element
        |> Translate.for "box-3"
        |> Translate.toX 300
        |> Translate.build
```

## Multiple Properties

Animate multiple properties on the same element:

```elm
complexAnimation : AnimBuilder -> AnimBuilder
complexAnimation builder =
    builder
        |> Translate.for "box"
        |> Translate.toXY 100 200
        |> Translate.build
        |> Rotate.for "box"
        |> Rotate.to 45
        |> Rotate.build
        |> Scale.for "box"
        |> Scale.to 1.5
        |> Scale.build
```

## Conditional Animations

Build animations based on state:

```elm
animation : Model -> AnimBuilder -> AnimBuilder
animation model builder =
    let
        base =
            builder
                |> Translate.for "box"
                |> Translate.duration 500
    in
    if model.isExpanded then
        base
            |> Translate.toY 0
            |> Translate.build
    else
        base
            |> Translate.toY -100
            |> Translate.build
```

## Best Practices

!!! tip "Keep animations small and focused"
    Create small, single-purpose animation functions and compose them together.

!!! tip "Use meaningful names"
    Name your animation functions based on what they do: `fadeIn`, `slideLeft`, `bounceOnHover`.

!!! tip "Extract common patterns"
    If you use the same duration/easing combination often, create a helper function.

```elm
-- Common timing helper
withStandardTiming : AnimBuilder -> AnimBuilder
withStandardTiming builder =
    builder
        |> CSS.duration 300
        |> CSS.easing QuintOut

-- Use it with any animation
myAnimation : AnimBuilder -> AnimBuilder
myAnimation builder =
    builder
        |> withStandardTiming
        |> Translate.for "box"
        |> Translate.toX 100
        |> Translate.build
        |> Opacity.for "box"
        |> Opacity.to 1
        |> Opacity.build
```
