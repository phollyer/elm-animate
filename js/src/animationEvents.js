/* eslint-env browser */
/* global window, requestAnimationFrame, cancelAnimationFrame, performance */
import { updateGroupIteration } from './utils.js';
import { activeAnimations, animationGroups, lastKnownTransforms, cleanupAnimGroup } from './state.js';
import { getDefaultTransformState, computeTransformFromResolved } from './transform.js';
import { sendLifecycleEvent, sendIterationEvent, sendPropertyUpdate, buildAnimatedPropertyData } from './ports.js';
import { reportError } from './errors.js';

/**
 * Property keys whose data is read from the live `CSSStyleDeclaration` returned
 * by `window.getComputedStyle(element)`. The `transform` branch is intentionally
 * absent: transform values are computed analytically from `transformState` and
 * never need a style flush. Custom-property keys are dynamic (`custom:<css>` /
 * `customColor:<css>`) and detected by prefix in `needsComputedStyle`.
 */
const COMPUTED_STYLE_KEYS = ['opacity', 'size', 'perspectiveOrigin'];

/**
 * Return true if any property in `propertyVersions` requires reading the
 * element's live computed style. Used to skip the layout-flushing
 * `getComputedStyle` call entirely for pure-transform animations - the most
 * common case for the WAAPI engine, and the one that benefits most from
 * compositor-only playback.
 */
export function needsComputedStyle(propertyVersions) {
    for (const key of COMPUTED_STYLE_KEYS) {
        if (key in propertyVersions) return true;
    }
    for (const key in propertyVersions) {
        if (key.startsWith('custom:') || key.startsWith('customColor:')) return true;
    }
    return false;
}

// Minimum interval (ms) between per-frame propertyUpdate emissions during an
// animation. Default 0 = no throttle: emit on every requestAnimationFrame
// tick, matching the display refresh rate (60 Hz, 120 Hz, 144 Hz, etc.).
// The visual animation runs on the browser compositor and is unaffected
// by this value - this only governs how often we read the live transform
// state and forward a propertyUpdate event to Elm.
//
// Set a positive value via `setPropertyUpdateThrottle(ms)` to cap the
// emission rate, e.g. 16 for ~60 Hz, 33 for ~30 Hz. Useful when many
// simultaneous animations on a high-refresh display would otherwise
// generate excessive port traffic for Elm-side real-time queries.
let propertyUpdateIntervalMs = 0;

/**
 * Set the minimum interval (in milliseconds) between per-frame
 * `propertyUpdate` events emitted to Elm during an animation.
 *
 * Pass 0 (the default) to disable throttling - one event is emitted per
 * requestAnimationFrame tick, matching the display refresh rate.
 *
 * Pass a positive number to cap the emission rate. The visual animation
 * is never affected; only the rate at which Elm subscribers see live
 * mid-animation values changes.
 *
 * @param {number} intervalMs - Non-negative number. 0 disables throttling.
 */
export function setPropertyUpdateThrottle(intervalMs) {
    if (typeof intervalMs !== 'number' || !Number.isFinite(intervalMs) || intervalMs < 0) {
        reportError('setPropertyUpdateThrottle requires a non-negative finite number', {
            source: 'setPropertyUpdateThrottle',
            severity: 'warning',
            code: 'THROTTLE_INVALID',
            details: { intervalMs: intervalMs }
        });
        return;
    }
    propertyUpdateIntervalMs = intervalMs;
}

function buildPropertyVersions(animGroup, propertyType, version) {
    const propertyVersions = {};
    const elementAnims = activeAnimations.get(animGroup);
    if (elementAnims) {
        elementAnims.forEach((animData, propType) => {
            propertyVersions[propType] = animData.version;
        });
    }
    if (propertyType && version != null) {
        propertyVersions[propertyType] = version;
    }
    return propertyVersions;
}

function removeTrackedAnimationVersion(animGroup, propertyType, version) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) {
        return;
    }

    const current = elementAnims.get(propertyType);
    if (current && current.version === version) {
        elementAnims.delete(propertyType);
        if (elementAnims.size === 0) {
            activeAnimations.delete(animGroup);
        }
    }
}

