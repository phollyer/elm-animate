/* eslint-env browser */
/* global window, document, console, CSS, requestAnimationFrame, cancelAnimationFrame, performance */
import { isTransformProperty, updateGroupIteration, easingFunctions, parseIterations } from './utils.js';
import { activeAnimations, animationGroups, lastKnownTransforms, elementTransformOrders } from './state.js';
import { getTransformState, getElementOrder, buildTransformString, getDefaultTransformState,
    interpolateSubProperty, computeTransformFromResolved } from './transform.js';
import { resolveNonTransformValues, createPropertyAnimation, extractPropertyConfig } from './properties.js';
import { sendLifecycleEvent, sendIterationEvent, sendPropertyUpdate, buildAnimatedPropertyData } from './ports.js';

// ─── DOM helpers ──────────────────────────────────────────────────────────────

/**
 * Find the single DOM element with a matching data-anim-target attribute (or id).
 */
export function findAnimTarget(targetId) {
    return document.querySelector('[data-anim-target="' + CSS.escape(targetId) + '"]')
        || document.getElementById(targetId)
        || null;
}

/**
 * Find all DOM elements with a matching data-anim-target attribute (or id).
 */
export function findAllAnimTargets(targetId) {
    const byAttr = Array.from(document.querySelectorAll('[data-anim-target="' + CSS.escape(targetId) + '"]'));
    if (byAttr.length > 0) return byAttr;
    const byId = document.getElementById(targetId);
    return byId ? [byId] : [];
}

// ─── Control helpers ──────────────────────────────────────────────────────────

/**
 * Iterate over animations in the group, optionally filtered to a subset of
 * property types, and invoke fn(animData, propertyType) for each match.
 * Returns { affected, total } for post-call cleanup decisions.
 */
function forEachAffectedAnimation(animGroup, properties, fn) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return { affected: 0, total: 0 };
    const filter = properties ? new Set(properties) : null;
    let affected = 0;
    elementAnims.forEach((animData, propertyType) => {
        if (!filter || filter.has(propertyType)) {
            fn(animData, propertyType);
            affected++;
        }
    });
    return { affected, total: elementAnims.size };
}

// ─── WAAPI animation engine ───────────────────────────────────────────────────

/**
 * Process a single element's animation configuration.
 * Merges all transform sub-properties into one animation (avoids WAAPI cascade).
 * Non-transform properties (opacity, color, etc.) are animated independently.
 */
