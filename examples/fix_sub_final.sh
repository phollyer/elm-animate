#!/bin/bash

# Apply the complete Sub example conversion pattern

for example in Rotation Color Choreography Mixed; do
    echo "Fixing $example example..."
    
    file="/Users/code/Elm-Lib/elm/packages/smooth-move/examples/src/ElmUI/Sub/$example/Main.elm"
    
    # Fix AnimationFrame handler
    sed -i '' 's/AnimationFrame Float ->/AnimationFrame deltaTime ->/' "$file"
    sed -i '' '/AnimationFrame deltaTime ->/{N;s/( model, Cmd.none )/( { model | animations = step deltaTime model.animations }, Cmd.none )/;}' "$file"
    
    # Fix subscriptions parameter
    sed -i '' 's/subscriptions _ =/subscriptions model =/' "$file"
    
    # Remove CSS transition styles
    sed -i '' '/htmlAttribute (Html.Attributes.style "transition"/,/htmlAttribute (onTransitionEnd/d' "$file"
    sed -i '' 's/++ \[ htmlAttribute (Html.Attributes.style "transition"//' "$file"
    sed -i '' '/onTransitionEnd/d' "$file"
    sed -i '' '/transitionStyles/d' "$file"
    
    # Fix closing parentheses after removing transition styles
    sed -i '' 's/        ])/        )/' "$file"
    
    echo "$example fixed"
done