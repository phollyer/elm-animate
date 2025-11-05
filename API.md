# API Examples

## Creating a single property animation

### Positioning

```elm
let
    (anim, cmd) =
        Anim.for "element_id"
            |> Position.to position
            |> Position.speed 50
            |> animate portFunction
in
({ model | anim = anim }, cmd)
```

## Creating a multi-property animation

### Option 1

```elm
let
    (anim, cmd) =
        Anim.for "element_id"
            |> Position.to position
            |> Position.speed 50
            |> Rotate.to 90
            |> Rotate.speed 10
            |> Rotate.delay 1000
            |> Rotate.easing easeInOut 
            |> animate portFunction
in
({ model | anim = anim }, cmd)
```

### Option 2

```elm
let
    (anim, cmd) =
        Anim.for "element_id"
            |> Anim.add
                (Position.to position
                    |> Position.speed 50
                )
            |> Anim.add
                (Rotate.to 90
                    |> Rotate.speed 10
                    |> Rotate.delay 1000
                    |> Rotate.easing easeInOut 
                )
            |> animateProperties portFunction
in
({ model | anim = anim }, cmd)
```

## Creating a multi-element animation


### Option 1

```elm
let
    (anim, cmd) =
        Anim.for "element_id_1"
            |> Position.to position
            |> Position.speed 50
            |> Rotate.to 90
            |> Rotate.speed 10
            |> Rotate.delay 1000
            |> Rotate.easing easeInOut 
            |> Anim.addElement "element_id_2"
            ...
            |> Anim.addElement "element_id_3"
            ...
            |> animateAll portFunction
in
({ model | anim = anim }, cmd)
```

### Option 2

```elm
let
    (anim, cmd) =
        Anim.for "element_id_1"
            |> Anim.add
                (Position.to position1
                    |> Position.speed 50
                    |> Rotate.to 90
                    |> Rotate.speed 10
                    |> Rotate.delay 1000
                    |> Rotate.easing easeInOut 
                )
            |> Anim.addElement "element_id_2"
                (Anim.add
                    (Position.to position2
                        |> Position.speed 60
                        |> Rotate.to 90
                        |> Rotate.speed 10
                        |> Rotate.delay 1000
                        |> Rotate.easing easeInOut 
                    )
                )
            |> animateProperties portFunction
in
({ model | anim = anim }, cmd)
```

### Option 3

```elm
let
    (anim, cmd) =
        Anim.for "element_id_1"
            |> Anim.add
                (Position.to position1
                    |> Position.speed 50
                )
            |> Anim.add
                (Rotate.to 90
                    |> Rotate.speed 10
                    |> Rotate.delay 1000
                    |> Rotate.easing easeInOut 
                )
            |> Anim.addElement "element_id_2"
                (Anim.add
                    (Position.to position2
                        |> Position.speed 60
                    )
                |> Anim.add
                    (Rotate.to 90
                        |> Rotate.speed 10
                        |> Rotate.delay 1000
                        |> Rotate.easing easeInOut 
                    )
                )
            |> animateProperties portFunction
in
({ model | anim = anim }, cmd)
```
        
