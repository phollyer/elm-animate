# Scroll Examples

Interactive examples demonstrating Elm Motion scroll capabilities.

Each example uses the same scroll behavior across all Scroll engines, so you can quickly compare runtime behavior and tradeoffs.

## Vertical Scrolling

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/vertical-scrolling.md:examples"

[Go to page](start-here.md#1-vertical-scrolling){ .md-button .md-button--primary }

---

## Horizontal Scrolling

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:desc"

--8<-- "docs/scroll/first-scrolls/horizontal-scrolling.md:examples"

[Go to page](start-here.md#2-horizontal-scrolling){ .md-button .md-button--primary }

---

## Spreadsheet Navigation

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:desc"

--8<-- "docs/scroll/first-scrolls/spreadsheet.md:examples"

[Go to page](start-here.md#3-spreadsheet-navigation){ .md-button .md-button--primary }

---

## Controlling Scrolls

Pause, resume, restart, stop, and reset scrolls while they run.

??? example "View Example"

    <iframe src="../../examples/src/Scroll/Sub/ControllingScrolls/index.html" class="example-iframe example-iframe--lg" loading="lazy"></iframe>

??? example "View Source Code"

    ```elm
    --8<-- "docs/examples/src/Engines/Scroll/Sub/ControllingScrolls/Main.elm"
    ```

[Go to page](concepts/controlling-scroll.md){ .md-button .md-button--primary }

---

## Interrupting Scrolls

Trigger a scroll, then trigger again mid-flight to compare interruption behavior across engines.

[Go to page](concepts/interrupting-scrolls.md){ .md-button .md-button--primary }
