/* eslint-env browser */
import { isTransformProperty, easingFunctions, parseIterations } from './utils.js';
import { activeAnimations, animationGroups, elementTransformOrders, cleanupAnimGroup, lastKnownTransforms } from './state.js';
import { getTransformState, getElementOrder, interpolateSubProperty, computeTransformFromResolved, buildTransformString } from './transform.js';
import { resolveNonTransformValues, createPropertyAnimation, extractPropertyConfig } from './properties.js';
import { sendLifecycleEvent } from './ports.js';
import { findAnimTarget, findAllAnimTargets } from './targets.js';
import { setupAnimationEvents } from './animationEvents.js';
import { reportError } from './errors.js';

const TRANSFORM_STATE_KEYS = {
    translate: { x: 'x', y: 'y', z: 'z' },
    scale: { x: 'scaleX', y: 'scaleY', z: 'scaleZ' },
    rotate: { x: 'rotateX', y: 'rotateY', z: 'rotateZ' },
    skew: { x: 'skewX', y: 'skewY' }
};

const START_FILL_AXES = {
    translate: [
        { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'x' },
        { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'y' },
        { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'z' }
    ],
    scale: [
        { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'scaleX' },
        { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'scaleY' },
        { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'scaleZ' }
    ],
    rotate: [
        { startKey: 'startX', defaultKey: 'defaultX', stateKey: 'rotateX' },
        { startKey: 'startY', defaultKey: 'defaultY', stateKey: 'rotateY' },
        { startKey: 'startZ', defaultKey: 'defaultZ', stateKey: 'rotateZ' }
    ],
    skew: [
        { startKey: 'startX', stateKey: 'skewX' },
        { startKey: 'startY', stateKey: 'skewY' }
    ]
};

const RESOLVED_TRANSFORM_AXES = {
    translate: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'x', useDefault: true },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'y', useDefault: true },
        { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'z', useDefault: true }
    ],
    scale: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'scaleX', useDefault: true },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'scaleY', useDefault: true },
        { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'scaleZ', useDefault: true }
    ],
    rotate: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'rotateX', useDefault: true },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'rotateY', useDefault: true },
        { suffix: 'Z', startKey: 'startZ', endKey: 'endZ', currentKey: 'rotateZ', useDefault: true }
    ],
    skew: [
        { suffix: 'X', startKey: 'startX', endKey: 'endX', currentKey: 'skewX', useDefault: false },
        { suffix: 'Y', startKey: 'startY', endKey: 'endY', currentKey: 'skewY', useDefault: false }
    ]
};

function fillMissingTransformStarts(property, currentState) {
    const axes = START_FILL_AXES[property.type];
    if (!axes) {
        return;
    }

    axes.forEach(({ startKey, defaultKey, stateKey }) => {
        const defaultMissing = !defaultKey || property[defaultKey] == null;
        if (property[startKey] == null && defaultMissing) {
            property[startKey] = currentState[stateKey];
        }
    });
}

function patchTransformStartsFromAnimation(existingTransform, mergedTransformProperties) {
    if (!existingTransform.resolvedValues || !existingTransform.animation) {
        return;
    }

    const timing = existingTransform.animation.effect?.getTiming();
    const currentTime = existingTransform.animation.currentTime || 0;
    const duration = timing?.duration || 0;
    if (duration <= 0) {
        return;
    }

    const progress = Math.min(1.0, Math.max(0.0, currentTime / duration));
    const currentState = computeTransformFromResolved(existingTransform.resolvedValues, progress, duration);
    mergedTransformProperties.forEach(property => {
        fillMissingTransformStarts(property, currentState);
    });
}

function buildRetainedTransformProperty(oldProp, currentTransform, duration) {
    const keys = TRANSFORM_STATE_KEYS[oldProp.type];
    return {
        type: oldProp.type,
        startX: currentTransform[keys.x],
        startY: currentTransform[keys.y],
        startZ: keys.z ? currentTransform[keys.z] : undefined,
        endX: currentTransform[keys.x],
        endY: currentTransform[keys.y],
        endZ: keys.z ? currentTransform[keys.z] : undefined,
        easing: oldProp.easing || 'linear',
        easingKeyframes: null,
        duration: duration,
        version: oldProp.version || 1
    };
}

