/* eslint-env browser */
/* global window */
import { easingFunctions, camelCase } from './utils.js';
import { lastKnownPerspectiveOrigins } from './state.js';
import { getTransformState } from './transform.js';

/**
 * Interpolate between two color strings.
 */
export function interpolateColor(startColor, endColor, progress) {
    // Parse rgb/rgba colors
    const parseColor = (str) => {
        const match = str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
        if (match) {
            return {
                r: parseInt(match[1], 10),
                g: parseInt(match[2], 10),
                b: parseInt(match[3], 10),
                a: match[4] !== undefined ? parseFloat(match[4]) : 1
            };
        }
        // Fallback for hex colors (convert to rgb)
        if (str.startsWith('#')) {
            const hex = str.substring(1);
            return {
                r: parseInt(hex.substring(0, 2), 16),
                g: parseInt(hex.substring(2, 4), 16),
                b: parseInt(hex.substring(4, 6), 16),
                a: 1
            };
        }
        return { r: 0, g: 0, b: 0, a: 1 };
    };

    const start = parseColor(startColor);
    const end = parseColor(endColor);

    const r = Math.round(start.r + (end.r - start.r) * progress);
    const g = Math.round(start.g + (end.g - start.g) * progress);
    const b = Math.round(start.b + (end.b - start.b) * progress);
    const a = start.a + (end.a - start.a) * progress;

    return `rgba(${r}, ${g}, ${b}, ${a})`;
}

/**
 * Resolve start/end values for a non-transform property so they can be
 * used to compute interpolated values without reading the DOM later.
 */
export function resolveNonTransformValues(animGroup, element, property) {
    const computedStyle = window.getComputedStyle(element);
    switch (property.type) {
        case 'opacity': { // NOPMD - block required for const scoping
            const computedOpacity = parseFloat(computedStyle.opacity);
            return {
                type: 'opacity',
                startValue: property.startValue ?? property.defaultValue ?? computedOpacity,
                endValue: property.endValue
            };
        }
        case 'backgroundColor':
            return {
                type: 'backgroundColor',
                startColor: property.startColor ?? property.defaultColor ?? computedStyle.backgroundColor,
                endColor: property.endColor
            };
        case 'color':
            return {
                type: 'color',
                startColor: property.startColor ?? property.defaultColor ?? computedStyle.color,
                endColor: property.endColor
            };
        case 'size':
            return {
                type: 'size',
                startWidth: property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width),
                startHeight: property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height),
                endWidth: property.endWidth,
                endHeight: property.endHeight
            };
        case 'customProperty': { // NOPMD - block required for const scoping
            const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
            return {
                type: 'customProperty',
                cssProperty: property.cssProperty,
                unit: property.unit,
                startValue: property.startValue ?? computedValue,
                endValue: property.endValue
            };
        }
        case 'customColorProperty': { // NOPMD - block required for const scoping
            const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
            return {
                type: 'customColorProperty',
                cssProperty: property.cssProperty,
                startColor: property.startColor ?? computedColor,
                endColor: property.endColor
            };
        }
        case 'perspectiveOrigin': { // NOPMD - block required for const scoping
            // Prefer last-known end values (tracked in original units) over
            // computedStyle, which returns resolved pixels after commitStyles()
            // causing a unit mismatch when the animation uses percent.
            const cached = lastKnownPerspectiveOrigins.get(animGroup);
            let fallbackX, fallbackY;
            if (cached && cached.unit === property.unit) {
                fallbackX = cached.x;
                fallbackY = cached.y;
            } else {
                const computedOrigin = computedStyle.perspectiveOrigin || '50% 50%';
                const parts = computedOrigin.split(' ');
                fallbackX = parseFloat(parts[0]) || 50;
                fallbackY = parseFloat(parts[1] ?? parts[0]) || 50;
            }
            const resolved = {
                type: 'perspectiveOrigin',
                startX: property.startX ?? fallbackX,
                startY: property.startY ?? fallbackY,
                endX: property.endX,
                endY: property.endY,
                unit: property.unit
            };
            // Record the end value so the next animation can use it as its start.
            lastKnownPerspectiveOrigins.set(animGroup, { x: property.endX, y: property.endY, unit: property.unit });
            return resolved;
        }
        default:
            return null;
    }
}
export function buildSimplePropertyKeyframes(resolved) {
    switch (resolved.type) {
        case 'opacity':
            return [
                { opacity: String(resolved.startValue) },
                { opacity: String(resolved.endValue) }
            ];
        case 'backgroundColor':
            return [
                { backgroundColor: resolved.startColor },
                { backgroundColor: resolved.endColor }
            ];
        case 'color':
            return [
                { color: resolved.startColor },
                { color: resolved.endColor }
            ];
        case 'size':
            return [
                { width: resolved.startWidth + 'px', height: resolved.startHeight + 'px' },
                { width: resolved.endWidth + 'px', height: resolved.endHeight + 'px' }
            ];
        case 'customProperty':
            return [
                { [camelCase(resolved.cssProperty)]: resolved.startValue + resolved.unit },
                { [camelCase(resolved.cssProperty)]: resolved.endValue + resolved.unit }
            ];
        case 'customColorProperty':
            return [
                { [camelCase(resolved.cssProperty)]: resolved.startColor },
                { [camelCase(resolved.cssProperty)]: resolved.endColor }
            ];
        case 'perspectiveOrigin':
            return [
                { perspectiveOrigin: resolved.startX + resolved.unit + ' ' + resolved.startY + resolved.unit },
                { perspectiveOrigin: resolved.endX + resolved.unit + ' ' + resolved.endY + resolved.unit }
            ];
        default:
            return null;
    }
}

