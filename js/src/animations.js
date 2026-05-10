/* eslint-env browser */
import { isTransformProperty, easingFunctions, parseIterations } from './utils.js';
import { activeAnimations, animationGroups, elementTransformOrders, cleanupAnimGroup } from './state.js';
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

    const totalProperties = (transformProperties.length > 0 ? 1 : 0) + nonTransformProperties.length;
    const existingGroup = animationGroups.get(animGroup);
    const generation = isRestart ? (existingGroup?.generation || 0) : ((existingGroup?.generation || 0) + 1);

    animationGroups.set(animGroup, {
        totalProperties: totalProperties,
        completedProperties: 0,
        started: false,
        generation: generation,
        nextPropertyIndex: 0,
        lastIteration: 0,
        propertyIterations: new Array(totalProperties).fill(0),
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
            const updateFn = setupAnimationEvents(animGroup, 'transform', element, animation, maxVersion, resolvedTransformValues);
            elementAnims.set('transform', {
                animation: animation,
                version: maxVersion,
                updateFn: updateFn,
                animGroup: animGroup,
                easingKeyframes: null,
                transformProperties: mergedTransformProperties,
                resolvedValues: resolvedTransformValues
            });

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
            const updateFn = setupAnimationEvents(animGroup, propType, element, animation, newVersion, null);
            elementAnims.set(propType, {
                animation: animation,
                version: newVersion,
                updateFn: updateFn,
                animGroup: animGroup,
                easingKeyframes: property.easingKeyframes || null,
                resolvedNonTransform: resolvedNonTransform
            });

            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
            }

            markAnimationGroupStarted(animGroup);
        }
    });

    if (elementAnims.size === 0) {
        cleanupAnimGroup(animGroup);
    }
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