function buildDefaultResolvedTransform(currentTransform) {
    return {
        translate: {
            startX: currentTransform.x, startY: currentTransform.y, startZ: currentTransform.z,
            endX: currentTransform.x, endY: currentTransform.y, endZ: currentTransform.z,
            easing: null, easingKeyframes: null, duration: 0
        },
        scale: {
            startX: currentTransform.scaleX, startY: currentTransform.scaleY, startZ: currentTransform.scaleZ,
            endX: currentTransform.scaleX, endY: currentTransform.scaleY, endZ: currentTransform.scaleZ,
            easing: null, easingKeyframes: null, duration: 0
        },
        rotate: {
            startX: currentTransform.rotateX, startY: currentTransform.rotateY, startZ: currentTransform.rotateZ,
            endX: currentTransform.rotateX, endY: currentTransform.rotateY, endZ: currentTransform.rotateZ,
            easing: null, easingKeyframes: null, duration: 0
        },
        skew: {
            startX: currentTransform.skewX, startY: currentTransform.skewY,
            endX: currentTransform.skewX, endY: currentTransform.skewY,
            easing: null, easingKeyframes: null, duration: 0
        }
    };
}

function assignResolvedTransformProperty(target, property, currentTransform, axes) {
    axes.forEach(({ suffix, startKey, endKey, currentKey, useDefault }) => {
        const defaultValue = useDefault ? property[`default${suffix}`] : undefined;
        target[startKey] = property[`start${suffix}`] ?? defaultValue ?? currentTransform[currentKey];
        target[endKey] = property[`end${suffix}`] ?? currentTransform[currentKey];
    });
    target.easing = property.easing;
    target.easingKeyframes = property.easingKeyframes;
    target.duration = property.duration;
}

function carryForwardMissingTransformProperties(animGroup, element, existingTransform, mergedTransformProperties) {
    if (!existingTransform.transformProperties) {
        return;
    }

    const newPropTypes = new Set(mergedTransformProperties.map(property => property.type));
    const currentTransform = getTransformState(animGroup, element);
    const duration = mergedTransformProperties[0]?.duration || 0;

    existingTransform.transformProperties.forEach(oldProp => {
        if (!newPropTypes.has(oldProp.type)) {
            mergedTransformProperties.push(buildRetainedTransformProperty(oldProp, currentTransform, duration));
        }
    });
}

function cancelLegacyTransformAnimations(elementAnims) {
    ['translate', 'scale', 'rotate', 'skew'].forEach(propType => {
        if (elementAnims.has(propType)) {
            const existing = elementAnims.get(propType);
            existing.animation.cancel();
            elementAnims.delete(propType);
        }
    });
}

function markAnimationGroupStarted(animGroup) {
    const groupInfo = animationGroups.get(animGroup);
    if (groupInfo && !groupInfo.started) {
        groupInfo.started = true;
        sendLifecycleEvent('started', animGroup);
    }
}

