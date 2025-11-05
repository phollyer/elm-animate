#!/bin/bash

# Fix common Sub example patterns
for example in Scale Rotation Color Choreography Mixed; do
    echo "Fixing $example example..."
    
    file="/Users/code/Elm-Lib/elm/packages/smooth-move/examples/src/ElmUI/Sub/$example/Main.elm"
    
    # Fix Msg type - add AnimationFrame Float and remove AnimationComplete
    sed -i '' '/AnimationFrame Float/!s/AnimationComplete/AnimationFrame Float/' "$file"
    
    # Fix subscriptions function
    sed -i '' 's/subscriptions : Model -> Sub Msg/subscriptions : Model -> Sub Msg/' "$file"
    sed -i '' '/subscriptions.*model =/{N;s/Anim\.Sub\.subscriptions AnimationFrame model\.animations/Anim.Sub.subscriptions AnimationFrame model.animations/;}' "$file"
    
    # Remove CSS-specific imports
    sed -i '' 's/, transitionStyles, onTransitionEnd//' "$file"
    sed -i '' 's/, transitionStyles//' "$file"  
    sed -i '' 's/, onTransitionEnd//' "$file"
    
    # Add step import if missing
    sed -i '' 's/\(Anim\.Sub exposing (Model, init,\)/\1 step, subscriptions,/' "$file"
    
    # Fix model type references
    sed -i '' 's/{ model | isAnimating = False }/model/' "$file"
    
    echo "Basic fixes applied to $example"
done

echo "Manual fixes still needed for each example:"
echo "1. Update Msg type to include AnimationFrame Float"  
echo "2. Add AnimationFrame handler in update function"
echo "3. Remove CSS transition styles from view"
echo "4. Update subscriptions function"