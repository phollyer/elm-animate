// Pure utility functions — no browser globals, no DOM access, no side effects.

/** Default CSS transform property order. */
const DEFAULT_TRANSFORM_ORDER = ['translate', 'rotate', 'skew', 'scale'];

/** CSS easing function map: Elm name → WAAPI CSS value. */
const easingFunctions = {
    'linear': 'linear',
    'ease': 'ease',
    'ease-in': 'ease-in',
    'ease-out': 'ease-out',
    'ease-in-out': 'ease-in-out',
    'ease-in-cubic': 'cubic-bezier(0.55, 0.055, 0.675, 0.19)',
    'ease-out-cubic': 'cubic-bezier(0.215, 0.61, 0.355, 1)',
    'ease-in-out-cubic': 'cubic-bezier(0.645, 0.045, 0.355, 1)',
    'ease-in-back': 'cubic-bezier(0.6, -0.28, 0.735, 0.045)',
    'ease-out-back': 'cubic-bezier(0.175, 0.885, 0.32, 1.275)',
    'ease-in-out-back': 'cubic-bezier(0.68, -0.55, 0.265, 1.55)'
};

/**
 * Returns true if the property type is a CSS transform sub-property.
 * @param {string} type
 */
function isTransformProperty(type) {
    return type === 'translate' || type === 'scale' || type === 'rotate' || type === 'skew';
}

/**
 * Parse an Elm iterations config object to a WAAPI iterations value.
 * @param {object|undefined} iterations
 * @returns {number}
 */
function parseIterations(iterations) {
    if (!iterations) return 1;
    switch (iterations.type) {
        case 'infinite': return Infinity;
        case 'times': return iterations.count;
        case 'once':
        default: return 1;
    }
}

/**
 * Convert a kebab-case CSS property name to camelCase for WAAPI keyframes.
 * e.g. "border-radius" → "borderRadius"
 * @param {string} str
 */
