/* eslint-env browser */
/* global window, console */
/**
 * ElmMotion JavaScript Integration (ES Module source)
 * Canonical source for bundling ESM and IIFE distributions.
 *
 * This is the entry point only. All implementation lives in the sub-modules:
 *   state.js      – shared mutable state Maps
 *   utils.js      – pure utility functions
 *   transform.js  – transform math and DOM helpers
 *   properties.js – property resolution and keyframe builders
 *   ports.js      – Elm port communication
 *   animations.js – WAAPI animation engine
 *   scroll.js     – scroll-driven and view-driven timeline engine
 */
import { addEasingFunction } from './utils.js';
import { activeAnimations } from './state.js';
import { getCurrentTransform } from './transform.js';
import { processAnimationData } from './animations.js';
import {
    stopAnimation,
    resetAnimation,
    restartAnimation,
    pauseAnimation,
    resumeAnimation,
    setProperties
} from './animationControls.js';
import { ensureTimelineApi, processScrollDrivenData, processViewDrivenData } from './scroll.js';

/**
 * Initialize the ElmMotion WAAPI system with Elm ports.
 * @param {object} ports - The Elm app ports object (app.ports)
 */
export function init(ports) {
    if (!ports) {
        console.error('ElmMotion: No ports provided to init()');
        return;
    }

    // Store reference for updates
    window.app = { ports: ports };

    if (ports.waapiCommand && ports.waapiCommand.subscribe) {
        ports.waapiCommand.subscribe(async function (commandData) {
            try {
                if (!commandData) {
                    console.warn('ElmMotion: No command data received');
                    return;
                }

                if (!commandData.type) {
                    console.warn('ElmMotion: Command missing type field:', commandData);
                    return;
                }

                switch (commandData.type) {
                    case 'animate':
                        processAnimationData(commandData);
                        break;

                    case 'scrollDriven':
                        if (await ensureTimelineApi('ScrollTimeline')) {
                            processScrollDrivenData(commandData);
                        }
                        break;

                    case 'viewDriven':
                        if (await ensureTimelineApi('ViewTimeline')) {
                            processViewDrivenData(commandData);
                        }
                        break;

                    case 'setProperties':
                        setProperties(commandData.updates);
                        break;

                    case 'stop':
                        stopAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'reset':
                        resetAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'restart':
                        restartAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'pause':
                        pauseAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'resume':
                        resumeAnimation(commandData.elementId, commandData.properties);
                        break;

                    default:
                        console.warn('ElmMotion: Unknown command type:', commandData.type);
                }
            } catch (error) {
                console.error('ElmMotion: Error processing WAAPI command:', error);
            }
        });
    } else {
        console.warn('ElmMotion: waapiCommand port not found or not subscribeable');
    }
}

export {
    addEasingFunction,
    getCurrentTransform,
    stopAnimation,
    resetAnimation,
    restartAnimation,
    pauseAnimation,
    resumeAnimation,
    activeAnimations
};

export default {
    init,
    getCurrentTransform,
    stopAnimation,
    resetAnimation,
    restartAnimation,
    pauseAnimation,
    resumeAnimation,
    addEasingFunction,
    activeAnimations
};
