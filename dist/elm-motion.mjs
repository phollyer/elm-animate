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
 * Register a custom CSS easing function by name.
 * @param {string} name - The Elm-side easing name
 * @param {string} cssValue - A valid CSS timing-function string
 */
function addEasingFunction(name, cssValue) {
    easingFunctions[name] = cssValue;
}

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

/**
 * Resolve start/end values for a non-transform property so they can be
 * used to compute interpolated values without reading the DOM later.
 */
function resolveNonTransformValues(animGroup, element, property) {
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
function buildSimplePropertyKeyframes(resolved) {
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
function buildComplexPropertyKeyframes(resolved, easingKeyframes) {
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
function resolveScrollDrivenTransformValues(transformProperties, currentTransform) {
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

/* eslint-env browser */
/* global window, document, console, CSS, requestAnimationFrame, cancelAnimationFrame, performance */

// ─── DOM helpers ──────────────────────────────────────────────────────────────

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
function processElementAnimation(animGroup, elementConfig, globalOptions = { iterations: 1, direction: 'normal' }, isRestart = false, resolvedElement = null) {
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

/**
 * Reset animation by jumping to start state.
 */
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

/**
 * Restart animation from beginning.
 */
function restartAnimation(animGroup, properties) {
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
function pauseAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => animData.animation.pause());
    sendLifecycleEvent('paused', animGroup);
}

/**
 * Resume animation.
 */
function resumeAnimation(animGroup, properties) {
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
function setProperties(updates) {
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
function processAnimationData(animationData) {
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

/* eslint-env browser */
/* global window, document, console, CSS, ScrollTimeline, ViewTimeline */

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
        console.warn('ElmMotion: Unable to load timeline polyfill:', error);
        return false;
    }

    if (!hasTimelineApi(apiName)) {
        console.warn('ElmMotion: Timeline polyfill loaded but ' + apiName + ' is still unavailable');
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
 * Process a scroll-driven animation using ScrollTimeline.
 */
function processScrollDrivenData(commandData) {
    if (!commandData || !commandData.elements) {
        console.warn('ElmMotion: Invalid scrollDriven data');
        return;
    }

    if (typeof ScrollTimeline === 'undefined') {
        console.warn('ElmMotion: ScrollTimeline is not supported in this browser');
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const sourceId = timelineConfig.source || 'document';
    const axis = timelineConfig.axis || 'block';

    const sourceElement = (sourceId === 'document')
        ? document.documentElement
        : (document.querySelector('[data-anim-target="' + CSS.escape(sourceId) + '"]')
            || document.getElementById(sourceId));

    if (!sourceElement) {
        console.warn('ElmMotion: Scroll source element "' + sourceId + '" not found');
        return;
    }

    const timeline = new ScrollTimeline({ source: sourceElement, axis: axis });
    const playbackOptions = {
        iterations: parseIterations(commandData.iterations),
        direction: commandData.direction || 'normal'
    };
    const discreteEntry = commandData.discreteEntry || {};
    const discreteExit = commandData.discreteExit || {};

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const targetId = elementConfig.target || animGroup;
        const element = findAnimTarget(targetId);
        if (!element) {
            console.warn('ElmMotion: Element target "' + targetId + '" not found for scroll-driven animation (animGroup: "' + animGroup + '")');
            return;
        }
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, null, playbackOptions, 'scrollTimeline', discreteEntry, discreteExit);
    });
}

/**
 * Process a view-driven animation using ViewTimeline.
 */
function processViewDrivenData(commandData) {
    if (!commandData || !commandData.elements) {
        console.warn('ElmMotion: Invalid viewDriven data');
        return;
    }

    if (typeof ViewTimeline === 'undefined') {
        console.warn('ElmMotion: ViewTimeline is not supported in this browser');
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const axis = timelineConfig.axis || 'block';

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const targetId = elementConfig.target || animGroup;
        const element = findAnimTarget(targetId);
        if (!element) {
            console.warn('ElmMotion: Element target "' + targetId + '" not found for view-driven animation (animGroup: "' + animGroup + '")');
            return;
        }

        const timeline = new ViewTimeline({ subject: element, axis: axis });
        const rangeOptions = {};
        if (timelineConfig.rangeStart) rangeOptions.rangeStart = timelineConfig.rangeStart;
        if (timelineConfig.rangeEnd) rangeOptions.rangeEnd = timelineConfig.rangeEnd;
        const playbackOptions = {
            iterations: parseIterations(commandData.iterations),
            direction: commandData.direction || 'normal'
        };
        const discreteEntry = commandData.discreteEntry || {};
        const discreteExit = commandData.discreteExit || {};
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, 'viewTimeline', discreteEntry, discreteExit);
    });
}

/* eslint-env browser */
/* global window, console */
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
 */

/**
 * Initialize the ElmMotion WAAPI system with Elm ports.
 * @param {object} ports - The Elm app ports object (app.ports)
 */
function init(ports) {
    if (!ports) {
        console.error('ElmMotion: No ports provided to init()');
        return;
    }

    // Store reference for updates
    window.app = { ports: ports };

    if (ports.waapiCommand && ports.waapiCommand.subscribe) {
        ports.waapiCommand.subscribe(async function (commandData) {
            try {
                if (!commandData) {
                    console.warn('ElmMotion: No command data received');
                    return;
                }

                if (!commandData.type) {
                    console.warn('ElmMotion: Command missing type field:', commandData);
                    return;
                }

                switch (commandData.type) {
                    case 'animate':
                        processAnimationData(commandData);
                        break;

                    case 'scrollDriven':
                        if (await ensureTimelineApi('ScrollTimeline')) {
                            processScrollDrivenData(commandData);
                        }
                        break;

                    case 'viewDriven':
                        if (await ensureTimelineApi('ViewTimeline')) {
                            processViewDrivenData(commandData);
                        }
                        break;

                    case 'setProperties':
                        setProperties(commandData.updates);
                        break;

                    case 'stop':
                        stopAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'reset':
                        resetAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'restart':
                        restartAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'pause':
                        pauseAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'resume':
                        resumeAnimation(commandData.elementId, commandData.properties);
                        break;

                    default:
                        console.warn('ElmMotion: Unknown command type:', commandData.type);
                }
            } catch (error) {
                console.error('ElmMotion: Error processing WAAPI command:', error);
            }
        });
    } else {
        console.warn('ElmMotion: waapiCommand port not found or not subscribeable');
    }
}

var index = {
    init,
    getCurrentTransform,
    stopAnimation,
    resetAnimation,
    restartAnimation,
    pauseAnimation,
    resumeAnimation,
    addEasingFunction,
    activeAnimations
};

export { activeAnimations, addEasingFunction, index as default, getCurrentTransform, init, pauseAnimation, resetAnimation, restartAnimation, resumeAnimation, stopAnimation };