function camelCase(str) {
    return str.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

/**
 * Slowest-wins group iteration tracking.
 * Each property updates its own slot in perAnimIterations. The group iteration
 * event fires only when ALL properties have completed the same loop
 * (i.e. Math.min of all slots advances past storedCount).
 * @param {number[]} perAnimIterations - Per-property iteration slots (mutated)
 * @param {number} propertyIndex - Index of the updating property
 * @param {number|undefined} currentIteration - Current iteration from WAAPI timing
 * @param {number} storedCount - Last emitted iteration count
 * @returns {number|null} New group iteration count, or null if unchanged
 */
function updateGroupIteration(perAnimIterations, propertyIndex, currentIteration, storedCount) {
    if (currentIteration == null || propertyIndex < 0 || propertyIndex >= perAnimIterations.length) {
        return null;
    }
    perAnimIterations[propertyIndex] = currentIteration;
    const minIteration = Math.min.apply(null, perAnimIterations);
    return minIteration > storedCount ? minIteration : null;
}

// Shared mutable state for all animation tracking.

// Active WAAPI animations per animation group.
// Map<animGroup, Map<propertyType, { animation, version, updateFn, animGroup, ... }>>
const activeAnimations = new Map();

// Animation group lifecycle tracking.
// Map<animGroup, { totalProperties, completedProperties, started, generation,
//                  nextPropertyIndex, lastIteration, propertyIterations, propertyConfigs }>
const animationGroups = new Map();

// Last-known correct transform values per animation group (in original CSS units).
// Avoids matrix decomposition normalisation (360° → 0°, 270° → -90°).
// Map<animGroup, { x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY }>
const lastKnownTransforms = new Map();

// Last-known perspectiveOrigin end values per animation group in original units.
// commitStyles() bakes resolved pixels into inline style, causing unit mismatch.
// Map<animGroup, { x: number, y: number, unit: string }>
const lastKnownPerspectiveOrigins = new Map();

// Group-level iteration counts for scroll-driven animations.
// Deduplicates iteration events: N properties fire N native events per loop, we emit one.
// Map<animGroup, number>
const scrollDrivenIterationCounts = new Map();

// Per-element transform order for consistent CSS transform rendering.
// Map<animGroup, string[]>  e.g. ['translate', 'rotate', 'skew', 'scale']
const elementTransformOrders = new Map();

/* eslint-env browser */
/* global window */

/**
 * Get the default identity transform state (no translation, no rotation, unit scale).
 * Used as a fallback when no prior transform state is known.
 */
function getDefaultTransformState() {
    return { x: 0, y: 0, z: 0, scaleX: 1, scaleY: 1, scaleZ: 1, rotateX: 0, rotateY: 0, rotateZ: 0, skewX: 0, skewY: 0 };
}

/**
 * Ensure transform state is complete and numeric.
 * Guards against partial cached objects (missing skew fields) and NaN values.
 */
function normalizeTransformState(state) {
    const defaults = getDefaultTransformState();
    const source = state || defaults;

    const num = (value, fallback) => Number.isFinite(value) ? value : fallback;

    return {
        x: num(source.x, defaults.x),
        y: num(source.y, defaults.y),
        z: num(source.z, defaults.z),
        scaleX: num(source.scaleX, defaults.scaleX),
        scaleY: num(source.scaleY, defaults.scaleY),
        scaleZ: num(source.scaleZ, defaults.scaleZ),
        rotateX: num(source.rotateX, defaults.rotateX),
        rotateY: num(source.rotateY, defaults.rotateY),
        rotateZ: num(source.rotateZ, defaults.rotateZ),
        skewX: num(source.skewX, defaults.skewX),
        skewY: num(source.skewY, defaults.skewY)
    };
}

/**
 * Get the current transform state for an element, preferring cached values from
 * lastKnownTransforms over DOM reads via getCurrentTransform().
 * This avoids matrix decomposition normalisation that loses angle information.
 */
function getTransformState(animGroup, element) {
    const cached = lastKnownTransforms.get(animGroup);
    if (cached) {
        return normalizeTransformState(cached);
    }
    return normalizeTransformState(getCurrentTransform(element));
}

/**
 * Get the stored transform order for a DOM element.
 */
function getElementOrder(element) {
    const id = element.getAttribute('data-anim-target') || element.id;
    return elementTransformOrders.get(id) || DEFAULT_TRANSFORM_ORDER;
}

/**
 * Build a complete transform string with 3D support.
 * The order parameter controls the order of translate, rotate, and scale
 * in the output string. Rotation axes are always applied X → Y → Z within
 * the rotate group.
 */
function buildTransformString(x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY, order) {
    const asNumber = (value, fallback) => Number.isFinite(value) ? value : fallback;
    const tx = asNumber(x, 0);
    const ty = asNumber(y, 0);
    const tz = asNumber(z, 0);
    const sx = asNumber(scaleX, 1);
    const sy = asNumber(scaleY, 1);
    const sz = asNumber(scaleZ, 1);
    const rx = asNumber(rotateX, 0);
    const ry = asNumber(rotateY, 0);
    const rz = asNumber(rotateZ, 0);
    const kx = asNumber(skewX, 0);
    const ky = asNumber(skewY, 0);

    const transformOrder = order || DEFAULT_TRANSFORM_ORDER;
    const parts = [];

    for (const group of transformOrder) {
        switch (group) {
            case 'translate':
                if (tx !== 0 || ty !== 0 || tz !== 0) {
                    parts.push(`translate3d(${tx}px, ${ty}px, ${tz}px)`);
                }
                break;
            case 'rotate':
                if (rx !== 0) {
                    parts.push(`rotateX(${rx}deg)`);
                }
                if (ry !== 0) {
                    parts.push(`rotateY(${ry}deg)`);
                }
                if (rz !== 0) {
                    parts.push(`rotateZ(${rz}deg)`);
                }
                break;
            case 'skew':
                if (kx !== 0) {
                    parts.push(`skewX(${kx}deg)`);
                }
                if (ky !== 0) {
                    parts.push(`skewY(${ky}deg)`);
                }
                break;
            case 'scale':
                if (sx !== 1) {
                    parts.push(`scaleX(${sx})`);
                }
                if (sy !== 1) {
                    parts.push(`scaleY(${sy})`);
                }
                if (sz !== 1) {
                    parts.push(`scaleZ(${sz})`);
                }
                break;
        }
    }

    return parts.join(' ') || 'none';
}

/**
 * Parse a CSS transform string (e.g. "translate3d(10px, 20px, 30px) rotateY(90deg)")
 * into individual transform components. This preserves axis-specific values that
 * are lost when the browser computes a matrix3d.
 */
function parseTransformString(transformStr) {
    const result = {
        transform: transformStr,
        x: 0, y: 0, z: 0,
        scaleX: 1, scaleY: 1, scaleZ: 1,
        rotateX: 0, rotateY: 0, rotateZ: 0,
        skewX: 0, skewY: 0
    };

    // translate3d(Xpx, Ypx, Zpx)
    const translate3d = transformStr.match(/translate3d\(\s*([-\d.]+)px\s*,\s*([-\d.]+)px\s*,\s*([-\d.]+)px\s*\)/);
    if (translate3d) {
        result.x = parseFloat(translate3d[1]);
        result.y = parseFloat(translate3d[2]);
        result.z = parseFloat(translate3d[3]);
    }

    // translateX(Xpx), translateY(Ypx), translateZ(Zpx)
    const translateX = transformStr.match(/translateX\(\s*([-\d.]+)px\s*\)/);
    const translateY = transformStr.match(/translateY\(\s*([-\d.]+)px\s*\)/);
    const translateZ = transformStr.match(/translateZ\(\s*([-\d.]+)px\s*\)/);
    if (translateX) result.x = parseFloat(translateX[1]);
    if (translateY) result.y = parseFloat(translateY[1]);
    if (translateZ) result.z = parseFloat(translateZ[1]);

    // rotateX(Xdeg), rotateY(Ydeg), rotateZ(Zdeg)
    const rotateX = transformStr.match(/rotateX\(\s*([-\d.]+)deg\s*\)/);
    const rotateY = transformStr.match(/rotateY\(\s*([-\d.]+)deg\s*\)/);
    const rotateZ = transformStr.match(/rotateZ\(\s*([-\d.]+)deg\s*\)/);
    if (rotateX) result.rotateX = parseFloat(rotateX[1]);
    if (rotateY) result.rotateY = parseFloat(rotateY[1]);
    if (rotateZ) result.rotateZ = parseFloat(rotateZ[1]);

    // skewX(Xdeg), skewY(Ydeg)
    const skewX = transformStr.match(/skewX\(\s*([-\d.]+)deg\s*\)/);
    const skewY = transformStr.match(/skewY\(\s*([-\d.]+)deg\s*\)/);
    if (skewX) result.skewX = parseFloat(skewX[1]);
    if (skewY) result.skewY = parseFloat(skewY[1]);

    // skew(Xdeg, Ydeg) - 2D shorthand
    const skew2d = transformStr.match(/skew\(\s*([-\d.]+)deg\s*(?:,\s*([-\d.]+)deg\s*)?\)/);
    if (skew2d && !skewX && !skewY) {
        result.skewX = parseFloat(skew2d[1]);
        result.skewY = skew2d[2] ? parseFloat(skew2d[2]) : 0;
    }

    // scale3d(X, Y, Z)
    const scale3d = transformStr.match(/scale3d\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)/);
    if (scale3d) {
        result.scaleX = parseFloat(scale3d[1]);
        result.scaleY = parseFloat(scale3d[2]);
        result.scaleZ = parseFloat(scale3d[3]);
    }

    // scaleX(X), scaleY(Y), scaleZ(Z)
    const scaleX = transformStr.match(/scaleX\(\s*([-\d.]+)\s*\)/);
    const scaleY = transformStr.match(/scaleY\(\s*([-\d.]+)\s*\)/);
    const scaleZ = transformStr.match(/scaleZ\(\s*([-\d.]+)\s*\)/);
    if (scaleX) result.scaleX = parseFloat(scaleX[1]);
    if (scaleY) result.scaleY = parseFloat(scaleY[1]);
    if (scaleZ) result.scaleZ = parseFloat(scaleZ[1]);

    // scale(X, Y) - 2D shorthand
    const scale2d = transformStr.match(/scale\(\s*([-\d.]+)\s*(?:,\s*([-\d.]+)\s*)?\)/);
    if (scale2d && !scale3d) {
        result.scaleX = parseFloat(scale2d[1]);
        result.scaleY = scale2d[2] ? parseFloat(scale2d[2]) : parseFloat(scale2d[1]);
    }

    return result;
}