export function processElementAnimation(animGroup, elementConfig, globalOptions = { iterations: 1, direction: 'normal' }, isRestart = false, resolvedElement = null) {
    const element = resolvedElement || findAnimTarget(animGroup);
    if (!element) {
        console.warn(`ElmMotion: Element with data-anim-target="${animGroup}" not found`);
        return;
    }

    const properties = elementConfig.properties || [];
    const transformOrder = elementConfig.transformOrder;
    if (transformOrder && transformOrder.length > 0) {
        elementTransformOrders.set(animGroup, transformOrder);
    }

    const transformProperties = properties.filter(p => isTransformProperty(p.type));
    const nonTransformProperties = properties.filter(p => !isTransformProperty(p.type));

    // Ensure element tracking map exists
    if (!activeAnimations.has(animGroup)) {
        activeAnimations.set(animGroup, new Map());
    }
    const elementAnims = activeAnimations.get(animGroup);

    const totalProperties = (transformProperties.length > 0 ? 1 : 0) + nonTransformProperties.length;

    // For restarts, reuse existing group with reset counters.
    // For new animations, create fresh group tracking.
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

    // Handle transform sub-properties (merged into a single animation)
    if (transformProperties.length > 0) {
        const mergedTransformProperties = [...transformProperties];

        // Carry forward any existing (un-cancelled) transform sub-property values
        // so that interrupting one animation and starting another begins from
        // the current animated position rather than jumping to the resolved start.
        if (elementAnims.has('transform')) {
            const existingTransform = elementAnims.get('transform');

            // Patch start values from real-time WAAPI position using currentTime
            if (existingTransform.resolvedValues && existingTransform.animation) {
                const existingAnim = existingTransform.animation;
                const timing = existingAnim.effect?.getTiming();
                const currentTime = existingAnim.currentTime || 0;
                const duration = timing?.duration || 0;
                if (duration > 0) {
                    const progress = Math.min(1.0, Math.max(0.0, currentTime / duration));
                    const currentState = computeTransformFromResolved(existingTransform.resolvedValues, progress, duration);

                    mergedTransformProperties.forEach(property => {
                        switch (property.type) {
                            case 'translate':
                                if (property.startX == null && property.defaultX == null) property.startX = currentState.x;
                                if (property.startY == null && property.defaultY == null) property.startY = currentState.y;
                                if (property.startZ == null && property.defaultZ == null) property.startZ = currentState.z;
                                break;
                            case 'scale':
                                if (property.startX == null && property.defaultX == null) property.startX = currentState.scaleX;
                                if (property.startY == null && property.defaultY == null) property.startY = currentState.scaleY;
                                if (property.startZ == null && property.defaultZ == null) property.startZ = currentState.scaleZ;
                                break;
                            case 'rotate':
                                if (property.startX == null && property.defaultX == null) property.startX = currentState.rotateX;
                                if (property.startY == null && property.defaultY == null) property.startY = currentState.rotateY;
                                if (property.startZ == null && property.defaultZ == null) property.startZ = currentState.rotateZ;
                                break;
                            case 'skew':
                                if (property.startX == null) property.startX = currentState.skewX;
                                if (property.startY == null) property.startY = currentState.skewY;
                                break;
                        }
                    });
                }
            }

            // Carry forward sub-properties not present in new animation from cached transform
            if (existingTransform.transformProperties) {
                const newPropTypes = new Set(mergedTransformProperties.map(p => p.type));
                const currentTransform = getTransformState(animGroup, element);

                existingTransform.transformProperties.forEach(oldProp => {
                    if (!newPropTypes.has(oldProp.type)) {
                        mergedTransformProperties.push({
                            type: oldProp.type,
                            startX: currentTransform[oldProp.type === 'translate' ? 'x' : oldProp.type === 'scale' ? 'scaleX' : oldProp.type === 'rotate' ? 'rotateX' : 'skewX'],
                            startY: currentTransform[oldProp.type === 'translate' ? 'y' : oldProp.type === 'scale' ? 'scaleY' : oldProp.type === 'rotate' ? 'rotateY' : 'skewY'],
                            startZ: currentTransform[oldProp.type === 'translate' ? 'z' : oldProp.type === 'scale' ? 'scaleZ' : oldProp.type === 'rotate' ? 'rotateZ' : undefined],
                            endX: currentTransform[oldProp.type === 'translate' ? 'x' : oldProp.type === 'scale' ? 'scaleX' : oldProp.type === 'rotate' ? 'rotateX' : 'skewX'],
                            endY: currentTransform[oldProp.type === 'translate' ? 'y' : oldProp.type === 'scale' ? 'scaleY' : oldProp.type === 'rotate' ? 'rotateY' : 'skewY'],
                            endZ: currentTransform[oldProp.type === 'translate' ? 'z' : oldProp.type === 'scale' ? 'scaleZ' : oldProp.type === 'rotate' ? 'rotateZ' : undefined],
                            easing: oldProp.easing || 'linear',
                            easingKeyframes: null,
                            duration: mergedTransformProperties[0]?.duration || 0,
                            version: oldProp.version || 1
                        });
                    }
                });
            }

            // Cancel existing transform animation
            existingTransform.animation.cancel();
        }
        // Also cancel individual sub-property animations from older code paths
        ['translate', 'scale', 'rotate', 'skew'].forEach(propType => {
            if (elementAnims.has(propType)) {
                const existing = elementAnims.get(propType);
                existing.animation.cancel();
                elementAnims.delete(propType);
            }
        });

        const maxVersion = Math.max(...mergedTransformProperties.map(p => p.version || 1));
        const mergeResult = createMergedTransformAnimation(animGroup, element, mergedTransformProperties, globalOptions);

        if (mergeResult) {
            const { animation, resolved: resolvedTransformValues } = mergeResult;
            const updateFn = setupAnimationEvents(animGroup, 'transform', element, animation, maxVersion, resolvedTransformValues);
            elementAnims.set('transform', {
                animation: animation,
                version: maxVersion,
                updateFn: updateFn,
                animGroup: animGroup,
                easingKeyframes: null, // merged animations always use keyframe-based interpolation
                transformProperties: mergedTransformProperties, // cache for resize and carry-forward
                resolvedValues: resolvedTransformValues // cached start/end for computing interpolated values
            });

            // Store property configs for lifecycle events
            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                transformProperties.forEach(property => {
                    groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
                });
            }

            // Emit Started event
            const groupInfo2 = animationGroups.get(animGroup);
            if (groupInfo2 && !groupInfo2.started) {
                groupInfo2.started = true;
                sendLifecycleEvent('started', animGroup);
            }
        }
    }

    // Process non-transform properties independently (opacity, color, etc.)
    nonTransformProperties.forEach(property => {
        const propType = property.type;
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

            if (groupInfo && !groupInfo.started) {
                groupInfo.started = true;
                sendLifecycleEvent('started', animGroup);
            }
        }
    });

    // Clean up element entry if no animations remain
    if (elementAnims.size === 0) {
        activeAnimations.delete(animGroup);
    }
}

