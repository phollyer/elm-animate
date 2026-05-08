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

function resolvePerspectiveOriginValues(animGroup, computedStyle, property) {
    const cached = lastKnownPerspectiveOrigins.get(animGroup);
    const computedOrigin = computedStyle.perspectiveOrigin || '50% 50%';
    const parts = computedOrigin.split(' ');
    const fallbackX = cached && cached.unit === property.unit ? cached.x : (parseFloat(parts[0]) || 50);
    const fallbackY = cached && cached.unit === property.unit ? cached.y : (parseFloat(parts[1] ?? parts[0]) || 50);

    const resolved = {
        type: 'perspectiveOrigin',
        startX: property.startX ?? fallbackX,
        startY: property.startY ?? fallbackY,
        endX: property.endX,
        endY: property.endY,
        unit: property.unit
    };

    lastKnownPerspectiveOrigins.set(animGroup, { x: property.endX, y: property.endY, unit: property.unit });
    return resolved;
}

const NON_TRANSFORM_RESOLVERS = {
    opacity(_animGroup, computedStyle, property) {
        const computedOpacity = parseFloat(computedStyle.opacity);
        return {
            type: 'opacity',
            startValue: property.startValue ?? property.defaultValue ?? computedOpacity,
            endValue: property.endValue
        };
    },
    size(_animGroup, computedStyle, property) {
        return {
            type: 'size',
            startWidth: property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width),
            startHeight: property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height),
            endWidth: property.endWidth,
            endHeight: property.endHeight
        };
    },
    customProperty(_animGroup, computedStyle, property) {
        const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
        return {
            type: 'customProperty',
            cssProperty: property.cssProperty,
            unit: property.unit,
            startValue: property.startValue ?? computedValue,
            endValue: property.endValue
        };
    },
    customColorProperty(_animGroup, computedStyle, property) {
        const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
        return {
            type: 'customColorProperty',
            cssProperty: property.cssProperty,
            startColor: property.startColor ?? computedColor,
            endColor: property.endColor
        };
    },
    perspectiveOrigin(animGroup, computedStyle, property) {
        return resolvePerspectiveOriginValues(animGroup, computedStyle, property);
    }
};

function getCurrentTransformConfig(animGroup, element, property, axes) {
    const currentTransform = getTransformState(animGroup, element);
    const fromValues = axes.map(({ suffix, currentKey, useDefault = true }) => {
        const defaultValue = useDefault ? property[`default${suffix}`] : undefined;
        return property[`start${suffix}`] ?? defaultValue ?? currentTransform[currentKey];
    });
    const toValues = axes.map(({ suffix, currentKey }) => property[`end${suffix}`] ?? currentTransform[currentKey]);
    return {
        from: fromValues.join(','),
        to: toValues.join(',')
    };
}

const TRANSFORM_CONFIG_AXES = {
    translate: [
        { suffix: 'X', currentKey: 'x' },
        { suffix: 'Y', currentKey: 'y' },
        { suffix: 'Z', currentKey: 'z' }
    ],
    scale: [
        { suffix: 'X', currentKey: 'scaleX' },
        { suffix: 'Y', currentKey: 'scaleY' },
        { suffix: 'Z', currentKey: 'scaleZ' }
    ],
    rotate: [
        { suffix: 'X', currentKey: 'rotateX' },
        { suffix: 'Y', currentKey: 'rotateY' },
        { suffix: 'Z', currentKey: 'rotateZ' }
    ],
    skew: [
        { suffix: 'X', currentKey: 'skewX', useDefault: false },
        { suffix: 'Y', currentKey: 'skewY', useDefault: false }
    ]
};

function buildTransformPropertyConfig(animGroup, element, _computedStyle, property, config) {
    Object.assign(config, getCurrentTransformConfig(animGroup, element, property, TRANSFORM_CONFIG_AXES[property.type]));
}