/**
 * Get current transform state of an element with 3D support.
 * When a WAAPI animation is active, uses getComputedStyle which reflects the
 * real animated values (including the WAAPI compositing layer). When no animation
 * is running, falls back to reading the inline style which preserves committed
 * final values with individual transform functions (rotateX, rotateY, etc.).
 */
function getCurrentTransform(element) {
    // Check if this element has active WAAPI animations.
    // If so, getComputedStyle reflects the real animated state (including the
    // WAAPI layer), while inline style only has the optimistic end values from Elm.
    const hasActiveAnimation = element.getAnimations && element.getAnimations().length > 0;

    if (!hasActiveAnimation) {
        // No WAAPI animation running - parse inline style which preserves
        // individual transform functions (rotateX, rotateY, etc.) from commitStyles
        const inlineTransform = element.style.transform;
        if (inlineTransform && inlineTransform !== 'none') {
            return parseTransformString(inlineTransform);
        }
    }

    // Use computed style - this reflects the actual animated transform
    const style = window.getComputedStyle(element);
    const transform = style.transform;

    if (transform === 'none' || !transform) {
        return {
            transform: 'none',
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0
        };
    }

    // Parse transform matrix (2D or 3D)
    const matrix2d = transform.match(/matrix\((.+)\)/);
    const matrix3d = transform.match(/matrix3d\((.+)\)/);

    if (matrix3d) {
        const values = matrix3d[1].split(', ').map(parseFloat);

        if (values.length === 16) {
            const tx = values[12] || 0;
            const ty = values[13] || 0;
            const tz = values[14] || 0;

            // Extract scale from column vector lengths
            const scaleX = Math.sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2]);
            const scaleY = Math.sqrt(values[4] * values[4] + values[5] * values[5] + values[6] * values[6]);
            const scaleZ = Math.sqrt(values[8] * values[8] + values[9] * values[9] + values[10] * values[10]);

            // Extract rotation matrix by dividing out scale
            const r00 = scaleX !== 0 ? values[0] / scaleX : 0;
            const r10 = scaleX !== 0 ? values[1] / scaleX : 0;
            const r20 = scaleX !== 0 ? values[2] / scaleX : 0;
            const r01 = scaleY !== 0 ? values[4] / scaleY : 0;
            const r11 = scaleY !== 0 ? values[5] / scaleY : 0;
            const r21 = scaleY !== 0 ? values[6] / scaleY : 0;
            const r22 = scaleZ !== 0 ? values[10] / scaleZ : 0;

            // Euler angles (XYZ convention) from rotation matrix
            const RAD_TO_DEG = 180 / Math.PI;
            let rotateX, rotateY, rotateZ;

            const sinY = -r20;
            if (sinY >= 1) {
                // Gimbal lock at +90 degrees
                rotateY = 90;
                rotateX = Math.atan2(r01, r11) * RAD_TO_DEG;
                rotateZ = 0;
            } else if (sinY <= -1) {
                // Gimbal lock at -90 degrees
                rotateY = -90;
                rotateX = Math.atan2(r01, r11) * RAD_TO_DEG;
                rotateZ = 0;
            } else {
                rotateY = Math.asin(sinY) * RAD_TO_DEG;
                rotateX = Math.atan2(r21, r22) * RAD_TO_DEG;
                rotateZ = Math.atan2(r10, r00) * RAD_TO_DEG;
            }

            return { transform, x: tx, y: ty, z: tz, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX: 0, skewY: 0 };
        }
    } else if (matrix2d) {
        const values = matrix2d[1].split(', ').map(parseFloat);

        if (values.length === 6) {
            const a = values[0];
            const b = values[1];
            const c = values[2];
            const d = values[3];
            const tx = values[4] || 0;
            const ty = values[5] || 0;

            const scaleX = Math.sqrt(a * a + b * b);
            const scaleY = Math.sqrt(c * c + d * d);
            const rotateZ = Math.atan2(b, a) * (180 / Math.PI);

            return {
                transform,
                x: tx, y: ty, z: 0,
                scaleX, scaleY, scaleZ: 1,
                rotateX: 0, rotateY: 0, rotateZ,
                skewX: 0, skewY: 0
            };
        }
    }

    return {
        transform,
        x: 0, y: 0, z: 0,
        scaleX: 1, scaleY: 1, scaleZ: 1,
        rotateX: 0, rotateY: 0, rotateZ: 0,
        skewX: 0, skewY: 0
    };
}

/**
 * Interpolate a transform sub-property at a given global progress,
 * accounting for its own duration and easing.
 */
function interpolateSubProperty(subProp, globalProgress, maxDuration) {
    // Scale progress by duration ratio (shorter animations complete before globalProgress=1)
    const durationRatio = subProp.duration > 0 ? subProp.duration / maxDuration : 1;
    const localProgress = Math.min(1.0, durationRatio > 0 ? globalProgress / durationRatio : 1.0);

    // Apply easing
    let easedProgress;
    if (subProp.easingKeyframes && Array.isArray(subProp.easingKeyframes) && subProp.easingKeyframes.length > 1) {
        // Complex easing (bounce, elastic): linearly interpolate between
        // pre-computed keyframes to match the browser's linear interpolation
        // within the 30-keyframe WAAPI animation.
        const len = subProp.easingKeyframes.length;
        const rawIdx = localProgress * (len - 1);
        const idx = Math.min(Math.floor(rawIdx), len - 2);
        const fraction = rawIdx - idx;
        easedProgress = subProp.easingKeyframes[idx] +
            (subProp.easingKeyframes[idx + 1] - subProp.easingKeyframes[idx]) * fraction;
    } else {
        // Simple easing: the browser handles easing via CSS animation-timing-function.
        // Use linear here since the CSS easing is applied by the browser, not by us.
        easedProgress = localProgress;
    }

    return {
        x: subProp.startX + (subProp.endX - subProp.startX) * easedProgress,
        y: subProp.startY + (subProp.endY - subProp.startY) * easedProgress,
        z: subProp.startZ + (subProp.endZ - subProp.startZ) * easedProgress
    };
}

/**
 * Compute transform state from resolved start/end values at a given progress.
 * Uses interpolateSubProperty so per-sub-property duration and easing are
 * respected (important for the complex multi-easing case).
 * @returns {{ x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY }}
 */
