#!/bin/bash

# Systematic conversion script for Ports examples
# Convert from CSS API to Ports API

cd /Users/code/Elm-Lib/elm/packages/smooth-move/examples

echo "Converting Ports examples from CSS to Ports API..."

# Step 1: Update imports
for example in Position Opacity Scale Rotation Color Mixed Choreography; do
    echo "Updating imports for $example..."
    
    # Change Anim.CSS to Anim.Ports
    sed -i '' 's/import Anim\.CSS/import Anim.Ports/g' "src/ElmUI/Ports/$example/Main.elm"
    
    # Update the module name in import
    sed -i '' 's/Anim\.CSS exposing/Anim.Ports exposing/g' "src/ElmUI/Ports/$example/Main.elm"
done

# Step 2: Update exposed functions - these will need manual adjustment since Ports API is different
echo "Note: Ports examples will need manual conversion of API calls"
echo "Key changes needed:"
echo "- Add port definitions"
echo "- Replace CSS style generation with port commands" 
echo "- Add JavaScript integration"
echo "- Update subscription patterns"

echo "Ports conversion setup complete. Manual API conversion needed."