const PROPERTY_CONFIG_BUILDERS = {
    translate: buildTransformPropertyConfig,
    scale: buildTransformPropertyConfig,
    rotate: buildTransformPropertyConfig,
    skew: buildTransformPropertyConfig,
    opacity(_animGroup, _element, computedStyle, property, config) {
        const computedOpacity = parseFloat(computedStyle.opacity);
        const fromVal = property.startValue ?? property.defaultValue ?? computedOpacity;
        config.from = `${fromVal}`;
        config.to = `${property.endValue}`;
    },
    size(_animGroup, _element, computedStyle, property, config) {
        const startWidth = property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width);
        const startHeight = property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height);
        config.from = `${startWidth},${startHeight}`;
        config.to = `${property.endWidth},${property.endHeight}`;
    },
    customProperty(_animGroup, _element, computedStyle, property, config) {
        const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
        const fromVal = property.startValue ?? computedValue;
        config.property = property.cssProperty;
        config.from = `${fromVal}${property.unit}`;
        config.to = `${property.endValue}${property.unit}`;
    },
    customColorProperty(_animGroup, _element, computedStyle, property, config) {
        const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
        config.property = property.cssProperty;
        config.from = property.startColor ?? computedColor;
        config.to = property.endColor;
    },
    perspectiveOrigin(_animGroup, _element, _computedStyle, property, config) {
        config.from = `${property.startX}${property.unit} ${property.startY}${property.unit}`;
        config.to = `${property.endX}${property.unit} ${property.endY}${property.unit}`;
    }
};

function assignResolvedAxes(start, end, property, currentTransform, axes) {
    axes.forEach(({ suffix, startKey, defaultKey, currentKey, endKey }) => {
        start[startKey] = defaultKey
            ? property[`start${suffix}`] ?? property[`default${suffix}`] ?? currentTransform[currentKey]
            : property[`start${suffix}`] ?? currentTransform[currentKey];
        end[endKey] = property[`end${suffix}`] ?? currentTransform[currentKey];
    });
}

const SCROLL_TRANSFORM_AXES = {
    translate: [
        { suffix: 'X', startKey: 'x', endKey: 'x', currentKey: 'x', defaultKey: 'defaultX' },
        { suffix: 'Y', startKey: 'y', endKey: 'y', currentKey: 'y', defaultKey: 'defaultY' },
        { suffix: 'Z', startKey: 'z', endKey: 'z', currentKey: 'z', defaultKey: 'defaultZ' }
    ],
    scale: [
        { suffix: 'X', startKey: 'scaleX', endKey: 'scaleX', currentKey: 'scaleX', defaultKey: 'defaultX' },
        { suffix: 'Y', startKey: 'scaleY', endKey: 'scaleY', currentKey: 'scaleY', defaultKey: 'defaultY' },
        { suffix: 'Z', startKey: 'scaleZ', endKey: 'scaleZ', currentKey: 'scaleZ', defaultKey: 'defaultZ' }
    ],
    rotate: [
        { suffix: 'X', startKey: 'rotateX', endKey: 'rotateX', currentKey: 'rotateX', defaultKey: 'defaultX' },
        { suffix: 'Y', startKey: 'rotateY', endKey: 'rotateY', currentKey: 'rotateY', defaultKey: 'defaultY' },
        { suffix: 'Z', startKey: 'rotateZ', endKey: 'rotateZ', currentKey: 'rotateZ', defaultKey: 'defaultZ' }
    ],
    skew: [
        { suffix: 'X', startKey: 'skewX', endKey: 'skewX', currentKey: 'skewX' },
        { suffix: 'Y', startKey: 'skewY', endKey: 'skewY', currentKey: 'skewY' }
    ]
};

function resolveScrollTransformProperty(property, start, end, currentTransform) {
    const axes = SCROLL_TRANSFORM_AXES[property.type];
    if (axes) {
        assignResolvedAxes(start, end, property, currentTransform, axes);
    }
}

