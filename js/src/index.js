/* eslint-env browser */
/**
 * ElmMotion JavaScript Integration (ES Module source)
 * Canonical source for bundling ESM and IIFE distributions.
 *
 * This is the entry point only. All implementation lives in the sub-modules:
 *   state.js      – shared mutable state Maps (incl. portsRef)
 *   utils.js      – pure utility functions
 *   transform.js  – transform math and DOM helpers
 *   properties.js – property resolution and keyframe builders
 *   ports.js      – Elm port communication
 *   animations.js – WAAPI animation engine
 *   scroll.js     – scroll-driven and view-driven timeline engine
 *   errors.js     – opt-in error reporting (onError, useConsoleReporter)
 */
import { processAnimationData, resizeTransformAnimation } from './animations.js';
import {
    stopAnimation,
    resetAnimation,
    restartAnimation,
    pauseAnimation,
    resumeAnimation,
    setProperties
} from './animationControls.js';
import { ensureTimelineApi, processScrollDrivenData, processViewDrivenData } from './scroll.js';
import { onError, useConsoleReporter, reportError } from './errors.js';
import { setPropertyUpdateThrottle } from './animationEvents.js';
import { portsRef, clearAllState } from './state.js';
import { resetPortMissingWarning } from './ports.js';

/**
 * Validate an inbound port command. Returns true if it is well-formed.
 */
function validateCommand(commandData) {
    if (!commandData) {
        reportError('No command data received', {
            source: 'motionCmd',
            severity: 'warning',
            code: 'COMMAND_EMPTY'
        });
        return false;
    }
    if (!commandData.type) {
        reportError('Command missing type field', {
            source: 'motionCmd',
            severity: 'warning',
            code: 'COMMAND_TYPE_MISSING',
            details: { commandData: commandData }
        });
        return false;
    }
    return true;
}

/**
 * Dispatch table mapping inbound command types to their handlers.
 * Each handler receives the raw commandData object.
 * Async handlers may return a Promise; the dispatcher awaits them.
 */
const COMMAND_HANDLERS = {
    animate: function (commandData) {
        processAnimationData(commandData);
    },
    resize: function (commandData) {
        resizeTransformAnimation(commandData);
    },
    scrollDriven: async function (commandData) {
        if (await ensureTimelineApi('ScrollTimeline')) {
            processScrollDrivenData(commandData);
        }
    },
    viewDriven: async function (commandData) {
        if (await ensureTimelineApi('ViewTimeline')) {
            processViewDrivenData(commandData);
        }
    },
    setProperties: function (commandData) {
        setProperties(commandData.updates);
    },
    stop: function (commandData) {
        stopAnimation(commandData.elementId, commandData.properties);
    },
    reset: function (commandData) {
        resetAnimation(commandData.elementId, commandData.properties);
    },
    restart: function (commandData) {
        restartAnimation(commandData.elementId, commandData.properties);
    },
    pause: function (commandData) {
        pauseAnimation(commandData.elementId, commandData.properties);
    },
    resume: function (commandData) {
        resumeAnimation(commandData.elementId, commandData.properties);
    }
};

/**
 * Look up and invoke the handler for a single command. Reports an error
 * if the command type is unknown or the handler throws/rejects.
 */
async function dispatchCommand(commandData) {
    const handler = COMMAND_HANDLERS[commandData.type];
    if (!handler) {
        reportError('Unknown command type: ' + commandData.type, {
            source: 'motionCmd',
            severity: 'warning',
            code: 'COMMAND_TYPE_UNKNOWN',
            commandType: commandData.type
        });
        return;
    }
    await handler(commandData);
}

/**
 * Initialize the ElmMotion WAAPI system with Elm ports.
 *
 * If called again with a different ports object (typical SPA route swap or
 * HMR scenario), `dispose()` is invoked automatically to release per-group
 * caches before re-attaching to the new app — callers don't need to clean
 * up manually for the common reinitialisation case. A warning is still
 * reported via `PORTS_REINITIALIZED` so the swap is observable.
 *
 * @param {object} ports - The Elm app ports object (app.ports)
 */
export function init(ports) {
    if (!ports) {
        reportError('No ports provided to init()', { source: 'init', code: 'PORTS_MISSING' });
        return;
    }

    if (portsRef.ports && portsRef.ports !== ports) {
        reportError('init() called with a different ports object; previous app state has been disposed automatically', {
            source: 'init',
            severity: 'warning',
            code: 'PORTS_REINITIALIZED'
        });
        dispose();
    }

    // Store reference for outbound events (replaces former `window.app = ...`).
    portsRef.ports = ports;
    resetPortMissingWarning();

    if (!ports.motionCmd || !ports.motionCmd.subscribe) {
        reportError('motionCmd port not found or not subscribeable', {
            source: 'init',
            severity: 'warning',
            code: 'PORT_NOT_SUBSCRIBEABLE'
        });
        return;
    }

    ports.motionCmd.subscribe(async function (commandData) {
        try {
            if (!validateCommand(commandData)) return;
            await dispatchCommand(commandData);
        } catch (error) {
            reportError(error, {
                source: 'motionCmd',
                code: 'COMMAND_PROCESSING_FAILED',
                commandType: commandData && commandData.type
            });
        }
    });
}

/**
 * Tear down the ElmMotion JS-side state. Call this when the host Elm app
 * is being unmounted (typical SPA / hot-reload scenarios) to release any
 * cached per-animation-group state and stop attempting to send events to
 * a stale ports object.
 *
 * After dispose(), call init() again with a fresh ports object to resume.
 */
export function dispose() {
    portsRef.ports = null;
    clearAllState();
    resetPortMissingWarning();
}

export { onError, useConsoleReporter, setPropertyUpdateThrottle };

export default { init: init, dispose: dispose, onError: onError, useConsoleReporter: useConsoleReporter, setPropertyUpdateThrottle: setPropertyUpdateThrottle };
