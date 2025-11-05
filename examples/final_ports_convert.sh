#!/bin/bash

# Final batch conversion for remaining Ports examples
cd /Users/code/Elm-Lib/elm/packages/smooth-move/examples

echo "Applying comprehensive Ports conversions for final 4 examples..."

for example in Rotation Color Mixed Choreography; do
    echo "Converting $example..."
    
    file="src/ElmUI/Ports/$example/Main.elm"
    
    # 1. Fix import line breaks if any
    sed -i '' 's/Json.Encode as Encodeimport/Json.Encode as Encode\
import/g' "$file"
    
    # 2. Update imports to remove CSS-specific functions
    sed -i '' 's/, onTransitionEnd//g' "$file"
    sed -i '' 's/, transitionStyles//g' "$file"
    
    # 3. Fix model type
    sed -i '' 's/Anim\.CSS\.Model/Anim.Ports.Model/g' "$file"
    
    # 4. Fix init function
    sed -i '' 's/Anim\.CSS\.init/Anim.Ports.init/g' "$file"
    
    # 5. Add port-related message types  
    sed -i '' 's/| AnimationComplete/| AnimationComplete String\
    | PositionUpdateReceived (Result Decode.Error Anim.Ports.PropertyUpdate)/g' "$file"
    
    # 6. Update view titles
    sed -i '' 's/"Anim\.CSS /"Anim.Ports /g' "$file"
    sed -i '' 's/UI\.pageHeader "CSS /UI.pageHeader "Ports /g' "$file"
    
    # 7. Remove CSS transition code patterns
    sed -i '' '/htmlAttribute.*transition/d' "$file"
    sed -i '' '/onTransitionEnd/d' "$file"
    sed -i '' '/transitionStyles/d' "$file"
    
done

echo "Basic conversion complete. Manual update function fixes needed for proper Ports pattern."