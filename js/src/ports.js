/* eslint-env browser */
/* global window */
import { activeAnimations, animationGroups, lastKnownPerspectiveOrigins } from './state.js';


/**
 * Send data to Elm via the waapiEvent port.
 * All port communication funnels through this single function.
 */
function sendToElm(data) {
    if (window.app && window.app.ports && window.app.ports.waapiEvent) {
        window.app.ports.waapiEvent.send(data);
    }
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
    if (!window.app || !window.app.ports || !window.app.ports.waapiEvent) return;

    const groupInfo = animationGroups.get(animGroup);

    // Get property configs to calculate max duration for progress
    const properties = groupInfo?.propertyConfigs || [];
    const maxDuration = properties.length > 0
        ? Math.max(...properties.map(p => p.duration))
        : 0;

    // Calculate progress based on event type
    let progress = 0;
    if (status === 'completed' || status === 'stopped') {
        progress = 1.0;
    } else if (status === 'started' || status === 'reset' || status === 'restarted') {
        progress = 0.0;
    } else {
        // For paused, resumed, cancelled - calculate actual progress
        const elementAnims = activeAnimations.get(animGroup);
        if (elementAnims && elementAnims.size > 0) {
            const firstAnim = elementAnims.values().next().value;
            if (firstAnim && firstAnim.animation && maxDuration > 0) {
                const currentTime = firstAnim.animation.currentTime || 0;
                progress = Math.min(1.0, Math.max(0.0, currentTime / maxDuration));
            }
        }
    }

    sendToElm({
        type: 'animationUpdate',
        engine: 'waapi',
        payload: {
            elementId: animGroup,
            animGroup: animGroup,
            status: status,
            progress: progress
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
        const computedOrigin = computedStyle.perspectiveOrigin || '50% 50%';
        const parts = computedOrigin.trim().split(/\s+/);

        const parsePart = (part) => {
            const match = String(part || '').trim().match(/^(-?\d*\.?\d+)(px|%)$/);
            if (!match) return null;
            return { value: parseFloat(match[1]), unit: match[2] };
        };

        const parsedX = parsePart(parts[0]);
        const parsedY = parsePart(parts[1] || parts[0]);
        const cached = lastKnownPerspectiveOrigins.get(animGroup);
        const targetUnit = cached?.unit || parsedX?.unit || '%';

        let x = parsedX?.value ?? cached?.x ?? 50;
        let y = parsedY?.value ?? cached?.y ?? 50;

        const width = element?.clientWidth || element?.offsetWidth || 1;
        const height = element?.clientHeight || element?.offsetHeight || 1;
        const parsedUnit = parsedX?.unit || parsedY?.unit;

        if (parsedUnit && parsedUnit !== targetUnit) {
            if (parsedUnit === 'px' && targetUnit === '%') {
                x = (x / width) * 100;
                y = (y / height) * 100;
            } else if (parsedUnit === '%' && targetUnit === 'px') {
                x = (x / 100) * width;
                y = (y / 100) * height;
            }
        }

        data.perspectiveOrigin = {
            x: x,
            y: y,
            unit: targetUnit === '%' ? 'percent' : 'px'
        };
    }
    const customProps = {};
    const customColorProps = {};
    for (const key of Object.keys(propertyVersions)) {
        if (key.startsWith('custom:')) {
            const cssName = key.slice(7);
            customProps[cssName] = parseFloat(computedStyle.getPropertyValue(cssName)) || 0;
        } else if (key.startsWith('customColor:')) {
            const cssName = key.slice(12);
            customColorProps[cssName] = computedStyle.getPropertyValue(cssName) || 'rgba(0, 0, 0, 1)';
        }
    }
    if (Object.keys(customProps).length > 0) {
        data.customProperties = customProps;
    }
    if (Object.keys(customColorProps).length > 0) {
        data.customColorProperties = customColorProps;
    }
    return data;
}

