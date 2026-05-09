# Error Reporting

The Elm Motion JavaScript companion ships with an opt-in error reporting system. By default the package is **silent** — no warnings, no errors, no messages. You opt in to receive reports either during development (via the built-in console adapter) or in production (via your own subscriber that forwards to a service like Sentry, Datadog, or any other transport).

!!! note "Who needs this page"
    This applies to users of the [WAAPI](../animation/engines/waapi.md), [ScrollTimeline](../animation/engines/scroll-timeline.md) and [ViewTimeline](../animation/engines/view-timeline.md) Engines — the Engines that require the JavaScript companion. The `Transition`, `Keyframe`, `Sub` and `Scroll.*` Engines run entirely in Elm and do not produce any of these reports.

## Why opt-in?

Once an app is in production, end users should never see internal package messages in their browser console. Equally, during development you want to know immediately when something is misconfigured. The opt-in subscriber model lets you configure each environment independently without touching the package itself.

## Quick Start

### Development

Pipe everything to the browser console:

```javascript
import ElmMotion from '@phollyer/elm-motion';

const app = Elm.Main.init({ node: document.getElementById('app') });

if (process.env.NODE_ENV !== 'production') {
    ElmMotion.useConsoleReporter();
}

ElmMotion.init(app.ports);
```

### Production

Forward reports to your error tracking service:

```javascript
import * as Sentry from '@sentry/browser';
import ElmMotion from '@phollyer/elm-motion';

const app = Elm.Main.init({ node: document.getElementById('app') });

ElmMotion.onError(function (error, context) {
    Sentry.captureException(error, { extra: context });
});

ElmMotion.init(app.ports);
```

### Both side by side

Subscribers are independent. You can register more than one and each receives every report:

```javascript
ElmMotion.useConsoleReporter({ verbose: true });   // dev tooling
ElmMotion.onError(sendToTelemetry);                // production tracking
```

A subscriber that throws is isolated; one bad handler will not block the others.

## API Reference

### `ElmMotion.onError(handler)`

Register a subscriber. Returns an `unsubscribe` function.

```typescript
type ErrorHandler = (error: Error, context: ErrorContext) => void;
type Unsubscribe  = () => void;

function onError(handler: ErrorHandler): Unsubscribe;
```