function getResolvedEndTransformState(resolvedTransformValues) {
    return {
        x: resolvedTransformValues.translate.endX,
        y: resolvedTransformValues.translate.endY,
        z: resolvedTransformValues.translate.endZ,
        scaleX: resolvedTransformValues.scale.endX,
        scaleY: resolvedTransformValues.scale.endY,
        scaleZ: resolvedTransformValues.scale.endZ,
        rotateX: resolvedTransformValues.rotate.endX,
        rotateY: resolvedTransformValues.rotate.endY,
        rotateZ: resolvedTransformValues.rotate.endZ,
        skewX: resolvedTransformValues.skew.endX,
        skewY: resolvedTransformValues.skew.endY
    };
}

function getTrackedTransformState(animGroup, resolvedTransformValues, fallbackTransformState) {
    if (resolvedTransformValues) {
        const transformState = fallbackTransformState || getDefaultTransformState();
        lastKnownTransforms.set(animGroup, transformState);
        return transformState;
    }

    return lastKnownTransforms.get(animGroup) || getDefaultTransformState();
}

function sendTrackedPropertyUpdate(animGroup, propertyType, version, transformState, element, isAnimating, progress) {
    const propertyVersions = buildPropertyVersions(animGroup, propertyType, version);
    // Skip the layout-flushing getComputedStyle call when only transform
    // properties are animated. The transform branch of buildAnimatedPropertyData
    // is computed analytically from transformState and never reads computedStyle,
    // so for the common pure-transform case (translate / rotate / scale / skew)
    // we save one style flush per element per rAF tick.
    const computedStyle = needsComputedStyle(propertyVersions)
        ? window.getComputedStyle(element)
        : null;
    const propertyData = {
        elementId: animGroup,
        animGroup: animGroup,
        ...buildAnimatedPropertyData(animGroup, propertyVersions, transformState, element, computedStyle),
        isAnimating: isAnimating,
        propertyVersions: propertyVersions
    };

    if (progress != null) {
        propertyData.progress = progress;
    }

    sendPropertyUpdate(propertyData);
}

function updateGroupIterationState(animGroup, groupGeneration, propertyIndex, animation) {
    const groupInfo = animationGroups.get(animGroup);
    if (!groupInfo || groupInfo.generation !== groupGeneration) {
        return;
    }

    try {
        const currentIteration = animation.effect?.getComputedTiming()?.currentIteration;
        const nextGroupIteration = updateGroupIteration(
            groupInfo.propertyIterations,
            propertyIndex,
            currentIteration,
            groupInfo.lastIteration
        );
        if (nextGroupIteration != null) {
            groupInfo.lastIteration = nextGroupIteration;
            sendIterationEvent(animGroup, nextGroupIteration);
        }
    } catch (error) {
        reportError(error, {
            source: 'animationEvents',
            severity: 'warning',
            code: 'ITERATION_TIMING_READ_FAILED',
            details: { animGroup: animGroup, propertyIndex: propertyIndex }
        });
    }
}

function getAnimationProgress(animGroup, animation) {
    const groupInfo = animationGroups.get(animGroup);
    const maxDuration = groupInfo?.propertyConfigs?.length > 0
        ? Math.max(...groupInfo.propertyConfigs.map(property => property.duration))
        : animation.effect?.getTiming()?.duration || 0;
    const currentTime = animation.currentTime || 0;
    return maxDuration > 0
        ? Math.min(1.0, Math.max(0.0, currentTime / maxDuration))
        : 0;
}

function getLiveTransformState(animGroup, animation, resolvedTransformValues, transformAnimDuration) {
    if (!resolvedTransformValues) {
        return lastKnownTransforms.get(animGroup) || getDefaultTransformState();
    }

    const currentTime = animation.currentTime || 0;
    const animProgress = transformAnimDuration > 0
        ? Math.min(1.0, Math.max(0.0, currentTime / transformAnimDuration))
        : 0;
    const transformState = computeTransformFromResolved(resolvedTransformValues, animProgress, transformAnimDuration);
    lastKnownTransforms.set(animGroup, transformState);
    return transformState;
}

