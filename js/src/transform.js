/* eslint-env browser */
/* global window */
import { DEFAULT_TRANSFORM_ORDER } from './utils.js';
import { lastKnownTransforms, elementTransformOrders } from './state.js';

/**
 * Get the default identity transform state (no translation, no rotation, unit scale).
 * Used as a fallback when no prior transform state is known.
 */
export function getDefaultTransformState() {
    return { x: 0, y: 0, z: 0, scaleX: 1, scaleY: 1, scaleZ: 1, rotateX: 0, rotateY: 0, rotateZ: 0, skewX: 0, skewY: 0 };
}

/**
 * Ensure transform state is complete and numeric.
 * Guards against partial cached objects (missing skew fields) and NaN values.
 */
export function normalizeTransformState(state) {
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
export function getTransformState(animGroup, element) {
    const cached = lastKnownTransforms.get(animGroup);
    if (cached) {
        return normalizeTransformState(cached);
    }
    return normalizeTransformState(getCurrentTransform(element));
}

/**
 * Get the stored transform order for a DOM element.
 */
export function getElementOrder(element) {
    const id = element.getAttribute('data-anim-target') || element.id;
    return elementTransformOrders.get(id) || DEFAULT_TRANSFORM_ORDER;
}

/**
 * Build a complete transform string with 3D support.
 * The order parameter controls the order of translate, rotate, and scale
 * in the output string. Rotation axes are always applied X → Y → Z within
 * the rotate group.
 *
 * `forceGroups` (optional Set or Array of `'translate'|'rotate'|'scale'|'skew'`)
 * forces the listed groups to emit *all* their axis functions even when the
 * values are at identity (e.g. `rotateX(0deg)`). This is required when
 * building WAAPI keyframes: every keyframe in an animation must list the same
 * set of transform functions or the browser falls back to matrix3d
 * interpolation, which decomposes rotations into a matrix and silently drops
 * any rotation that lands on an identity matrix at either endpoint.
 */
export function buildTransformString(x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY, order, forceGroups) {
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
    const force = forceGroups instanceof Set
        ? forceGroups
        : (Array.isArray(forceGroups) ? new Set(forceGroups) : null);
    const isForced = group => force !== null && force.has(group);
    const parts = [];

    for (const group of transformOrder) {
        switch (group) {
            case 'translate':
                if (isForced('translate')) {
                    parts.push(`translate3d(${tx}px, ${ty}px, ${tz}px)`);
                } else if (tx !== 0 || ty !== 0 || tz !== 0) {
                    parts.push(`translate3d(${tx}px, ${ty}px, ${tz}px)`);
                }
                break;
            case 'rotate':
                if (isForced('rotate')) {
                    parts.push(`rotateX(${rx}deg)`);
                    parts.push(`rotateY(${ry}deg)`);
                    parts.push(`rotateZ(${rz}deg)`);
                } else {
                    if (rx !== 0) {
                        parts.push(`rotateX(${rx}deg)`);
                    }
                    if (ry !== 0) {
                        parts.push(`rotateY(${ry}deg)`);
                    }
                    if (rz !== 0) {
                        parts.push(`rotateZ(${rz}deg)`);
                    }
                }
                break;
            case 'skew':
                if (isForced('skew')) {
                    parts.push(`skewX(${kx}deg)`);
                    parts.push(`skewY(${ky}deg)`);
                } else {
                    if (kx !== 0) {
                        parts.push(`skewX(${kx}deg)`);
                    }
                    if (ky !== 0) {
                        parts.push(`skewY(${ky}deg)`);
                    }
                }
                break;
            case 'scale':
                if (isForced('scale')) {
                    parts.push(`scaleX(${sx})`);
                    parts.push(`scaleY(${sy})`);
                    parts.push(`scaleZ(${sz})`);
                } else {
                    if (sx !== 1) {
                        parts.push(`scaleX(${sx})`);
                    }
                    if (sy !== 1) {
                        parts.push(`scaleY(${sy})`);
                    }
                    if (sz !== 1) {
                        parts.push(`scaleZ(${sz})`);
                    }
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
export function parseTransformString(transformStr) {
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
export function getCurrentTransform(element) {
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
export function interpolateSubProperty(subProp, globalProgress, maxDuration) {
    // Scale progress by duration ratio (shorter animations complete before globalProgress=1)
    const durationRatio = subProp.duration > 0 ? subProp.duration / maxDuration : 1;
    const localProgress = Math.min(1.0, durationRatio > 0 ? globalProgress / durationRatio : 1.0);

    // Apply easing
    let easedProgress;
    if (subProp.easingKeyframes && Array.isArray(subProp.easingKeyframes) && subProp.easingKeyframes.length > 1) {
        // Complex easing (bounce, elastic): linearly interpolate between
        // pre-computed keyframes to match the browser's linear interpolation
        // within the WAAPI animation. Sample count is whatever the Elm side
        // emitted (see Shared.Easing.Keyframes.defaultKeyframeCount).
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
export function computeTransformFromResolved(resolved, globalProgress, maxDuration) {
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
