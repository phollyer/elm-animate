# Scroll Examples

Interactive examples demonstrating Elm Animate scroll capabilities.

Each example uses the same scroll behavior across all Scroll engines, so you can quickly compare runtime behavior and tradeoffs.

## Vertical Scrolling

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:examples"

[Go to page](first-scrolls.md#1-vertical-scrolling){ .md-button .md-button--primary }

---

## Horizontal Scrolling

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:examples"

[Go to page](first-scrolls.md#2-horizontal-scrolling){ .md-button .md-button--primary }

---

## Spreadsheet Navigation

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:desc"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:examples"

[Go to page](first-scrolls.md#3-spreadsheet-navigation){ .md-button .md-button--primary }

---

## Controlling Scrolls

Pause, resume, restart, stop, and reset scrolls while they run.

??? example "View Example"

    <iframe src="../../examples/src/Scroll/Sub/ControllingScrolls/index.html" style="width: 100%; height: 500px; border: 1px solid var(--md-default-fg-color--lightest); border-radius: 8px;" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/ControllingScrolls/Main.elm"
    ```

[Go to page](concepts/controlling-scroll.md){ .md-button .md-button--primary }

---

## Interrupting Scrolls

Trigger a scroll, then trigger again mid-flight to compare interruption behavior across engines.

[Go to page](concepts/interrupting-scrolls.md){ .md-button .md-button--primary }