/**
 * Build a multi-keyframe array for a resolved non-transform property using
 * pre-computed easing progress values (for bounce/elastic easings).
 * Returns null for property types where this path is not supported (caller
 * should fall back to buildSimplePropertyKeyframes).
 */
export function buildComplexPropertyKeyframes(resolved, easingKeyframes) {
    switch (resolved.type) {
        case 'opacity':
            return easingKeyframes.map(p => ({
                opacity: String(resolved.startValue + (resolved.endValue - resolved.startValue) * p)
            }));
        case 'backgroundColor':
            return easingKeyframes.map(p => ({
                backgroundColor: interpolateColor(resolved.startColor, resolved.endColor, p)
            }));
        case 'color':
            return easingKeyframes.map(p => ({
                color: interpolateColor(resolved.startColor, resolved.endColor, p)
            }));
        case 'size':
            return easingKeyframes.map(p => ({
                width: (resolved.startWidth + (resolved.endWidth - resolved.startWidth) * p) + 'px',
                height: (resolved.startHeight + (resolved.endHeight - resolved.startHeight) * p) + 'px'
            }));
        case 'customProperty':
            return easingKeyframes.map(p => ({
                [camelCase(resolved.cssProperty)]: (resolved.startValue + (resolved.endValue - resolved.startValue) * p) + resolved.unit
            }));
        case 'customColorProperty':
            return easingKeyframes.map(p => ({
                [camelCase(resolved.cssProperty)]: interpolateColor(resolved.startColor, resolved.endColor, p)
            }));
        case 'perspectiveOrigin':
            return easingKeyframes.map(p => ({
                perspectiveOrigin: (resolved.startX + (resolved.endX - resolved.startX) * p) + resolved.unit
                    + ' ' + (resolved.startY + (resolved.endY - resolved.startY) * p) + resolved.unit
            }));
        default:
            return null;
    }
}

/**
 * Build keyframes and the animation easing value for a resolved non-transform property.
 * Returns { keyframes, animationEasing }.
 * When easingKeyframes is provided (complex easing), bakes it into the keyframes
 * and sets animationEasing to 'linear'. Otherwise returns 2 keyframes with the
 * CSS easing string as animationEasing.
 */