/**
 * Create a single WAAPI animation for multiple transform sub-properties.
 * Merges translate, scale, rotate, and skew into one animation with per-property
 * easing via generated keyframes. This avoids the WAAPI cascade issue where
 * multiple animations on 'transform' replace each other.
 */
function createMergedTransformAnimation(animGroup, element, transformProperties, globalOptions = { iterations: 1, direction: 'normal' }) {
    const currentTransform = getTransformState(animGroup, element);
    const order = getElementOrder(element);

    // Resolve start/end values for each sub-property.
    // These resolved values are also returned so callers can store them
    // for computing interpolated values without reading the DOM.
    const resolved = {
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

    let maxDuration = 0;

    transformProperties.forEach(property => {
        const p = property;
        switch (p.type) {
            case 'translate':
                resolved.translate.startX = p.startX ?? p.defaultX ?? currentTransform.x;
                resolved.translate.startY = p.startY ?? p.defaultY ?? currentTransform.y;
                resolved.translate.startZ = p.startZ ?? p.defaultZ ?? currentTransform.z;
                resolved.translate.endX = p.endX ?? currentTransform.x;
                resolved.translate.endY = p.endY ?? currentTransform.y;
                resolved.translate.endZ = p.endZ ?? currentTransform.z;
                resolved.translate.easing = p.easing;
                resolved.translate.easingKeyframes = p.easingKeyframes;
                resolved.translate.duration = p.duration;
                break;
            case 'scale':
                resolved.scale.startX = p.startX ?? p.defaultX ?? currentTransform.scaleX;
                resolved.scale.startY = p.startY ?? p.defaultY ?? currentTransform.scaleY;
                resolved.scale.startZ = p.startZ ?? p.defaultZ ?? currentTransform.scaleZ;
                resolved.scale.endX = p.endX ?? currentTransform.scaleX;
                resolved.scale.endY = p.endY ?? currentTransform.scaleY;
                resolved.scale.endZ = p.endZ ?? currentTransform.scaleZ;
                resolved.scale.easing = p.easing;
                resolved.scale.easingKeyframes = p.easingKeyframes;
                resolved.scale.duration = p.duration;
                break;
            case 'rotate':
                resolved.rotate.startX = p.startX ?? p.defaultX ?? currentTransform.rotateX;
                resolved.rotate.startY = p.startY ?? p.defaultY ?? currentTransform.rotateY;
                resolved.rotate.startZ = p.startZ ?? p.defaultZ ?? currentTransform.rotateZ;
                resolved.rotate.endX = p.endX ?? currentTransform.rotateX;
                resolved.rotate.endY = p.endY ?? currentTransform.rotateY;
                resolved.rotate.endZ = p.endZ ?? currentTransform.rotateZ;
                resolved.rotate.easing = p.easing;
                resolved.rotate.easingKeyframes = p.easingKeyframes;
                resolved.rotate.duration = p.duration;
                break;
            case 'skew':
                resolved.skew.startX = p.startX ?? currentTransform.skewX;
                resolved.skew.startY = p.startY ?? currentTransform.skewY;
                resolved.skew.endX = p.endX ?? currentTransform.skewX;
                resolved.skew.endY = p.endY ?? currentTransform.skewY;
                resolved.skew.easing = p.easing;
                resolved.skew.easingKeyframes = p.easingKeyframes;
                resolved.skew.duration = p.duration;
                break;
        }
        if (p.duration > maxDuration) maxDuration = p.duration;
    });

    // Check if all sub-properties share the same simple easing (no easingKeyframes)
    const activeProps = transformProperties.map(p => resolved[p.type]);
    const allSameEasing = activeProps.every(r => !r.easingKeyframes && r.easing === activeProps[0].easing);
    const allSameDuration = activeProps.every(r => r.duration === activeProps[0].duration);

    if (allSameEasing && allSameDuration) {
        // Simple case: same easing and duration, use 2-keyframe animation
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

    // Complex case: different easings or durations per sub-property.
    // Generate keyframes where each sub-property is independently eased.
    const KEYFRAME_COUNT = 30;
    const keyframes = [];

    for (let i = 0; i < KEYFRAME_COUNT; i++) {
        const globalProgress = i / (KEYFRAME_COUNT - 1); // 0.0 to 1.0

        const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
        const interpScale = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
        const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
        const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);

        const transform = buildTransformString(
            interpTranslate.x, interpTranslate.y, interpTranslate.z,
            interpScale.x, interpScale.y, interpScale.z,
            interpRotate.x, interpRotate.y, interpRotate.z,
            interpSkew.x, interpSkew.y, order
        );

        keyframes.push({ transform });
    }

    return {
        animation: element.animate(keyframes, {
            duration: maxDuration,
            easing: 'linear', // easing is baked into keyframes
            fill: 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        }),
        resolved: resolved
    };
}

/**
 * Set up animation event listeners and property updates with version tracking.
 * Returns the RAF update function so it can be restarted on resume.
 */
function setupAnimationEvents(animGroup, propertyType, element, animation, version, resolvedTransformValues) {
    // Capture the current group generation so that old animation handlers
    // (from previous animate calls) don't corrupt the new group's tracking.
    const groupGeneration = animationGroups.get(animGroup)?.generation || 0;

    // Claim a property index for iteration tracking (slowest-wins: the group
    // iteration event fires only when all properties have completed the loop).
    const groupInfoForIndex = animationGroups.get(animGroup);
    const propertyIndex = groupInfoForIndex ? groupInfoForIndex.nextPropertyIndex++ : 0;
    let updatePort = null;

    // Find the update port
    if (typeof window.app !== 'undefined' &&
        window.app.ports &&
        window.app.ports.waapiEvent &&
        typeof window.app.ports.waapiEvent.send === 'function') {
        updatePort = window.app.ports.waapiEvent;
    }

    // Duration of the transform animation (for computing interpolated values).
    const transformAnimDuration = resolvedTransformValues
        ? (animation.effect?.getTiming()?.duration || 0)
        : 0;

    // Track last computed transform state during animation.
    // Used by the cancel handler since animation.currentTime is null after cancel.
    let lastComputedTransformState = resolvedTransformValues
        ? computeTransformFromResolved(resolvedTransformValues, 0, transformAnimDuration)
        : null;

    // Send updates during animation
    let lastTime = 0;
    const updateInterval = 16; // ~60fps
    let rafId = null;

    function sendAnimationUpdate() {
        const now = performance.now();
        if (now - lastTime >= updateInterval) {
            // Detect iteration boundary changes (slowest-wins).
            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo && groupInfo.generation === groupGeneration) {
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
                } catch (_) { /* ignore timing errors */ }
            }

            const computedStyle = window.getComputedStyle(element);

            let transformState;
            if (resolvedTransformValues) {
                const currentTime = animation.currentTime || 0;
                const animProgress = transformAnimDuration > 0
                    ? Math.min(1.0, Math.max(0.0, currentTime / transformAnimDuration))
                    : 0;
                transformState = computeTransformFromResolved(resolvedTransformValues, animProgress, transformAnimDuration);
                lastComputedTransformState = transformState;
                lastKnownTransforms.set(animGroup, transformState);
            } else {
                transformState = lastKnownTransforms.get(animGroup) || getDefaultTransformState();
            }

            if (updatePort) {
                const propertyVersions = {};
                const elementAnims = activeAnimations.get(animGroup);
                if (elementAnims) {
                    elementAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }

                const groupInfo = animationGroups.get(animGroup);
                const maxDuration = groupInfo?.propertyConfigs?.length > 0
                    ? Math.max(...groupInfo.propertyConfigs.map(p => p.duration))
                    : animation.effect?.getTiming()?.duration || 0;
                const currentTime = animation.currentTime || 0;
                const progress = maxDuration > 0
                    ? Math.min(1.0, Math.max(0.0, currentTime / maxDuration))
                    : 0;

                const propertyData = {
                    elementId: animGroup,
                    animGroup: animGroup,
                    progress: progress,
                    ...buildAnimatedPropertyData(animGroup, propertyVersions, transformState, element, computedStyle),
                    isAnimating: true,
                    propertyVersions: propertyVersions
                };
                sendPropertyUpdate(propertyData);
            }
            lastTime = now;
        }

        if (animation.playState === 'running') {
            rafId = requestAnimationFrame(sendAnimationUpdate);
        } else {
            rafId = null;
        }
    }

    // Start sending updates
    rafId = requestAnimationFrame(sendAnimationUpdate);

    // Track whether finish handler already processed this animation.
    // animation.cancel() inside finish triggers the cancel event — this
    // flag prevents the cancel handler from double-counting completions.
    let finishHandled = false;

    animation.addEventListener('finish', () => {
        finishHandled = true;

        if (rafId !== null) {
            cancelAnimationFrame(rafId);
            rafId = null;
        }
        // CRITICAL: Commit the animated styles to inline styles, then cancel
        // MDN: After commitStyles(), you must cancel() to fully remove the animation
        try {
            animation.commitStyles();
            animation.cancel();
        } catch (_) {
            try { animation.cancel(); } catch (_) { /* ignore */ }
        }

        const elementAnims = activeAnimations.get(animGroup);
        if (elementAnims) {
            const current = elementAnims.get(propertyType);
            if (current && current.version === version) {
                elementAnims.delete(propertyType);
                if (elementAnims.size === 0) {
                    activeAnimations.delete(animGroup);
                }
            }
        }

        const groupInfo = animationGroups.get(animGroup);
        if (groupInfo && groupInfo.generation === groupGeneration) {
            groupInfo.completedProperties++;
            const allComplete = groupInfo.completedProperties >= groupInfo.totalProperties;

            if (updatePort) {
                let finalTransformState;
                if (resolvedTransformValues) {
                    finalTransformState = {
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
                    lastKnownTransforms.set(animGroup, finalTransformState);
                } else {
                    finalTransformState = lastKnownTransforms.get(animGroup) || getDefaultTransformState();
                }
                const computedStyle = window.getComputedStyle(element);

                const propertyVersions = {};
                const remainingAnims = activeAnimations.get(animGroup);
                if (remainingAnims) {
                    remainingAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }
                propertyVersions[propertyType] = version;

                const finalPropertyData = {
                    elementId: animGroup,
                    animGroup: animGroup,
                    ...buildAnimatedPropertyData(animGroup, propertyVersions, finalTransformState, element, computedStyle),
                    isAnimating: !allComplete,
                    propertyVersions: propertyVersions
                };
                sendPropertyUpdate(finalPropertyData);
            }

            if (allComplete) {
                sendLifecycleEvent('completed', animGroup);
                animationGroups.delete(animGroup);
            }
        }
    });

    animation.addEventListener('cancel', () => {
        if (finishHandled) return;

        const elementAnims = activeAnimations.get(animGroup);
        if (elementAnims) {
            const current = elementAnims.get(propertyType);
            if (current && current.version === version) {
                elementAnims.delete(propertyType);
                if (elementAnims.size === 0) {
                    activeAnimations.delete(animGroup);
                }
            }
        }

        const groupInfo = animationGroups.get(animGroup);
        if (groupInfo && groupInfo.generation === groupGeneration) {
            groupInfo.completedProperties++;
            const allCancelled = groupInfo.completedProperties >= groupInfo.totalProperties;

            if (updatePort) {
                let cancelTransformState;
                if (resolvedTransformValues) {
                    cancelTransformState = lastComputedTransformState || getDefaultTransformState();
                    lastKnownTransforms.set(animGroup, cancelTransformState);
                } else {
                    cancelTransformState = lastKnownTransforms.get(animGroup) || getDefaultTransformState();
                }
                const computedStyle = window.getComputedStyle(element);

                const propertyVersions = {};
                const remainingAnims = activeAnimations.get(animGroup);
                if (remainingAnims) {
                    remainingAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }
                propertyVersions[propertyType] = version;

                const currentPropertyData = {
                    elementId: animGroup,
                    animGroup: animGroup,
                    ...buildAnimatedPropertyData(animGroup, propertyVersions, cancelTransformState, element, computedStyle),
                    isAnimating: !allCancelled,
                    propertyVersions: propertyVersions
                };
                sendPropertyUpdate(currentPropertyData);
            }

            if (allCancelled) {
                sendLifecycleEvent('cancelled', animGroup);
                animationGroups.delete(animGroup);
            }
        }
    });

    return sendAnimationUpdate;
}