function computeTransformFromResolved(resolved, globalProgress, maxDuration) {
    const t = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
    const s = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
    const r = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
    const k = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);
    return {
        x: t.x, y: t.y, z: t.z,
        scaleX: s.x, scaleY: s.y, scaleZ: s.z,
        rotateX: r.x, rotateY: r.y, rotateZ: r.z,
        skewX: k.x, skewY: k.y
    };
}

/* eslint-env browser */
/* global window */

/**
 * Interpolate between two color strings.
 */
function interpolateColor(startColor, endColor, progress) {
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

function parsePerspectiveOriginParts(computedStyle) {
    const computedOrigin = computedStyle.perspectiveOrigin || '50% 50%';
    const parts = computedOrigin.split(' ');
    const rawY = parts[1] ?? parts[0];
    return {
        x: parseFloat(parts[0]) || 50,
        y: parseFloat(rawY) || 50
    };
}

function getPerspectiveOriginFallback(animGroup, computedStyle, unit) {
    const cached = lastKnownPerspectiveOrigins.get(animGroup);
    if (cached && cached.unit === unit) {
        return { x: cached.x, y: cached.y };
    }
    return parsePerspectiveOriginParts(computedStyle);
}

function resolvePerspectiveOriginValues(animGroup, computedStyle, property) {
    const fallback = getPerspectiveOriginFallback(animGroup, computedStyle, property.unit);
    const resolved = {
        type: 'perspectiveOrigin',
        startX: property.startX ?? fallback.x,
        startY: property.startY ?? fallback.y,
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
function resolveNonTransformValues(animGroup, element, property) {
    const computedStyle = window.getComputedStyle(element);
    const resolver = NON_TRANSFORM_RESOLVERS[property.type];
    return resolver ? resolver(animGroup, computedStyle, property) : null;
}
function buildSimplePropertyKeyframes(resolved) {
    const buildKeyframes = SIMPLE_KEYFRAME_BUILDERS[resolved.type];
    return buildKeyframes ? buildKeyframes(resolved) : null;
}

/**
 * Build a multi-keyframe array for a resolved non-transform property using
 * pre-computed easing progress values (for bounce/elastic easings).
 * Returns null for property types where this path is not supported (caller
 * should fall back to buildSimplePropertyKeyframes).
 */
function buildComplexPropertyKeyframes(resolved, easingKeyframes) {
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
function buildPropertyKeyframes(resolved, easingKeyframes, easing) {
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
function createPropertyAnimation(element, resolved, property, globalOptions = { iterations: 1, direction: 'normal' }) {
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
function extractPropertyConfig(animGroup, element, property) {
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
function resolveScrollDrivenTransformValues(transformProperties, currentTransform) {
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

/* eslint-env browser */
/* global window */


/**
 * Send data to Elm via the waapiEvent port.
 * All port communication funnels through this single function.
 */
function sendToElm(data) {
    if (window.app && window.app.ports && window.app.ports.waapiEvent) {
        window.app.ports.waapiEvent.send(data);
    }
}

function hasWaapiEventPort() {
    return Boolean(window.app && window.app.ports && window.app.ports.waapiEvent);
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
function sendIterationEvent(animGroup, iterationNumber) {
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
function sendLifecycleEvent(status, animGroup) {
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
function sendScrollLifecycleEvent(status, animGroup, progress, engine) {
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
function sendPropertyUpdate(propertyData) {
    sendToElm({ type: 'propertyUpdate', ...propertyData });
}

/**
 * Build property data containing only the properties that are currently animated.
 * Uses propertyVersions keys to determine which properties to include,
 * so only animated values are sent to Elm (reducing decoder work per frame).
 */
function buildAnimatedPropertyData(animGroup, propertyVersions, transformState, element, computedStyle) {
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

/* eslint-env browser */
/* global document, CSS */

/**
 * Find the single DOM element with a matching data-anim-target attribute (or id).
 */
function findAnimTarget(targetId) {
    return document.querySelector('[data-anim-target="' + CSS.escape(targetId) + '"]')
        || document.getElementById(targetId)
        || null;
}

/**
 * Find all DOM elements with a matching data-anim-target attribute (or id).
 */
function findAllAnimTargets(targetId) {
    const byAttr = Array.from(document.querySelectorAll('[data-anim-target="' + CSS.escape(targetId) + '"]'));
    if (byAttr.length > 0) return byAttr;
    const byId = document.getElementById(targetId);
    return byId ? [byId] : [];
}

/* eslint-env browser */
/* global window, requestAnimationFrame, cancelAnimationFrame, performance */

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

function setupAnimationEvents(animGroup, propertyType, element, animation, version, resolvedTransformValues) {
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

/* eslint-env browser */
/* global console */
/**
 * Error reporting for ElmMotion.
 *
 * Default behavior: silent. Consumers opt in by registering one or more
 * subscribers via `onError`, or by enabling the built-in console adapter
 * with `useConsoleReporter`. This keeps production browsers free of
 * internal package warnings while letting developers see everything
 * during development and ship errors to a service of their choice in
 * production.
 *
 * See: https://phollyer.github.io/elm-motion/shared/error-reporting/
 *
 * @typedef {'error' | 'warning'} ErrorSeverity
 *
 * @typedef {('init' | 'waapiCommand' | 'animation' | 'scrollDriven' | 'viewDriven' | 'polyfill' | string)} ErrorSource
 *
 * @typedef {Object} ErrorContext
 * @property {ErrorSource}              source                 Where the report originated.
 * @property {ErrorSeverity}            severity               'error' (default) or 'warning'.
 * @property {string}                   [code]                 Stable enum string, e.g. 'TARGET_NOT_FOUND'.
 * @property {string}                   [commandType]          The offending Elm command type, when relevant.
 * @property {string}                   [elementId]            The affected element id, when relevant.
 * @property {'WAAPI' | 'ScrollTimeline' | 'ViewTimeline'} [engine]
 * @property {Record<string, unknown>}  [details]              Additional structured information.
 *
 * @typedef {(error: Error, context: ErrorContext) => void} ErrorHandler
 * @typedef {() => void} Unsubscribe
 */

const subscribers = new Set();

/**
 * Register a subscriber to receive ElmMotion error reports.
 *
 * Subscribers are independent — register as many as you like. A subscriber
 * that throws is isolated; one bad handler will not block the others.
 * Non-function arguments are ignored and a no-op `unsubscribe` is returned.
 *
 * @param {ErrorHandler} handler
 * @returns {Unsubscribe} Call to remove the subscriber.
 *
 * @example
 * const off = ElmMotion.onError((error, context) => {
 *     console.log(context.code, error.message);
 * });
 * // later
 * off();
 */
function onError(handler) {
    if (typeof handler !== 'function') {
        return function noop() { };
    }
    subscribers.add(handler);
    return function unsubscribe() {
        subscribers.delete(handler);
    };
}

function consoleMethodFor(context) {
    return context && context.severity === 'warning' ? 'warn' : 'error';
}

function consoleLabelFor(context) {
    const source = (context && context.source) || 'unknown';
    return '[ElmMotion:' + source + ']';
}

function compactSummary(context) {
    const ctx = context || {};
    return {
        code: ctx.code,
        commandType: ctx.commandType,
        elementId: ctx.elementId,
        engine: ctx.engine
    };
}

/**
 * @typedef {Object} ConsoleReporterOptions
 * @property {boolean} [verbose=false]  When true, logs the full error and full context.
 *                                      When false (default), logs a one-line summary.
 * @property {Console} [target=console] Any object with `.error()` and `.warn()` methods.
 */

/**
 * Built-in subscriber that forwards reports to a console-like target.
 * Opt-in — call this explicitly to enable console output.
 *
 * Reports with `severity: 'warning'` are sent to `target.warn`; everything
 * else is sent to `target.error`.
 *
 * @param {ConsoleReporterOptions} [options]
 * @returns {Unsubscribe} Call to detach the console subscriber.
 *
 * @example
 * // Development: pipe everything to the browser console
 * if (process.env.NODE_ENV !== 'production') {
 *     ElmMotion.useConsoleReporter();
 * }
 *
 * @example
 * // Tests: capture into a custom transport
 * const captured = [];
 * ElmMotion.useConsoleReporter({
 *     target: {
 *         error: (...args) => captured.push({ level: 'error', args }),
 *         warn:  (...args) => captured.push({ level: 'warn',  args })
 *     }
 * });
 */
function useConsoleReporter(options) {
    const opts = options || {};
    const verbose = opts.verbose === true;
    const target = opts.target || console;

    return onError(function consoleReporter(error, context) {
        const method = consoleMethodFor(context);
        const label = consoleLabelFor(context);
        if (verbose) {
            target[method](label, error, context);
        } else {
            target[method](label, error.message, compactSummary(context));
        }
    });
}

/**
 * Internal: dispatch a report to all subscribers.
 *
 * Wraps the input as an `Error` if necessary and guarantees a context
 * object with at least `severity` and `source` defaults. Short-circuits
 * when no subscribers are registered. Subscribers that throw are
 * isolated — one bad handler must never break the package, and the
 * dispatcher must not recurse to report its own subscribers' failures.
 *
 * Not exported from `index.js`; intended for internal use only.
 *
 * @param {unknown} err
 * @param {Partial<ErrorContext>} [context]
 * @returns {void}
 */
function reportError(err, context) {
    if (subscribers.size === 0) {
        return;
    }
    const errorObj = err instanceof Error ? err : new Error(String(err));
    const ctx = Object.assign({ severity: 'error', source: 'unknown' }, context || {});

    subscribers.forEach(function (handler) {
        try {
            handler(errorObj, ctx);
        } catch (_handlerErr) {
            // Intentionally swallow: a misbehaving subscriber must never
            // break the package. We cannot use the dispatcher to report
            // its own failure without risking infinite recursion.
        }
    });
}

/* eslint-env browser */

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

function processElementAnimation(animGroup, elementConfig, globalOptions = { iterations: 1, direction: 'normal' }, isRestart = false, resolvedElement = null) {
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

            markAnimationGroupStarted(animGroup);
        }
    });

    if (elementAnims.size === 0) {
        activeAnimations.delete(animGroup);
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

function processAnimationData(animationData) {
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

/* eslint-env browser */

const DIRECT_TRANSFORM_KEYS = [
    'x', 'y', 'z',
    'scaleX', 'scaleY', 'scaleZ',
    'rotateX', 'rotateY', 'rotateZ',
    'skewX', 'skewY'
];

const DIRECT_STYLE_APPLIERS = {
    opacity(style, value) {
        style.opacity = String(value);
    }
};

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

function hasDirectTransformUpdates(props) {
    return DIRECT_TRANSFORM_KEYS.some(key => props[key] !== undefined);
}

function clearTrackedAnimations(animGroup, element) {
    element.getAnimations().forEach(anim => {
        anim.cancel();
    });
    activeAnimations.delete(animGroup);
    animationGroups.delete(animGroup);
}

function applyDirectTransformStyles(animGroup, element, props) {
    if (!hasDirectTransformUpdates(props)) {
        return;
    }

    const order = elementTransformOrders.get(animGroup) || ['translate', 'rotate', 'skew', 'scale'];
    const {
        x = 0,
        y = 0,
        z = 0,
        scaleX = 1,
        scaleY = 1,
        scaleZ = 1,
        rotateX = 0,
        rotateY = 0,
        rotateZ = 0,
        skewX = 0,
        skewY = 0
    } = props;

    element.style.transform = buildTransformString(
        x,
        y,
        z,
        scaleX,
        scaleY,
        scaleZ,
        rotateX,
        rotateY,
        rotateZ,
        skewX,
        skewY,
        order
    );
}

function applyDirectStyleUpdates(style, props) {
    Object.entries(DIRECT_STYLE_APPLIERS).forEach(([key, applyStyle]) => {
        if (props[key] !== undefined) {
            applyStyle(style, props[key]);
        }
    });

    if (props.width !== undefined && props.height !== undefined) {
        style.width = `${props.width}px`;
        style.height = `${props.height}px`;
    }
}

function applyDirectPropertyUpdate(update) {
    const animGroup = update.elementId;
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

    clearTrackedAnimations(animGroup, element);

    const props = update.properties;
    applyDirectTransformStyles(animGroup, element, props);
    applyDirectStyleUpdates(element.style, props);
}

function stopAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    const { affected, total } = forEachAffectedAnimation(animGroup, properties, animData => animData.animation.finish());
    if (!properties || affected === total) {
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);
    }
    sendLifecycleEvent('stopped', animGroup);
}

function resetAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    const { affected, total } = forEachAffectedAnimation(animGroup, properties, animData => animData.animation.cancel());
    if (!properties || affected === total) {
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);
    }
    sendLifecycleEvent('reset', animGroup);
}

function restartAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => {
        animData.animation.cancel();
        animData.animation.play();
    });

    const groupTracking = animationGroups.get(animGroup);
    if (groupTracking) {
        groupTracking.completedProperties = 0;
        groupTracking.started = false;
    }
    sendLifecycleEvent('restarted', animGroup);
}

function pauseAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => animData.animation.pause());
    sendLifecycleEvent('paused', animGroup);
}

function resumeAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => {
        animData.animation.play();
        if (animData.updateFn) {
            animData.updateFn();
        }
    });
    sendLifecycleEvent('resumed', animGroup);
}

function setProperties(updates) {
    updates.forEach(applyDirectPropertyUpdate);
}

/* eslint-env browser */
/* global window, document, CSS, ScrollTimeline, ViewTimeline */

// Shared load guard so multiple timeline commands do not trigger duplicate loads.
let timelinePolyfillLoadPromise = null;

/**
 * Returns true if the named timeline API is available in the current window.
 */
function hasTimelineApi(apiName) {
    return typeof window !== 'undefined' && typeof window[apiName] !== 'undefined';
}

/**
 * Lazy-load the scroll-timeline polyfill script the first time it is needed.
 * Subsequent calls return the same Promise.
 */
function loadTimelinePolyfill() {
    if (timelinePolyfillLoadPromise) {
        return timelinePolyfillLoadPromise;
    }

    timelinePolyfillLoadPromise = new Promise((resolve, reject) => {
        if (typeof document === 'undefined') {
            reject(new Error('No document available to load timeline polyfill script'));
            return;
        }

        const existing = document.querySelector('script[data-elm-motion-timeline-polyfill="true"]');
        if (existing) {
            existing.addEventListener('load', () => resolve(), { once: true });
            existing.addEventListener('error', () => reject(new Error('Failed to load existing timeline polyfill script')), { once: true });
            return;
        }

        const script = document.createElement('script');
        script.src = 'https://unpkg.com/scroll-timeline-polyfill/dist/scroll-timeline.js';
        script.async = true;
        script.setAttribute('data-elm-motion-timeline-polyfill', 'true');
        script.onload = () => resolve();
        script.onerror = () => reject(new Error('Failed to load scroll-timeline polyfill'));
        document.head.appendChild(script);
    });

    return timelinePolyfillLoadPromise;
}

/**
 * Ensure a timeline API is available, loading the polyfill if necessary.
 * Returns true if the API is available after this call, false otherwise.
 */
async function ensureTimelineApi(apiName) {
    if (hasTimelineApi(apiName)) {
        return true;
    }

    try {
        await loadTimelinePolyfill();
    } catch (error) {
        reportError(error, {
            source: 'polyfill',
            severity: 'warning',
            code: 'POLYFILL_LOAD_FAILED',
            engine: apiName
        });
        return false;
    }

    if (!hasTimelineApi(apiName)) {
        reportError('Timeline polyfill loaded but ' + apiName + ' is still unavailable', {
            source: 'polyfill',
            severity: 'warning',
            code: 'POLYFILL_API_MISSING',
            engine: apiName
        });
        return false;
    }

    return true;
}

/**
 * Read the current progress (0.0–1.0) of a scroll-driven Animation object.
 * Unlike time-based animations, currentTime is a CSSUnitValue, not a number.
 * getComputedTiming().progress is always a plain number in [0, 1] or null.
 */
function getScrollAnimationProgress(animation) {
    try {
        const timing = animation.effect && animation.effect.getComputedTiming();
        if (timing && timing.progress !== null && timing.progress !== undefined) {
            return Math.min(1.0, Math.max(0.0, timing.progress));
        }
    } catch (_) { /* ignore */ }
    return 0;
}

/**
 * Attach finish, cancel, and iteration listeners to a group of scroll-driven animations.
 * Emits port events to Elm matching the 'animationUpdate' format used by the WAAPI engine.
 */
function attachScrollDrivenListeners(animGroup, animations, engine, element, discreteExit) {
    const total = animations.length;
    let finishedCount = 0;
    let cancelFired = false;

    // Initialise group iteration counter (reset on each animate call).
    scrollDrivenIterationCounts.set(animGroup, 0);

    // Per-animation iteration counts used to deduplicate the group event:
    // a group with N properties fires N native 'iteration' events per loop.
    const perAnimIterations = new Array(total).fill(0);

    animations.forEach(function (animation, i) {
        animation.addEventListener('finish', function () {
            finishedCount++;
            if (finishedCount === total) {
                if (element && discreteExit) {
                    Object.entries(discreteExit).forEach(function ([prop, values]) {
                        element.style[prop] = values.to;
                    });
                }
                sendScrollLifecycleEvent('completed', animGroup, 1.0, engine);
            }
        }, { once: true });

        animation.addEventListener('cancel', function () {
            if (cancelFired) return;
            cancelFired = true;
            const progress = getScrollAnimationProgress(animation);
            sendScrollLifecycleEvent('cancelled', animGroup, progress, engine);
        }, { once: true });

        animation.addEventListener('iteration', function () {
            perAnimIterations[i]++;
            const storedCount = scrollDrivenIterationCounts.get(animGroup) || 0;
            const nextGroupIteration = updateGroupIteration(perAnimIterations, i, perAnimIterations[i], storedCount);
            if (nextGroupIteration != null) {
                scrollDrivenIterationCounts.set(animGroup, nextGroupIteration);
                sendScrollLifecycleEvent('iteration', animGroup, nextGroupIteration, engine);
            }
        });
    });
}

/**
 * Apply a scroll/view-driven animation to a single element using the given timeline.
 * Builds start/end keyframes from each property config and calls element.animate().
 */
function applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, engine, discreteEntry, discreteExit) {
    // Apply discrete entry styles immediately so the element is in the correct
    // state when the animation begins.
    if (discreteEntry) {
        Object.entries(discreteEntry).forEach(function ([prop, value]) {
            element.style[prop] = value;
        });
    }
    const baseTimingOptions = Object.assign(
        { timeline: timeline, fill: 'both' },
        rangeOptions || {},
        playbackOptions ? { iterations: playbackOptions.iterations, direction: playbackOptions.direction } : {}
    );
    const properties = elementConfig.properties || [];

    const transformProperties = properties.filter(p =>
        p.type === 'translate' || p.type === 'scale' || p.type === 'rotate' || p.type === 'skew'
    );
    const nonTransformProperties = properties.filter(p =>
        p.type !== 'translate' && p.type !== 'scale' && p.type !== 'rotate' && p.type !== 'skew'
    );

    const animations = [];

    nonTransformProperties.forEach(function (property) {
        const resolved = resolveNonTransformValues(animGroup, element, property);
        if (!resolved) return;

        const { keyframes, animationEasing } = buildPropertyKeyframes(resolved, property.easingKeyframes, property.easing);
        if (!keyframes) return;

        const propertyTimingOptions = Object.assign({}, baseTimingOptions, { easing: animationEasing });
        animations.push(element.animate(keyframes, propertyTimingOptions));
    });

    if (transformProperties.length > 0) {
        const currentTransform = getTransformState(animGroup, element);
        const order = (elementConfig.transformOrder && elementConfig.transformOrder.length > 0)
            ? elementConfig.transformOrder
            : (elementTransformOrders.get(animGroup) || ['translate', 'rotate', 'skew', 'scale']);

        const { start: sv, end: ev } = resolveScrollDrivenTransformValues(transformProperties, currentTransform);

        const transformTimingOptions = Object.assign({}, baseTimingOptions);
        const firstTransform = transformProperties[0];

        let transformKeyframes;
        if (firstTransform.easingKeyframes && Array.isArray(firstTransform.easingKeyframes)) {
            transformKeyframes = firstTransform.easingKeyframes.map(function (p) {
                return {
                    transform: buildTransformString(
                        sv.x + (ev.x - sv.x) * p,
                        sv.y + (ev.y - sv.y) * p,
                        sv.z + (ev.z - sv.z) * p,
                        sv.scaleX + (ev.scaleX - sv.scaleX) * p,
                        sv.scaleY + (ev.scaleY - sv.scaleY) * p,
                        sv.scaleZ + (ev.scaleZ - sv.scaleZ) * p,
                        sv.rotateX + (ev.rotateX - sv.rotateX) * p,
                        sv.rotateY + (ev.rotateY - sv.rotateY) * p,
                        sv.rotateZ + (ev.rotateZ - sv.rotateZ) * p,
                        sv.skewX + (ev.skewX - sv.skewX) * p,
                        sv.skewY + (ev.skewY - sv.skewY) * p,
                        order
                    )
                };
            });
            transformTimingOptions.easing = 'linear';
        } else {
            const startTransform = buildTransformString(
                sv.x, sv.y, sv.z,
                sv.scaleX, sv.scaleY, sv.scaleZ,
                sv.rotateX, sv.rotateY, sv.rotateZ,
                sv.skewX, sv.skewY, order
            );
            const endTransform = buildTransformString(
                ev.x, ev.y, ev.z,
                ev.scaleX, ev.scaleY, ev.scaleZ,
                ev.rotateX, ev.rotateY, ev.rotateZ,
                ev.skewX, ev.skewY, order
            );
            transformKeyframes = [{ transform: startTransform }, { transform: endTransform }];
            if (firstTransform.easing) {
                transformTimingOptions.easing = easingFunctions[firstTransform.easing] || firstTransform.easing;
            }
        }

        animations.push(element.animate(transformKeyframes, transformTimingOptions));
    }

    if (animations.length > 0 && engine) {
        attachScrollDrivenListeners(animGroup, animations, engine, element, discreteExit || {});
    }
}

/**
 * Build the {playbackOptions, discreteEntry, discreteExit} bundle shared by
 * both scroll-driven and view-driven processing.
 */
function buildSharedTimelineOptions(commandData) {
    return {
        playbackOptions: {
            iterations: parseIterations(commandData.iterations),
            direction: commandData.direction || 'normal'
        },
        discreteEntry: commandData.discreteEntry || {},
        discreteExit: commandData.discreteExit || {}
    };
}

/**
 * Build the rangeOptions object for a ViewTimeline from its config.
 */
function buildViewRangeOptions(timelineConfig) {
    const rangeOptions = {};
    if (timelineConfig.rangeStart) rangeOptions.rangeStart = timelineConfig.rangeStart;
    if (timelineConfig.rangeEnd) rangeOptions.rangeEnd = timelineConfig.rangeEnd;
    return rangeOptions;
}

/**
 * Validate that a timeline command has the expected shape and that the
 * required browser API is present. Reports the appropriate error and
 * returns false on failure.
 */
function validateTimelineCommand(commandData, source, engine, apiPresent) {
    if (!commandData || !commandData.elements) {
        reportError('Invalid ' + source + ' data', {
            source: source,
            severity: 'warning',
            code: 'COMMAND_INVALID',
            engine: engine
        });
        return false;
    }
    if (!apiPresent) {
        reportError(engine + ' is not supported in this browser', {
            source: source,
            severity: 'warning',
            code: 'API_UNSUPPORTED',
            engine: engine
        });
        return false;
    }
    return true;
}

/**
 * Resolve the scroll-source element from a timelineConfig.source id.
 * Returns null and reports an error if not found.
 */
function resolveScrollSource(sourceId) {
    if (sourceId === 'document') {
        return document.documentElement;
    }
    const element = document.querySelector('[data-anim-target="' + CSS.escape(sourceId) + '"]')
        || document.getElementById(sourceId);
    if (!element) {
        reportError('Scroll source element "' + sourceId + '" not found', {
            source: 'scrollDriven',
            severity: 'warning',
            code: 'SCROLL_SOURCE_NOT_FOUND',
            engine: 'ScrollTimeline',
            details: { sourceId: sourceId }
        });
    }
    return element;
}

/**
 * Resolve a per-element animation target. Returns null and reports an error
 * if the target cannot be found.
 */
function resolveTimelineTarget(targetId, animGroup, source, engine) {
    const element = findAnimTarget(targetId);
    if (!element) {
        reportError('Element target "' + targetId + '" not found for ' + source + ' animation', {
            source: source,
            severity: 'warning',
            code: 'TARGET_NOT_FOUND',
            engine: engine,
            elementId: targetId,
            details: { animGroup: animGroup }
        });
    }
    return element;
}

/**
 * Process a scroll-driven animation using ScrollTimeline.
 */
function processScrollDrivenData(commandData) {
    if (!validateTimelineCommand(commandData, 'scrollDriven', 'ScrollTimeline', typeof ScrollTimeline !== 'undefined')) {
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const sourceId = timelineConfig.source || 'document';
    const axis = timelineConfig.axis || 'block';

    const sourceElement = resolveScrollSource(sourceId);
    if (!sourceElement) {
        return;
    }

    const timeline = new ScrollTimeline({ source: sourceElement, axis: axis });
    const { playbackOptions, discreteEntry, discreteExit } = buildSharedTimelineOptions(commandData);

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const targetId = elementConfig.target || animGroup;
        const element = resolveTimelineTarget(targetId, animGroup, 'scrollDriven', 'ScrollTimeline');
        if (!element) return;
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, null, playbackOptions, 'scrollTimeline', discreteEntry, discreteExit);
    });
}

/**
 * Apply a view-driven animation to a single element entry.
 */
function applyViewDrivenForEntry(animGroup, elementConfig, axis, rangeOptions, playbackOptions, discreteEntry, discreteExit) {
    const targetId = elementConfig.target || animGroup;
    const element = resolveTimelineTarget(targetId, animGroup, 'viewDriven', 'ViewTimeline');
    if (!element) return;

    const timeline = new ViewTimeline({ subject: element, axis: axis });
    applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, 'viewTimeline', discreteEntry, discreteExit);
}