export function processElementAnimation(animGroup, elementConfig, globalOptions = { iterations: 1, direction: 'normal' }, isRestart = false, resolvedElement = null) {
    const element = resolvedElement || findAnimTarget(animGroup);
    if (!element) {
        reportError(`Element with data-anim-target="${animGroup}" not found`, {
            source: 'animation',
            severity: 'warning',
            code: 'TARGET_NOT_FOUND',
            engine: 'WAAPI',
            elementId: animGroup
        });
        return;
    }

    const properties = elementConfig.properties || [];

    const transformOrder = elementConfig.transformOrder;
    if (transformOrder && transformOrder.length > 0) {
        elementTransformOrders.set(animGroup, transformOrder);
    }

    const transformProperties = properties.filter(property => isTransformProperty(property.type));
    const nonTransformProperties = properties.filter(property => !isTransformProperty(property.type));

    if (!activeAnimations.has(animGroup)) {
        activeAnimations.set(animGroup, new Map());
    }
    const elementAnims = activeAnimations.get(animGroup);

    const existingGroup = animationGroups.get(animGroup);
    const generation = isRestart ? (existingGroup?.generation || 0) : ((existingGroup?.generation || 0) + 1);

    // Reset the group bookkeeping for the new generation. `totalProperties`,
    // `propertyIterations` and `propertyConfigs` are filled in below as new
    // animations are created and as carryover (still-running, untouched)
    // animations are re-keyed to the new generation. Without carrying forward
    // those untouched entries, the new generation's `finalizeAnimationTracking`
    // would treat itself as complete as soon as the new (often very short)
    // animations finish - and `cleanupAnimGroup` would then wipe the still-
    // running animations' bookkeeping, freezing the per-frame propertyUpdate
    // values Elm uses for snapshot baselines.
    animationGroups.set(animGroup, {
        totalProperties: 0,
        completedProperties: 0,
        started: false,
        generation: generation,
        nextPropertyIndex: 0,
        lastIteration: 0,
        propertyIterations: [],
        propertyConfigs: []
    });

    if (transformProperties.length > 0) {
        const mergedTransformProperties = [...transformProperties];

        if (elementAnims.has('transform')) {
            const existingTransform = elementAnims.get('transform');
            patchTransformStartsFromAnimation(existingTransform, mergedTransformProperties);
            carryForwardMissingTransformProperties(animGroup, element, existingTransform, mergedTransformProperties);
            existingTransform.animation.cancel();
        }

        cancelLegacyTransformAnimations(elementAnims);

        const maxVersion = Math.max(...mergedTransformProperties.map(property => property.version || 1));
        const mergeResult = createMergedTransformAnimation(animGroup, element, mergedTransformProperties, globalOptions);

        if (mergeResult) {
            const { animation, resolved: resolvedTransformValues } = mergeResult;
            const entry = {
                animation: animation,
                version: maxVersion,
                animGroup: animGroup,
                easingKeyframes: null,
                transformProperties: mergedTransformProperties,
                resolvedValues: resolvedTransformValues,
                generation: generation,
                propertyIndex: allocatePropertyIndex(animGroup)
            };
            elementAnims.set('transform', entry);
            entry.updateFn = setupAnimationEvents(animGroup, 'transform', element, animation, maxVersion, resolvedTransformValues);

            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                transformProperties.forEach(property => {
                    groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
                });
            }

            markAnimationGroupStarted(animGroup);
        }
    }

    nonTransformProperties.forEach(property => {
        const propType = (property.type === 'customProperty')
            ? `custom:${property.cssProperty}`
            : (property.type === 'customColorProperty')
                ? `customColor:${property.cssProperty}`
                : property.type;
        const newVersion = property.version || 1;

        if (elementAnims.has(propType)) {
            elementAnims.get(propType).animation.cancel();
        }

        const resolvedNonTransform = resolveNonTransformValues(animGroup, element, property);
        const animation = createPropertyAnimation(element, resolvedNonTransform, property, globalOptions);

        if (animation) {
            const entry = {
                animation: animation,
                version: newVersion,
                animGroup: animGroup,
                easingKeyframes: property.easingKeyframes || null,
                resolvedNonTransform: resolvedNonTransform,
                generation: generation,
                propertyIndex: allocatePropertyIndex(animGroup)
            };
            elementAnims.set(propType, entry);
            entry.updateFn = setupAnimationEvents(animGroup, propType, element, animation, newVersion, null);

            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
            }

            markAnimationGroupStarted(animGroup);
        }
    });

    // Carry forward any entries that this call did not supersede so that the
    // new generation accounts for them. They were created in a previous
    // generation; without re-keying, their `finish`/`cancel` handlers would
    // skip `finalizeAnimationTracking` (generation mismatch) and the new
    // generation's totals would be wrong.
    elementAnims.forEach(entry => {
        if (entry.generation !== generation) {
            entry.generation = generation;
            entry.propertyIndex = allocatePropertyIndex(animGroup);
            const carryDuration = entry.animation?.effect?.getTiming()?.duration || 0;
            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                groupInfo.propertyConfigs.push({ duration: carryDuration });
            }
        }
    });

    const finalGroupInfo = animationGroups.get(animGroup);
    if (finalGroupInfo) {
        finalGroupInfo.totalProperties = elementAnims.size;
        finalGroupInfo.propertyIterations = new Array(elementAnims.size).fill(0);
    }

    if (elementAnims.size === 0) {
        cleanupAnimGroup(animGroup);
    }
}

function allocatePropertyIndex(animGroup) {
    const groupInfo = animationGroups.get(animGroup);
    if (!groupInfo) return 0;
    const index = groupInfo.nextPropertyIndex;
    groupInfo.nextPropertyIndex++;
    return index;
}

