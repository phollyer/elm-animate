#!/bin/bash

# Systematic conversion script for Ports examples based on established pattern
cd /Users/code/Elm-Lib/elm/packages/smooth-move/examples

echo "Converting remaining Ports examples..."

# Convert each example systematically
for example in Opacity Scale Rotation Color Mixed Choreography; do
    echo "Converting $example..."
    
    file="src/ElmUI/Ports/$example/Main.elm"
    
    # 1. Change to port module
    sed -i '' 's/^module ElmUI\.CSS\./port module ElmUI.Ports./g' "$file"
    
    # 2. Update imports
    sed -i '' 's/import Anim\.CSS/import Anim.Ports/g' "$file"
    sed -i '' 's/Anim\.CSS exposing/Anim.Ports exposing/g' "$file"
    
    # 3. Update function imports (add JSON imports and remove CSS-specific)
    sed -i '' 's/transitionStyles, /encodeAnimationCommand, /g' "$file"
    sed -i '' 's/getCurrentPosition/getPosition/g' "$file"
    sed -i '' 's/animatePosition/animateTo/g' "$file"
    
    # 4. Add JSON imports if not present
    if ! grep -q "import Json.Decode as Decode" "$file"; then
        sed -i '' '/^import Anim exposing/i\
import Json.Decode as Decode\
import Json.Encode as Encode' "$file"
    fi
    
    # 5. Update imports to include handlePropertyUpdateFromJson
    sed -i '' 's/styleProperties)/styleProperties, encodeAnimationCommand, handlePropertyUpdateFromJson)/g' "$file"
    
done

echo "Basic conversion complete. Manual fixes needed for:"
echo "- Port definitions (add after imports)"
echo "- Model type (Anim.CSS.Model -> Anim.Ports.Model)"
echo "- Update function pattern (command generation and ports)"
echo "- Message handling (add PositionUpdateReceived and AnimationComplete String)"
echo "- Subscriptions (port subscriptions)"
echo "- View updates (remove CSS transitions, fix position access)"