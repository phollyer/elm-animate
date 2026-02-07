# Controlling Scroll Animations

The Scroll Engine provides full programmatic control over running scroll animations when using stateful subscription-based scrolling. You can `stop`, `reset`, `restart`, `pause` and `resume` scroll animations at any time.

!!! note "Stateful Scrolling Only"
    Control functions are only available when using stateful subscription-based scrolling via `animate`. Fire-and-forget `toCmd` and task-based `toTask` scrolling cannot be controlled after they begin.

## Available Controls

| Function | Behavior |
| ---------- | ---------- |
| `stop` | Jump instantly to the scroll **target position** and complete |
| `pause` | Freeze the scroll at its current position |
| `resume` | Continue a paused scroll from where it was frozen |
| `reset` | Jump instantly to the **start position** and stop |
| `restart` | Reset to start position, then begin scrolling again |

## Document vs Container

Each control function has two variants:

- **Document functions** (`stop`, `pause`, etc.) - Control document body scrolling
- **Container functions** (`stopContainer`, `pauseContainer`, etc.) - Control scrolling within specific containers

```elm
-- Stop document scrolling
Scroll.stop model.scrollAnimations

-- Stop a specific container's scrolling
Scroll.stopContainer "my-scrollable-div" model.scrollAnimations
```

## Using Control Functions

All control functions follow the same pattern - they take the current `AnimState` and return an updated state.

### Stop

Immediately jumps to the target scroll position and completes the animation:

```elm
update msg model =
    case msg of
        StopScrolling ->
            ( { model | scrollAnimations = Scroll.stop model.scrollAnimations }
            , Cmd.none
            )
```

### Pause

Freezes the scroll at its current position. The scroll can be resumed later:

```elm
update msg model =
    case msg of
        PauseScrolling ->
            ( { model | scrollAnimations = Scroll.pause model.scrollAnimations }
            , Cmd.none
            )
```

### Resume

Continues a paused scroll from exactly where it was frozen:

```elm
update msg model =
    case msg of
        ResumeScrolling ->
            ( { model | scrollAnimations = Scroll.resume model.scrollAnimations }
            , Cmd.none
            )
```

### Reset

Immediately jumps back to the starting scroll position and stops:

```elm
update msg model =
    case msg of
        ResetScrolling ->
            ( { model | scrollAnimations = Scroll.reset model.scrollAnimations }
            , Cmd.none
            )
```

### Restart

Resets to the start position, then immediately begins scrolling again:

```elm
update msg model =
    case msg of
        RestartScrolling ->
            ( { model | scrollAnimations = Scroll.restart model.scrollAnimations }
            , Cmd.none
            )
```

## Container-Specific Controls

For scrollable containers, use the container variants with the element ID:

```elm
-- Pause scrolling in a specific container
Scroll.pauseContainer "article-content" model.scrollAnimations

-- Resume scrolling in that container
Scroll.resumeContainer "article-content" model.scrollAnimations

-- Stop scrolling in a sidebar
Scroll.stopContainer "sidebar-nav" model.scrollAnimations
```

