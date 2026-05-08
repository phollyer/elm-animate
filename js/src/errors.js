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
 * Each subscriber receives `(error, context)`:
 *   error   - always an Error instance (strings/unknowns are wrapped)
 *   context - plain object with shape:
 *               source       string  e.g. 'init', 'waapiCommand', 'animation',
 *                                    'scrollDriven', 'viewDriven', 'polyfill'
 *               severity     'error' | 'warning'
 *               code         stable enum string, e.g. 'POLYFILL_LOAD_FAILED'
 *               commandType? string  the offending Elm command type
 *               elementId?   string
 *               engine?      'WAAPI' | 'ScrollTimeline' | 'ViewTimeline'
 *               details?     object  any additional structured info
 */

const subscribers = new Set();

/**
 * Register a subscriber to receive ElmMotion error reports.
 * Returns an unsubscribe function.
 *
 * @param {(error: Error, context: object) => void} handler
 * @returns {() => void} unsubscribe
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
 * Built-in subscriber that forwards reports to a console-like target.
 * Opt-in. Returns an unsubscribe function.
 *
 * @param {{ verbose?: boolean, target?: Console }} [options]
 * @returns {() => void} unsubscribe
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
 * Wraps the input as an Error if necessary and guarantees a context object.
 * Subscribers that throw are isolated; one bad handler cannot block others.
 *
 * @param {unknown} err
 * @param {object} [context]
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
 * Test-only: clear all subscribers. Not exported from index.js.
 */
export function _resetSubscribers() {
    subscribers.clear();
}