- `error` is **always** an `Error` instance. Strings and other thrown values are wrapped automatically.
- `context` is **always** a plain object — see [Error context](#error-context).
- Non-function arguments are silently ignored and return a no-op `unsubscribe`.

```javascript
const unsubscribe = ElmMotion.onError((error, context) => {
    console.log(context.code, error.message);
});

// later
unsubscribe();
```

### `ElmMotion.useConsoleReporter(options?)`

Built-in subscriber that forwards reports to a console-like target. Returns an `unsubscribe` function. **Opt-in** — call this explicitly to enable console output.

```typescript
interface ConsoleReporterOptions {
    verbose?: boolean;      // default: false
    target?: Console;       // default: globalThis.console
}

function useConsoleReporter(options?: ConsoleReporterOptions): Unsubscribe;
```

| Option | Effect |
| --- | --- |
| `verbose: false` (default) | One-line summary: `[ElmMotion:source] message { code, commandType, elementId, engine }` |
| `verbose: true` | Full dump: error object plus the entire context object |
| `target` | Any object exposing `.error()` and `.warn()`. Useful for tests or custom log shipping. |

Reports with `severity: 'warning'` use `target.warn`; everything else uses `target.error`.

## Error context

Every subscriber receives a `context` object with this shape:

```typescript
interface ErrorContext {
    source: ErrorSource;           // where the report originated
    severity: ErrorSeverity;       // 'error' | 'warning'
    code?: string;                 // stable enum string (see table below)
    commandType?: string;          // the offending Elm command type
    elementId?: string;            // the affected element id, when relevant
    engine?: 'WAAPI' | 'ScrollTimeline' | 'ViewTimeline';
    details?: Record<string, unknown>;  // any additional structured info
}

type ErrorSeverity = 'error' | 'warning';
type ErrorSource =
    | 'init'
    | 'motionCmd'
    | 'animation'
    | 'scrollDriven'
    | 'viewDriven'
    | 'polyfill'
    | string;        // future-proof; treat unknown values as opaque
```

The `code` field is the most useful for routing — it is a stable string you can switch on without parsing the human-readable `error.message`.

## Error codes

The current set of error codes emitted by the JavaScript companion:

| Code | Severity | Source | Meaning |
| ---- | -------- | ------ | ------- |
| `PORTS_MISSING` | error | `init` | `ElmMotion.init()` was called without a ports object |
| `PORTS_REINITIALIZED` | warning | `init` | `ElmMotion.init()` was called with a different ports object; the previous app's state has been disposed automatically before attaching to the new ports |
| `PORT_NOT_SUBSCRIBEABLE` | warning | `init` | The `motionCmd` port was not declared in your Elm app, or is not subscribeable |
| `COMMAND_EMPTY` | warning | `motionCmd` | A port message arrived with no payload |
| `COMMAND_TYPE_MISSING` | warning | `motionCmd` | A port message arrived without a `type` field |
| `COMMAND_TYPE_UNKNOWN` | warning | `motionCmd` | A port message used a `type` the companion does not recognise |
| `COMMAND_PROCESSING_FAILED` | error | `motionCmd` | A handler threw or rejected while processing a command |
| `COMMAND_INVALID` | warning | `animation` / `scrollDriven` / `viewDriven` | A command's payload was missing required fields (typically `elements`) |
| `TARGET_NOT_FOUND` | warning | `animation` / `scrollDriven` / `viewDriven` | An element with the requested `data-anim-target` was not present in the DOM |
| `SCROLL_SOURCE_NOT_FOUND` | warning | `scrollDriven` | A scroll source element referenced by id was not found |
| `API_UNSUPPORTED` | warning | `scrollDriven` / `viewDriven` | The browser does not support the requested timeline API and no polyfill could provide it |
| `POLYFILL_LOAD_FAILED` | warning | `polyfill` | The dynamic import of the timeline polyfill rejected |
| `POLYFILL_API_MISSING` | warning | `polyfill` | The polyfill loaded but did not expose the expected API |
| `SCROLL_PROGRESS_READ_FAILED` | warning | `scroll` | Reading `getComputedTiming().progress` on a scroll-driven animation threw |
| `ITERATION_TIMING_READ_FAILED` | warning | `animationEvents` | Reading `getComputedTiming().currentIteration` for iteration tracking threw |
| `COMMIT_STYLES_FAILED` | warning | `animationEvents` | `animation.commitStyles()` threw at the end of an animation (e.g., element detached) |
| `ANIMATION_CANCEL_FAILED` | warning | `animationEvents` | `animation.cancel()` threw during the fallback after a `commitStyles()` failure |
| `MOTION_MSG_PORT_MISSING` | warning | `ports` | The first attempt to send an event to Elm found no `motionMsg` port (likely missing port declaration in the Elm app); reported once per session, then events are silently dropped until `init()` is called again |
| `THROTTLE_INVALID` | warning | `setPropertyUpdateThrottle` | `ElmMotion.setPropertyUpdateThrottle()` was called with a value that was not a non-negative finite number; the previous throttle setting is left unchanged |

!!! tip "Stable additions"
    New codes may be added in future releases. Treat unknown codes as opaque — switch on the codes you care about and let the rest fall through to a generic handler.

## Patterns

### Filter by severity

```javascript
ElmMotion.onError((error, context) => {
    if (context.severity === 'error') {
        Sentry.captureException(error, { extra: context });
    }
});
```

### Route by code

```javascript
ElmMotion.onError((error, context) => {
    switch (context.code) {
        case 'TARGET_NOT_FOUND':
            // Common during view transitions; downgrade to a metric
            recordMissingTarget(context.elementId);
            break;
        case 'API_UNSUPPORTED':
            // Browser capability issue; surface a feature flag
            disableScrollDrivenAnimations();
            break;
        default:
            Sentry.captureException(error, { extra: context });
    }
});
```

### Inspect everything during development

```javascript
ElmMotion.useConsoleReporter({ verbose: true });
```

### Capture into a custom transport (tests, log shipping)

```javascript
const captured = [];

ElmMotion.useConsoleReporter({
    target: {
        error: (...args) => captured.push({ level: 'error', args }),
        warn:  (...args) => captured.push({ level: 'warn',  args })
    }
});
```
