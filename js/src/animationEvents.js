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

/**
 * Convert a camelCase JS property name (as used in Web Animations API
 * keyframe objects, e.g. `backgroundColor`) to its CSS hyphenated form
 * (e.g. `background-color`) for use with `CSSStyleDeclaration.setProperty`.
 */
function camelToKebab(name) {
    return name.replace(/[A-Z]/g, m => '-' + m.toLowerCase());
}

/**
 * Best-effort equivalent of `Animation.commitStyles()` for browsers that
 * don't implement it (notably older iOS Safari). Reads the last keyframe
 * of the animation and writes each animatable property to the element's
 * inline style. Skips the `composite`, `easing`, `offset` pseudo-keys.
 *
 * Falls through to the native `commitStyles()` when available.
 */
export function commitAnimatedStyles(element, animation) {
    if (typeof animation.commitStyles === 'function') {
        animation.commitStyles();
        return;
    }
    const effect = animation.effect;
    if (!effect || typeof effect.getKeyframes !== 'function') {
        return;
    }
    const keyframes = effect.getKeyframes();
    if (!keyframes || keyframes.length === 0) {
        return;
    }
    const endFrame = keyframes[keyframes.length - 1];
    for (const key in endFrame) {
        if (!Object.prototype.hasOwnProperty.call(endFrame, key)) continue;
        if (key === 'composite' || key === 'easing' || key === 'offset' || key === 'computedOffset') continue;
        const value = endFrame[key];
        if (value == null) continue;
        if (key.startsWith('--')) {
            element.style.setProperty(key, String(value));
        } else {
            element.style.setProperty(camelToKebab(key), String(value));
        }
    }
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

export function getAnimationProgress(animGroup, animation) {
    // Always read the LIVE per-iteration duration off the animation's own
    // effect. `resizeTransformAnimation` recreates the animation with a
    // new duration on every resize, but `groupInfo.propertyConfigs` is
    // populated only once at setup time and is never refreshed. Using the
    // cached config duration here returns
    //   (newCurrentTime % oldDuration) / oldDuration
    // after a resize — which wraps the just-seeked `currentTime` (e.g.
    // 1630 ms set against the new 2895 ms duration) back through the OLD
    // 1435 ms duration and reports 0.136 instead of 0.563. Elm then stores
    // that bogus progress and uses it on the NEXT resize, drifting the box
    // away from its true proportional position on every orientation switch.
    //
    // The animation is created with a single `duration` covering the max
    // of all sub-property durations (see `createMergedTransformAnimation`
    // and the `maxDuration` calc in `resizeTransformAnimation`), so the
    // live timing is the authoritative max-duration after any resize.
    const liveDuration = Number(animation.effect?.getTiming?.()?.duration) || 0;
    const groupInfo = animationGroups.get(animGroup);
    const fallbackDuration = groupInfo?.propertyConfigs?.length > 0
        ? Math.max(...groupInfo.propertyConfigs.map(property => property.duration))
        : 0;
    const maxDuration = liveDuration > 0 ? liveDuration : fallbackDuration;
    const currentTime = animation.currentTime || 0;
    if (maxDuration <= 0) {
        return 0;
    }
    // Per-iteration raw progress. WAAPI's `currentTime` is total elapsed time
    // across all iterations and keeps growing forever on looping animations,
    // so a naive `currentTime / maxDuration` saturates at 1.0 after the first
    // iteration and gets clamped to 1 thereafter, telling Elm the animation
    // is permanently at end-of-leg. That poisons resize math in
    // `Anim.Internal.Engine.WAAPI.applyTranslateResize` (Proportional path),
    // which computes `(oldIter + progress) * newDuration` — with a stale
    // `progress=1` it lands the new `currentTime` exactly on the next
    // iteration boundary, snapping the box to the start of the next leg.
    return (currentTime % maxDuration) / maxDuration;
}

export function getLiveTransformState(animGroup, animation, resolvedTransformValues, transformAnimDuration) {
    if (!resolvedTransformValues) {
        return lastKnownTransforms.get(animGroup) || getDefaultTransformState();
    }

    // While a freshly-created animation is in `pending` state (after
    // `element.animate(...)` but before its ready promise resolves on the
    // first compositor frame), `animation.currentTime` is null/0 even if
    // we explicitly set a target `currentTime` for resize continuity.
    // Returning the cached snapshot avoids emitting a one-frame
    // `t.x = 0` propertyUpdate that visually snaps the element to the
    // start of its keyframes before WAAPI applies the requested time.
    if (animation.playState === 'pending') {
        return lastKnownTransforms.get(animGroup) || getDefaultTransformState();
    }

    // Always read the live per-iteration duration from the effect rather
    // than relying on the duration captured at `setupAnimationEvents` time.
    // `resizeTransformAnimation` mutates the running animation in place via
    // `effect.updateTiming`, after which the captured value is stale and
    // would skew the modulo + reverse-leg math below — leaving the box at
    // the wrong position for the rest of the resized animation.
    const timing = animation.effect?.getTiming?.() || {};
    const liveDuration = Number(timing.duration) || transformAnimDuration || 0;
    const currentTime = animation.currentTime || 0;
    // Per-iteration progress: WAAPI's `currentTime` is the animation's total
    // elapsed time across all iterations, not the progress within the current
    // iteration. Without the modulo, multi-iteration animations (looping or
    // alternate) saturate `rawProgress` at 1.0 forever once `currentTime`
    // exceeds the per-iteration duration, which then poisons the snapshot
    // (especially after `flip` for alternate's reverse leg, where it would
    // collapse to 0).
    const rawProgress = liveDuration > 0
        ? ((currentTime % liveDuration) / liveDuration)
        : 0;

    // Flip progress on the reverse half of an `alternate`/`alternate-reverse`
    // iteration so the snapshot reflects the live visual position. WAAPI's
    // `currentTime` keeps marching forward each iteration, so for odd-indexed
    // alternate iterations the box is visually traveling end → start while
    // `currentTime / duration` keeps reading 0 → 1. Without this flip the
    // snapshot stays glued near `endX` for the whole reverse leg, which then
    // poisons resize math (proportional rescaling treats `oldEnd` as the
    // current position and snaps the box).
    const direction = timing.direction || 'normal';
    let animProgress = rawProgress;
    if (direction === 'alternate' || direction === 'alternate-reverse') {
        const computed = animation.effect?.getComputedTiming?.() || {};
        const iter = computed.currentIteration;
        if (Number.isFinite(iter)) {
            const startsReversed = direction === 'alternate-reverse';
            const isReverseLeg = (iter % 2 === 1) !== startsReversed;
            if (isReverseLeg) {
                animProgress = 1 - rawProgress;
            }
        }
    } else if (direction === 'reverse') {
        animProgress = 1 - rawProgress;
    }

    const transformState = computeTransformFromResolved(resolvedTransformValues, animProgress, liveDuration);
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
    // Generation and propertyIndex are looked up per-event from the
    // `elementAnims` entry instead of being captured in this closure. This
    // lets `processElementAnimation` "carry forward" still-running animations
    // into a new generation (re-keying their entry's `generation` /
    // `propertyIndex` fields) without them mistakenly failing the generation
    // check at finish/cancel time.
    function getEntry() {
        return activeAnimations.get(animGroup)?.get(propertyType);
    }
    function isActiveEntry() {
        const entry = getEntry();
        return !!entry && entry.version === version;
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
            const entry = getEntry();
            if (entry && entry.version === version) {
                updateGroupIterationState(animGroup, entry.generation, entry.propertyIndex, animation);
            }

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
            commitAnimatedStyles(element, animation);
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

        const wasActive = isActiveEntry();
        const entryGeneration = getEntry()?.generation;
        removeTrackedAnimationVersion(animGroup, propertyType, version);

        if (wasActive && entryGeneration != null && animationGroups.get(animGroup)?.generation === entryGeneration) {
            const allComplete = finalizeAnimationTracking(animGroup, entryGeneration, 'completed');
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

        const wasActive = isActiveEntry();
        const entryGeneration = getEntry()?.generation;
        removeTrackedAnimationVersion(animGroup, propertyType, version);

        if (wasActive && entryGeneration != null && animationGroups.get(animGroup)?.generation === entryGeneration) {
            const allCancelled = finalizeAnimationTracking(animGroup, entryGeneration, 'cancelled');
            const cancelTransformState = getTrackedTransformState(animGroup, resolvedTransformValues, lastComputedTransformState);
            sendTrackedPropertyUpdate(animGroup, propertyType, version, cancelTransformState, element, !allCancelled);
        }
    });

    return sendAnimationUpdate;
}