function finalizeAnimationTracking(animGroup, groupGeneration, status) {
    const groupInfo = animationGroups.get(animGroup);
    if (!groupInfo || groupInfo.generation !== groupGeneration) {
        return false;
    }

    groupInfo.completedProperties++;
    const allComplete = groupInfo.completedProperties >= groupInfo.totalProperties;
    if (allComplete) {
        sendLifecycleEvent(status, animGroup);
        cleanupAnimGroup(animGroup);
    }
    return allComplete;
}

export function setupAnimationEvents(animGroup, propertyType, element, animation, version, resolvedTransformValues) {
    const groupGeneration = animationGroups.get(animGroup)?.generation || 0;
    const groupInfoForIndex = animationGroups.get(animGroup);
    let propertyIndex = 0;
    if (groupInfoForIndex) {
        propertyIndex = groupInfoForIndex.nextPropertyIndex;
        groupInfoForIndex.nextPropertyIndex++;
    }
    const transformAnimDuration = resolvedTransformValues
        ? (animation.effect?.getTiming()?.duration || 0)
        : 0;

    let lastComputedTransformState = resolvedTransformValues
        ? computeTransformFromResolved(resolvedTransformValues, 0, transformAnimDuration)
        : null;
    let lastTime = 0;
    let rafId = null;

    function sendAnimationUpdate() {
        const now = performance.now();
        if (propertyUpdateIntervalMs <= 0 || now - lastTime >= propertyUpdateIntervalMs) {
            updateGroupIterationState(animGroup, groupGeneration, propertyIndex, animation);

            const transformState = getLiveTransformState(animGroup, animation, resolvedTransformValues, transformAnimDuration);
            lastComputedTransformState = transformState;

            sendTrackedPropertyUpdate(
                animGroup,
                null,
                null,
                transformState,
                element,
                true,
                getAnimationProgress(animGroup, animation)
            );
            lastTime = now;
        }

        if (animation.playState === 'running') {
            rafId = requestAnimationFrame(sendAnimationUpdate);
        } else {
            rafId = null;
        }
    }

    rafId = requestAnimationFrame(sendAnimationUpdate);
    let finishHandled = false;

    animation.addEventListener('finish', () => {
        finishHandled = true;

        if (rafId !== null) {
            cancelAnimationFrame(rafId);
            rafId = null;
        }
        try {
            animation.commitStyles();
            animation.cancel();
        } catch (commitError) {
            reportError(commitError, {
                source: 'animationEvents',
                severity: 'warning',
                code: 'COMMIT_STYLES_FAILED',
                details: { animGroup: animGroup, propertyType: propertyType }
            });
            try {
                animation.cancel();
            } catch (cancelError) {
                reportError(cancelError, {
                    source: 'animationEvents',
                    severity: 'warning',
                    code: 'ANIMATION_CANCEL_FAILED',
                    details: { animGroup: animGroup, propertyType: propertyType }
                });
            }
        }

        removeTrackedAnimationVersion(animGroup, propertyType, version);

        if (animationGroups.get(animGroup)?.generation === groupGeneration) {
            const allComplete = finalizeAnimationTracking(animGroup, groupGeneration, 'completed');
            const finalTransformState = getTrackedTransformState(
                animGroup,
                resolvedTransformValues,
                resolvedTransformValues ? getResolvedEndTransformState(resolvedTransformValues) : null
            );
            sendTrackedPropertyUpdate(animGroup, propertyType, version, finalTransformState, element, !allComplete);
        }
    });

    animation.addEventListener('cancel', () => {
        if (finishHandled) return;

        removeTrackedAnimationVersion(animGroup, propertyType, version);

        if (animationGroups.get(animGroup)?.generation === groupGeneration) {
            const allCancelled = finalizeAnimationTracking(animGroup, groupGeneration, 'cancelled');
            const cancelTransformState = getTrackedTransformState(animGroup, resolvedTransformValues, lastComputedTransformState);
            sendTrackedPropertyUpdate(animGroup, propertyType, version, cancelTransformState, element, !allCancelled);
        }
    });

    return sendAnimationUpdate;
}
