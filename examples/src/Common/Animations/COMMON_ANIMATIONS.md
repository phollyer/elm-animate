# Common Animations

## Overview

The animations in `Common.Animations.*` modules work across **all animation engines** (CSS Transitions, CSS Keyframes, Sub, and WAAPI).

This demonstrates the **"easy migration"** feature of elm-animate - the same animation logic works identically across all engines!

## Architecture

### Common Animation Modules

Located in `src/Common/Animations/`:

- **Position.elm** - moveToXY, moveLeft, moveRight, moveUp, moveDown, returnToOrigin
- **Rotate.elm** - rotate45, rotate90, rotate180, rotateLeft, rotateRight, resetRotate
- **Scale.elm** - scaleUp, scaleDown, scaleReset, scaleWide, scaleTall
- **Opacity.elm** - fadeIn, fadeOut, fadeToggle, fadeToHalf, fadeToQuarter
- **Color.elm** - changeToBlue, changeToGreen, changeToOrange, changeToRed, changeToPurple, resetColor
- **Size.elm** - sizeReset, sizeWide, sizeTall, sizeSquare, sizeLarge

### Function Signature Pattern

All animation functions follow this pattern:

```elm
animationName : String -> Builder.AnimBuilder -> Builder.AnimBuilder
animationName elementId builder =
    builder
        |> Property.for elementId
        |> Property.toValue value
        |> Property.duration ms
        |> Property.easing easingFunction
        |> Property.build
```

The functions:
1. Take an element ID string
2. Take an `AnimBuilder` (engine-agnostic)
3. Return an `AnimBuilder` (for chaining or passing to `animate`)

## Usage Example

### Before (Engine-Specific)

```elm
-- CSS Keyframes version
update msg model =
    case msg of
        MoveLeft ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> Position.for "box"
                        |> Position.toX 0
                        |> Position.duration 1000
                        |> Position.easing Easing.BounceOut
                        |> Position.build
                        |> CSS.animate
              }
            , Cmd.none
            )
```

### After (Engine-Agnostic)

```elm
import Common.Animations.Position as Animations

update msg model =
    case msg of
        MoveLeft ->
            ( { model
                | animations =
                    model.animations
                        |> CSS.builder
                        |> Animations.moveLeft "box"
                        |> CSS.animate
              }
            , Cmd.none
            )
```

The **same** animation function works with all engines:

```elm
-- CSS Keyframes
CSS.builder |> Animations.moveLeft "box" |> CSS.animate

-- CSS Transitions  
CSS.builder |> Animations.moveLeft "box" |> CSS.animate

-- Sub
Sub.builder |> Animations.moveLeft "box" |> Sub.animate

-- WAAPI
WAAPI.builder |> Animations.moveLeft "box" |> WAAPI.animate
```

## Benefits

1. **Consistency** - All engines use identical animations
2. **Maintainability** - Update animation once, affects all engines
3. **Easy Migration** - Switch engines by changing only the builder/animate calls
4. **Readability** - Examples focus on UI logic, not animation details
5. **Reusability** - Common animations available across all examples

## Migration Status

### ✅ Completed
- Common.Animations.Position (all functions)
- Common.Animations.Rotate (all functions)
- Common.Animations.Scale (all functions)
- Common.Animations.Opacity (all functions)
- Common.Animations.Color (all functions)
- Common.Animations.Size (all functions)
- ElmUI.CSS.Keyframes.Position.Main (refactored to use common animations)

### 🔄 To Migrate

All remaining position/rotate/scale/opacity/color/size examples across:
- ElmUI/CSS/Transitions/*
- ElmUI/CSS/Keyframes/*
- ElmUI/Sub/*
- ElmUI/WAAPI/*
- HTML/* (if applicable)

## Next Steps

1. Update all Position examples to use `Common.Animations.Position`
2. Update all Rotate examples to use `Common.Animations.Rotate`
3. Update all Scale examples to use `Common.Animations.Scale`
4. Update all Opacity examples to use `Common.Animations.Opacity`
5. Update all Color examples to use `Common.Animations.Color`
6. Update all Size examples to use `Common.Animations.Size`
7. Create additional common animation modules as needed (Mixed, Choreography patterns)
8. Update build scripts to compile all examples
9. Test all examples to ensure consistent behavior

## Notes

- If example types have slightly different animations, one set has been chosen for consistency
- Animations can be customized later if engine-specific differences are needed
- Mixed property animations (combining multiple properties) may need special handling
- Choreography examples may need additional common pattern modules
