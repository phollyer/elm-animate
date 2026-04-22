# Initialize

Only the `Sub` Engine needs to track it's own internal state, so only the
`Sub` Engine needs initializing. This step is not relevant for the
`Cmd` and `Task` Engines.

## Why Initialize?

Initializing creates the initial empty state to store and manage scroll configurations.

## Engine `init` function

A simple function that creates empty state.

??? example "View Source Code"




## Store it in your Model