// ─── Animation control commands ───────────────────────────────────────────────

/**
 * Stop animation by jumping to end state.
 */
export function stopAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    const { affected, total } = forEachAffectedAnimation(animGroup, properties, animData => animData.animation.finish());
    if (!properties || affected === total) {
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);
    }
    sendLifecycleEvent('stopped', animGroup);
}

/**
 * Reset animation by jumping to start state.
 */
export function resetAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    const { affected, total } = forEachAffectedAnimation(animGroup, properties, animData => animData.animation.cancel());
    if (!properties || affected === total) {
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);
    }
    sendLifecycleEvent('reset', animGroup);
}

/**
 * Restart animation from beginning.
 */
export function restartAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => {
        animData.animation.cancel();
        animData.animation.play();
    });

    // Reset group tracking for restart
    const groupTracking = animationGroups.get(animGroup);
    if (groupTracking) {
        groupTracking.completedProperties = 0;
        groupTracking.started = false;
    }
    sendLifecycleEvent('restarted', animGroup);
}

/**
 * Pause animation.
 */
export function pauseAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => animData.animation.pause());
    sendLifecycleEvent('paused', animGroup);
}

/**
 * Resume animation.
 */
export function resumeAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => {
        animData.animation.play();
        // Restart the RAF update loop
        if (animData.updateFn) {
            animData.updateFn();
        }
    });
    sendLifecycleEvent('resumed', animGroup);
}