export function buildPropertyKeyframes(resolved, easingKeyframes, easing) {
    const cssEasing = easingFunctions[easing] || easing;

    if (easingKeyframes && Array.isArray(easingKeyframes)) {
        const keyframes = buildComplexPropertyKeyframes(resolved, easingKeyframes);
        if (keyframes) {
            return { keyframes, animationEasing: 'linear' };
        }
    }

    return { keyframes: buildSimplePropertyKeyframes(resolved), animationEasing: cssEasing };
}

/**
 * Create a WAAPI animation for a non-transform property using pre-resolved values.
 * Using pre-resolved values avoids a redundant DOM read (resolveNonTransformValues
 * is always called by the caller before this function).
 */
export function createPropertyAnimation(element, resolved, property, globalOptions = { iterations: 1, direction: 'normal' }) {
    if (!resolved) return null;
    const { keyframes, animationEasing } = buildPropertyKeyframes(resolved, property.easingKeyframes, property.easing);
    if (!keyframes) return null;
    return element.animate(keyframes, {
        duration: property.duration,
        easing: animationEasing,
        fill: 'forwards',
        iterations: globalOptions.iterations,
        direction: globalOptions.direction
    });
}

/**
 * Extract property configuration for lifecycle events.
 * Returns a normalized config object with from/to values as strings.
 */
export function extractPropertyConfig(animGroup, element, property) {
    const config = {
        property: property.type,
        duration: property.duration,
        easing: property.easing,
        from: '',
        to: ''
    };

    const computedStyle = window.getComputedStyle(element);

    switch (property.type) {
        case 'translate': { // NOPMD - block required for const scoping
            const currentTransform = getTransformState(animGroup, element);
            const fromX = property.startX ?? property.defaultX ?? currentTransform.x;
            const fromY = property.startY ?? property.defaultY ?? currentTransform.y;
            const fromZ = property.startZ ?? property.defaultZ ?? currentTransform.z;
            const toX = property.endX ?? currentTransform.x;
            const toY = property.endY ?? currentTransform.y;
            const toZ = property.endZ ?? currentTransform.z;
            config.from = `${fromX},${fromY},${fromZ}`;
            config.to = `${toX},${toY},${toZ}`;
            break;
        }
        case 'scale': { // NOPMD - block required for const scoping
            const currentTransform = getTransformState(animGroup, element);
            const fromX = property.startX ?? property.defaultX ?? currentTransform.scaleX;
            const fromY = property.startY ?? property.defaultY ?? currentTransform.scaleY;
            const fromZ = property.startZ ?? property.defaultZ ?? currentTransform.scaleZ;
            const toX = property.endX ?? currentTransform.scaleX;
            const toY = property.endY ?? currentTransform.scaleY;
            const toZ = property.endZ ?? currentTransform.scaleZ;
            config.from = `${fromX},${fromY},${fromZ}`;
            config.to = `${toX},${toY},${toZ}`;
            break;
        }
        case 'rotate': { // NOPMD - block required for const scoping
            const currentTransform = getTransformState(animGroup, element);
            const fromX = property.startX ?? property.defaultX ?? currentTransform.rotateX;
            const fromY = property.startY ?? property.defaultY ?? currentTransform.rotateY;
            const fromZ = property.startZ ?? property.defaultZ ?? currentTransform.rotateZ;
            const toX = property.endX ?? currentTransform.rotateX;
            const toY = property.endY ?? currentTransform.rotateY;
            const toZ = property.endZ ?? currentTransform.rotateZ;
            config.from = `${fromX},${fromY},${fromZ}`;
            config.to = `${toX},${toY},${toZ}`;
            break;
        }
        case 'skew': { // NOPMD - block required for const scoping
            const currentTransform = getTransformState(animGroup, element);
            const fromX = property.startX ?? currentTransform.skewX;
            const fromY = property.startY ?? currentTransform.skewY;
            const toX = property.endX ?? currentTransform.skewX;
            const toY = property.endY ?? currentTransform.skewY;
            config.from = `${fromX},${fromY}`;
            config.to = `${toX},${toY}`;
            break;
        }
        case 'opacity': { // NOPMD - block required for const scoping
            const computedOpacity = parseFloat(computedStyle.opacity);
            const fromVal = property.startValue ?? property.defaultValue ?? computedOpacity;
            config.from = `${fromVal}`;
            config.to = `${property.endValue}`;
            break;
        }
        case 'backgroundColor':
        case 'color': { // NOPMD - block required for const scoping
            const cssProp = property.type === 'backgroundColor' ? 'backgroundColor' : 'color';
            const computedColor = computedStyle[cssProp];
            config.from = property.startColor ?? property.defaultColor ?? computedColor;
            config.to = property.endColor;
            break;
        }
        case 'size': { // NOPMD - block required for const scoping
            const startWidth = property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width);
            const startHeight = property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height);
            config.from = `${startWidth},${startHeight}`;
            config.to = `${property.endWidth},${property.endHeight}`;
            break;
        }
        case 'customProperty': { // NOPMD - block required for const scoping
            const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
            const fromVal = property.startValue ?? computedValue;
            config.property = property.cssProperty;
            config.from = `${fromVal}${property.unit}`;
            config.to = `${property.endValue}${property.unit}`;
            break;
        }
        case 'customColorProperty': { // NOPMD - block required for const scoping
            const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
            config.property = property.cssProperty;
            config.from = property.startColor ?? computedColor;
            config.to = property.endColor;
            break;
        }
        case 'perspectiveOrigin':
            config.from = `${property.startX}${property.unit} ${property.startY}${property.unit}`;
            config.to = `${property.endX}${property.unit} ${property.endY}${property.unit}`;
            break;
    }

    return config;
}

