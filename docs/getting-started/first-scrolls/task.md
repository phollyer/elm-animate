# Task Example

--8<-- [start:examples]

Composable scrolling with `Scroll.toTask` for success/failure handling.

<iframe src="../../../examples/src/Engines/Scroll/FirstScrollTask/index.html" style="width: 100%; height: 550px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm"
    ```

## Breaking It Down

### 1. Build

The scroll builder is piped into `Scroll.toTask` followed by `Task.attempt` to convert it into a `Cmd`:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm:build"
    ```

- `Scroll.toTask` - returns a `Task ScrollError ScrollOk` instead of a `Cmd`
- `Task.attempt` - converts the Task into a Cmd, delivering the result as a `Result`

### 2. Initialize

Since we're handling results, the model tracks scroll status:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm:model"
    ```

### 3. Trigger

Trigger the scroll and set the status to `Scrolling`:

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm:trigger"
    ```

### 4. Handle the Result

When the scroll completes, you get a `Result` with either `ScrollOk` (containing the target description) or `ScrollError` (containing the container ID, target element ID, and DOM error):

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/FirstScrollTask/Main.elm:result"
    ```

Tasks are also composable - you can chain multiple scrolls with `Task.andThen`, or combine them with other Tasks.

--8<-- [end:examples]