const SIMPLE_KEYFRAME_BUILDERS = {
    opacity(resolved) {
        return [
            { opacity: String(resolved.startValue) },
            { opacity: String(resolved.endValue) }
        ];
    },
    size(resolved) {
        return [
            { width: resolved.startWidth + 'px', height: resolved.startHeight + 'px' },
            { width: resolved.endWidth + 'px', height: resolved.endHeight + 'px' }
        ];
    },
    customProperty(resolved) {
        return [
            { [camelCase(resolved.cssProperty)]: resolved.startValue + resolved.unit },
            { [camelCase(resolved.cssProperty)]: resolved.endValue + resolved.unit }
        ];
    },
    customColorProperty(resolved) {
        return [
            { [camelCase(resolved.cssProperty)]: resolved.startColor },
            { [camelCase(resolved.cssProperty)]: resolved.endColor }
        ];
    },
    perspectiveOrigin(resolved) {
        return [
            { perspectiveOrigin: resolved.startX + resolved.unit + ' ' + resolved.startY + resolved.unit },
            { perspectiveOrigin: resolved.endX + resolved.unit + ' ' + resolved.endY + resolved.unit }
        ];
    }
};

const COMPLEX_KEYFRAME_BUILDERS = {
    opacity(resolved, easingKeyframes) {
        return easingKeyframes.map(p => ({
            opacity: String(resolved.startValue + (resolved.endValue - resolved.startValue) * p)
        }));
    },
    size(resolved, easingKeyframes) {
        return easingKeyframes.map(p => ({
            width: (resolved.startWidth + (resolved.endWidth - resolved.startWidth) * p) + 'px',
            height: (resolved.startHeight + (resolved.endHeight - resolved.startHeight) * p) + 'px'
        }));
    },
    customProperty(resolved, easingKeyframes) {
        return easingKeyframes.map(p => ({
            [camelCase(resolved.cssProperty)]: (resolved.startValue + (resolved.endValue - resolved.startValue) * p) + resolved.unit
        }));
    },
    customColorProperty(resolved, easingKeyframes) {
        return easingKeyframes.map(p => ({
            [camelCase(resolved.cssProperty)]: interpolateColor(resolved.startColor, resolved.endColor, p)
        }));
    },
    perspectiveOrigin(resolved, easingKeyframes) {
        return easingKeyframes.map(p => ({
            perspectiveOrigin: (resolved.startX + (resolved.endX - resolved.startX) * p) + resolved.unit
                + ' ' + (resolved.startY + (resolved.endY - resolved.startY) * p) + resolved.unit
        }));
    }
};

/**
 * Resolve start/end values for a non-transform property so they can be
 * used to compute interpolated values without reading the DOM later.
 */
export function resolveNonTransformValues(animGroup, element, property) {
    const computedStyle = window.getComputedStyle(element);
    const resolver = NON_TRANSFORM_RESOLVERS[property.type];
    return resolver ? resolver(animGroup, computedStyle, property) : null;
}
export function buildSimplePropertyKeyframes(resolved) {
    const buildKeyframes = SIMPLE_KEYFRAME_BUILDERS[resolved.type];
    return buildKeyframes ? buildKeyframes(resolved) : null;
}

/**
 * Build a multi-keyframe array for a resolved non-transform property using
 * pre-computed easing progress values (for bounce/elastic easings).
 * Returns null for property types where this path is not supported (caller
 * should fall back to buildSimplePropertyKeyframes).
 */
export function buildComplexPropertyKeyframes(resolved, easingKeyframes) {
    const buildKeyframes = COMPLEX_KEYFRAME_BUILDERS[resolved.type];
    return buildKeyframes ? buildKeyframes(resolved, easingKeyframes) : null;
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

    const buildConfig = PROPERTY_CONFIG_BUILDERS[property.type];
    if (buildConfig) {
        buildConfig(animGroup, element, computedStyle, property, config);
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

    transformProperties.forEach(function (property) {
        resolveScrollTransformProperty(property, start, end, currentTransform);
    });

    return { start, end };
}
