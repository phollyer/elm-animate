var ElmMotion = (function (exports) {
    'use strict';

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

    // Reference to the Elm app's ports object, set by init() in index.js.
    // Module-scoped instead of window-scoped to avoid global pollution and
    // silent collisions with host code that already uses `window.app`.
    // { ports: object | null }
    const portsRef = { ports: null };

    /**
     * Drop every per-`animGroup` entry from every Map. Called when an animation
     * group's lifecycle ends (completed / cancelled / stopped / reset / replaced
     * by direct property update). Without this, the per-group caches grow
     * without bound for the lifetime of the page.
     *
     * `lastKnownPerspectiveOrigins` is intentionally NOT cleared here. CSS
     * `getComputedStyle(...).perspectiveOrigin` always reports pixels, so once
     * the cached unit is gone we cannot tell whether the user originally chose
     * `%` or `px`. Without that, the runtime baseline reported back to Elm
     * after an animation finishes would silently switch to pixels, causing the
     * next animation to be encoded with mismatched start (px) and end (%) values.
     * The entry is keyed by user-supplied `animGroup` and overwritten on every
     * resolve, so retention across cleanup does not leak.
     */
    function cleanupAnimGroup(animGroup) {
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);
        lastKnownTransforms.delete(animGroup);
        scrollDrivenIterationCounts.delete(animGroup);
        elementTransformOrders.delete(animGroup);
    }

    /**
     * Clear every Map. Called by `dispose()` when the host Elm app is being
     * torn down (typical SPA teardown / hot-reload).
     */
    function clearAllState() {
        activeAnimations.clear();
        animationGroups.clear();
        lastKnownTransforms.clear();
        lastKnownPerspectiveOrigins.clear();
        scrollDrivenIterationCounts.clear();
        elementTransformOrders.clear();
    }

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
     * Parse an `rgb(...)`, `rgba(...)`, or 6-digit `#hhhhhh` color string
     * into `{ r, g, b, a }` channel components.
     *
     * Returns opaque black (`{ r: 0, g: 0, b: 0, a: 1 }`) for any input the
     * parser does not recognise — named colors, 3-digit hex, `hsl(...)`, etc.
     * The fallback keeps animations visually safe but silently flattens
     * unsupported color formats; pre-resolve colors on the Elm side
     * (`Anim.Extra.Color`) to avoid surprises.
     */
    function parseColor(str) {
        const match = str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
        if (match) {
            return {
                r: parseInt(match[1], 10),
                g: parseInt(match[2], 10),
                b: parseInt(match[3], 10),
                a: match[4] !== undefined ? parseFloat(match[4]) : 1
            };
        }
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
    }

    /**
     * Interpolate between two color strings.
     */
    function interpolateColor(startColor, endColor, progress) {
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
     * @typedef {('init' | 'motionCmd' | 'animation' | 'scrollDriven' | 'viewDriven' | 'polyfill' | string)} ErrorSource
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

    // Whether we have already reported the missing-motionMsg-port warning.
    // Reset by index.js init() so a fresh app gets a fresh chance to warn.
    let portMissingWarned = false;

    function resetPortMissingWarning() {
        portMissingWarned = false;
    }

    /**
     * Send data to Elm via the motionMsg port.
     * All port communication funnels through this single function so the
     * port-presence check lives in exactly one place. If the port is missing,
     * we report once via reportError and then silently no-op for the rest of
     * the session (so per-frame senders don't spam the reporter).
     */
    function sendToElm(data) {
        const ports = portsRef.ports;
        if (ports && ports.motionMsg && typeof ports.motionMsg.send === 'function') {
            ports.motionMsg.send(data);
            return;
        }
        if (!portMissingWarned) {
            portMissingWarned = true;
            reportError('motionMsg port is not available; outbound events will be dropped', {
                source: 'ports',
                severity: 'warning',
                code: 'MOTION_MSG_PORT_MISSING'
            });
        }
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
     *
     * `computedStyle` may be null when only transform properties are being animated
     * (see `needsComputedStyle`); in that case only the transform branch runs and
     * no style flush is performed.
     */
    function buildAnimatedPropertyData(animGroup, propertyVersions, transformState, element, computedStyle) {
        const data = {};
        if ('transform' in propertyVersions) {
            data.translate = { x: transformState.x, y: transformState.y, z: transformState.z };
            data.rotate = { x: transformState.rotateX, y: transformState.rotateY, z: transformState.rotateZ };
            data.skew = { x: transformState.skewX, y: transformState.skewY };
            data.scale = { x: transformState.scaleX, y: transformState.scaleY, z: transformState.scaleZ };
        }
        if (!computedStyle) {
            return data;
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

    /**
     * Property keys whose data is read from the live `CSSStyleDeclaration` returned
     * by `window.getComputedStyle(element)`. The `transform` branch is intentionally
     * absent: transform values are computed analytically from `transformState` and
     * never need a style flush. Custom-property keys are dynamic (`custom:<css>` /
     * `customColor:<css>`) and detected by prefix in `needsComputedStyle`.
     */
    const COMPUTED_STYLE_KEYS = ['opacity', 'size', 'perspectiveOrigin'];

    /**
     * Return true if any property in `propertyVersions` requires reading the
     * element's live computed style. Used to skip the layout-flushing
     * `getComputedStyle` call entirely for pure-transform animations - the most
     * common case for the WAAPI engine, and the one that benefits most from
     * compositor-only playback.
     */
    function needsComputedStyle(propertyVersions) {
        for (const key of COMPUTED_STYLE_KEYS) {
            if (key in propertyVersions) return true;
        }
        for (const key in propertyVersions) {
            if (key.startsWith('custom:') || key.startsWith('customColor:')) return true;
        }
        return false;
    }

    // Minimum interval (ms) between per-frame propertyUpdate emissions during an
    // animation. Default 0 = no throttle: emit on every requestAnimationFrame
    // tick, matching the display refresh rate (60 Hz, 120 Hz, 144 Hz, etc.).
    // The visual animation runs on the browser compositor and is unaffected
    // by this value - this only governs how often we read the live transform
    // state and forward a propertyUpdate event to Elm.
    //
    // Set a positive value via `setPropertyUpdateThrottle(ms)` to cap the
    // emission rate, e.g. 16 for ~60 Hz, 33 for ~30 Hz. Useful when many
    // simultaneous animations on a high-refresh display would otherwise
    // generate excessive port traffic for Elm-side real-time queries.
    let propertyUpdateIntervalMs = 0;

    /**
     * Set the minimum interval (in milliseconds) between per-frame
     * `propertyUpdate` events emitted to Elm during an animation.
     *
     * Pass 0 (the default) to disable throttling - one event is emitted per
     * requestAnimationFrame tick, matching the display refresh rate.
     *
     * Pass a positive number to cap the emission rate. The visual animation
     * is never affected; only the rate at which Elm subscribers see live
     * mid-animation values changes.
     *
     * @param {number} intervalMs - Non-negative number. 0 disables throttling.
     */
    function setPropertyUpdateThrottle(intervalMs) {
        if (typeof intervalMs !== 'number' || !Number.isFinite(intervalMs) || intervalMs < 0) {
            reportError('setPropertyUpdateThrottle requires a non-negative finite number', {
                source: 'setPropertyUpdateThrottle',
                severity: 'warning',
                code: 'THROTTLE_INVALID',
                details: { intervalMs: intervalMs }
            });
            return;
        }
        propertyUpdateIntervalMs = intervalMs;
    }

    /**
     * Convert a camelCase JS property name (as used in Web Animations API
     * keyframe objects, e.g. `backgroundColor`) to its CSS hyphenated form
     * (e.g. `background-color`) for use with `CSSStyleDeclaration.setProperty`.
     */
    function camelToKebab(name) {
        return name.replace(/[A-Z]/g, m => '-' + m.toLowerCase());
    }

    /**
     * Best-effort equivalent of `Animation.commitStyles()` for browsers that
     * don't implement it (notably older iOS Safari). Reads the last keyframe
     * of the animation and writes each animatable property to the element's
     * inline style. Skips the `composite`, `easing`, `offset` pseudo-keys.
     *
     * Falls through to the native `commitStyles()` when available.
     */
    function commitAnimatedStyles(element, animation) {
        if (typeof animation.commitStyles === 'function') {
            animation.commitStyles();
            return;
        }
        const effect = animation.effect;
        if (!effect || typeof effect.getKeyframes !== 'function') {
            return;
        }
        const keyframes = effect.getKeyframes();
        if (!keyframes || keyframes.length === 0) {
            return;
        }
        const endFrame = keyframes[keyframes.length - 1];
        for (const key in endFrame) {
            if (!Object.prototype.hasOwnProperty.call(endFrame, key)) continue;
            if (key === 'composite' || key === 'easing' || key === 'offset' || key === 'computedOffset') continue;
            const value = endFrame[key];
            if (value == null) continue;
            if (key.startsWith('--')) {
                element.style.setProperty(key, String(value));
            } else {
                element.style.setProperty(camelToKebab(key), String(value));
            }
        }
    }

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
        const propertyVersions = buildPropertyVersions(animGroup, propertyType, version);
        // Skip the layout-flushing getComputedStyle call when only transform
        // properties are animated. The transform branch of buildAnimatedPropertyData
        // is computed analytically from transformState and never reads computedStyle,
        // so for the common pure-transform case (translate / rotate / scale / skew)
        // we save one style flush per element per rAF tick.
        const computedStyle = needsComputedStyle(propertyVersions)
            ? window.getComputedStyle(element)
            : null;
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
        } catch (error) {
            reportError(error, {
                source: 'animationEvents',
                severity: 'warning',
                code: 'ITERATION_TIMING_READ_FAILED',
                details: { animGroup: animGroup, propertyIndex: propertyIndex }
            });
        }
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
            cleanupAnimGroup(animGroup);
        }
        return allComplete;
    }

    function setupAnimationEvents(animGroup, propertyType, element, animation, version, resolvedTransformValues) {
        const groupGeneration = animationGroups.get(animGroup)?.generation || 0;
        const groupInfoForIndex = animationGroups.get(animGroup);
        let propertyIndex = 0;
        if (groupInfoForIndex) {
            propertyIndex = groupInfoForIndex.nextPropertyIndex;
            groupInfoForIndex.nextPropertyIndex++;
        }
        const transformAnimDuration = resolvedTransformValues
            ? (animation.effect?.getTiming()?.duration || 0)
            : 0;

        let lastComputedTransformState = resolvedTransformValues
            ? computeTransformFromResolved(resolvedTransformValues, 0, transformAnimDuration)
            : null;
        let lastTime = 0;
        let rafId = null;

        function sendAnimationUpdate() {
            const now = performance.now();
            if (propertyUpdateIntervalMs <= 0 || now - lastTime >= propertyUpdateIntervalMs) {
                updateGroupIterationState(animGroup, groupGeneration, propertyIndex, animation);

                const transformState = getLiveTransformState(animGroup, animation, resolvedTransformValues, transformAnimDuration);
                lastComputedTransformState = transformState;

                sendTrackedPropertyUpdate(
                    animGroup,
                    null,
                    null,
                    transformState,
                    element,
                    true,
                    getAnimationProgress(animGroup, animation)
                );
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
                commitAnimatedStyles(element, animation);
                animation.cancel();
            } catch (commitError) {
                reportError(commitError, {
                    source: 'animationEvents',
                    severity: 'warning',
                    code: 'COMMIT_STYLES_FAILED',
                    details: { animGroup: animGroup, propertyType: propertyType }
                });
                try {
                    animation.cancel();
                } catch (cancelError) {
                    reportError(cancelError, {
                        source: 'animationEvents',
                        severity: 'warning',
                        code: 'ANIMATION_CANCEL_FAILED',
                        details: { animGroup: animGroup, propertyType: propertyType }
                    });
                }
            }

            removeTrackedAnimationVersion(animGroup, propertyType, version);

            if (animationGroups.get(animGroup)?.generation === groupGeneration) {
                const allComplete = finalizeAnimationTracking(animGroup, groupGeneration, 'completed');
                const finalTransformState = getTrackedTransformState(
                    animGroup,
                    resolvedTransformValues,
                    resolvedTransformValues ? getResolvedEndTransformState(resolvedTransformValues) : null
                );
                sendTrackedPropertyUpdate(animGroup, propertyType, version, finalTransformState, element, !allComplete);
            }
        });

        animation.addEventListener('cancel', () => {
            if (finishHandled) return;

            removeTrackedAnimationVersion(animGroup, propertyType, version);

            if (animationGroups.get(animGroup)?.generation === groupGeneration) {
                const allCancelled = finalizeAnimationTracking(animGroup, groupGeneration, 'cancelled');
                const cancelTransformState = getTrackedTransformState(animGroup, resolvedTransformValues, lastComputedTransformState);
                sendTrackedPropertyUpdate(animGroup, propertyType, version, cancelTransformState, element, !allCancelled);
            }
        });

        return sendAnimationUpdate;
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
        cleanupAnimGroup(animGroup);
    }

    function applyDirectTransformStyles(animGroup, element, props) {
        if (!hasDirectTransformUpdates(props)) {
            return;
        }

        const order = elementTransformOrders.get(animGroup) || DEFAULT_TRANSFORM_ORDER;
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
            cleanupAnimGroup(animGroup);
        }
        sendLifecycleEvent('stopped', animGroup);
    }

    function resetAnimation(animGroup, properties) {
        const elementAnims = activeAnimations.get(animGroup);
        if (!elementAnims) return;
        const { affected, total } = forEachAffectedAnimation(animGroup, properties, animData => animData.animation.cancel());
        if (!properties || affected === total) {
            cleanupAnimGroup(animGroup);
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
     * Lazy-load the scroll-timeline polyfill the first time it is needed.
     * Subsequent calls return the same Promise.
     *
     * The polyfill is bundled into the elm-motion distribution at build time
     * (rollup `inlineDynamicImports: true`), so the dynamic import resolves
     * synchronously from the bundle - no third-party CDN fetch, no SRI, no
     * version drift between npm dependency and runtime fetch.
     *
     * The polyfill module is a side-effect script: importing it runs an IIFE
     * that feature-detects ScrollTimeline / ViewTimeline and installs them on
     * `window` if absent.
     */
    function loadTimelinePolyfill() {
        if (timelinePolyfillLoadPromise) {
            return timelinePolyfillLoadPromise;
        }

        timelinePolyfillLoadPromise = Promise.resolve().then(function () { return scrollTimeline; })
            .then(() => undefined);

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
        } catch (error) {
            reportError(error, {
                source: 'scroll',
                severity: 'warning',
                code: 'SCROLL_PROGRESS_READ_FAILED'
            });
        }
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
                    cleanupAnimGroup(animGroup);
                }
            }, { once: true });

            animation.addEventListener('cancel', function () {
                if (cancelFired) return;
                cancelFired = true;
                const progress = getScrollAnimationProgress(animation);
                sendScrollLifecycleEvent('cancelled', animGroup, progress, engine);
                cleanupAnimGroup(animGroup);
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
                : (elementTransformOrders.get(animGroup) || DEFAULT_TRANSFORM_ORDER);

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
    /**
     * ElmMotion JavaScript Integration (ES Module source)
     * Canonical source for bundling ESM and IIFE distributions.
     *
     * This is the entry point only. All implementation lives in the sub-modules:
     *   state.js      – shared mutable state Maps (incl. portsRef)
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
                source: 'motionCmd',
                severity: 'warning',
                code: 'COMMAND_EMPTY'
            });
            return false;
        }
        if (!commandData.type) {
            reportError('Command missing type field', {
                source: 'motionCmd',
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
                source: 'motionCmd',
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
     *
     * If called again with a different ports object (typical SPA route swap or
     * HMR scenario), `dispose()` is invoked automatically to release per-group
     * caches before re-attaching to the new app — callers don't need to clean
     * up manually for the common reinitialisation case. A warning is still
     * reported via `PORTS_REINITIALIZED` so the swap is observable.
     *
     * @param {object} ports - The Elm app ports object (app.ports)
     */
    function init(ports) {
        if (!ports) {
            reportError('No ports provided to init()', { source: 'init', code: 'PORTS_MISSING' });
            return;
        }

        if (portsRef.ports && portsRef.ports !== ports) {
            reportError('init() called with a different ports object; previous app state has been disposed automatically', {
                source: 'init',
                severity: 'warning',
                code: 'PORTS_REINITIALIZED'
            });
            dispose();
        }

        // Store reference for outbound events (replaces former `window.app = ...`).
        portsRef.ports = ports;
        resetPortMissingWarning();

        if (!ports.motionCmd || !ports.motionCmd.subscribe) {
            reportError('motionCmd port not found or not subscribeable', {
                source: 'init',
                severity: 'warning',
                code: 'PORT_NOT_SUBSCRIBEABLE'
            });
            return;
        }

        ports.motionCmd.subscribe(async function (commandData) {
            try {
                if (!validateCommand(commandData)) return;
                await dispatchCommand(commandData);
            } catch (error) {
                reportError(error, {
                    source: 'motionCmd',
                    code: 'COMMAND_PROCESSING_FAILED',
                    commandType: commandData && commandData.type
                });
            }
        });
    }

    /**
     * Tear down the ElmMotion JS-side state. Call this when the host Elm app
     * is being unmounted (typical SPA / hot-reload scenarios) to release any
     * cached per-animation-group state and stop attempting to send events to
     * a stale ports object.
     *
     * After dispose(), call init() again with a fresh ports object to resume.
     */
    function dispose() {
        portsRef.ports = null;
        clearAllState();
        resetPortMissingWarning();
    }

    var index = { init: init, dispose: dispose, onError: onError, useConsoleReporter: useConsoleReporter, setPropertyUpdateThrottle: setPropertyUpdateThrottle };

    var __defProp=Object.defineProperty,__defNormalProp=(e,t,n)=>t in e?__defProp(e,t,{enumerable:true,configurable:true,writable:true,value:n}):e[t]=n,__publicField=(e,t,n)=>(__defNormalProp(e,"symbol"!=typeof t?t+"":t,n),n);!function(){class e{}class t extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class n extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class i extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class r extends e{constructor(e,t="unrestricted"){super(),__publicField(this,"type"),__publicField(this,"value"),this.value=e,this.type=t;}}class o extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class s extends e{}class a extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class l extends e{}class c extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class u extends e{constructor(e,t="integer"){super(),__publicField(this,"value"),__publicField(this,"type"),this.value=e,this.type=t;}}class m extends e{constructor(e){super(),__publicField(this,"value"),this.value=e;}}class f extends e{constructor(e,t,n){super(),__publicField(this,"value"),__publicField(this,"type"),__publicField(this,"unit"),this.value=e,this.type=t,this.unit=n;}}class h extends e{}class p extends e{}class d extends e{}class S extends e{}class g extends e{}class v extends e{}class T extends e{}class y extends e{}class w extends e{}class x extends e{}class b extends e{}class C extends e{}class E{constructor(e){__publicField(this,"input"),__publicField(this,"index",0),this.input=e;}consume(){const e=this.input.codePointAt(this.index);return void 0!==e&&(this.index+=String.fromCodePoint(e).length),e}reconsume(e){ void 0!==e&&(this.index-=String.fromCodePoint(e).length);}peek(){const e=[];let t=this.index;for(let n=0;n<3&&t<this.input.length;n++){const n=this.input.codePointAt(t);e.push(n),t+=String.fromCodePoint(n).length;}return e}}function k(e){return 10===e}function M(e){return k(e)||8192===e||32===e}function P(e){return e>=48&&e<=57}function I(e){return P(e)||e>=65&&e<=70||e>=97&&e<=102}function R(e){return function(e){return function(e){return e>=65&&e<=90}(e)||function(e){return e>=97&&e<=122}(e)}(e)||function(e){return e>=128}(e)||95===e}function N(e){return R(e)||P(e)||45===e}function A(e){return e>=0&&e<=8||11===e||e>=14&&e<=31||127===e}function V(e,t){return 92===e&&!k(t)}function _(e,t,n){return 45===e?R(t)||45===t||V(t,n):!!R(e)||92===e&&V(e,t)}function L(e,t,n){return 43===e||45===e?P(t)||46===t&&P(n):P(46===e?t:e)}function O(e){const t=e.consume();if(I(t)){let n=[t];for(;I(...e.peek())&&n.length<5;)n.push(e.consume());M(...e.peek())&&e.consume();const i=parseInt(String.fromCodePoint(...n),16);return 0===i||i>1114111?65533:i}return void 0===t?65533:t}function U(e,t){const n=new o("");for(;;){const i=e.consume();if(i===t)return n;if(void 0===i)return n;if(10===i)return e.reconsume(i),new s;if(92===i){const t=e.peek()[0];void 0===t||(k(t)?e.consume():n.value+=String.fromCodePoint(O(e)));}else n.value+=String.fromCodePoint(i);}}function j(e){let t="";for(;;){const n=e.consume();if(N(n))t+=String.fromCodePoint(n);else {if(!V(...e.peek()))return e.reconsume(n),t;t+=String.fromCodePoint(O(e));}}}function W(e){let t=function(e){let t="integer",n="";for([43,45].includes(e.peek()[0])&&(n+=String.fromCodePoint(e.consume()));P(...e.peek());)n+=String.fromCodePoint(e.consume());if(46===e.peek()[0]&&P(e.peek()[1]))for(n+=String.fromCodePoint(e.consume(),e.consume()),t="number";P(...e.peek());)n+=String.fromCodePoint(e.consume());return [69,101].includes(e.peek()[0])&&([45,43].includes(e.peek()[1])&&P(e.peek()[2])?(n+=String.fromCodePoint(e.consume(),e.consume(),e.consume()),t="number"):P(e.peek()[1])&&(n+=String.fromCodePoint(e.consume(),e.consume()),t="number")),{value:parseFloat(n),type:t}}(e);return _(...e.peek())?new f(t.value,t.type,j(e)):37===e.peek()[0]?(e.consume(),new m(t.value)):new u(t.value,t.type)}function F(e){for(;;){const t=e.consume();if(41===t||void 0===t)return;V(...e.peek())&&O(e);}}function D(e){const i=j(e);if(i.match(/url/i)&&40===e.peek()[0]){for(e.consume();M(e.peek()[0])&&M(e.peek()[1]);)e.consume();return [34,39].includes(e.peek()[0])||M(e.peek()[0])&&[34,39].includes(e.peek()[1])?new n(i):function(e){const t=new a("");for(;M(...e.peek());)e.consume();for(;;){const n=e.consume();if(41===n)return t;if(void 0===n)return t;if(M(n)){for(;M(...e.peek());)e.consume();return 41===e.peek()[0]||void 0===e.peek()[0]?(e.consume(),t):(F(e),new l)}if([34,39,40].includes(n)||A(n))return F(e),new l;if(92===n){if(!V(...e.peek()))return F(e),new l;t.value+=O(e);}else t.value+=String.fromCodePoint(n);}}(e)}return 40===e.peek()[0]?(e.consume(),new n(i)):new t(i)}function z(e){const t=e.consume(),n=e.peek();if(M(t)){for(;M(...e.peek());)e.consume();return new h}if(34===t)return U(e,t);if(35===t){if(N(n[0])||V(...n)){const t=new r;return _(...n)&&(t.type="id"),t.value=j(e),t}return new c(String.fromCodePoint(t))}return 39===t?U(e,t):40===t?new w:41===t?new x:43===t?L(...n)?(e.reconsume(t),W(e)):new c(String.fromCodePoint(t)):44===t?new v:45===t?L(...e.peek())?(e.reconsume(t),W(e)):45===e.peek()[0]&&62===e.peek()[1]?(e.consume(),e.consume(),new d):_(...e.peek())?(e.reconsume(t),D(e)):new c(String.fromCodePoint(t)):46===t?L(...e.peek())?(e.reconsume(t),W(e)):new c(String.fromCodePoint(t)):58===t?new S:59===t?new g:60===t?33===n[0]&&45===n[1]&&45===n[2]?(e.consume(),e.consume(),e.consume(),new p):new c(String.fromCodePoint(t)):64===t?_(...n)?new i(j(e)):new c(String.fromCodePoint(t)):91===t?new T:92===t?V(...n)?(e.reconsume(t),D(e)):new c(String.fromCodePoint(t)):93===t?new y:123===t?new b:125===t?new C:P(t)?(e.reconsume(t),W(e)):R(t)?(e.reconsume(t),D(e)):void 0===t?void 0:new c(String.fromCodePoint(t))}const H=new Set(["px","deg","s","hz","dppx","number","fr"]);function $(e){return H.has(e.toLowerCase())}function q(e,t){if(["x","y"].includes(e))return e;if(!t)throw new Error("To determine the normalized axis the computedStyle of the source is required.");const n="horizontal-tb"==t.writingMode;if("block"===e)e=n?"y":"x";else {if("inline"!==e)throw new TypeError(`Invalid axis “${e}”`);e=n?"x":"y";}return e}function B(e){const t=[];let n=0;function i(){let t=0;const i=n;for(;n<e.length;){const i=e.slice(n,n+1);if(/\s/.test(i)&&0===t)break;if("("===i)t+=1;else if(")"===i&&(t-=1,0===t)){n++;break}n++;}return e.slice(i,n)}function r(){for(;/\s/.test(e.slice(n,n+1));)n++;}for(;n<e.length;){const o=e.slice(n,n+1);/\s/.test(o)?r():t.push(i());}return t}function K(e,t){return e.reduce(((e,n)=>(e.has(n[t])?e.get(n[t]).push(n):e.set(n[t],[n]),e)),new Map)}function G(e,t){const n=[],i=[];for(const r of e)t(r)?n.push(r):i.push(r);return [n,i]}function Q(e,t={}){function n(e){return Array.from(e).map((e=>Q(e,t)))}if(e instanceof CSSUnitValue){if("percent"===e.unit&&t.percentageReference){const n=e.value/100*t.percentageReference.value,i=t.percentageReference.unit;return new CSSUnitValue(n,i)}const n=e.toSum();if(n&&1===n.values.length&&(e=n.values[0]),e instanceof CSSUnitValue&&"em"===e.unit&&t.fontSize&&(e=new CSSUnitValue(e.value*t.fontSize.value,t.fontSize.unit)),e instanceof CSSKeywordValue){if("e"===e.value)return new CSSUnitValue(Math.E,"number");if("pi"===e.value)return new CSSUnitValue(Math.PI,"number")}return e}if(!e.operator)return e;switch(e.operator){case "sum":e=new CSSMathSum(...n(e.values));break;case "product":e=new CSSMathProduct(...n(e.values));break;case "negate":e=new CSSMathNegate(Q(e.value,t));break;case "clamp":e=new CSSMathClamp(Q(e.lower,t),Q(e.value,t),Q(e.upper,t));break;case "invert":e=new CSSMathInvert(Q(e.value,t));break;case "min":e=new CSSMathMin(...n(e.values));break;case "max":e=new CSSMathMax(...n(e.values));}if(e instanceof CSSMathMin||e instanceof CSSMathMax){const t=Array.from(e.values);if(t.every((e=>e instanceof CSSUnitValue&&"percent"!==e.unit&&$(e.unit)&&e.unit===t[0].unit))){const n=Math[e.operator].apply(Math,t.map((({value:e})=>e)));return new CSSUnitValue(n,t[0].unit)}}if(e instanceof CSSMathMin||e instanceof CSSMathMax){const t=Array.from(e.values),[n,i]=G(t,(e=>e instanceof CSSUnitValue&&"percent"!==e.unit)),r=Array.from(K(n,"unit").values());if(r.some((e=>e.length>0))){const t=r.map((t=>{const n=Math[e.operator].apply(Math,t.map((({value:e})=>e)));return new CSSUnitValue(n,t[0].unit)}));e=e instanceof CSSMathMin?new CSSMathMin(...t,...i):new CSSMathMax(...t,...i);}return 1===t.length?t[0]:e}if(e instanceof CSSMathNegate)return e.value instanceof CSSUnitValue?new CSSUnitValue(0-e.value.value,e.value.unit):e.value instanceof CSSMathNegate?e.value.value:e;if(e instanceof CSSMathInvert)return e.value instanceof CSSMathInvert?e.value.value:e;if(e instanceof CSSMathSum){let t=function(e){const t=e.filter((e=>e instanceof CSSUnitValue));return [...e.filter((e=>!(e instanceof CSSUnitValue))),...Array.from(K(t,"unit").entries()).map((([e,t])=>{const n=t.reduce(((e,{value:t})=>e+t),0);return new CSSUnitValue(n,e)}))]},n=[];for(const i of e.values)i instanceof CSSMathSum?n.push(...i.values):n.push(i);return n=t(n),1===n.length?n[0]:new CSSMathSum(...n)}if(e instanceof CSSMathProduct){let t=[];for(const r of e.values)r instanceof CSSMathProduct?t.push(...r.values):t.push(r);const[n,i]=G(t,(e=>e instanceof CSSUnitValue&&"number"===e.unit));if(n.length>1){const e=n.reduce(((e,{value:t})=>e*t),1);t=[new CSSUnitValue(e,"number"),...i];}if(2===t.length){let e,n;for(const i of t)i instanceof CSSUnitValue&&"number"===i.unit?e=i:i instanceof CSSMathSum&&[...i.values].every((e=>e instanceof CSSUnitValue))&&(n=i);if(e&&n)return new CSSMathSum(...[...n.values].map((t=>new CSSUnitValue(t.value*e.value,t.unit))))}if(t.every((e=>e instanceof CSSUnitValue&&$(e.unit)||e instanceof CSSMathInvert&&e.value instanceof CSSUnitValue&&$(e.value.unit)))){const e=new CSSMathProduct(...t).toSum();if(e&&1===e.values.length)return e.values[0]}return new CSSMathProduct(...t)}return e}const X=null,Y=["percent","length","angle","time","frequency","resolution","flex"],J={fontRelativeLengths:{units:new Set(["em","rem","ex","rex","cap","rcap","ch","rch","ic","ric","lh","rlh"])},viewportRelativeLengths:{units:new Set(["vw","lvw","svw","dvw","vh","lvh","svh","dvh","vi","lvi","svi","dvi","vb","lvb","svb","dvb","vmin","lvmin","svmin","dvmin","vmax","lvmax","svmax","dvmax"])},absoluteLengths:{units:new Set(["cm","mm","Q","in","pt","pc","px"]),compatible:true,canonicalUnit:"px",ratios:{cm:96/2.54,mm:96/2.54/10,Q:96/2.54/40,in:96,pc:16,pt:96/72,px:1}},angle:{units:new Set(["deg","grad","rad","turn"]),compatible:true,canonicalUnit:"deg",ratios:{deg:1,grad:.9,rad:180/Math.PI,turn:360}},time:{units:new Set(["s","ms"]),compatible:true,canonicalUnit:"s",ratios:{s:1,ms:.001}},frequency:{units:new Set(["hz","khz"]),compatible:true,canonicalUnit:"hz",ratios:{hz:1,khz:1e3}},resolution:{units:new Set(["dpi","dpcm","dppx"]),compatible:true,canonicalUnit:"dppx",ratios:{dpi:1/96,dpcm:2.54/96,dppx:1}}},Z=new Map;for(const Vt of Object.values(J))if(Vt.compatible)for(const e of Vt.units)Z.set(e,Vt);function ee(e){return Z.get(e)}function te(e,t){const n={...e};for(const i of Object.keys(t))n[i]?n[i]+=t[i]:n[i]=t[i];return n}function ne(e){return "number"===e?{}:"percent"===e?{percent:1}:J.absoluteLengths.units.has(e)||J.fontRelativeLengths.units.has(e)||J.viewportRelativeLengths.units.has(e)?{length:1}:J.angle.units.has(e)?{angle:1}:J.time.units.has(e)?{time:1}:J.frequency.units.has(e)?{frequency:1}:J.resolution.units.has(e)?{resolution:1}:"fr"===e?{flex:1}:X}function ie(e){if(e instanceof CSSUnitValue){let{unit:t,value:n}=e;const i=ee(e.unit);return i&&t!==i.canonicalUnit&&(n*=i.ratios[t],t=i.canonicalUnit),"number"===t?[[n,{}]]:[[n,{[t]:1}]]}if(e instanceof CSSMathInvert){if(!(e.value instanceof CSSUnitValue))throw new Error("Not implemented");const t=ie(e.value);if(t===X)return X;if(t.length>1)return X;const n=t[0],i={};for(const[e,r]of Object.entries(n[1]))i[e]=-1*r;return t[0]=[1/n[0],i],t}if(e instanceof CSSMathProduct){let t=[[1,{}]];for(const n of e.values){const e=ie(n),i=[];if(e===X)return X;for(const n of t)for(const t of e)i.push([n[0]*t[0],te(n[1],t[1])]);t=i;}return t}throw new Error("Not implemented")}function re(e,t){if(ne(t)===X)throw new SyntaxError("The string did not match the expected pattern.");const n=ie(e);if(!n)throw new TypeError;if(n.length>1)throw new TypeError("Sum has more than one item");const i=function(e,t){const n=e.unit,i=e.value,r=ee(n),o=ee(t);if(!o||r!==o)return X;return new CSSUnitValue(i*o.ratios[n]/o.ratios[t],t)}(oe(n[0]),t);if(i===X)throw new TypeError;return i}function oe(e){const[t,n]=e,i=Object.entries(n);if(i.length>1)return X;if(0===i.length)return new CSSUnitValue(t,"number");const r=i[0];return 1!==r[1]?X:new CSSUnitValue(t,r[0])}function se(e,...t){if(t&&t.length)throw new Error("Not implemented");const n=ie(e).map((e=>oe(e)));if(n.some((e=>e===X)))throw new TypeError("Type error");return new CSSMathSum(...n)}function ae(e,t){if(e.percentHint&&t.percentHint&&e.percentHint!==t.percentHint)return X;const n={...e,percentHint:e.percentHint??t.percentHint};for(const i of Y)t[i]&&(n[i]??(n[i]=0),n[i]+=t[i]);return n}class CSSFunction{constructor(e,t){__publicField(this,"name"),__publicField(this,"values"),this.name=e,this.values=t;}}class CSSSimpleBlock{constructor(e,t){__publicField(this,"value"),__publicField(this,"associatedToken"),this.value=e,this.associatedToken=t;}}function le(e){if(Array.isArray(e))return e;if("string"==typeof e)return function(e){const t=new E(e),n=[];for(;;){const e=z(t);if(void 0===e)return n;n.push(e);}}(e);throw new TypeError("Invalid input type "+typeof e)}function ce(e){const t=e.shift();return t instanceof b||t instanceof T||t instanceof w?function(e,t){let n;if(t instanceof b)n=C;else if(t instanceof w)n=x;else {if(!(t instanceof T))return;n=y;}const i=new CSSSimpleBlock([],t);for(;;){const t=e.shift();if(t instanceof n)return i;if(void 0===t)return i;e.unshift(t),i.value.push(ce(e));}}(e,t):t instanceof n?function(e,t){const n=new CSSFunction(e.value,[]);for(;;){const e=t.shift();if(e instanceof x)return n;if(void 0===e)return n;t.unshift(e),n.values.push(ce(t));}}(t,e):t}function ue(e){if(e instanceof w||e instanceof x)return 6;if(e instanceof c){switch(e.value){case "*":case "/":return 4;case "+":case "-":return 2}}}function me(e){return e[e.length-1]}function fe(e,t,n){const i=["+","-"].includes(e.value)?"ADDITION":"MULTIPLICATION",r=t.type===i?t.values:[t],o=n.type===i?n.values:[n];return "-"===e.value?o[0]={type:"NEGATE",value:o[0]}:"/"===e.value&&(o[0]={type:"INVERT",value:o[0]}),{type:i,values:[...r,...o]}}function he(e){if("ADDITION"===e.type)return new CSSMathSum(...e.values.map((e=>he(e))));if("MULTIPLICATION"===e.type)return new CSSMathProduct(...e.values.map((e=>he(e))));if("NEGATE"===e.type)return new CSSMathNegate(he(e.value));if("INVERT"===e.type)return new CSSMathInvert(he(e.value));if(e instanceof CSSSimpleBlock)return pe(new CSSFunction("calc",e.value));if(e instanceof t){if("e"===e.value)return new CSSUnitValue(Math.E,"number");if("pi"===e.value)return new CSSUnitValue(Math.PI,"number");throw new SyntaxError("Invalid math expression")}return de(e)}function pe(e){if("min"===e.name||"max"===e.name){const t=e.values.filter((e=>!(e instanceof h||e instanceof v))).map((e=>Q(pe(new CSSFunction("calc",e)))));return "min"===e.name?new CSSMathMin(...t):new CSSMathMax(...t)}if("calc"!==e.name)return null;const n=he(function(e){const n=[],i=[];for(;e.length;){const r=e.shift();if(r instanceof u||r instanceof f||r instanceof m||r instanceof CSSFunction||r instanceof CSSSimpleBlock||r instanceof t)i.push(r);else if(r instanceof c&&["*","/","+","-"].includes(r.value)){for(;n.length&&!(me(n)instanceof w)&&ue(me(n))>ue(r);){const e=n.pop(),t=i.pop(),r=i.pop();i.push(fe(e,r,t));}n.push(r);}else if(r instanceof w)n.push(r);else if(r instanceof x){if(!n.length)return null;for(;!(me(n)instanceof w);){const e=n.pop(),t=i.pop(),r=i.pop();i.push(fe(e,r,t));}if(!(me(n)instanceof w))return null;n.pop();}else if(!(r instanceof h))return null}for(;n.length;){if(me(n)instanceof w)return null;const e=n.pop(),t=i.pop(),r=i.pop();i.push(fe(e,r,t));}return i[0]}([...e.values]));let i;try{i=Q(n);}catch(r){(new CSSStyleSheet).insertRule("error",0);}return i instanceof CSSUnitValue?new CSSMathSum(i):i}function de(e){return e instanceof CSSFunction&&["calc","min","max","clamp"].includes(e.name)?pe(e):e instanceof u&&0===e.value&&!e.unit?new CSSUnitValue(0,"px"):e instanceof u?new CSSUnitValue(e.value,"number"):e instanceof m?new CSSUnitValue(e.value,"percent"):e instanceof f?new CSSUnitValue(e.value,e.unit):void 0}function Se(e){const t=function(e){const t=le(e);for(;t[0]instanceof h;)t.shift();if(void 0===t[0])return null;const n=ce(t);for(;t[0]instanceof h;)t.shift();return void 0===t[0]?n:null}(e);if(null===t&&(new CSSStyleSheet).insertRule("error",0),t instanceof u||t instanceof m||t instanceof f||t instanceof CSSFunction||(new CSSStyleSheet).insertRule("error",0),t instanceof f){null===ne(t.unit)&&(new CSSStyleSheet).insertRule("error",0);}return de(t)}!function(){let e=new WeakMap;function t(e){const t=[];for(let i=0;i<e.length;i++)t[i]="number"==typeof(n=e[i])?new CSSUnitValue(n,"number"):n;var n;return t}class CSSNumericValue2{static parse(e){return e instanceof CSSNumericValue2?e:Q(Se(e),{})}}class CSSMathValue extends CSSNumericValue2{constructor(n,i,r,o){super(),e.set(this,{values:t(n),operator:i,name:r||i,delimiter:o||", "});}get operator(){return e.get(this).operator}get values(){return e.get(this).values}toString(){const t=e.get(this);return `${t.name}(${t.values.join(t.delimiter)})`}}const n={CSSNumericValue:CSSNumericValue2,CSSMathValue:CSSMathValue,CSSUnitValue:class extends CSSNumericValue2{constructor(t,n){super(),e.set(this,{value:t,unit:n});}get value(){return e.get(this).value}set value(t){e.get(this).value=t;}get unit(){return e.get(this).unit}to(e){return re(this,e)}toSum(...e){return se(this,...e)}type(){return ne(e.get(this).unit)}toString(){const t=e.get(this);return `${t.value}${function(e){switch(e){case "percent":return "%";case "number":return "";default:return e.toLowerCase()}}(t.unit)}`}},CSSKeywordValue:class{constructor(e){this.value=e;}toString(){return this.value.toString()}},CSSMathSum:class extends CSSMathValue{constructor(e){super(arguments,"sum","calc"," + ");}},CSSMathProduct:class extends CSSMathValue{constructor(e){super(arguments,"product","calc"," * ");}toSum(...e){return se(this,...e)}type(){return e.get(this).values.map((e=>e.type())).reduce(ae)}},CSSMathNegate:class extends CSSMathValue{constructor(e){super([arguments[0]],"negate","-");}get value(){return e.get(this).values[0]}type(){return this.value.type()}},CSSMathInvert:class extends CSSMathValue{constructor(e){super([1,arguments[0]],"invert","calc"," / ");}get value(){return e.get(this).values[1]}type(){return function(e){const t={};for(const n of Y)t[n]=-1*e[n];return t}(e.get(this).values[1].type())}},CSSMathMax:class extends CSSMathValue{constructor(){super(arguments,"max");}},CSSMathMin:class extends CSSMathValue{constructor(){super(arguments,"min");}}};if(!window.CSS&&!Reflect.defineProperty(window,"CSS",{value:{}}))throw Error("Error installing CSSOM support");window.CSSUnitValue||["number","percent","em","ex","px","cm","mm","in","pt","pc","Q","vw","vh","vmin","vmax","rems","ch","deg","rad","grad","turn","ms","s","Hz","kHz","dppx","dpi","dpcm","fr"].forEach((e=>{if(!Reflect.defineProperty(CSS,e,{value:t=>new CSSUnitValue(t,e)}))throw Error(`Error installing CSS.${e}`)}));for(let[i,r]of Object.entries(n))if(!(i in window)&&!Reflect.defineProperty(window,i,{value:r}))throw Error(`Error installing CSSOM support for ${i}`)}();const ge="block";let ve=new WeakMap,Te=new WeakMap;const ye=["entry","exit","cover","contain","entry-crossing","exit-crossing"];function we(e){return e===document.scrollingElement?document:e}function xe(e){Ee(e);let t=ve.get(e).animations;if(0===t.length)return;let n=e.currentTime;for(let i=0;i<t.length;i++)t[i].tickAnimation(n);}function be(e,t){if(!e)return null;const n=Te.get(e).sourceMeasurements,i=getComputedStyle(e);let r=n.scrollTop;return "x"===q(t,i)&&(r=Math.abs(n.scrollLeft)),r}function Ce(e,t){const n=Q(e,t);if(n instanceof CSSUnitValue){if("px"===n.unit)return n.value;throw TypeError("Unhandled unit type "+n.unit)}throw TypeError("Unsupported value type: "+typeof e)}function Ee(e){if(!(e instanceof $e))return void function(e){const t=ve.get(e);if(!t.anonymousSource)return;const n=_e(t.anonymousSource,t.anonymousTarget);Re(e,n);}(e);const t=e.subject;if(!t)return void Re(e,null);if("none"==getComputedStyle(t).display)return void Re(e,null);Re(e,We(t));}function ke(e){return ["block","inline","x","y"].includes(e)}function Me(e){const t=getComputedStyle(e);return {scrollLeft:e.scrollLeft,scrollTop:e.scrollTop,scrollWidth:e.scrollWidth,scrollHeight:e.scrollHeight,clientWidth:e.clientWidth,clientHeight:e.clientHeight,writingMode:t.writingMode,direction:t.direction,scrollPaddingTop:t.scrollPaddingTop,scrollPaddingBottom:t.scrollPaddingBottom,scrollPaddingLeft:t.scrollPaddingLeft,scrollPaddingRight:t.scrollPaddingRight}}function Pe(e,t){if(!e||!t)return;let n=0,i=0,r=t;const o=e.offsetParent;for(;r&&r!=o;)i+=r.offsetLeft,n+=r.offsetTop,r=r.offsetParent;i-=e.offsetLeft+e.clientLeft,n-=e.offsetTop+e.clientTop;const s=getComputedStyle(t);return {top:n,left:i,offsetWidth:t.offsetWidth,offsetHeight:t.offsetHeight,fontSize:s.fontSize}}function Ie(e){let t=Te.get(e);t.sourceMeasurements=Me(e);for(const n of t.timelineRefs){const t=n.deref();if(t instanceof $e){ve.get(t).subjectMeasurements=Pe(e,t.subject);}}t.updateScheduled||(setTimeout((()=>{for(const e of t.timelineRefs){const t=e.deref();t&&xe(t);}t.updateScheduled=false;})),t.updateScheduled=true);}function Re(e,t){const n=ve.get(e),i=n.source;if(i!=t){if(i){const t=Te.get(i);if(t){t.timelineRefs.delete(e);const n=Array.from(t.timelineRefs).filter((e=>void 0===e.deref()));for(const e of n)t.timelineRefs.delete(e);0===t.timelineRefs.size&&(t.disconnect(),Te.delete(i));}}if(n.source=t,t){let i=Te.get(t);if(!i){i={timelineRefs:new Set,sourceMeasurements:Me(t)},Te.set(t,i);const e=new ResizeObserver((e=>{for(const t of e)Ie(n.source);}));e.observe(t);for(const n of t.children)e.observe(n);const r=new MutationObserver((e=>{for(const t of e)Ie(t.target);}));r.observe(t,{attributes:true,attributeFilter:["style","class"]});const o=()=>{i.sourceMeasurements.scrollLeft=t.scrollLeft,i.sourceMeasurements.scrollTop=t.scrollTop;for(const e of i.timelineRefs){const t=e.deref();t&&xe(t);}};we(t).addEventListener("scroll",o),i.disconnect=()=>{e.disconnect(),r.disconnect(),we(t).removeEventListener("scroll",o);};}i.timelineRefs.add(new WeakRef(e));}}}function Ne(e,t){let n=ve.get(e).animations;for(let i=0;i<n.length;i++)n[i].animation==t&&n.splice(i,1);}function Ae(e,t,n){let i=ve.get(e).animations;for(let r=0;r<i.length;r++)if(i[r].animation==t)return;i.push({animation:t,tickAnimation:n}),queueMicrotask((()=>{xe(e);}));}class ScrollTimeline{constructor(e){ve.set(this,{source:null,axis:ge,anonymousSource:e?e.anonymousSource:null,anonymousTarget:e?e.anonymousTarget:null,subject:null,inset:null,animations:[],subjectMeasurements:null});if(Re(this,e&&void 0!==e.source?e.source:document.scrollingElement),e&&void 0!==e.axis&&e.axis!=ge){if(!ke(e.axis))throw TypeError("Invalid axis");ve.get(this).axis=e.axis;}xe(this);}set source(e){Re(this,e),xe(this);}get source(){return ve.get(this).source}set axis(e){if(!ke(e))throw TypeError("Invalid axis");ve.get(this).axis=e,xe(this);}get axis(){return ve.get(this).axis}get duration(){return CSS.percent(100)}get phase(){const e=this.source;if(!e)return "inactive";let t=getComputedStyle(e);return "none"==t.display?"inactive":e==document.scrollingElement||"visible"!=t.overflow&&"clip"!=t.overflow?"active":"inactive"}get currentTime(){const e=null,t=this.source;if(!t||!t.isConnected)return e;if("inactive"==this.phase)return e;const n=getComputedStyle(t);if("inline"===n.display||"none"===n.display)return e;const i=this.axis,r=be(t,i),o=function(e,t){const n=Te.get(e).sourceMeasurements,i="horizontal-tb"==getComputedStyle(e).writingMode;return "block"===t?t=i?"y":"x":"inline"===t&&(t=i?"x":"y"),"y"===t?n.scrollHeight-n.clientHeight:"x"===t?n.scrollWidth-n.clientWidth:void 0}(t,i);return o>0?CSS.percent(100*r/o):CSS.percent(100)}get __polyfill(){return  true}}function Ve(e,t){let n=e.parentElement;for(;null!=n;){if(t(n))return n;n=n.parentElement;}}function _e(e,t){switch(e){case "root":return document.scrollingElement;case "nearest":return We(t);case "self":return t;default:throw new TypeError("Invalid ScrollTimeline Source Type.")}}function Le(e){switch(getComputedStyle(e).display){case "block":case "inline-block":case "list-item":case "table":case "table-caption":case "flow-root":case "flex":case "grid":return  true}return  false}function Oe(e){const t=getComputedStyle(e);return "none"!=t.transform||"none"!=t.perspective||("transform"==t.willChange||"perspective"==t.willChange||("none"!=t.filter||"filter"==t.willChange||"none"!=t.backdropFilter))}function Ue(e){return "static"!=getComputedStyle(e).position||Oe(e)}function je(e){switch(getComputedStyle(e).position){case "static":case "relative":case "sticky":return Ve(e,Le);case "absolute":return Ve(e,Ue);case "fixed":return Ve(e,Oe)}}function We(e){if(e&&e.isConnected){for(;e=je(e);){switch(getComputedStyle(e)["overflow-x"]){case "auto":case "scroll":case "hidden":return e==document.body&&"visible"==getComputedStyle(document.scrollingElement).overflow?document.scrollingElement:e}}return document.scrollingElement}}function Fe(e,t){const n=ve.get(e),i=n.subjectMeasurements,r=Te.get(n.source).sourceMeasurements;return "inactive"===e.phase?null:e instanceof $e?De(t,r,i,n.axis,n.inset):null}function De(e,t,n,i,r){const o="rtl"==t.direction||"vertical-rl"==t.writingMode;let s,a,l={fontSize:n.fontSize};"x"===q(i,t)?(s=n.offsetWidth,a=n.left,l.scrollPadding=[t.scrollPaddingLeft,t.scrollPaddingRight],o&&(a+=t.scrollWidth-t.clientWidth,l.scrollPadding=[t.scrollPaddingRight,t.scrollPaddingLeft]),l.containerSize=t.clientWidth):(s=n.offsetHeight,a=n.top,l.scrollPadding=[t.scrollPaddingTop,t.scrollPaddingBottom],l.containerSize=t.clientHeight);const c=function(e,t){const n={start:0,end:0};if(!e)return n;const[i,r]=[e.start,e.end].map(((e,n)=>"auto"===e?"auto"===t.scrollPadding[n]?0:parseFloat(t.scrollPadding[n]):Ce(e,{percentageReference:CSS.px(t.containerSize),fontSize:CSS.px(parseFloat(t.fontSize))})));return {start:i,end:r}}(r,l),u=a-l.containerSize+c.end,m=a+s-c.start,f=u+s,h=m-s,p=Math.min(f,h),d=Math.max(f,h);let S,g;const v=s>l.containerSize-c.start-c.end;switch(e){case "cover":S=u,g=m;break;case "contain":S=p,g=d;break;case "entry":S=u,g=p;break;case "exit":S=d,g=m;break;case "entry-crossing":S=u,g=v?d:p;break;case "exit-crossing":S=v?p:d,g=m;}return {start:S,end:g}}function ze(e,t){if(e instanceof $e){const{rangeName:n,offset:i}=t;return He(Fe(e,n),i,Fe(e,"cover"),e.subject)}if(e instanceof ScrollTimeline){const{axis:n,source:i}=e,{sourceMeasurements:r}=Te.get(i);let o;o="x"===q(n,r)?r.scrollWidth-r.clientWidth:r.scrollHeight-r.clientHeight;return Ce(t,{percentageReference:CSS.px(o)})/o}unsupportedTimeline(e);}function He(e,t,n,i){if(!e||!n)return 0;let r=getComputedStyle(i);return (Ce(t,{percentageReference:CSS.px(e.end-e.start),fontSize:CSS.px(parseFloat(r.fontSize))})+e.start-n.start)/(n.end-n.start)}let $e=class ViewTimeline extends ScrollTimeline{constructor(e){super(e);const t=ve.get(this);if(t.subject=e&&e.subject?e.subject:void 0,e&&e.inset&&(t.inset=function(e){if(!e)return {start:0,end:0};let t;if(t="string"==typeof e?B(e).map((t=>{if("auto"===t)return "auto";try{return CSSNumericValue.parse(t)}catch(n){throw TypeError(`Could not parse inset "${e}"`)}})):Array.isArray(e)?e:[e],0===t.length||t.length>2)throw TypeError("Invalid inset");for(const n of t){if("auto"===n)continue;const e=n.type();if(1!==e.length&&1!==e.percent)throw TypeError("Invalid inset")}return {start:t[0],end:t[1]??t[0]}}(e.inset)),t.subject){new ResizeObserver((()=>{Ie(t.source);})).observe(t.subject);new MutationObserver((()=>{Ie(t.source);})).observe(t.subject,{attributes:true,attributeFilter:["class","style"]});}Ee(this),t.subjectMeasurements=Pe(t.source,t.subject),xe(this);}get source(){return Ee(this),ve.get(this).source}set source(e){throw new Error("Cannot set the source of a view timeline")}get subject(){return ve.get(this).subject}get axis(){return ve.get(this).axis}get currentTime(){const e=null,t=be(this.source,this.axis);if(t==e)return e;const n=Fe(this,"cover");if(!n)return e;const i=(t-n.start)/(n.end-n.start);return CSS.percent(100*i)}get startOffset(){return CSS.px(Fe(this,"cover").start)}get endOffset(){return CSS.px(Fe(this,"cover").end)}};const qe=document.getAnimations,Be=window.Element.prototype.getAnimations,Ke=window.Element.prototype.animate,Ge=window.Animation;class Qe{constructor(){this.state="pending",this.nativeResolve=this.nativeReject=null,this.promise=new Promise(((e,t)=>{this.nativeResolve=e,this.nativeReject=t;}));}resolve(e){this.state="resolved",this.nativeResolve(e);}reject(e){this.state="rejected",this.promise.catch((()=>{})),this.nativeReject(e);}}function Xe(e){e.readyPromise=new Qe,requestAnimationFrame((()=>{var t;null!==((null==(t=e.timeline)?void 0:t.currentTime)??null)&&(dt(e),"play"!==e.pendingTask||null===e.startTime&&null===e.holdTime?"pause"===e.pendingTask&&tt(e):et(e));}));}function Ye(){return new DOMException("The user aborted a request","AbortError")}function Je(e,t){if(null===t)return t;if("number"!=typeof t)throw new DOMException(`Unexpected value: ${t}.  Cannot convert to CssNumberish`,"InvalidStateError");const n=e.rangeDuration??100,i=at(e),r=i?n*t/i:0;return CSS.percent(r)}function Ze(e,t){if(e.timeline){if(null===t)return t;if("percent"===t.unit){const n=e.rangeDuration??100,i=at(e);return t.value*i/n}throw new DOMException("CSSNumericValue must be a percentage for progress based animations.","NotSupportedError")}{if(null==t||"number"==typeof t)return t;const e=t.to("ms");if(e)return e.value;throw new DOMException("CSSNumericValue must be either a number or a time value for time based animations.","InvalidStateError")}}function et(e){const t=Ze(e,e.timeline.currentTime);if(null!=e.holdTime)rt(e),0==e.animation.playbackRate?e.startTime=t:(e.startTime=t-e.holdTime/e.animation.playbackRate,e.holdTime=null);else if(null!==e.startTime&&null!==e.pendingPlaybackRate){const n=(t-e.startTime)*e.animation.playbackRate;rt(e);const i=e.animation.playbackRate;0==i?(e.holdTime=null,e.startTime=t):e.startTime=t-n/i;}e.readyPromise&&"pending"==e.readyPromise.state&&e.readyPromise.resolve(e.proxy),st(e,false,false),lt(e),e.pendingTask=null;}function tt(e){const t=Ze(e,e.timeline.currentTime);null!=e.startTime&&null==e.holdTime&&(e.holdTime=(t-e.startTime)*e.animation.playbackRate),rt(e),e.startTime=null,e.readyPromise.resolve(e.proxy),st(e,false,false),lt(e),e.pendingTask=null;}function nt(e){if(!e.finishedPromise||"pending"!=e.finishedPromise.state)return;if("finished"!=e.proxy.playState)return;e.finishedPromise.resolve(e.proxy),e.animation.pause();const t=new CustomEvent("finish",{detail:{currentTime:e.proxy.currentTime,timelineTime:e.proxy.timeline.currentTime}});Object.defineProperty(t,"currentTime",{get:function(){return this.detail.currentTime}}),Object.defineProperty(t,"timelineTime",{get:function(){return this.detail.timelineTime}}),requestAnimationFrame((()=>{queueMicrotask((()=>{e.animation.dispatchEvent(t);}));}));}function it(e){return null!==e.pendingPlaybackRate?e.pendingPlaybackRate:e.animation.playbackRate}function rt(e){null!==e.pendingPlaybackRate&&(e.animation.playbackRate=e.pendingPlaybackRate,e.pendingPlaybackRate=null);}function ot(e){if(!e.timeline)return null;const t=Ze(e,e.timeline.currentTime);if(null===t)return null;if(null===e.startTime)return null;let n=(t-e.startTime)*e.animation.playbackRate;return  -0==n&&(n=0),n}function st(e,t,n){if(!e.timeline)return;let i=t?Ze(e,e.proxy.currentTime):ot(e);if(i&&null!=e.startTime&&!e.proxy.pending){const n=it(e),r=at(e);let o=e.previousCurrentTime;n>0&&i>=r&&null!=e.previousCurrentTime?((null===o||o<r)&&(o=r),e.holdTime=t?i:o):n<0&&i<=0?((null==o||o>0)&&(o=0),e.holdTime=t?i:o):0!=n&&(t&&null!==e.holdTime&&(e.startTime=function(e,t){if(!e.timeline)return null;const n=Ze(e,e.timeline.currentTime);return null==n?null:n-t/e.animation.playbackRate}(e,e.holdTime)),e.holdTime=null);}lt(e),e.previousCurrentTime=Ze(e,e.proxy.currentTime);"finished"==e.proxy.playState?(e.finishedPromise||(e.finishedPromise=new Qe),"pending"==e.finishedPromise.state&&(n?nt(e):Promise.resolve().then((()=>{nt(e);})))):(e.finishedPromise&&"resolved"==e.finishedPromise.state&&(e.finishedPromise=new Qe),"paused"!=e.animation.playState&&e.animation.pause());}function at(e){const t=function(e){const t=e.proxy.effect.getTiming();return e.normalizedTiming||t}(e),n=t.delay+t.endDelay+t.iterations*t.duration;return Math.max(0,n)}function lt(e){if(e.timeline)if(null!==e.startTime){const t=e.timeline.currentTime;if(null==t)return;ct(e,(Ze(e,t)-e.startTime)*e.animation.playbackRate);}else null!==e.holdTime&&ct(e,e.holdTime);}function ct(e,t){const n=e.timeline,i=e.animation.playbackRate,r=n.currentTime&&n.currentTime.value==(i<0?0:100)?i<0?.001:-1e-3:0;e.animation.currentTime=t+r;}function ut(e,t){if(!e.timeline)return;const n="paused"==e.proxy.playState&&e.proxy.pending;let i=false,r=Ze(e,e.proxy.currentTime);0==it(e)&&null==r&&(e.holdTime=0),null==r&&(e.autoAlignStartTime=true),("finished"===e.proxy.playState||n)&&(e.holdTime=null,e.startTime=null,e.autoAlignStartTime=true),e.holdTime&&(e.startTime=null),e.pendingTask&&(e.pendingTask=null,i=true),(null!==e.holdTime||e.autoAlignStartTime||n||null!==e.pendingPlaybackRate)&&(e.readyPromise&&!i&&(e.readyPromise=null),lt(e),e.readyPromise||Xe(e),e.pendingTask="play",Ae(e.timeline,e.animation,mt.bind(e.proxy)),st(e,false,false));}function mt(e){const t=ht.get(this);if(!t)return;if(null==e)return void("paused"!==t.proxy.playState&&"idle"!=t.animation.playState&&t.animation.cancel());dt(t),t.pendingTask&&requestAnimationFrame((()=>{"play"!==t.pendingTask||null===t.startTime&&null===t.holdTime?"pause"===t.pendingTask&&tt(t):et(t);}));const n=this.playState;if("running"==n||"finished"==n){const n=Ze(t,e);ct(t,(n-Ze(t,this.startTime))*this.playbackRate),st(t,false,false);}}function ft(e){e.specifiedTiming=null;}let ht=new WeakMap;window.addEventListener("pagehide",(e=>{ht=new WeakMap;}),false);let pt=new WeakMap;function dt(e){if(!e.autoAlignStartTime)return;if(!e.timeline||!e.timeline.currentTime)return;if("idle"===e.proxy.playState||"paused"===e.proxy.playState&&null!==e.holdTime)return;const t=e.rangeDuration;let n,i;try{n=CSS.percent(100*function(e){if(!e.animationRange)return 0;const t="normal"===e.animationRange.start?gt(e.timeline):e.animationRange.start;return ze(e.timeline,t)}(e));}catch(o){n=CSS.percent(0),e.animationRange.start="normal",console.warn("Exception when calculating start offset",o);}try{i=CSS.percent(100*(1-function(e){if(!e.animationRange)return 0;const t="normal"===e.animationRange.end?vt(e.timeline):e.animationRange.end;return 1-ze(e.timeline,t)}(e)));}catch(o){i=CSS.percent(100),e.animationRange.end="normal",console.warn("Exception when calculating end offset",o);}e.rangeDuration=i.value-n.value;const r=it(e);e.startTime=Ze(e,r>=0?n:i),e.holdTime=null,e.rangeDuration!==t&&ft(e);}function St(e){throw new Error("Unsupported timeline class")}function gt(e){return e instanceof ViewTimeline?{rangeName:"cover",offset:CSS.percent(0)}:e instanceof ScrollTimeline?CSS.percent(0):void St()}function vt(e){return e instanceof ViewTimeline?{rangeName:"cover",offset:CSS.percent(100)}:e instanceof ScrollTimeline?CSS.percent(100):void St()}function Tt(e,t){if(!t)return {start:"normal",end:"normal"};const n={start:gt(e),end:vt(e)};if(e instanceof ViewTimeline){const e=B(t),i=[],r=[];if(e.forEach((e=>{if(ye.includes(e))i.push(e);else try{r.push(CSSNumericValue.parse(e));}catch(n){throw TypeError(`Could not parse range "${t}"`)}})),i.length>2||r.length>2||1==r.length)throw TypeError("Invalid time range or unsupported time range format.");return i.length&&(n.start.rangeName=i[0],n.end.rangeName=i.length>1?i[1]:i[0]),r.length>1&&(n.start.offset=r[0],n.end.offset=r[1]),n}if(e instanceof ScrollTimeline){const e=t.split(" ");if(2!=e.length)throw TypeError("Invalid time range or unsupported time range format.");return n.start=CSSNumericValue.parse(e[0]),n.end=CSSNumericValue.parse(e[1]),n}St();}function yt(e,t,n){if(!t||"normal"===t)return "normal";if(e instanceof ViewTimeline){let e="cover",i="start"===n?CSS.percent(0):CSS.percent(100);if(t instanceof Object) void 0!==t.rangeName&&(e=t.rangeName),void 0!==t.offset&&(i=t.offset);else {const n=B(t);1===n.length?ye.includes(n[0])?e=n[0]:i=Q(CSSNumericValue.parse(n[0]),{}):2===n.length&&(e=n[0],i=Q(CSSNumericValue.parse(n[1]),{}));}if(!ye.includes(e))throw TypeError("Invalid range name");return {rangeName:e,offset:i}}if(e instanceof ScrollTimeline)return CSSNumericValue.parse(t);St();}class wt{constructor(e,t,n={}){const i=t instanceof ScrollTimeline,r=e instanceof Ge?e:new Ge(e,i?void 0:t);pt.set(r,this),ht.set(this,{animation:r,timeline:i?t:void 0,playState:i?"idle":null,readyPromise:null,finishedPromise:null,startTime:null,holdTime:null,rangeDuration:null,previousCurrentTime:null,autoAlignStartTime:false,pendingPlaybackRate:null,pendingTask:null,specifiedTiming:null,normalizedTiming:null,effect:null,animationRange:i?Tt(t,n["animation-range"]):null,proxy:this});}get effect(){const e=ht.get(this);return e.timeline?(e.effect||(e.effect=function(e){const t=e.animation.effect,n=t.updateTiming,i={apply:function(n){t.getTiming();const i=n.apply(t);if(e.timeline){const t=e.duration??100;i.localTime=Je(e,i.localTime),i.endTime=Je(e,i.endTime),i.activeDuration=Je(e,i.activeDuration);const n=at(e),r=i.iterations?(n-i.delay-i.endDelay)/i.iterations:0;i.duration=n?CSS.percent(t*r/n):CSS.percent(0),void 0===e.timeline.currentTime&&(i.localTime=null);}return i}},r={apply:function(i,r){if(e.specifiedTiming)return e.specifiedTiming;e.specifiedTiming=i.apply(t);let o,s=Object.assign({},e.specifiedTiming);if(s.duration===1/0)throw TypeError("Effect duration cannot be Infinity when used with Scroll Timelines");return (null===s.duration||"auto"===s.duration||e.autoDurationEffect)&&e.timeline&&(e.autoDurationEffect=true,s.delay=0,s.endDelay=0,o=s.iterations?1e5:0,s.duration=s.iterations?(o-s.delay-s.endDelay)/s.iterations:0,s.duration<0&&(s.duration=0,s.endDelay=o-s.delay),n.apply(t,[s])),e.normalizedTiming=s,e.specifiedTiming}},o={apply:function(n,i,r){if(r&&r.length){if(e.timeline&&r[0]){const t=r[0],n=t.duration;if(n===1/0)throw TypeError("Effect duration cannot be Infinity when used with Scroll Timelines");if(t.iterations===1/0)throw TypeError("Effect iterations cannot be Infinity when used with Scroll Timelines");void 0!==n&&"auto"!==n&&(e.autoDurationEffect=null);}e.specifiedTiming&&n.apply(t,[e.specifiedTiming]),n.apply(t,r),ft(e);}}},s=new Proxy(t,{get:function(e,n){const i=e[n];return "function"==typeof i?i.bind(t):i},set:function(e,t,n){return e[t]=n,true}});return s.getComputedTiming=new Proxy(t.getComputedTiming,i),s.getTiming=new Proxy(t.getTiming,r),s.updateTiming=new Proxy(t.updateTiming,o),s}(e)),e.effect):e.animation.effect}set effect(e){const t=ht.get(this);t.animation.effect=e,t.effect=null,t.autoDurationEffect=null;}get timeline(){const e=ht.get(this);return e.timeline||e.animation.timeline}set timeline(e){const t=ht.get(this),n=this.timeline;if(n==e)return;const i=this.playState,r=this.currentTime;let o,s=at(t);o=null===r?null:0===s?0:Ze(t,r)/s;const a=n instanceof ScrollTimeline,l=e instanceof ScrollTimeline,c=this.pending;if(a&&Ne(t.timeline,t.animation),l)return t.timeline=e,rt(t),t.autoAlignStartTime=true,t.startTime=null,t.holdTime=null,"running"!==i&&"finished"!==i||(t.readyPromise&&"resolved"!==t.readyPromise.state||Xe(t),t.pendingTask="play",Ae(t.timeline,t.animation,mt.bind(this))),"paused"===i&&null!==o&&(t.holdTime=o*s),c&&(t.readyPromise&&"resolved"!=t.readyPromise.state||Xe(t),t.pendingTask="paused"==i?"pause":"play"),null!==t.startTime&&(t.holdTime=null),void st(t,false,false);if(t.animation.timeline!=e)throw TypeError("Unsupported timeline: "+e);if(Ne(t.timeline,t.animation),t.timeline=null,a)switch(null!==r&&(t.animation.currentTime=o*at(t)),i){case "paused":t.animation.pause();break;case "running":case "finished":t.animation.play();}}get startTime(){const e=ht.get(this);return e.timeline?Je(e,e.startTime):e.animation.startTime}set startTime(e){const t=ht.get(this);if(e=Ze(t,e),!t.timeline)return void(t.animation.startTime=e);t.autoAlignStartTime=false;null==Ze(t,t.timeline.currentTime)&&null!=t.startTime&&(t.holdTime=null,lt(t));const n=Ze(t,this.currentTime);rt(t),t.startTime=e,null!==t.startTime&&0!=t.animation.playbackRate?t.holdTime=null:t.holdTime=n,t.pendingTask&&(t.pendingTask=null,t.readyPromise.resolve(this)),st(t,true,false),lt(t);}get currentTime(){const e=ht.get(this);return e.timeline?null!=e.holdTime?Je(e,e.holdTime):Je(e,ot(e)):e.animation.currentTime}set currentTime(e){const t=ht.get(this);t.timeline?(!function(e,t){if(null==t&&null!==e.currentTime)throw new TypeError;t=Ze(e,t),e.autoAlignStartTime=false,null!==e.holdTime||null===e.startTime||"inactive"===e.timeline.phase||0===e.animation.playbackRate?e.holdTime=t:e.startTime=Ze(e,e.timeline.currentTime)-t/e.animation.playbackRate,"inactive"===e.timeline.phase&&(e.startTime=null),e.previousCurrentTime=null;}(t,e),"pause"==t.pendingTask&&(t.holdTime=Ze(t,e),rt(t),t.startTime=null,t.pendingTask=null,t.readyPromise.resolve(this)),st(t,true,false)):t.animation.currentTime=e;}get playbackRate(){return ht.get(this).animation.playbackRate}set playbackRate(e){const t=ht.get(this);if(!t.timeline)return void(t.animation.playbackRate=e);t.pendingPlaybackRate=null;const n=this.currentTime;t.animation.playbackRate=e,null!==n&&(this.currentTime=n);}get playState(){const e=ht.get(this);if(!e.timeline)return e.animation.playState;const t=Ze(e,this.currentTime);if(null===t&&null===e.startTime&&null==e.pendingTask)return "idle";if("pause"==e.pendingTask||null===e.startTime&&"play"!=e.pendingTask)return "paused";if(null!=t){if(e.animation.playbackRate>0&&t>=at(e))return "finished";if(e.animation.playbackRate<0&&t<=0)return "finished"}return "running"}get rangeStart(){var e;return (null==(e=ht.get(this).animationRange)?void 0:e.start)??"normal"}set rangeStart(e){const t=ht.get(this);if(!t.timeline)return t.animation.rangeStart=e;if(t.timeline instanceof ScrollTimeline){t.animationRange.start=yt(t.timeline,e,"start"),dt(t),lt(t);}}get rangeEnd(){var e;return (null==(e=ht.get(this).animationRange)?void 0:e.end)??"normal"}set rangeEnd(e){const t=ht.get(this);if(!t.timeline)return t.animation.rangeEnd=e;if(t.timeline instanceof ScrollTimeline){t.animationRange.end=yt(t.timeline,e,"end"),dt(t),lt(t);}}get replaceState(){return ht.get(this).animation.pending}get pending(){const e=ht.get(this);return e.timeline?!!e.readyPromise&&"pending"==e.readyPromise.state:e.animation.pending}finish(){const e=ht.get(this);if(!e.timeline)return void e.animation.finish();const t=it(e),n=at(e);if(0==t)throw new DOMException("Cannot finish Animation with a playbackRate of 0.","InvalidStateError");if(t>0&&n==1/0)throw new DOMException("Cannot finish Animation with an infinite target effect end.","InvalidStateError");rt(e);const i=t<0?0:n;this.currentTime=Je(e,i);const r=Ze(e,e.timeline.currentTime);null===e.startTime&&null!==r&&(e.startTime=r-i/e.animation.playbackRate),"pause"==e.pendingTask&&null!==e.startTime&&(e.holdTime=null,e.pendingTask=null,e.readyPromise.resolve(this)),"play"==e.pendingTask&&null!==e.startTime&&(e.pendingTask=null,e.readyPromise.resolve(this)),st(e,true,true);}play(){const e=ht.get(this);e.timeline?ut(e):e.animation.play();}pause(){const e=ht.get(this);e.timeline?"paused"!=this.playState&&(null===e.animation.currentTime&&(e.autoAlignStartTime=true),"play"==e.pendingTask?e.pendingTask=null:e.readyPromise=null,e.readyPromise||Xe(e),e.pendingTask="pause",Ae(e.timeline,e.animation,mt.bind(e.proxy))):e.animation.pause();}reverse(){const e=ht.get(this),t=it(e),n=Ze(e,this.currentTime),i=at(e)==1/0,r=0!=t&&(t<0||n>0||!i);if(!e.timeline||!r)return r&&(e.pendingPlaybackRate=-it(e)),void e.animation.reverse();if("inactive"==e.timeline.phase)throw new DOMException("Cannot reverse an animation with no active timeline","InvalidStateError");this.updatePlaybackRate(-t),ut(e);}updatePlaybackRate(e){const t=ht.get(this);if(t.pendingPlaybackRate=e,!t.timeline)return void t.animation.updatePlaybackRate(e);const n=this.playState;if(!t.readyPromise||"pending"!=t.readyPromise.state)switch(n){case "idle":case "paused":rt(t);break;case "finished":const n=Ze(t,t.timeline.currentTime),i=null!==n?(n-t.startTime)*t.animation.playbackRate:null;t.startTime=0==e?n:null!=n&&null!=i?(n-i)/e:null,rt(t),st(t,false,false),lt(t);break;default:ut(t);}}persist(){ht.get(this).animation.persist();}get id(){return ht.get(this).animation.id}set id(e){ht.get(this).animation.id=e;}cancel(){const e=ht.get(this);e.timeline?("idle"!=this.playState&&(!function(e){e.pendingTask&&(e.pendingTask=null,rt(e),e.readyPromise.reject(Ye()),Xe(e),e.readyPromise.resolve(e.proxy));}(e),e.finishedPromise&&"pending"==e.finishedPromise.state&&e.finishedPromise.reject(Ye()),e.finishedPromise=new Qe,e.animation.cancel()),e.startTime=null,e.holdTime=null,Ne(e.timeline,e.animation)):e.animation.cancel();}get onfinish(){return ht.get(this).animation.onfinish}set onfinish(e){ht.get(this).animation.onfinish=e;}get oncancel(){return ht.get(this).animation.oncancel}set oncancel(e){ht.get(this).animation.oncancel=e;}get onremove(){return ht.get(this).animation.onremove}set onremove(e){ht.get(this).animation.onremove=e;}get finished(){const e=ht.get(this);return e.timeline?(e.finishedPromise||(e.finishedPromise=new Qe),e.finishedPromise.promise):e.animation.finished}get ready(){const e=ht.get(this);return e.timeline?(e.readyPromise||(e.readyPromise=new Qe,e.readyPromise.resolve(this)),e.readyPromise.promise):e.animation.ready}addEventListener(e,t,n){ht.get(this).animation.addEventListener(e,t,n);}removeEventListener(e,t,n){ht.get(this).animation.removeEventListener(e,t,n);}dispatchEvent(e){ht.get(this).animation.dispatchEvent(e);}}function xt(e,t){const n=t.timeline;n instanceof ScrollTimeline&&delete t.timeline;const i=Ke.apply(this,[e,t]),r=new wt(i,n);if(n instanceof ScrollTimeline){i.pause();ht.get(r).animationRange={start:yt(n,t.rangeStart,"start"),end:yt(n,t.rangeEnd,"end")},r.play();}return r}function bt(e){for(let t=0;t<e.length;++t){let n=pt.get(e[t]);n&&(e[t]=n);}return e}function Ct(e){return bt(Be.apply(this,[e]))}function Et(e){return bt(qe.apply(this,[e]))}const kt={IDENTIFIER:/[\w\\\@_-]+/g,WHITE_SPACE:/\s*/g,TIME:/^[0-9]+(s|ms)/,SCROLL_TIMELINE:/scroll-timeline\s*:([^;}]+)/,SCROLL_TIMELINE_NAME:/scroll-timeline-name\s*:([^;}]+)/,SCROLL_TIMELINE_AXIS:/scroll-timeline-axis\s*:([^;}]+)/,VIEW_TIMELINE:/view-timeline\s*:([^;}]+)/,VIEW_TIMELINE_NAME:/view-timeline-name\s*:([^;}]+)/,VIEW_TIMELINE_AXIS:/view-timeline-axis\s*:([^;}]+)/,VIEW_TIMELINE_INSET:/view-timeline-inset\s*:([^;}]+)/,ANIMATION_TIMELINE:/animation-timeline\s*:([^;}]+)/,ANIMATION_TIME_RANGE:/animation-range\s*:([^;}]+)/,ANIMATION_NAME:/animation-name\s*:([^;}]+)/,ANIMATION:/animation\s*:([^;}]+)/,ANONYMOUS_SCROLL_TIMELINE:/scroll\(([^)]*)\)/,ANONYMOUS_VIEW_TIMELINE:/view\(([^)]*)\)/},Mt=["block","inline","x","y"],Pt=["nearest","root","self"];const It=new class{constructor(){this.cssRulesWithTimelineName=[],this.nextAnonymousTimelineNameIndex=0,this.anonymousScrollTimelineOptions=new Map,this.anonymousViewTimelineOptions=new Map,this.sourceSelectorToScrollTimeline=[],this.subjectSelectorToViewTimeline=[],this.keyframeNamesSelectors=new Map;}transpileStyleSheet(e,t,n){const i={sheetSrc:e,index:0,name:n};for(;i.index<i.sheetSrc.length&&(this.eatWhitespace(i),!(i.index>=i.sheetSrc.length));){if(this.lookAhead("/*",i)){for(;this.lookAhead("/*",i);)this.eatComment(i),this.eatWhitespace(i);continue}const e=this.parseQualifiedRule(i);e&&(t?this.parseKeyframesAndSaveNameMapping(e,i):this.handleScrollTimelineProps(e,i));}return i.sheetSrc}getAnimationTimelineOptions(e,t){for(let n=this.cssRulesWithTimelineName.length-1;n>=0;n--){const i=this.cssRulesWithTimelineName[n];try{if(t.matches(i.selector)&&(!i["animation-name"]||i["animation-name"]==e))return {"animation-timeline":i["animation-timeline"],"animation-range":i["animation-range"]}}catch{}}return null}getAnonymousScrollTimelineOptions(e,t){const n=this.anonymousScrollTimelineOptions.get(e);return n?{anonymousSource:n.source,anonymousTarget:t,source:_e(n.source??"nearest",t),axis:n.axis?n.axis:"block"}:null}getScrollTimelineOptions(e,t){const n=this.getAnonymousScrollTimelineOptions(e,t);if(n)return n;for(let i=this.sourceSelectorToScrollTimeline.length-1;i>=0;i--){const n=this.sourceSelectorToScrollTimeline[i];if(n.name==e){const e=this.findPreviousSiblingOrAncestorMatchingSelector(t,n.selector);if(e)return {source:e,...n.axis?{axis:n.axis}:{}}}}return null}findPreviousSiblingOrAncestorMatchingSelector(e,t){let n=e;for(;n;){if(n.matches(t))return n;n=n.previousElementSibling||n.parentElement;}return null}getAnonymousViewTimelineOptions(e,t){const n=this.anonymousViewTimelineOptions.get(e);return n?{subject:t,axis:n.axis?n.axis:"block",inset:n.inset?n.inset:"auto"}:null}getViewTimelineOptions(e,t){const n=this.getAnonymousViewTimelineOptions(e,t);if(n)return n;for(let i=this.subjectSelectorToViewTimeline.length-1;i>=0;i--){const n=this.subjectSelectorToViewTimeline[i];if(n.name==e){const e=this.findPreviousSiblingOrAncestorMatchingSelector(t,n.selector);if(e)return {subject:e,axis:n.axis,inset:n.inset}}}return null}handleScrollTimelineProps(e,t){if(e.selector.includes("@keyframes"))return;const n=e.block.contents.includes("animation-name:"),i=e.block.contents.includes("animation-timeline:"),r=e.block.contents.includes("animation:");if(this.saveSourceSelectorToScrollTimeline(e),this.saveSubjectSelectorToViewTimeline(e),!i&&!n&&!r)return;let o=[],s=[],a=false;i&&(o=this.extractScrollTimelineNames(e.block.contents)),n&&(s=this.extractMatches(e.block.contents,kt.ANIMATION_NAME)),i&&n||(r&&this.extractMatches(e.block.contents,kt.ANIMATION).forEach((t=>{const n=this.extractAnimationName(t);n&&i&&s.push(n),i&&(this.hasDuration(t)||(this.hasAutoDuration(t)&&(e.block.contents=e.block.contents.replace("auto","    ")),e.block.contents=e.block.contents.replace(t," 1s "+t),a=true));})),a&&this.replacePart(e.block.startIndex,e.block.endIndex,e.block.contents,t)),this.saveRelationInList(e,o,s);}saveSourceSelectorToScrollTimeline(e){const t=e.block.contents.includes("scroll-timeline:"),n=e.block.contents.includes("scroll-timeline-name:"),i=e.block.contents.includes("scroll-timeline-axis:");if(!t&&!n)return;let r=[];if(t){const t=this.extractMatches(e.block.contents,kt.SCROLL_TIMELINE);for(const n of t){const t=this.split(n);let i={selector:e.selector,name:""};1==t.length?i.name=t[0]:2==t.length&&(Mt.includes(t[0])?(i.axis=t[0],i.name=t[1]):(i.axis=t[1],i.name=t[0])),r.push(i);}}if(n){const t=this.extractMatches(e.block.contents,kt.SCROLL_TIMELINE_NAME);for(let n=0;n<t.length;n++)if(n<r.length)r[n].name=t[n];else {let i={selector:e.selector,name:t[n]};r.push(i);}}let o=[];if(i){const t=this.extractMatches(e.block.contents,kt.SCROLL_TIMELINE_AXIS);if(o=t.filter((e=>Mt.includes(e))),o.length!=t.length)throw new Error("Invalid axis")}for(let s=0;s<r.length;s++)o.length&&(r[s].axis=o[s%r.length]);this.sourceSelectorToScrollTimeline.push(...r);}saveSubjectSelectorToViewTimeline(e){const t=e.block.contents.includes("view-timeline:"),n=e.block.contents.includes("view-timeline-name:"),i=e.block.contents.includes("view-timeline-axis:"),r=e.block.contents.includes("view-timeline-inset:");if(!t&&!n)return;let o=[];if(t){const t=this.extractMatches(e.block.contents,kt.VIEW_TIMELINE);for(let n of t){const t=this.split(n);let i={selector:e.selector,name:"",inset:null};1==t.length?i.name=t[0]:2==t.length&&(Mt.includes(t[0])?(i.axis=t[0],i.name=t[1]):(i.axis=t[1],i.name=t[0])),o.push(i);}}if(n){const t=this.extractMatches(e.block.contents,kt.VIEW_TIMELINE_NAME);for(let n=0;n<t.length;n++)if(n<o.length)o[n].name=t[n];else {let i={selector:e.selector,name:t[n],inset:null};o.push(i);}}let s=[],a=[];if(r&&(s=this.extractMatches(e.block.contents,kt.VIEW_TIMELINE_INSET)),i){const t=this.extractMatches(e.block.contents,kt.VIEW_TIMELINE_AXIS);if(a=t.filter((e=>Mt.includes(e))),a.length!=t.length)throw new Error("Invalid axis")}for(let l=0;l<o.length;l++)s.length&&(o[l].inset=s[l%o.length]),a.length&&(o[l].axis=a[l%o.length]);this.subjectSelectorToViewTimeline.push(...o);}hasDuration(e){return e.split(" ").filter((e=>{return t=e,kt.TIME.exec(t);var t;})).length>=1}hasAutoDuration(e){return e.split(" ").filter((e=>"auto"===e)).length>=1}saveRelationInList(e,t,n){let i=[];e.block.contents.includes("animation-range:")&&(i=this.extractMatches(e.block.contents,kt.ANIMATION_TIME_RANGE));const r=Math.max(t.length,n.length,i.length);for(let o=0;o<r;o++)this.cssRulesWithTimelineName.push({selector:e.selector,"animation-timeline":t[o%t.length],...n.length?{"animation-name":n[o%n.length]}:{},...i.length?{"animation-range":i[o%i.length]}:{}});}extractScrollTimelineNames(e){const t=kt.ANIMATION_TIMELINE.exec(e)[1].trim(),n=[];return t.split(",").map((e=>e.trim())).forEach((e=>{if(function(e){return (e.startsWith("scroll")||e.startsWith("view"))&&e.includes("(")}(e)){const t=this.saveAnonymousTimelineName(e);n.push(t);}else n.push(e);})),n}saveAnonymousTimelineName(e){const t=":t"+this.nextAnonymousTimelineNameIndex++;return e.startsWith("scroll(")?this.anonymousScrollTimelineOptions.set(t,this.parseAnonymousScrollTimeline(e)):this.anonymousViewTimelineOptions.set(t,this.parseAnonymousViewTimeline(e)),t}parseAnonymousScrollTimeline(e){const t=kt.ANONYMOUS_SCROLL_TIMELINE.exec(e);if(!t)return null;const n=t[1],i={};return n.split(" ").forEach((e=>{Mt.includes(e)?i.axis=e:Pt.includes(e)&&(i.source=e);})),i}parseAnonymousViewTimeline(e){const t=kt.ANONYMOUS_VIEW_TIMELINE.exec(e);if(!t)return null;const n=t[1],i={};return n.split(" ").forEach((e=>{Mt.includes(e)?i.axis=e:i.inset=i.inset?`${i.inset} ${e}`:e;})),i}extractAnimationName(e){return this.findMatchingEntryInContainer(e,this.keyframeNamesSelectors)}findMatchingEntryInContainer(e,t){const n=e.split(" ").filter((e=>t.has(e)));return n?n[0]:null}parseIdentifier(e){kt.IDENTIFIER.lastIndex=e.index;const t=kt.IDENTIFIER.exec(e.sheetSrc);if(!t)throw this.parseError(e,"Expected an identifier");return e.index+=t[0].length,t[0]}parseKeyframesAndSaveNameMapping(e,t){if(e.selector.startsWith("@keyframes")){const n=this.replaceKeyframesAndGetMapping(e,t);e.selector.split(" ").forEach(((e,t)=>{t>0&&this.keyframeNamesSelectors.set(e,n);}));}}replaceKeyframesAndGetMapping(e,t){function n(e){return ye.some((t=>e.startsWith(t)))}const i=e.block.contents,r=function(e){let t=0,n=-1,i=-1;const r=[];for(let o=0;o<e.length;o++)"{"==e[o]?t++:"}"==e[o]&&t--,1==t&&"{"!=e[o]&&"}"!=e[o]&&-1==n&&(n=o),2==t&&"{"==e[o]&&(i=o,r.push({start:n,end:i}),n=i=-1);return r}(i);if(0==r.length)return new Map;const o=new Map;let s=false;const a=[];a.push(i.substring(0,r[0].start));for(let l=0;l<r.length;l++){const e=i.substring(r[l].start,r[l].end);let t=[];e.split(",").forEach((e=>{const i=e.split(" ").map((e=>e.trim())).filter((e=>""!=e)).join(" ");const r=o.size;o.set(r,i),t.push(`${r}%`),n(i)&&(s=true);})),a.push(t.join(",")),l==r.length-1?a.push(i.substring(r[l].end)):a.push(i.substring(r[l].end,r[l+1].start));}return s?(e.block.contents=a.join(""),this.replacePart(e.block.startIndex,e.block.endIndex,e.block.contents,t),o):new Map}parseQualifiedRule(e){const t=e.index,n=this.parseSelector(e).trim();if(!n)return;return {selector:n,block:this.eatBlock(e),startIndex:t,endIndex:e.index}}removeEnclosingDoubleQuotes(e){let t='"'==e[0]?1:0,n='"'==e[e.length-1]?e.length-1:e.length;return e.substring(t,n)}assertString(e,t){if(e.sheetSrc.substr(e.index,t.length)!=t)throw this.parseError(e,`Did not find expected sequence ${t}`);e.index+=t.length;}replacePart(e,t,n,i){if(i.sheetSrc=i.sheetSrc.slice(0,e)+n+i.sheetSrc.slice(t),i.index>=t){const r=i.index-t;i.index=e+n.length+r;}}eatComment(e){this.assertString(e,"/*"),this.eatUntil("*/",e,true),this.assertString(e,"*/");}eatBlock(e){const t=e.index;this.assertString(e,"{");let n=1;for(;0!=n;)this.lookAhead("/*",e)?this.eatComment(e):("{"===e.sheetSrc[e.index]?n++:"}"===e.sheetSrc[e.index]&&n--,this.advance(e));const i=e.index;return {startIndex:t,endIndex:i,contents:e.sheetSrc.slice(t,i)}}advance(e){if(e.index++,e.index>e.sheetSrc.length)throw this.parseError(e,"Advanced beyond the end")}parseError(e,t){return Error(`(${e.name?e.name:"<anonymous file>"}): ${t}`)}eatUntil(e,t,n=false){const i=t.index;for(;!this.lookAhead(e,t);)this.advance(t);return n&&(t.sheetSrc=t.sheetSrc.slice(0,i)+" ".repeat(t.index-i)+t.sheetSrc.slice(t.index)),t.sheetSrc.slice(i,t.index)}parseSelector(e){let t=e.index;if(this.eatUntil("{",e),t===e.index)throw Error("Empty selector");return e.sheetSrc.slice(t,e.index)}eatWhitespace(e){kt.WHITE_SPACE.lastIndex=e.index;const t=kt.WHITE_SPACE.exec(e.sheetSrc);t&&(e.index+=t[0].length);}lookAhead(e,t){return t.sheetSrc.substr(t.index,e.length)==e}peek(e){return e.sheetSrc[e.index]}extractMatches(e,t,n=","){return t.exec(e)[1].trim().split(n).map((e=>e.trim()))}split(e){return e.split(" ").map((e=>e.trim())).filter((e=>""!=e))}};function Rt(e,t,n,i,r,o){const s=Me(t),a=Pe(t,n);return He(De(e,s,a,i,r),o,De("cover",s,a,i,r),n)}function Nt(e,t,n){const i=It.getAnimationTimelineOptions(t,n);if(!i)return null;const r=i["animation-timeline"];if(!r)return null;let o=It.getScrollTimelineOptions(r,n)||It.getViewTimelineOptions(r,n);return o?(o.subject&&function(e,t){const n=We(t.subject),i=t.axis||t.axis;function r(e,r){let o=null;for(const[s,a]of e)if(s==100*r.offset){if("from"==a)o=0;else if("to"==a)o=100;else {const e=a.split(" ");o=1==e.length?parseFloat(e[0]):100*Rt(e[0],n,t.subject,i,t.inset,CSS.percent(parseFloat(e[1])));}break}return o}const o=It.keyframeNamesSelectors.get(e.animationName);if(o&&o.size){const t=[];e.effect.getKeyframes().forEach((e=>{const n=r(o,e);null!==n&&n>=0&&n<=100&&(e.offset=n/100,t.push(e));}));const n=t.sort(((e,t)=>e.offset<t.offset?-1:e.affset>t.offset?1:0));e.effect.setKeyframes(n);}}(e,o),{timeline:o.source?new ScrollTimeline(o):new $e(o),animOptions:i}):null}function At(){if(CSS.supports("animation-timeline: --works"))return  true;!function(){function e(e){if(0===e.innerHTML.trim().length||"aphrodite"in e.dataset)return;let t=It.transpileStyleSheet(e.innerHTML,true);t=It.transpileStyleSheet(t,false),e.innerHTML=t;}function t(e){"text/css"!=e.type&&"stylesheet"!=e.rel||!e.href||new URL(e.href,document.baseURI).origin==location.origin&&fetch(e.getAttribute("href")).then((async t=>{const n=await t.text();let i=It.transpileStyleSheet(n,true);if(i=It.transpileStyleSheet(n,false),i!=n){const t=new Blob([i],{type:"text/css"}),n=URL.createObjectURL(t);e.setAttribute("href",n);}}));}new MutationObserver((n=>{for(const i of n)for(const n of i.addedNodes)n instanceof HTMLStyleElement&&e(n),n instanceof HTMLLinkElement&&t(n);})).observe(document.documentElement,{childList:true,subtree:true}),document.querySelectorAll("style").forEach((t=>e(t))),document.querySelectorAll("link").forEach((e=>t(e)));}();const e=CSS.supports;CSS.supports=t=>(t=t.replaceAll(/(animation-timeline|scroll-timeline(-(name|axis))?|view-timeline(-(name|axis|inset))?|timeline-scope)\s*:/g,"--supported-property:"),e(t)),window.addEventListener("animationstart",(e=>{e.target.getAnimations().filter((t=>t.animationName===e.animationName)).forEach((t=>{const n=Nt(t,t.animationName,e.target);if(n)if(!n.timeline||t instanceof wt)t.timeline=n.timeline;else {const e=new wt(t,n.timeline,n.animOptions);t.pause(),e.play();}}));}));}!function(){if(!At()){if(!Reflect.defineProperty(window,"ScrollTimeline",{value:ScrollTimeline}))throw Error("Error installing ScrollTimeline polyfill: could not attach ScrollTimeline to window");if(!Reflect.defineProperty(window,"ViewTimeline",{value:$e}))throw Error("Error installing ViewTimeline polyfill: could not attach ViewTimeline to window");if(!Reflect.defineProperty(Element.prototype,"animate",{value:xt}))throw Error("Error installing ScrollTimeline polyfill: could not attach WAAPI's animate to DOM Element");if(!Reflect.defineProperty(window,"Animation",{value:wt}))throw Error("Error installing Animation constructor.");if(!Reflect.defineProperty(Element.prototype,"getAnimations",{value:Ct}))throw Error("Error installing ScrollTimeline polyfill: could not attach WAAPI's getAnimations to DOM Element");if(!Reflect.defineProperty(document,"getAnimations",{value:Et}))throw Error("Error installing ScrollTimeline polyfill: could not attach WAAPI's getAnimations to document")}}();}();

    var scrollTimeline = /*#__PURE__*/Object.freeze({
        __proto__: null
    });

    exports.default = index;
    exports.dispose = dispose;
    exports.init = init;
    exports.onError = onError;
    exports.setPropertyUpdateThrottle = setPropertyUpdateThrottle;
    exports.useConsoleReporter = useConsoleReporter;

    Object.defineProperty(exports, '__esModule', { value: true });

    return exports;

})({});
//# sourceMappingURL=elm-motion.js.map
