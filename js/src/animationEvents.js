/* eslint-env browser */
/* global window, requestAnimationFrame, cancelAnimationFrame, performance */
import { updateGroupIteration } from './utils.js';
import { activeAnimations, animationGroups, lastKnownTransforms } from './state.js';
import { getDefaultTransformState, computeTransformFromResolved } from './transform.js';
import { sendLifecycleEvent, sendIterationEvent, sendPropertyUpdate, buildAnimatedPropertyData } from './ports.js';

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
    const computedStyle = window.getComputedStyle(element);
    const propertyVersions = buildPropertyVersions(animGroup, propertyType, version);
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
    } catch (_) { /* ignore timing errors */ }
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
        animationGroups.delete(animGroup);
    }
    return allComplete;
}

function getUpdatePort() {
    if (typeof window.app !== 'undefined' &&
        window.app.ports &&
        window.app.ports.waapiEvent &&
        typeof window.app.ports.waapiEvent.send === 'function') {
        return window.app.ports.waapiEvent;
    }
    return null;
}

export function setupAnimationEvents(animGroup, propertyType, element, animation, version, resolvedTransformValues) {
    const groupGeneration = animationGroups.get(animGroup)?.generation || 0;
    const groupInfoForIndex = animationGroups.get(animGroup);
    let propertyIndex = 0;
    if (groupInfoForIndex) {
        propertyIndex = groupInfoForIndex.nextPropertyIndex;
        groupInfoForIndex.nextPropertyIndex++;
    }
    const updatePort = getUpdatePort();
    const transformAnimDuration = resolvedTransformValues
        ? (animation.effect?.getTiming()?.duration || 0)
        : 0;

    let lastComputedTransformState = resolvedTransformValues
        ? computeTransformFromResolved(resolvedTransformValues, 0, transformAnimDuration)
        : null;
    let lastTime = 0;
    const updateInterval = 16;
    let rafId = null;

    function sendAnimationUpdate() {
        const now = performance.now();
        if (now - lastTime >= updateInterval) {
            updateGroupIterationState(animGroup, groupGeneration, propertyIndex, animation);

            const transformState = getLiveTransformState(animGroup, animation, resolvedTransformValues, transformAnimDuration);
            lastComputedTransformState = transformState;

            if (updatePort) {
                sendTrackedPropertyUpdate(
                    animGroup,
                    null,
                    null,
                    transformState,
                    element,
                    true,
                    getAnimationProgress(animGroup, animation)
                );
            }
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
        } catch (_) {
            try { animation.cancel(); } catch (_) { /* ignore */ }
        }

        removeTrackedAnimationVersion(animGroup, propertyType, version);

        if (animationGroups.get(animGroup)?.generation === groupGeneration) {
            const allComplete = finalizeAnimationTracking(animGroup, groupGeneration, 'completed');
            if (updatePort) {
                const finalTransformState = getTrackedTransformState(
                    animGroup,
                    resolvedTransformValues,
                    resolvedTransformValues ? getResolvedEndTransformState(resolvedTransformValues) : null
                );
                sendTrackedPropertyUpdate(animGroup, propertyType, version, finalTransformState, element, !allComplete);
            }
        }
    });

    animation.addEventListener('cancel', () => {
        if (finishHandled) return;

        removeTrackedAnimationVersion(animGroup, propertyType, version);

        if (animationGroups.get(animGroup)?.generation === groupGeneration) {
            const allCancelled = finalizeAnimationTracking(animGroup, groupGeneration, 'cancelled');
            if (updatePort) {
                const cancelTransformState = getTrackedTransformState(animGroup, resolvedTransformValues, lastComputedTransformState);
                sendTrackedPropertyUpdate(animGroup, propertyType, version, cancelTransformState, element, !allCancelled);
            }
        }
    });

    return sendAnimationUpdate;
}