function createMergedTransformAnimation(animGroup, element, transformProperties, globalOptions = { iterations: 1, direction: 'normal' }) {
    const currentTransform = getTransformState(animGroup, element);
    const order = getElementOrder(element);
    const resolved = buildDefaultResolvedTransform(currentTransform);

    let maxDuration = 0;

    transformProperties.forEach(property => {
        const target = resolved[property.type];
        const axes = RESOLVED_TRANSFORM_AXES[property.type];
        if (target && axes) {
            assignResolvedTransformProperty(target, property, currentTransform, axes);
        }
        if (property.duration > maxDuration) {
            maxDuration = property.duration;
        }
    });

    const activeProps = transformProperties.map(property => resolved[property.type]);
    const allSameEasing = activeProps.every(item => !item.easingKeyframes && item.easing === activeProps[0].easing);
    const allSameDuration = activeProps.every(item => item.duration === activeProps[0].duration);

    if (allSameEasing && allSameDuration) {
        const startTransform = buildTransformString(
            resolved.translate.startX, resolved.translate.startY, resolved.translate.startZ,
            resolved.scale.startX, resolved.scale.startY, resolved.scale.startZ,
            resolved.rotate.startX, resolved.rotate.startY, resolved.rotate.startZ,
            resolved.skew.startX, resolved.skew.startY, order
        );
        const endTransform = buildTransformString(
            resolved.translate.endX, resolved.translate.endY, resolved.translate.endZ,
            resolved.scale.endX, resolved.scale.endY, resolved.scale.endZ,
            resolved.rotate.endX, resolved.rotate.endY, resolved.rotate.endZ,
            resolved.skew.endX, resolved.skew.endY, order
        );

        const easing = activeProps[0].easing;
        const animationEasing = easingFunctions[easing] || easing;

        return {
            animation: element.animate([
                { transform: startTransform },
                { transform: endTransform }
            ], {
                duration: maxDuration,
                easing: animationEasing,
                fill: 'forwards',
                iterations: globalOptions.iterations,
                direction: globalOptions.direction
            }),
            resolved: resolved
        };
    }

    const KEYFRAME_COUNT = 30;
    const keyframes = [];

    for (let index = 0; index < KEYFRAME_COUNT; index++) {
        const globalProgress = index / (KEYFRAME_COUNT - 1);
        const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
        const interpScale = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
        const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
        const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);

        keyframes.push({
            transform: buildTransformString(
                interpTranslate.x, interpTranslate.y, interpTranslate.z,
                interpScale.x, interpScale.y, interpScale.z,
                interpRotate.x, interpRotate.y, interpRotate.z,
                interpSkew.x, interpSkew.y, order
            )
        });
    }

    return {
        animation: element.animate(keyframes, {
            duration: maxDuration,
            easing: 'linear',
            fill: 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        }),
        resolved: resolved
    };
}

/**
 * Persist a resized translate or scale value into the `lastKnownTransforms`
 * cache so subsequent `getTransformState` lookups (during further resizes
 * or as the start-state seed for the next `WAAPI.animate` cycle) reflect
 * the resized value rather than the pre-resize value.
 *
 * The element's inline `style.transform` is intentionally not written here:
 * Elm's `WAAPI.attributes` already re-renders the new transform inline from
 * the snapshot updated by `applyScaleResize` / `applyTranslateResize`.
 * Writing it from JS as well would be redundant and could interfere with
 * an in-flight transform animation by triggering a style/layout
 * invalidation mid-cycle.
 */
function persistResizedTransform(animGroup, element, propertyKey, currentResized) {
    const current = getTransformState(animGroup, element);
    const updated = { ...current };
    if (propertyKey === 'scale') {
        updated.scaleX = currentResized.x;
        updated.scaleY = currentResized.y;
        updated.scaleZ = currentResized.z;
    } else {
        updated.x = currentResized.x;
        updated.y = currentResized.y;
        updated.z = currentResized.z;
    }
    lastKnownTransforms.set(animGroup, updated);
}

