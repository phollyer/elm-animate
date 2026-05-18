/* eslint-env browser */
import { isTransformProperty, easingFunctions, parseIterations } from './utils.js';
import { activeAnimations, animationGroups, elementTransformOrders, cleanupAnimGroup, lastKnownTransforms } from './state.js';
import { getTransformState, getElementOrder, interpolateSubProperty, computeTransformFromResolved, buildTransformString, getDefaultTransformState } from './transform.js';
import { resolveNonTransformValues, createPropertyAnimation, extractPropertyConfig, buildPropertyKeyframes } from './properties.js';
import { sendLifecycleEvent } from './ports.js';
import { findAnimTarget, findAllAnimTargets } from './targets.js';
import { setupAnimationEvents } from './animationEvents.js';
import { reportError } from './errors.js';

function isFiniteNumber(value) {
    return typeof value === 'number' && Number.isFinite(value);
}

function distance3(a, b) {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    const dz = a.z - b.z;
    return Math.sqrt(dx * dx + dy * dy + dz * dz);
}

function distance2(a, b) {
    const dx = a.x - b.x;
    const dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
}

function isSuspiciousResetToZero(elmCurrentTimeMs, oldCurrentTime, startPoint, currentPoint) {
    if (!(typeof elmCurrentTimeMs === 'number' && isFinite(elmCurrentTimeMs) && elmCurrentTimeMs === 0)) {
        return false;
    }

    if (!isFiniteNumber(oldCurrentTime) || oldCurrentTime <= 0) {
        return false;
    }

    if (!startPoint || !currentPoint) {
        return false;
    }

    const hasZ = isFiniteNumber(startPoint.z) && isFiniteNumber(currentPoint.z);
    const distanceFromStart = hasZ
        ? distance3(startPoint, currentPoint)
        : distance2(startPoint, currentPoint);

    // Ignore zero-time resets when the target is clearly not at leg start.
    return distanceFromStart > 0.5;
}

function isSuspiciousZeroFromContinuity(elmCurrentTimeMs, oldCurrentTime, oldVisualPoint, currentPoint) {
    if (!(typeof elmCurrentTimeMs === 'number' && isFinite(elmCurrentTimeMs) && elmCurrentTimeMs === 0)) {
        return false;
    }

    if (!isFiniteNumber(oldCurrentTime) || oldCurrentTime <= 0) {
        return false;
    }

    if (!oldVisualPoint || !currentPoint) {
        return false;
    }

    const hasZ = isFiniteNumber(oldVisualPoint.z) && isFiniteNumber(currentPoint.z);
    const continuityDistance = hasZ
        ? distance3(oldVisualPoint, currentPoint)
        : distance2(oldVisualPoint, currentPoint);

    // If resize target is still very close to the pre-resize visual position,
    // forcing currentTime=0 is almost certainly an unintended restart.
    return continuityDistance <= 12;
}

function computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation) {
    if (!isFiniteNumber(oldCurrentTime) || !isFiniteNumber(oldDuration) || oldDuration <= 0) {
        return null;
    }

    const oldRawProgress = (oldCurrentTime % oldDuration) / oldDuration;
    let oldLegProgress = oldRawProgress;
    if (oldDirection === 'alternate' || oldDirection === 'alternate-reverse') {
        const computed = animation?.effect?.getComputedTiming?.() || {};
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

    return oldLegProgress;
}

function scaleCurrentTimeForResize(oldCurrentTime, oldDuration, newDuration) {
    if (!isFiniteNumber(oldCurrentTime)
        || !isFiniteNumber(oldDuration)
        || !isFiniteNumber(newDuration)
        || oldDuration <= 0
        || newDuration <= 0) {
        return null;
    }

    return (oldCurrentTime / oldDuration) * newDuration;
}

function axisBoundsChanged(oldStart, oldEnd, newStart, newEnd, epsilon = 0.001) {
    return Math.abs(oldStart - newStart) > epsilon || Math.abs(oldEnd - newEnd) > epsilon;
}

function chooseEffectiveAxisValue(oldStart, oldEnd, newStart, newEnd, commandValue, liveValue) {
    if (!isFiniteNumber(liveValue)) {
        return commandValue;
    }

    return axisBoundsChanged(oldStart, oldEnd, newStart, newEnd)
        ? commandValue
        : liveValue;
}

function chooseDominantAxis(spans, epsilon = 0.0001) {
    let chosenAxis = null;
    let maxAbsSpan = epsilon;

    ['x', 'y', 'z'].forEach((axis) => {
        const span = Number(spans[axis]);
        const absSpan = Math.abs(span);
        if (isFiniteNumber(span) && absSpan > maxAbsSpan) {
            chosenAxis = axis;
            maxAbsSpan = absSpan;
        }
    });

    return chosenAxis;
}

function sanitizeResizeDuration(candidateDuration, oldDuration) {
    if (!isFiniteNumber(candidateDuration) || candidateDuration <= 0) {
        return oldDuration;
    }

    if (!isFiniteNumber(oldDuration) || oldDuration <= 0) {
        return candidateDuration;
    }

    const maxDuration = oldDuration * 8;

    // Keep lower durations untouched - end-of-leg resizes legitimately
    // shorten the remaining leg time. Clamp only implausible huge jumps.
    if (candidateDuration > maxDuration) {
        return oldDuration;
    }

    return candidateDuration;
}

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

/**
 * Determine which transform sub-property groups must be force-emitted in
 * every keyframe of a WAAPI animation. Returns a Set containing any of
 * `'translate' | 'scale' | 'rotate' | 'skew'`.
 *
 * WAAPI requires every keyframe in an animation to list the same set of
 * transform functions to interpolate per-function (e.g. animating
 * `rotateX` directly). If keyframes differ, the browser falls back to
 * matrix3d decomposition, which silently drops rotation when either
 * endpoint produces an identity rotation matrix (e.g. `rotateX(360deg)`
 * decomposes to identity). The fix is to force-emit a group on every
 * keyframe whenever any endpoint of the resolved animation is non-identity
 * for that group, so the function lists match across all keyframes.
 */
function computeForceGroups(resolved) {
    const force = new Set();
    const isAxisActive = (group, identity, axes) => {
        const value = resolved[group];
        if (!value) return false;
        for (const axis of axes) {
            const start = value[`start${axis}`];
            const end = value[`end${axis}`];
            if (Number.isFinite(start) && start !== identity) return true;
            if (Number.isFinite(end) && end !== identity) return true;
        }
        return false;
    };
    if (isAxisActive('translate', 0, ['X', 'Y', 'Z'])) force.add('translate');
    if (isAxisActive('scale', 1, ['X', 'Y', 'Z'])) force.add('scale');
    if (isAxisActive('rotate', 0, ['X', 'Y', 'Z'])) force.add('rotate');
    if (isAxisActive('skew', 0, ['X', 'Y'])) force.add('skew');
    return force;
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

/**
 * Convert the Elm-side `transformBaseline` payload (a snapshot of init/runtime
 * baseline values for translate, scale, rotate, skew) into the flat
 * transform-state shape used by `lastKnownTransforms`. Missing axes fall back
 * to identity defaults.
 */
function baselineToTransformState(baseline) {
    const state = getDefaultTransformState();
    if (!baseline) {
        return state;
    }
    const num = (v, fallback) => Number.isFinite(v) ? v : fallback;
    if (baseline.translate) {
        state.x = num(baseline.translate.x, state.x);
        state.y = num(baseline.translate.y, state.y);
        state.z = num(baseline.translate.z, state.z);
    }
    if (baseline.scale) {
        state.scaleX = num(baseline.scale.x, state.scaleX);
        state.scaleY = num(baseline.scale.y, state.scaleY);
        state.scaleZ = num(baseline.scale.z, state.scaleZ);
    }
    if (baseline.rotate) {
        state.rotateX = num(baseline.rotate.x, state.rotateX);
        state.rotateY = num(baseline.rotate.y, state.rotateY);
        state.rotateZ = num(baseline.rotate.z, state.rotateZ);
    }
    if (baseline.skew) {
        state.skewX = num(baseline.skew.x, state.skewX);
        state.skewY = num(baseline.skew.y, state.skewY);
    }
    return state;
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

    // Seed `lastKnownTransforms` from the Elm-side snapshot baseline before
    // any keyframes are computed. This ensures init-only transform values
    // (e.g. `Translate.initZ animGroup 200`) survive the moment Elm hands
    // ownership of the inline `transform` style to JS — without this,
    // `getTransformState` would fall back to reading the (now-empty)
    // inline transform and silently default missing axes to identity.
    // We only seed when the cache is empty for this animGroup, so that
    // post-animation `commitStyles` results from prior generations remain
    // authoritative.
    if (elementConfig.transformBaseline && !lastKnownTransforms.has(animGroup)) {
        lastKnownTransforms.set(animGroup, baselineToTransformState(elementConfig.transformBaseline));
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

    const forceGroups = computeForceGroups(resolved);

    if (allSameEasing && allSameDuration) {
        const startTransform = buildTransformString(
            resolved.translate.startX, resolved.translate.startY, resolved.translate.startZ,
            resolved.scale.startX, resolved.scale.startY, resolved.scale.startZ,
            resolved.rotate.startX, resolved.rotate.startY, resolved.rotate.startZ,
            resolved.skew.startX, resolved.skew.startY, order, forceGroups
        );
        const endTransform = buildTransformString(
            resolved.translate.endX, resolved.translate.endY, resolved.translate.endZ,
            resolved.scale.endX, resolved.scale.endY, resolved.scale.endZ,
            resolved.rotate.endX, resolved.rotate.endY, resolved.rotate.endZ,
            resolved.skew.endX, resolved.skew.endY, order, forceGroups
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
                interpSkew.x, interpSkew.y, order, forceGroups
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
 * cache and into the element's inline `style.transform`.
 *
 * Inline write rationale: once any transform sub-property is animated by
 * WAAPI, the transform slot is "JS-owned" and Elm's `WAAPI.attributes`
 * stops rendering inline `transform` to avoid fighting the running
 * animation. That means JS is now the sole writer for inline `transform`,
 * and resize must update it so the resized value is visible after the
 * animation finishes/cancels (and so the DOM truthfully reflects the
 * post-resize state in devtools). While an animation is running, WAAPI
 * fully shadows the inline value, so this write is invisible until the
 * animation releases the slot — exactly when we need it.
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

    const order = getElementOrder(element);
    const transformString = buildTransformString(
        updated.x, updated.y, updated.z,
        updated.scaleX, updated.scaleY, updated.scaleZ,
        updated.rotateX, updated.rotateY, updated.rotateZ,
        updated.skewX, updated.skewY, order
    );
    element.style.transform = transformString;
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
 * Resize commands arrive at native input cadence (often 30+ per displayed
 * frame during a drag-resize). We coalesce them via `requestAnimationFrame`
 * so each unique `(animGroup, property)` does at most one cancel+recreate
 * per displayed frame. Without coalescing, the dot's compositor layer
 * spends most of each frame snapped to its base transform during the brief
 * gap between `animation.cancel()` and the new `Animation` being committed,
 * which visually freezes the dot during the drag.
 *
 * Tests bypass coalescing by importing `_resizeTransformAnimationImmediate`
 * directly (see `js/tests/resize.test.js`).
 *
 * @param {object} commandData - Decoded `resize` port command payload.
 */
export function resizeTransformAnimation(commandData) {
    scheduleResize(commandData);
}

/**
 * Per-frame resize coalescing. Keyed by `${animGroup}:${property || 'translate'}`
 * so commands targeting different properties of the same element do not
 * stomp each other. Only the latest payload per key per frame is applied.
 */
const pendingResizes = new Map();
let pendingResizeFrame = null;

function scheduleResize(commandData) {
    const animGroup = commandData.elementId || commandData.animGroup;
    if (!animGroup) {
        // Let the immediate path emit the missing-id error so behaviour
        // matches pre-coalescing tests and runtime diagnostics.
        _resizeTransformAnimationImmediate(commandData);
        return;
    }
    const key = `${animGroup}:${commandData.property || 'translate'}`;
    pendingResizes.set(key, commandData);

    const raf = typeof globalThis !== 'undefined' && typeof globalThis.requestAnimationFrame === 'function'
        ? globalThis.requestAnimationFrame
        : null;
    if (raf === null) {
        // No rAF (non-browser host) — flush synchronously to preserve behaviour.
        flushPendingResizes();
        return;
    }
    if (pendingResizeFrame !== null) {
        return;
    }
    pendingResizeFrame = raf(() => {
        pendingResizeFrame = null;
        flushPendingResizes();
    });
}

/**
 * Drain the coalesced resize queue immediately. Exported so tests and
 * shutdown paths can force a flush without waiting for a rAF tick.
 */
export function flushPendingResizes() {
    if (pendingResizes.size === 0) {
        return;
    }
    const batch = Array.from(pendingResizes.values());
    pendingResizes.clear();
    for (const payload of batch) {
        try {
            _resizeTransformAnimationImmediate(payload);
        } catch (err) {
            reportError(`resize flush failed: ${err && err.message ? err.message : err}`, {
                source: 'animation',
                severity: 'error',
                code: 'COMMAND_FAILED',
                engine: 'WAAPI'
            });
        }
    }
}

/**
 * Synchronous resize worker. Direct callers (tests, `flushPendingResizes`)
 * use this to bypass the per-frame coalescing layer.
 *
 * @param {object} commandData - Decoded `resize` port command payload.
 */
export function _resizeTransformAnimationImmediate(commandData) {
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

    if (commandData.property === 'perspectiveOrigin') {
        resizePerspectiveOriginAnimation(commandData, animGroup, element);
        return;
    }

    const propertyKey = commandData.property === 'scale' ? 'scale' : 'translate';

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
    const oldLegProgress = computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation);

    // Strategy-aware target position from Elm. Falls back to the box's
    // current physical position derived from the running animation if the
    // payload omits it (older callers / safety).
    const hasCurrentFromCommand = commandData.currentX !== undefined
        && commandData.currentY !== undefined
        && commandData.currentZ !== undefined;
    const oldVisualPosition = oldLegProgress !== null
        ? interpolateSubProperty(resolved[propertyKey], oldLegProgress, oldDuration)
        : null;

    const hasElmCurrentTime = typeof commandData.currentTimeMs === 'number' && isFinite(commandData.currentTimeMs);

    let targetPosition = null;
    if (!hasElmCurrentTime && oldVisualPosition) {
        targetPosition = {
            x: chooseEffectiveAxisValue(
                Number(resolved[propertyKey].startX),
                Number(resolved[propertyKey].endX),
                Number(commandData.startX),
                Number(commandData.endX),
                hasCurrentFromCommand ? Number(commandData.currentX) : oldVisualPosition.x,
                oldVisualPosition.x
            ),
            y: chooseEffectiveAxisValue(
                Number(resolved[propertyKey].startY),
                Number(resolved[propertyKey].endY),
                Number(commandData.startY),
                Number(commandData.endY),
                hasCurrentFromCommand ? Number(commandData.currentY) : oldVisualPosition.y,
                oldVisualPosition.y
            ),
            z: chooseEffectiveAxisValue(
                Number(resolved[propertyKey].startZ),
                Number(resolved[propertyKey].endZ),
                Number(commandData.startZ),
                Number(commandData.endZ),
                hasCurrentFromCommand ? Number(commandData.currentZ) : oldVisualPosition.z,
                oldVisualPosition.z
            )
        };
    } else if (hasCurrentFromCommand) {
        targetPosition = {
            x: Number(commandData.currentX),
            y: Number(commandData.currentY),
            z: Number(commandData.currentZ)
        };
    } else if (oldVisualPosition) {
        targetPosition = oldVisualPosition;
    }

    const currentResized = targetPosition || {
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

    // Patch the resized property slot with the Elm-supplied new bounds.
    // Other transform sub-properties keep their existing resolved values
    // so a resize on one property does not disturb the others.
    //
    // `hasAnimationBaseline === false` means Elm has no real animation for
    // this property (e.g. `Scale.init` paired with `Scale.onResize` while
    // a Rotate animation runs). The payload's `duration` is a synthetic
    // snapshot-bake value; using it would shrink the resized slot's
    // duration and (worse) starve the keyframe sampling for co-running
    // properties. Preserve the previous slot duration in that case.
    const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
    const hasBaseline = commandData.hasAnimationBaseline !== false;
    const newDuration = hasBaseline ? payloadDuration : oldDuration;
    const previousSlotDuration = resolved[propertyKey].duration;
    resolved[propertyKey] = {
        startX: Number(commandData.startX),
        startY: Number(commandData.startY),
        startZ: Number(commandData.startZ),
        endX: Number(commandData.endX),
        endY: Number(commandData.endY),
        endZ: Number(commandData.endZ),
        easing: resolved[propertyKey].easing,
        easingKeyframes: resolved[propertyKey].easingKeyframes,
        duration: hasBaseline ? payloadDuration : previousSlotDuration
    };

    const order = getElementOrder(element);

    // Build a 30-frame interpolated transform so non-linear timing on
    // co-running rotate/scale/skew is preserved. This mirrors the
    // multi-easing branch of createMergedTransformAnimation, which
    // samples every sub-property against the *maximum* duration across
    // all sub-properties — using a single sub-property's duration here
    // (e.g. the resized one) would scale the others' progress by
    // `subProp.duration / chosenDuration`, freezing co-running long
    // animations like an 8000 ms rotate when a 300 ms scale resizes.
    const maxDuration = Math.max(
        Number(resolved.translate?.duration) || 0,
        Number(resolved.scale?.duration) || 0,
        Number(resolved.rotate?.duration) || 0,
        Number(resolved.skew?.duration) || 0
    );
    const forceGroups = computeForceGroups(resolved);
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
                interpSkew.x, interpSkew.y, order, forceGroups
            )
        });
    }

    // When Elm has no animation baseline for the resized property (init-only
    // value, e.g. `Scale.init` alongside a Rotate animation), the resize is
    // a "snapshot bake": we only want to splice the new value into the
    // running transform animation's keyframes so it stays visually current.
    // Recreating the animation here would restart the unrelated property's
    // animation (rotate, etc.) because the synthesized baseline carries
    // `duration=0` / `currentTimeMs=0`. Apply keyframes in place and exit.
    if (commandData.hasAnimationBaseline === false) {
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
        return;
    }

    // Compute the target `currentTime` BEFORE we touch the running
    // animation, so we can apply it atomically on the freshly-created
    // replacement. Two paths:
    //
    // - Elm-supplied `currentTimeMs` (Proportional strategy): Elm has the
    //   authoritative answer (preserve full-iteration count + in-iteration
    //   progress for looping legs, restart from `0` for the collapsed
    //   one-shot leg). We just apply it.
    //
    // - Fallback (Clamp strategy / `currentTimeMs == null`): solve for
    //   the currentTime that places the box at the strategy-aware target
    //   position Elm computed via `Resize.applyAxis`. Reuse the box's
    //   pre-resize `oldIter` to preserve iteration count + leg parity.
    //   For a 1D translate (the common resize case) this is exact for
    //   Linear easing and approximate for non-linear, matching Clamp's
    //   "preserve current value" promise.
    let newCurrentTime = null;
    const elmCurrentTimeMs = commandData.currentTimeMs;
    let useElmCurrentTime = false;
    let suspiciousZeroReset = false;
    if (hasElmCurrentTime) {
        const suspiciousResetFromStart = isSuspiciousResetToZero(
            elmCurrentTimeMs,
            oldCurrentTime,
            {
                x: Number(commandData.startX),
                y: Number(commandData.startY),
                z: Number(commandData.startZ)
            },
            targetPosition
        );
        const suspiciousResetFromContinuity = isSuspiciousZeroFromContinuity(
            elmCurrentTimeMs,
            oldCurrentTime,
            oldVisualPosition,
            targetPosition
        );
        const suspiciousReset = suspiciousResetFromStart || suspiciousResetFromContinuity;
        suspiciousZeroReset = suspiciousReset;

        if (!suspiciousReset) {
            useElmCurrentTime = true;
            newCurrentTime = elmCurrentTimeMs;
        }

    }

    if (!useElmCurrentTime && targetPosition !== null && newDuration > 0 && oldDuration > 0) {
        if (suspiciousZeroReset) {
            const scaledCurrentTime = scaleCurrentTimeForResize(oldCurrentTime, oldDuration, newDuration);
            if (scaledCurrentTime !== null) {
                newCurrentTime = scaledCurrentTime;
            }
        }

        if (newCurrentTime !== null && suspiciousZeroReset) {
            // Prefer proportional time preservation for suspicious reset payloads.
            // This keeps timeline continuity even when Elm start/end bounds are
            // rebuilt around the current point during live resizing.
        } else {
            const newStartX = Number(commandData.startX);
            const newEndX = Number(commandData.endX);
            const newStartY = Number(commandData.startY);
            const newEndY = Number(commandData.endY);
            const newStartZ = Number(commandData.startZ);
            const newEndZ = Number(commandData.endZ);

            const spans = {
                x: newEndX - newStartX,
                y: newEndY - newStartY,
                z: newEndZ - newStartZ
            };

            const chosenAxis = chooseDominantAxis(spans);
            let pWanted = 0;
            if (chosenAxis === 'x') {
                pWanted = (targetPosition.x - newStartX) / spans.x;
            } else if (chosenAxis === 'y') {
                pWanted = (targetPosition.y - newStartY) / spans.y;
            } else if (chosenAxis === 'z') {
                pWanted = (targetPosition.z - newStartZ) / spans.z;
            }
            if (pWanted < 0) pWanted = 0;
            if (pWanted > 1) pWanted = 1;

            const oldIter = Math.floor(oldCurrentTime / oldDuration);
            let pWithinIter = pWanted;
            if (oldDirection === 'alternate' || oldDirection === 'alternate-reverse') {
                const startsReversed = oldDirection === 'alternate-reverse';
                const isReverseLeg = (oldIter % 2 === 1) !== startsReversed;
                if (isReverseLeg) {
                    pWithinIter = 1 - pWanted;
                }
            } else if (oldDirection === 'reverse') {
                pWithinIter = 1 - pWanted;
            }
            newCurrentTime = (oldIter + pWithinIter) * newDuration;

        }
    }

    // Cancel + recreate (not in-place mutate). The in-place approach
    // (`setKeyframes` → `updateTiming` → `currentTime =`) suffers from a
    // one-composited-frame race: between `setKeyframes` and the
    // `currentTime` write, the compositor can sample the new keyframes
    // at the *old* `currentTime`, producing a visible flicker
    // `tx = newEnd × (oldCurrentTime / oldDuration)` for one frame before
    // snapping to the correct seeked position. Recreating the Animation
    // with the new keyframes/timing already set, then seeking before the
    // first composite, avoids the mismatched-state frame entirely.
    //
    // Iteration count and alternate-leg parity survive the recreate
    // because the seeked `currentTime` (= `(oldIter + pWithin) × newDuration`)
    // already encodes them — WAAPI derives `currentIteration` from
    // `currentTime / duration`, so iter=N forward/reverse leg is restored
    // automatically without an explicit `iterationStart`.
    const transformEntry = elementAnims.get('transform');
    const oldVersion = transformEntry.version;
    const newVersion = oldVersion + 1;
    const wasPaused = animation.playState === 'paused';
    const oldIterations = oldTiming.iterations;
    const animateOptions = {
        duration: newDuration > 0 ? newDuration : oldDuration,
        easing: 'linear',
        fill: 'forwards',
        iterations: Number.isFinite(oldIterations) || oldIterations === Infinity ? oldIterations : 1,
        direction: oldDirection
    };

    // Bump entry.version BEFORE cancelling so the old animation's `cancel`
    // event handler sees `entry.version !== capturedVersion` and exits
    // early without emitting a `cancelled` lifecycle event. The new
    // animation's `setupAnimationEvents` call below installs fresh
    // listeners keyed on the new version.
    transformEntry.version = newVersion;
    try {
        animation.cancel();
    } catch (err) {
        reportError(`cancel failed during resize: ${err && err.message ? err.message : err}`, {
            source: 'animation',
            severity: 'warning',
            code: 'RESIZE_CANCEL_FAILED',
            engine: 'WAAPI',
            elementId: animGroup
        });
    }

    let newAnimation = null;
    try {
        newAnimation = element.animate(keyframes, animateOptions);
    } catch (err) {
        reportError(`element.animate failed during resize: ${err && err.message ? err.message : err}`, {
            source: 'animation',
            severity: 'warning',
            code: 'RESIZE_RECREATE_FAILED',
            engine: 'WAAPI',
            elementId: animGroup
        });
        return;
    }

    if (newCurrentTime !== null) {
        try {
            newAnimation.currentTime = newCurrentTime;
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

    if (wasPaused) {
        try { newAnimation.pause(); } catch (_pauseErr) { /* non-fatal */ }
    }

    transformEntry.animation = newAnimation;
    transformEntry.updateFn = setupAnimationEvents(
        animGroup,
        'transform',
        element,
        newAnimation,
        newVersion,
        transformEntry.resolvedValues
    );
}

function resizePerspectiveOriginAnimation(commandData, animGroup, element) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims || !elementAnims.has('perspectiveOrigin')) {
        return;
    }

    const entry = elementAnims.get('perspectiveOrigin');
    const animation = entry.animation;
    if (!animation || !animation.effect) {
        return;
    }

    const oldTiming = animation.effect.getTiming() || {};
    const oldDuration = Number(oldTiming.duration) || 0;
    const oldCurrentTime = Number(animation.currentTime) || 0;
    const oldDirection = oldTiming.direction || 'normal';
    const oldLegProgress = computeLegProgress(oldCurrentTime, oldDuration, oldDirection, animation);

    const unit = typeof commandData.unit === 'string' ? commandData.unit : '%';
    const previousResolved = entry.resolvedNonTransform || null;
    const oldVisual =
        oldLegProgress !== null
            && previousResolved
            && isFiniteNumber(previousResolved.startX)
            && isFiniteNumber(previousResolved.endX)
            && isFiniteNumber(previousResolved.startY)
            && isFiniteNumber(previousResolved.endY)
            ? {
                x: previousResolved.startX + (previousResolved.endX - previousResolved.startX) * oldLegProgress,
                y: previousResolved.startY + (previousResolved.endY - previousResolved.startY) * oldLegProgress
            }
            : null;

    const hasElmCurrentTime = typeof commandData.currentTimeMs === 'number' && isFinite(commandData.currentTimeMs);
    const effectiveCurrentPosition = !hasElmCurrentTime && oldVisual
        ? {
            x: chooseEffectiveAxisValue(
                Number(previousResolved?.startX),
                Number(previousResolved?.endX),
                Number(commandData.startX),
                Number(commandData.endX),
                Number(commandData.currentX),
                oldVisual.x
            ),
            y: chooseEffectiveAxisValue(
                Number(previousResolved?.startY),
                Number(previousResolved?.endY),
                Number(commandData.startY),
                Number(commandData.endY),
                Number(commandData.currentY),
                oldVisual.y
            )
        }
        : {
            x: Number(commandData.currentX),
            y: Number(commandData.currentY)
        };

    const resolved = {
        type: 'perspectiveOrigin',
        startX: Number(commandData.startX),
        startY: Number(commandData.startY),
        endX: Number(commandData.endX),
        endY: Number(commandData.endY),
        unit: unit
    };

    const keyframeData = buildPropertyKeyframes(resolved, entry.easingKeyframes, 'linear');
    if (!keyframeData || !keyframeData.keyframes) {
        return;
    }

    const hasBaseline = commandData.hasAnimationBaseline !== false;
    const payloadDuration = sanitizeResizeDuration(Number(commandData.duration), oldDuration);
    const newDuration = hasBaseline ? payloadDuration : oldDuration;
    const wasPaused = animation.playState === 'paused';

    let newCurrentTime = null;
    const elmCurrentTimeMs = commandData.currentTimeMs;
    let useElmCurrentTime = false;
    let suspiciousZeroReset = false;
    if (hasElmCurrentTime) {
        const suspiciousResetFromStart = isSuspiciousResetToZero(
            elmCurrentTimeMs,
            oldCurrentTime,
            {
                x: Number(commandData.startX),
                y: Number(commandData.startY)
            },
            {
                x: Number(commandData.currentX),
                y: Number(commandData.currentY)
            }
        );
        const suspiciousResetFromContinuity = isSuspiciousZeroFromContinuity(
            elmCurrentTimeMs,
            oldCurrentTime,
            oldVisual,
            effectiveCurrentPosition
        );
        const suspiciousReset = suspiciousResetFromStart || suspiciousResetFromContinuity;
        suspiciousZeroReset = suspiciousReset;

        if (!suspiciousReset) {
            useElmCurrentTime = true;
            newCurrentTime = elmCurrentTimeMs;
        }

    }

    if (!useElmCurrentTime && oldDuration > 0 && newDuration > 0) {
        if (suspiciousZeroReset) {
            const scaledCurrentTime = scaleCurrentTimeForResize(oldCurrentTime, oldDuration, newDuration);
            if (scaledCurrentTime !== null) {
                newCurrentTime = scaledCurrentTime;
            }
        }

        if (newCurrentTime !== null && suspiciousZeroReset) {
            // Prefer proportional time preservation for suspicious reset payloads.
            // This keeps timeline continuity even when Elm start/end bounds are
            // rebuilt around the current point during live resizing.
        } else {
            const oldIter = Math.floor(oldCurrentTime / oldDuration);
            const startsReversed = oldDirection === 'alternate-reverse';
            const isAlternate = oldDirection === 'alternate' || oldDirection === 'alternate-reverse';
            const isReverseLeg = isAlternate ? ((oldIter % 2 === 1) !== startsReversed) : oldDirection === 'reverse';

            const xStart = Number(commandData.startX);
            const xEnd = Number(commandData.endX);
            const yStart = Number(commandData.startY);
            const yEnd = Number(commandData.endY);

            const spans = {
                x: xEnd - xStart,
                y: yEnd - yStart,
                z: 0
            };

            const chosenAxis = chooseDominantAxis(spans);

            let pWanted = 0;
            if (chosenAxis === 'x') {
                pWanted = (effectiveCurrentPosition.x - xStart) / spans.x;
            } else if (chosenAxis === 'y') {
                pWanted = (effectiveCurrentPosition.y - yStart) / spans.y;
            }
            if (pWanted < 0) pWanted = 0;
            if (pWanted > 1) pWanted = 1;

            const pWithinIter = isReverseLeg ? 1 - pWanted : pWanted;
            newCurrentTime = (oldIter + pWithinIter) * newDuration;

        }
    }

    const oldVersion = entry.version;
    const newVersion = oldVersion + 1;
    const oldIterations = oldTiming.iterations;
    const animateOptions = {
        duration: newDuration > 0 ? newDuration : oldDuration,
        easing: keyframeData.animationEasing || 'linear',
        fill: 'forwards',
        iterations: Number.isFinite(oldIterations) || oldIterations === Infinity ? oldIterations : 1,
        direction: oldDirection
    };

    entry.version = newVersion;
    try {
        animation.cancel();
    } catch (_err) {
        // Best-effort: keep going and recreate.
    }

    let newAnimation = null;
    try {
        newAnimation = element.animate(keyframeData.keyframes, animateOptions);
    } catch (_err) {
        return;
    }

    if (newCurrentTime !== null) {
        try {
            newAnimation.currentTime = newCurrentTime;
        } catch (_err) {
            // Non-fatal; animation still recreated with new bounds.
        }
    }

    if (wasPaused) {
        try { newAnimation.pause(); } catch (_pauseErr) { /* non-fatal */ }
    }

    element.style.perspectiveOrigin = `${effectiveCurrentPosition.x}${unit} ${effectiveCurrentPosition.y}${unit}`;

    entry.animation = newAnimation;
    entry.resolvedNonTransform = resolved;
    entry.updateFn = setupAnimationEvents(
        animGroup,
        'perspectiveOrigin',
        element,
        newAnimation,
        newVersion,
        null
    );
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
