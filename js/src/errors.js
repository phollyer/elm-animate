/* eslint-env browser */
/* global console */
/**
 * Error reporting for ElmMotion.
 *
 * Default behavior: silent. Consumers opt in by registering one or more
 * subscribers via `onError`, or by enabling the built-in console adapter
 * with `useConsoleReporter`. This keeps production browsers free of
 * internal package warnings while letting developers see everything
 * during development and ship errors to a service of their choice in
 * production.
 *
 * See: https://phollyer.github.io/elm-motion/shared/error-reporting/
 *
 * @typedef {'error' | 'warning'} ErrorSeverity
 *
 * @typedef {('init' | 'motionCmd' | 'animation' | 'scrollDriven' | 'viewDriven' | 'polyfill' | string)} ErrorSource
 *
 * @typedef {Object} ErrorContext
 * @property {ErrorSource}              source                 Where the report originated.
 * @property {ErrorSeverity}            severity               'error' (default) or 'warning'.
 * @property {string}                   [code]                 Stable enum string, e.g. 'TARGET_NOT_FOUND'.
 * @property {string}                   [commandType]          The offending Elm command type, when relevant.
 * @property {string}                   [elementId]            The affected element id, when relevant.
 * @property {'WAAPI' | 'ScrollTimeline' | 'ViewTimeline'} [engine]
 * @property {Record<string, unknown>}  [details]              Additional structured information.
 *
 * @typedef {(error: Error, context: ErrorContext) => void} ErrorHandler
 * @typedef {() => void} Unsubscribe
 */

const subscribers = new Set();

/**
 * Register a subscriber to receive ElmMotion error reports.
 *
 * Subscribers are independent — register as many as you like. A subscriber
 * that throws is isolated; one bad handler will not block the others.
 * Non-function arguments are ignored and a no-op `unsubscribe` is returned.
 *
 * @param {ErrorHandler} handler
 * @returns {Unsubscribe} Call to remove the subscriber.
 *
 * @example
 * const off = ElmMotion.onError((error, context) => {
 *     console.log(context.code, error.message);
 * });
 * // later
 * off();
 */
export function onError(handler) {
    if (typeof handler !== 'function') {
        return function noop() { };
    }
    subscribers.add(handler);
    return function unsubscribe() {
        subscribers.delete(handler);
    };
}

function consoleMethodFor(context) {
    return context && context.severity === 'warning' ? 'warn' : 'error';
}

function consoleLabelFor(context) {
    const source = (context && context.source) || 'unknown';
    return '[ElmMotion:' + source + ']';
}

function compactSummary(context) {
    const ctx = context || {};
    return {
        code: ctx.code,
        commandType: ctx.commandType,
        elementId: ctx.elementId,
        engine: ctx.engine
    };
}

/**
 * @typedef {Object} ConsoleReporterOptions
 * @property {boolean} [verbose=false]  When true, logs the full error and full context.
 *                                      When false (default), logs a one-line summary.
 * @property {Console} [target=console] Any object with `.error()` and `.warn()` methods.
 */

/**
 * Built-in subscriber that forwards reports to a console-like target.
 * Opt-in — call this explicitly to enable console output.
 *
 * Reports with `severity: 'warning'` are sent to `target.warn`; everything
 * else is sent to `target.error`.
 *
 * @param {ConsoleReporterOptions} [options]
 * @returns {Unsubscribe} Call to detach the console subscriber.
 *
 * @example
 * // Development: pipe everything to the browser console
 * if (process.env.NODE_ENV !== 'production') {
 *     ElmMotion.useConsoleReporter();
 * }
 *
 * @example
 * // Tests: capture into a custom transport
 * const captured = [];
 * ElmMotion.useConsoleReporter({
 *     target: {
 *         error: (...args) => captured.push({ level: 'error', args }),
 *         warn:  (...args) => captured.push({ level: 'warn',  args })
 *     }
 * });
 */
export function useConsoleReporter(options) {
    const opts = options || {};
    const verbose = opts.verbose === true;
    const target = opts.target || console;

    return onError(function consoleReporter(error, context) {
        const method = consoleMethodFor(context);
        const label = consoleLabelFor(context);
        if (verbose) {
            target[method](label, error, context);
        } else {
            target[method](label, error.message, compactSummary(context));
        }
    });
}

/**
 * Internal: dispatch a report to all subscribers.
 *
 * Wraps the input as an `Error` if necessary and guarantees a context
 * object with at least `severity` and `source` defaults. Short-circuits
 * when no subscribers are registered. Subscribers that throw are
 * isolated — one bad handler must never break the package, and the
 * dispatcher must not recurse to report its own subscribers' failures.
 *
 * Not exported from `index.js`; intended for internal use only.
 *
 * @param {unknown} err
 * @param {Partial<ErrorContext>} [context]
 * @returns {void}
 */
export function reportError(err, context) {
    if (subscribers.size === 0) {
        return;
    }
    const errorObj = err instanceof Error ? err : new Error(String(err));
    const ctx = Object.assign({ severity: 'error', source: 'unknown' }, context || {});

    subscribers.forEach(function (handler) {
        try {
            handler(errorObj, ctx);
        } catch (_handlerErr) {
            // Intentionally swallow: a misbehaving subscriber must never
            // break the package. We cannot use the dispatcher to report
            // its own failure without risking infinite recursion.
        }
    });
}

/**
 * Test-only: clear all subscribers. Not exported from `index.js`.
 *
 * @returns {void}
 */
export function _resetSubscribers() {
    subscribers.clear();
}