/**
 * Update the in-flight transform animation for a group's translate sub-property
 * to match new bounds, without restarting. Replaces the underlying
 * `Animation` with one that has the new keyframes/timing, then sets
 * `currentTime` so the box continues moving smoothly from where it is.
 *
 * Triggered by Elm `Anim.Engine.WAAPI.onResize`. The Elm side has already
 * computed the new translate `start` / `end` / `current` values, the new
 * leg duration, the resize `strategy`, and the `currentTime` to set —
 * see `Anim.Internal.Engine.WAAPI.computeResizePayload` and
 * `Anim.Internal.Engine.WAAPI.scaleDurationForResize` for the math.
 *
 * Strategy branches when seeking `currentTime`:
 * - `proportional` preserves the temporal progress ratio
 *   (`currentTime / duration`) so the eased visual position lands at the
 *   same fractional spot along the new leg, exactly, for any easing.
 * - `clamp` (and any unknown / missing value, for back-compat) solves
 *   for the `currentTime` that places the box at the Elm-supplied
 *   `currentX/Y/Z` value via a linear inversion of the leg span.
 *
 * Non-translate transform sub-properties (rotate, scale, skew) are
 * preserved at their current resolved values.
 *
 * @param {object} commandData - Decoded `resize` port command payload.
 */