/**
 * Process a view-driven animation using ViewTimeline.
 */
function processViewDrivenData(commandData) {
    if (!validateTimelineCommand(commandData, 'viewDriven', 'ViewTimeline', typeof ViewTimeline !== 'undefined')) {
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const axis = timelineConfig.axis || 'block';
    const rangeOptions = buildViewRangeOptions(timelineConfig);
    const { playbackOptions, discreteEntry, discreteExit } = buildSharedTimelineOptions(commandData);

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        applyViewDrivenForEntry(animGroup, elementConfig, axis, rangeOptions, playbackOptions, discreteEntry, discreteExit);
    });
}

/* eslint-env browser */
/* global window */
/**
 * ElmMotion JavaScript Integration (ES Module source)
 * Canonical source for bundling ESM and IIFE distributions.
 *
 * This is the entry point only. All implementation lives in the sub-modules:
 *   state.js      – shared mutable state Maps
 *   utils.js      – pure utility functions
 *   transform.js  – transform math and DOM helpers
 *   properties.js – property resolution and keyframe builders
 *   ports.js      – Elm port communication
 *   animations.js – WAAPI animation engine
 *   scroll.js     – scroll-driven and view-driven timeline engine
 *   errors.js     – opt-in error reporting (onError, useConsoleReporter)
 */