/**
 * Set all properties directly for elements (initialization).
 * Called during initProperties to synchronize Elm, JS, and inline styles.
 */
export function setProperties(updates) {
    updates.forEach(update => {
        const animGroup = update.elementId;
        const element = findAnimTarget(animGroup);
        if (!element) {
            console.warn(`ElmMotion: Element with data-anim-target="${animGroup}" not found`);
            return;
        }

        // Cancel all existing animations
        const animations = element.getAnimations();
        animations.forEach((anim) => {
            anim.cancel();
        });

        // Clean up tracking for this animation group
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);

        const props = update.properties;

        if (props.x !== undefined || props.y !== undefined || props.z !== undefined ||
            props.scaleX !== undefined || props.scaleY !== undefined || props.scaleZ !== undefined ||
            props.rotateX !== undefined || props.rotateY !== undefined || props.rotateZ !== undefined ||
            props.skewX !== undefined || props.skewY !== undefined) {

            const order = elementTransformOrders.get(animGroup) || ['translate', 'rotate', 'skew', 'scale'];
            const transform = buildTransformString(
                props.x || 0,
                props.y || 0,
                props.z || 0,
                props.scaleX !== undefined ? props.scaleX : 1,
                props.scaleY !== undefined ? props.scaleY : 1,
                props.scaleZ !== undefined ? props.scaleZ : 1,
                props.rotateX || 0,
                props.rotateY || 0,
                props.rotateZ || 0,
                props.skewX || 0,
                props.skewY || 0,
                order
            );

            element.style.transform = transform;
        }

        if (props.opacity !== undefined) {
            element.style.opacity = props.opacity.toString();
        }
        if (props.backgroundColor !== undefined) {
            element.style.backgroundColor = props.backgroundColor;
        }
        if (props.color !== undefined) {
            element.style.color = props.color;
        }
        if (props.width !== undefined && props.height !== undefined) {
            element.style.width = `${props.width}px`;
            element.style.height = `${props.height}px`;
        }
    });
}

/**
 * Process animation data received from Elm.
 * Dispatches to processElementAnimation for each target element.
 */
export function processAnimationData(animationData) {
    if (animationData && animationData.elements) {
        const globalOptions = {
            iterations: parseIterations(animationData.iterations),
            direction: animationData.direction || 'normal'
        };
        const isRestart = animationData.isRestart || false;

        Object.entries(animationData.elements).forEach(([animGroup, elementConfig]) => {
            const targets = findAllAnimTargets(animGroup);
            if (targets.length <= 1) {
                processElementAnimation(animGroup, elementConfig, globalOptions, isRestart);
            } else {
                targets.forEach((el, idx) => {
                    const uniqueId = el.id || (animGroup + '__multi_' + idx);
                    processElementAnimation(uniqueId, elementConfig, globalOptions, isRestart, el);
                });
            }
        });
    } else {
        console.warn('ElmMotion: Invalid animation data format received');
    }
}