export function resizeTransformAnimation(commandData) {
    const animGroup = commandData.elementId || commandData.animGroup;
    if (!animGroup) {
        reportError('resize command missing elementId/animGroup', {
            source: 'animation',
            severity: 'warning',
            code: 'COMMAND_INVALID',
            engine: 'WAAPI'
        });
        return;
    }

    const element = findAnimTarget(animGroup);
    if (!element) {
        reportError(`Element with data-anim-target="${animGroup}" not found`, {
            source: 'animation',
            severity: 'warning',
            code: 'TARGET_NOT_FOUND',
            engine: 'WAAPI',
            elementId: animGroup
        });
        return;
    }

    const propertyKey = commandData.property === 'scale' ? 'scale' : 'translate';

    // Authoritative "current" position the box should occupy after resize.
    // Elm always supplies currentX/Y/Z; fall back to endX/Y/Z for older callers.
    const currentResized = {
        x: commandData.currentX !== undefined ? Number(commandData.currentX) : Number(commandData.endX),
        y: commandData.currentY !== undefined ? Number(commandData.currentY) : Number(commandData.endY),
        z: commandData.currentZ !== undefined ? Number(commandData.currentZ) : Number(commandData.endZ)
    };

    // Persist the resized values into lastKnownTransforms and inline style so
    // they survive across animation cleanup boundaries. The inline transform
    // is shadowed while a transform animation is running, but takes effect
    // the moment the animation is cancelled or finishes without `fill`,
    // ensuring the next `WAAPI.animate` cycle reads the resized values as its
    // start. Also handles the no-active-animation case directly.
    persistResizedTransform(animGroup, element, propertyKey, currentResized);

    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims || !elementAnims.has('transform')) {
        return;
    }

    const existing = elementAnims.get('transform');
    const resolved = existing.resolvedValues;
    if (!resolved || !resolved[propertyKey]) {
        return;
    }

    const animation = existing.animation;
    if (!animation || !animation.effect) {
        return;
    }

    // Read the live pre-resize state. WAAPI preserves `currentIteration`
    // and direction across `setKeyframes` / `updateTiming`, so all we need
    // to preserve manually is the box's target physical position. Elm
    // computes that target via `Resize.applyAxis` (honouring Proportional
    // vs Clamp) and ships it as `currentX/Y/Z` in the payload — JS must
    // solve for the `currentTime` that lands the box at that target,
    // otherwise the strategy choice is silently overridden.
    const oldTiming = animation.effect.getTiming() || {};
    const oldDuration = Number(oldTiming.duration) || 0;
    const oldCurrentTime = Number(animation.currentTime) || 0;
    const oldDirection = oldTiming.direction || 'normal';

    // Strategy-aware target position from Elm. Falls back to the box's
    // current physical position derived from the running animation if the
    // payload omits it (older callers / safety).
    let targetPosition = null;
    if (commandData.currentX !== undefined
        && commandData.currentY !== undefined
        && commandData.currentZ !== undefined) {
        targetPosition = {
            x: Number(commandData.currentX),
            y: Number(commandData.currentY),
            z: Number(commandData.currentZ)
        };
    } else if (oldDuration > 0) {
        const oldRawProgress = (oldCurrentTime % oldDuration) / oldDuration;
        let oldLegProgress = oldRawProgress;
        if (oldDirection === 'alternate' || oldDirection === 'alternate-reverse') {
            const computed = animation.effect.getComputedTiming?.() || {};
            const iter = computed.currentIteration;
            if (Number.isFinite(iter)) {
                const startsReversed = oldDirection === 'alternate-reverse';
                const isReverseLeg = (iter % 2 === 1) !== startsReversed;
                if (isReverseLeg) {
                    oldLegProgress = 1 - oldRawProgress;
                }
            }
        } else if (oldDirection === 'reverse') {
            oldLegProgress = 1 - oldRawProgress;
        }
        targetPosition = interpolateSubProperty(resolved[propertyKey], oldLegProgress, oldDuration);
    }

    // Patch the resized property slot with the Elm-supplied new bounds.
    // Other transform sub-properties keep their existing resolved values
    // so a resize on one property does not disturb the others.
    const newDuration = Number(commandData.duration) || oldDuration;
    resolved[propertyKey] = {
        startX: Number(commandData.startX),
        startY: Number(commandData.startY),
        startZ: Number(commandData.startZ),
        endX: Number(commandData.endX),
        endY: Number(commandData.endY),
        endZ: Number(commandData.endZ),
        easing: resolved[propertyKey].easing,
        easingKeyframes: resolved[propertyKey].easingKeyframes,
        duration: newDuration
    };

    const order = getElementOrder(element);

    // Build a 30-frame interpolated transform so non-linear timing on
    // co-running rotate/scale/skew is preserved. This mirrors the
    // multi-easing branch of createMergedTransformAnimation.
    const KEYFRAME_COUNT = 30;
    const keyframes = [];
    for (let index = 0; index < KEYFRAME_COUNT; index++) {
        const globalProgress = index / (KEYFRAME_COUNT - 1);
        const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, newDuration);
        const interpScale = interpolateSubProperty(resolved.scale, globalProgress, newDuration);
        const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, newDuration);
        const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, newDuration);

        keyframes.push({
            transform: buildTransformString(
                interpTranslate.x, interpTranslate.y, interpTranslate.z,
                interpScale.x, interpScale.y, interpScale.z,
                interpRotate.x, interpRotate.y, interpRotate.z,
                interpSkew.x, interpSkew.y, order
            )
        });
    }

    // In-place mutation: replace keyframes and (if changed) timing on the
    // running Animation. WAAPI preserves `playState`, `currentIteration`,
    // and the alternating-leg phase across these calls, so the box keeps
    // moving without a one-frame snap to keyframe[0]. No cancel, no
    // `element.animate()` recreate, no version bump, no resetup of event
    // listeners — the existing RAF loop continues against the same
    // Animation instance and keeps emitting `propertyUpdate` cleanly.
    try {
        animation.effect.setKeyframes(keyframes);
    } catch (err) {
        reportError(`setKeyframes failed during resize: ${err && err.message ? err.message : err}`, {
            source: 'animation',
            severity: 'warning',
            code: 'RESIZE_SET_KEYFRAMES_FAILED',
            engine: 'WAAPI',
            elementId: animGroup
        });
    }

    // When Elm has no animation baseline for the resized property (init-only
    // value, e.g. `Scale.init` alongside a Rotate animation), the resize is
    // a "snapshot bake": we only want to splice the new value into the
    // running transform animation's keyframes so it stays visually current.
    // Touching `effect.updateTiming` or `animation.currentTime` here would
    // restart the unrelated property's animation (rotate, etc.) because the
    // synthesized baseline carries `duration=0` / `currentTimeMs=0`.
    if (commandData.hasAnimationBaseline === false) {
        return;
    }

    if (newDuration > 0 && newDuration !== oldDuration) {
        try {
            animation.effect.updateTiming({ duration: newDuration });
        } catch (err) {
            reportError(`updateTiming failed during resize: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'warning',
                code: 'RESIZE_UPDATE_TIMING_FAILED',
                engine: 'WAAPI',
                elementId: animGroup
            });
        }
    }

    // Seek the animation's currentTime. Two paths:
    //
    // - Elm-supplied `currentTimeMs` (Proportional strategy): Elm has the
    //   authoritative answer (preserve full-iteration count + in-iteration
    //   progress for looping legs, restart from `0` for the collapsed
    //   one-shot leg). We just apply it.
    //
    // - Fallback (Clamp strategy / `currentTimeMs == null`): solve for
    //   the currentTime that places the box at the strategy-aware target
    //   position Elm computed via `Resize.applyAxis`. WAAPI's
    //   `currentIteration` is preserved across `updateTiming`, so we keep
    //   the same iteration index and only adjust the in-iteration time.
    //   For a 1D translate (the common resize case) this is exact for
    //   Linear easing and approximate for non-linear, matching Clamp's
    //   "preserve current value" promise.
    const elmCurrentTimeMs = commandData.currentTimeMs;
    if (typeof elmCurrentTimeMs === 'number' && isFinite(elmCurrentTimeMs)) {
        try {
            animation.currentTime = elmCurrentTimeMs;
        } catch (err) {
            reportError(`currentTime assignment failed during resize: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'warning',
                code: 'RESIZE_CURRENT_TIME_FAILED',
                engine: 'WAAPI',
                elementId: animGroup
            });
        }
    } else if (targetPosition !== null && newDuration > 0 && oldDuration > 0) {
        const newStartX = Number(commandData.startX);
        const newEndX = Number(commandData.endX);
        const newSpanX = newEndX - newStartX;
        let pWanted = 0;
        if (Math.abs(newSpanX) > 0.0001) {
            pWanted = (targetPosition.x - newStartX) / newSpanX;
        }
        // Clamp to a sane range — past-end positions can occur when the new
        // bounds shrink below the current physical position; let the next
        // frame ease toward the end rather than seeking past iteration end.
        if (pWanted < 0) pWanted = 0;
        if (pWanted > 1) pWanted = 1;

        // Honour the current leg's direction so we map the desired physical
        // progress back to the right side of an alternate iteration. We
        // MUST compute leg parity from the *old* timing — `updateTiming`
        // above already mutated `effect.duration`, so reading
        // `getComputedTiming().currentIteration` now would divide the still
        // unchanged `oldCurrentTime` by `newDuration` and report the wrong
        // iteration index (e.g. iter=1 reverse leg flipping to iter=2
        // forward leg whenever newDuration < oldDuration), which causes a
        // visible jump on every reverse-leg resize.
        const newDirection = (animation.effect.getTiming?.() || {}).direction || oldDirection;
        const oldIter = Math.floor(oldCurrentTime / oldDuration);
        let pWithinIter = pWanted;
        if (newDirection === 'alternate' || newDirection === 'alternate-reverse') {
            const startsReversed = newDirection === 'alternate-reverse';
            const isReverseLeg = (oldIter % 2 === 1) !== startsReversed;
            if (isReverseLeg) {
                pWithinIter = 1 - pWanted;
            }
        } else if (newDirection === 'reverse') {
            pWithinIter = 1 - pWanted;
        }

        // Preserve full-iterations count so looping/alternate keep advancing
        // through the right iteration index after the resize.
        const newCurrentTime = (oldIter + pWithinIter) * newDuration;
        try {
            animation.currentTime = newCurrentTime;
        } catch (err) {
            reportError(`currentTime assignment failed during resize: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'warning',
                code: 'RESIZE_CURRENT_TIME_FAILED',
                engine: 'WAAPI',
                elementId: animGroup
            });
        }
    }
}

export function processAnimationData(animationData) {
    if (!animationData || !animationData.elements) {
        reportError('Invalid animation data format received', {
            source: 'animation',
            severity: 'warning',
            code: 'COMMAND_INVALID',
            engine: 'WAAPI'
        });
        return;
    }

    const globalOptions = {
        iterations: parseIterations(animationData.iterations),
        direction: animationData.direction || 'normal'
    };
    const isRestart = animationData.isRestart || false;

    Object.entries(animationData.elements).forEach(([animGroup, elementConfig]) => {
        const targets = findAllAnimTargets(animGroup);
        if (targets.length <= 1) {
            processElementAnimation(animGroup, elementConfig, globalOptions, isRestart);
            return;
        }

        targets.forEach((element, index) => {
            const uniqueId = element.id || (animGroup + '__multi_' + index);
            processElementAnimation(uniqueId, elementConfig, globalOptions, isRestart, element);
        });
    });
}