/**
 * Validate an inbound port command. Returns true if it is well-formed.
 */
function validateCommand(commandData) {
    if (!commandData) {
        reportError('No command data received', {
            source: 'waapiCommand',
            severity: 'warning',
            code: 'COMMAND_EMPTY'
        });
        return false;
    }
    if (!commandData.type) {
        reportError('Command missing type field', {
            source: 'waapiCommand',
            severity: 'warning',
            code: 'COMMAND_TYPE_MISSING',
            details: { commandData: commandData }
        });
        return false;
    }
    return true;
}

/**
 * Dispatch table mapping inbound command types to their handlers.
 * Each handler receives the raw commandData object.
 * Async handlers may return a Promise; the dispatcher awaits them.
 */
const COMMAND_HANDLERS = {
    animate: function (commandData) {
        processAnimationData(commandData);
    },
    scrollDriven: async function (commandData) {
        if (await ensureTimelineApi('ScrollTimeline')) {
            processScrollDrivenData(commandData);
        }
    },
    viewDriven: async function (commandData) {
        if (await ensureTimelineApi('ViewTimeline')) {
            processViewDrivenData(commandData);
        }
    },
    setProperties: function (commandData) {
        setProperties(commandData.updates);
    },
    stop: function (commandData) {
        stopAnimation(commandData.elementId, commandData.properties);
    },
    reset: function (commandData) {
        resetAnimation(commandData.elementId, commandData.properties);
    },
    restart: function (commandData) {
        restartAnimation(commandData.elementId, commandData.properties);
    },
    pause: function (commandData) {
        pauseAnimation(commandData.elementId, commandData.properties);
    },
    resume: function (commandData) {
        resumeAnimation(commandData.elementId, commandData.properties);
    }
};

