# Sequencing Animations

Sequencing is running animations one after another — building complex choreography from simple pieces.

## Two Approaches

| Approach | How It Works | Best For |
| -------- | ------------ | -------- |
| **State Continuity** | Engine tracks end values, uses them as next start values | Cumulative movement, chained transitions |
| **Event-Based** | Listen for `Ended` events, trigger next animation | Distinct stages, conditional sequences |

## State Continuity

When using `animate`, the engine remembers where each animation ended. The next animation picks up from there automatically.

### Cumulative Movement

```elm
moveRight : AnimBuilder -> AnimBuilder
moveRight =
    Translate.for "box"
        >> Translate.byX 100  -- End value only
        >> Translate.build

-- First trigger:  0 → 100
-- Second trigger: 100 → 200  
-- Third trigger:  200 → 300
```

You only specify the end value. The engine supplies the start value from the previous end state.

### Setting Initial Values

For the first trigger, set initial values via `init`:

```elm
init _ =
    ( { animState =
            Transitions.init
                [ Translate.initX "box" -100
                , Opacity.init "box" 0
                ]
      }
    , Cmd.none
    )
```

If nothing is set, properties use sensible defaults — see each property page for details.

### Manual Tracking with `fireAndForget`

With `fireAndForget`, each call starts fresh. You must specify both start and end values, tracking state yourself:

```elm
moveRight : Float -> AnimBuilder -> AnimBuilder
moveRight currentX =
    Translate.for "box"
        >> Translate.fromX currentX
        >> Translate.byX 100
        >> Translate.build
```

Track `currentX` in your model and update it after each trigger.

## Event-Based Sequencing

For distinct animation stages, trigger the next animation when the previous one ends using [animation events](events.md):

```elm
update msg model =
    case msg of
        GotStartSequence ->
            ( { model | animState = Transitions.animate model.animState (fadeIn "header") }
            , Cmd.none
            )

        GotAnimEvent (Transitions.Ended "header") ->
            ( { model | animState = Transitions.animate model.animState (slideIn "sidebar") }
            , Cmd.none
            )

        GotAnimEvent (Transitions.Ended "sidebar") ->
            ( { model | animState = Transitions.animate model.animState (fadeIn "content") }
            , Cmd.none
            )
```

This gives you full control over the sequence — you can add delays, conditionally skip steps, or branch based on application state.

## Combining Approaches

Use both together for complex choreography:

```elm
update msg model =
    case msg of
        GotMoveBox ->
            -- State continuity: cumulative movement
            ( { model | animState = Transitions.animate model.animState moveRight }
            , Cmd.none
            )

        GotAnimEvent (Transitions.Ended "box") ->
            -- Event-based: chain to next element
            ( { model | animState = Transitions.animate model.animState (fadeIn "nextElement") }
            , Cmd.none
            )
```

## Engine Support

| Feature | Transitions | Keyframes | Sub | WAAPI |
| ------- | :---------: | :-------: | :-: | :---: |
| State Continuity | ✓ | ✓ | ✓ | ✓ |
| `Ended` Events | ✓ | ✓ | ✓ | ✓ |
| Mid-flight Redirection | ✓ | | ✓ | ✓ |

All engines support sequencing. Keyframes can't redirect mid-flight, but can still sequence via events.