/**
 * Resolve both the start and end transform component values for scroll-driven
 * animations in a single pass, eliminating the need for two separate iterators.
 * Returns { start, end } where each is a flat transform state object.
 */
export function resolveScrollDrivenTransformValues(transformProperties, currentTransform) {
    const base = {
        x: currentTransform.x, y: currentTransform.y, z: currentTransform.z,
        scaleX: currentTransform.scaleX, scaleY: currentTransform.scaleY, scaleZ: currentTransform.scaleZ,
        rotateX: currentTransform.rotateX, rotateY: currentTransform.rotateY, rotateZ: currentTransform.rotateZ,
        skewX: currentTransform.skewX, skewY: currentTransform.skewY
    };
    const start = Object.assign({}, base);
    const end = Object.assign({}, base);

    transformProperties.forEach(function (p) {
        switch (p.type) {
            case 'translate':
                start.x = p.startX ?? p.defaultX ?? currentTransform.x;
                start.y = p.startY ?? p.defaultY ?? currentTransform.y;
                start.z = p.startZ ?? p.defaultZ ?? currentTransform.z;
                end.x = p.endX ?? currentTransform.x;
                end.y = p.endY ?? currentTransform.y;
                end.z = p.endZ ?? currentTransform.z;
                break;
            case 'scale':
                start.scaleX = p.startX ?? p.defaultX ?? currentTransform.scaleX;
                start.scaleY = p.startY ?? p.defaultY ?? currentTransform.scaleY;
                start.scaleZ = p.startZ ?? p.defaultZ ?? currentTransform.scaleZ;
                end.scaleX = p.endX ?? currentTransform.scaleX;
                end.scaleY = p.endY ?? currentTransform.scaleY;
                end.scaleZ = p.endZ ?? currentTransform.scaleZ;
                break;
            case 'rotate':
                start.rotateX = p.startX ?? p.defaultX ?? currentTransform.rotateX;
                start.rotateY = p.startY ?? p.defaultY ?? currentTransform.rotateY;
                start.rotateZ = p.startZ ?? p.defaultZ ?? currentTransform.rotateZ;
                end.rotateX = p.endX ?? currentTransform.rotateX;
                end.rotateY = p.endY ?? currentTransform.rotateY;
                end.rotateZ = p.endZ ?? currentTransform.rotateZ;
                break;
            case 'skew':
                start.skewX = p.startX ?? currentTransform.skewX;
                start.skewY = p.startY ?? currentTransform.skewY;
                end.skewX = p.endX ?? currentTransform.skewX;
                end.skewY = p.endY ?? currentTransform.skewY;
                break;
        }
    });

    return { start, end };
}
