/* eslint-env browser */
import { activeAnimations, animationGroups, lastKnownPerspectiveOrigins, portsRef } from './state.js';


/**
 * Send data to Elm via the waapiEvent port.
 * All port communication funnels through this single function.
 */
function sendToElm(data) {
    const ports = portsRef.ports;
    if (ports && ports.waapiEvent) {
        ports.waapiEvent.send(data);
    }
}

function hasWaapiEventPort() {
    const ports = portsRef.ports;
    return Boolean(ports && ports.waapiEvent);
}

function getGroupMaxDuration(animGroup) {
    const properties = animationGroups.get(animGroup)?.propertyConfigs || [];
    return properties.length > 0
        ? Math.max(...properties.map(property => property.duration))
        : 0;
}

function getRunningAnimationProgress(animGroup, maxDuration) {
    if (maxDuration <= 0) {
        return 0;
    }

    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims || elementAnims.size === 0) {
        return 0;
    }

    const firstAnim = elementAnims.values().next().value;
    if (!firstAnim || !firstAnim.animation) {
        return 0;
    }

    const currentTime = firstAnim.animation.currentTime || 0;
    return Math.min(1.0, Math.max(0.0, currentTime / maxDuration));
}

function getLifecycleProgress(status, animGroup) {
    if (status === 'completed' || status === 'stopped') {
        return 1.0;
    }

    if (status === 'started' || status === 'reset' || status === 'restarted') {
        return 0.0;
    }

    return getRunningAnimationProgress(animGroup, getGroupMaxDuration(animGroup));
}

function parsePerspectiveOriginPart(part) {
    const match = String(part || '').trim().match(/^(-?\d*\.?\d+)(px|%)$/);
    if (!match) {
        return null;
    }

    return { value: parseFloat(match[1]), unit: match[2] };
}

function convertPerspectiveOriginValue(value, fromUnit, toUnit, size) {
    if (!fromUnit || fromUnit === toUnit) {
        return value;
    }

    if (fromUnit === 'px' && toUnit === '%') {
        return (value / size) * 100;
    }

    if (fromUnit === '%' && toUnit === 'px') {
        return (value / 100) * size;
    }

    return value;
}

function buildPerspectiveOriginData(animGroup, element, computedStyle) {
    const computedOrigin = computedStyle.perspectiveOrigin || '50% 50%';
    const parts = computedOrigin.trim().split(/\s+/);
    const parsedX = parsePerspectiveOriginPart(parts[0]);
    const parsedY = parsePerspectiveOriginPart(parts[1] || parts[0]);
    const cached = lastKnownPerspectiveOrigins.get(animGroup);
    const targetUnit = cached?.unit || parsedX?.unit || '%';
    const parsedUnit = parsedX?.unit || parsedY?.unit;
    const width = element?.clientWidth || element?.offsetWidth || 1;
    const height = element?.clientHeight || element?.offsetHeight || 1;

    return {
        x: convertPerspectiveOriginValue(parsedX?.value ?? cached?.x ?? 50, parsedUnit, targetUnit, width),
        y: convertPerspectiveOriginValue(parsedY?.value ?? cached?.y ?? 50, parsedUnit, targetUnit, height),
        unit: targetUnit === '%' ? 'percent' : 'px'
    };
}

function collectCustomProperties(propertyVersions, computedStyle) {
    const customProperties = {};
    const customColorProperties = {};

    Object.keys(propertyVersions).forEach(key => {
        if (key.startsWith('custom:')) {
            const cssName = key.slice(7);
            customProperties[cssName] = parseFloat(computedStyle.getPropertyValue(cssName)) || 0;
            return;
        }

        if (key.startsWith('customColor:')) {
            const cssName = key.slice(12);
            customColorProperties[cssName] = computedStyle.getPropertyValue(cssName) || 'rgba(0, 0, 0, 1)';
        }
    });

    return { customProperties, customColorProperties };
}

/**
 * Send iteration event to Elm when an animation crosses an iteration boundary.
 * The iteration count is sent as the progress value so Elm can decode it
 * via: Iteration animGroupName (round progress)
 */
export function sendIterationEvent(animGroup, iterationNumber) {
    sendToElm({
        type: 'animationUpdate',
        payload: {
            elementId: animGroup,
            animGroup: animGroup,
            status: 'iteration',
            progress: iterationNumber
        }
    });
}

/**
 * Send lifecycle event to Elm (started, completed, cancelled, paused, resumed, etc.)
 * Includes current progress calculated from the active animation state.
 */
export function sendLifecycleEvent(status, animGroup) {
    if (!hasWaapiEventPort()) {
        return;
    }

    sendToElm({
        type: 'animationUpdate',
        engine: 'waapi',
        payload: {
            elementId: animGroup,
            animGroup: animGroup,
            status: status,
            progress: getLifecycleProgress(status, animGroup)
        }
    });
}

/**
 * Send a lifecycle event for a scroll-driven animation group to Elm.
 * Payload matches the 'animationUpdate' shape used by the WAAPI engine, plus
 * an 'engine' field so Elm decoders can filter to their own events.
 */
export function sendScrollLifecycleEvent(status, animGroup, progress, engine) {
    sendToElm({
        type: 'animationUpdate',
        engine: engine,
        payload: {
            elementId: animGroup,
            animGroup: animGroup,
            status: status,
            progress: progress
        }
    });
}

/**
 * Send property update to Elm (during animation).
 * Uses 'propertyUpdate' type which Elm routes to PropertyUpdate handling.
 */
export function sendPropertyUpdate(propertyData) {
    sendToElm({ type: 'propertyUpdate', ...propertyData });
}

/**
 * Build property data containing only the properties that are currently animated.
 * Uses propertyVersions keys to determine which properties to include,
 * so only animated values are sent to Elm (reducing decoder work per frame).
 */
export function buildAnimatedPropertyData(animGroup, propertyVersions, transformState, element, computedStyle) {
    const data = {};
    if ('transform' in propertyVersions) {
        data.translate = { x: transformState.x, y: transformState.y, z: transformState.z };
        data.rotate = { x: transformState.rotateX, y: transformState.rotateY, z: transformState.rotateZ };
        data.skew = { x: transformState.skewX, y: transformState.skewY };
        data.scale = { x: transformState.scaleX, y: transformState.scaleY, z: transformState.scaleZ };
    }
    if ('opacity' in propertyVersions) {
        data.opacity = parseFloat(computedStyle.opacity);
    }
    if ('size' in propertyVersions) {
        data.size = { width: parseFloat(computedStyle.width), height: parseFloat(computedStyle.height) };
    }
    if ('perspectiveOrigin' in propertyVersions) {
        data.perspectiveOrigin = buildPerspectiveOriginData(animGroup, element, computedStyle);
    }
    const { customProperties, customColorProperties } = collectCustomProperties(propertyVersions, computedStyle);
    if (Object.keys(customProperties).length > 0) {
        data.customProperties = customProperties;
    }
    if (Object.keys(customColorProperties).length > 0) {
        data.customColorProperties = customColorProperties;
    }
    return data;
}