/**
 * Look up and invoke the handler for a single command. Reports an error
 * if the command type is unknown or the handler throws/rejects.
 */
async function dispatchCommand(commandData) {
    const handler = COMMAND_HANDLERS[commandData.type];
    if (!handler) {
        reportError('Unknown command type: ' + commandData.type, {
            source: 'waapiCommand',
            severity: 'warning',
            code: 'COMMAND_TYPE_UNKNOWN',
            commandType: commandData.type
        });
        return;
    }
    await handler(commandData);
}

/**
 * Initialize the ElmMotion WAAPI system with Elm ports.
 * @param {object} ports - The Elm app ports object (app.ports)
 */
function init(ports) {
    if (!ports) {
        reportError('No ports provided to init()', { source: 'init', code: 'PORTS_MISSING' });
        return;
    }

    // Store reference for updates
    window.app = { ports: ports };

    if (!ports.waapiCommand || !ports.waapiCommand.subscribe) {
        reportError('waapiCommand port not found or not subscribeable', {
            source: 'init',
            severity: 'warning',
            code: 'PORT_NOT_SUBSCRIBEABLE'
        });
        return;
    }

    ports.waapiCommand.subscribe(async function (commandData) {
        try {
            if (!validateCommand(commandData)) return;
            await dispatchCommand(commandData);
        } catch (error) {
            reportError(error, {
                source: 'waapiCommand',
                code: 'COMMAND_PROCESSING_FAILED',
                commandType: commandData && commandData.type
            });
        }
    });
}

var index = { init: init, onError: onError, useConsoleReporter: useConsoleReporter };

export { index as default, init, onError, useConsoleReporter };
