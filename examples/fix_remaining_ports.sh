#!/bin/bash

# Fix all remaining Ports examples with consistent pattern
cd /Users/code/Elm-Lib/elm/packages/smooth-move/examples

echo "Fixing remaining Ports examples with missing ports and parentheses issues..."

for example in Color Mixed Choreography; do
    echo "Fixing $example..."
    
    file="src/ElmUI/Ports/$example/Main.elm"
    
    # 1. Add handlePropertyUpdateFromJson to imports
    sed -i '' 's/encodeAnimationCommand)/encodeAnimationCommand, handlePropertyUpdateFromJson)/g' "$file"
    
    # 2. Add port definitions after the imports but before MAIN
    sed -i '' '/-- MAIN/i\
\
-- PORTS\
\
\
port animateElement : Encode.Value -> Cmd msg\
\
\
port stopElement : Encode.Value -> Cmd msg\
\
\
port positionUpdates : (Decode.Value -> msg) -> Sub msg\
\
\
port animationComplete : (String -> msg) -> Sub msg\
\
' "$file"
    
    # 3. Fix parentheses issues from CSS transition removal
    sed -i '' 's/])/)/g' "$file"
    
done

echo "Fixed imports, ports, and parentheses. Manual update function fixes still needed."