/**
 * ElmAnimateWAAPI JavaScript Integration (ES Module)
 *
 * This file provides the JavaScript side of port-based animations for the
 * ElmAnimateWAAPI Elm module. It uses the Web Animations API for high-performance
 * hardware-accelerated animations supporting all animation properties.
 *
 * Usage:
 * import ElmAnimateWAAPI from 'elm-animate-waapi';
 *
 * const app = Elm.Main.init({ node: document.getElementById('app') });
 * ElmAnimateWAAPI.init(app.ports);
 */

// Track active animations for cleanup and management
// Structure: Map<elementId, Map<propertyType, { animation, version }>>
const activeAnimations = new Map();

// Default easing functions mapping for Web Animations API
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

// Store ports reference for event sending
let portsRef = null;

/**
 * Process animation data received from Elm
 */
function processAnimationData(animationData) {
    if (animationData && animationData.elements) {
        Object.entries(animationData.elements).forEach(([elementId, elementConfig]) => {
            processElementAnimation(elementId, elementConfig);
        });
    } else {
        console.warn('ElmAnimateWAAPI: Invalid animation data format received');
    }
}

/**
 * Find a DOM element by its animation target identifier.
 * Looks for data-anim-target attribute first (set by Elm's WAAPI.attributes),
 * then falls back to getElementById for backward compatibility.
 *
 * @param {string} targetId - The animation target identifier
 * @returns {Element|null} The DOM element, or null if not found
 */
function findAnimTarget(targetId) {
    return document.querySelector('[data-anim-target="' + CSS.escape(targetId) + '"]')
        || document.getElementById(targetId);
}

/**
 * Process animation for a single element with all its properties
 * Supports property-level animation tracking with version control
 */
function processElementAnimation(elementId, elementConfig) {
    const element = findAnimTarget(elementId);
    if (!element) {
        console.warn(`ElmAnimateWAAPI: Element "${elementId}" not found. Ensure WAAPI.attributes is applied to the target element.`);
        return;
    }

    // Get or create element animation tracking map
    if (!activeAnimations.has(elementId)) {
        activeAnimations.set(elementId, new Map());
    }
    const elementAnims = activeAnimations.get(elementId);

    // Separate transform properties from non-transform properties.
    // Transform sub-properties (translate, scale, rotate) must be merged into a
    // single WAAPI animation because they all target the CSS 'transform' property.
    const transformProperties = [];
    const nonTransformProperties = [];

    elementConfig.properties.forEach(property => {
        if (property.type === 'translate' || property.type === 'scale' || property.type === 'rotate') {
            transformProperties.push(property);
        } else {
            nonTransformProperties.push(property);
        }
    });

    // Process merged transform properties as a single animation
    if (transformProperties.length > 0) {
        // Cancel existing transform animation if any
        if (elementAnims.has('transform')) {
            const existing = elementAnims.get('transform');
            existing.animation.cancel();
        }
        ['translate', 'scale', 'rotate'].forEach(propType => {
            if (elementAnims.has(propType)) {
                const existing = elementAnims.get(propType);
                existing.animation.cancel();
                elementAnims.delete(propType);
            }
        });

        const maxVersion = Math.max(...transformProperties.map(p => p.version || 1));
        const animation = createMergedTransformAnimation(element, transformProperties);

        if (animation) {
            animation.__elmAnimate = true;
            const updateFn = setupAnimationEvents(elementId, 'transform', element, animation, maxVersion);
            elementAnims.set('transform', {
                animation: animation,
                version: maxVersion,
                updateFn: updateFn,
                easingKeyframes: null,
                transformProperties: transformProperties
            });
        }
    }

    // Process non-transform properties independently
    nonTransformProperties.forEach(property => {
        const propType = property.type;
        const newVersion = property.version || 1;

        if (elementAnims.has(propType)) {
            const existing = elementAnims.get(propType);
            existing.animation.cancel();
        }

        const animation = createPropertyAnimation(element, property);

        if (animation) {
            animation.__elmAnimate = true;
            const updateFn = setupAnimationEvents(elementId, propType, element, animation, newVersion);
            elementAnims.set(propType, {
                animation: animation,
                version: newVersion,
                updateFn: updateFn,
                easingKeyframes: property.easingKeyframes || null
            });
        }
    });

    if (elementAnims.size === 0) {
        activeAnimations.delete(elementId);
    }
}

/**
 * Helper to generate keyframes with easing applied.
 */
function generateKeyframesWithEasing(startValue, endValue, easingKeyframes, propertyName) {
    if (easingKeyframes && Array.isArray(easingKeyframes)) {
        return easingKeyframes.map(easingProgress => {
            const interpolatedValue = interpolateValue(startValue, endValue, easingProgress);
            return { [propertyName]: interpolatedValue };
        });
    } else {
        return [
            { [propertyName]: startValue },
            { [propertyName]: endValue }
        ];
    }
}

/**
 * Interpolate between start and end values based on progress (0.0 to 1.0).
 */
function interpolateValue(start, end, progress) {
    if (typeof start === 'string' && typeof end === 'string' &&
        (start === 'none' || end === 'none' ||
            start.includes('translate') || start.includes('scale') || start.includes('rotate'))) {
        return interpolateTransform(start, end, progress);
    }

    if (typeof start === 'number' && typeof end === 'number') {
        return start + (end - start) * progress;
    }

    if (typeof start === 'string' && (start.startsWith('rgb') || start.startsWith('#'))) {
        return interpolateColor(start, end, progress);
    }

    return end;
}

/**
 * Interpolate between two transform strings.
 */
function interpolateTransform(startTransform, endTransform, progress) {
    const parseTransform = (str) => {
        const translate = str.match(/translate3d\(([-\d.]+)px, ([-\d.]+)px, ([-\d.]+)px\)/);
        const scale = str.match(/scale3d\(([-\d.]+), ([-\d.]+), ([-\d.]+)\)/);
        const rotateX = str.match(/rotateX\(([-\d.]+)deg\)/);
        const rotateY = str.match(/rotateY\(([-\d.]+)deg\)/);
        const rotateZ = str.match(/rotateZ\(([-\d.]+)deg\)/);

        return {
            tx: translate ? parseFloat(translate[1]) : 0,
            ty: translate ? parseFloat(translate[2]) : 0,
            tz: translate ? parseFloat(translate[3]) : 0,
            sx: scale ? parseFloat(scale[1]) : 1,
            sy: scale ? parseFloat(scale[2]) : 1,
            sz: scale ? parseFloat(scale[3]) : 1,
            rx: rotateX ? parseFloat(rotateX[1]) : 0,
            ry: rotateY ? parseFloat(rotateY[1]) : 0,
            rz: rotateZ ? parseFloat(rotateZ[1]) : 0,
        };
    };

    const start = parseTransform(startTransform);
    const end = parseTransform(endTransform);

    const tx = start.tx + (end.tx - start.tx) * progress;
    const ty = start.ty + (end.ty - start.ty) * progress;
    const tz = start.tz + (end.tz - start.tz) * progress;
    const sx = start.sx + (end.sx - start.sx) * progress;
    const sy = start.sy + (end.sy - start.sy) * progress;
    const sz = start.sz + (end.sz - start.sz) * progress;
    const rx = start.rx + (end.rx - start.rx) * progress;
    const ry = start.ry + (end.ry - start.ry) * progress;
    const rz = start.rz + (end.rz - start.rz) * progress;

    return buildTransformString(tx, ty, tz, sx, sy, sz, rx, ry, rz);
}

/**
 * Interpolate between two color strings.
 */
function interpolateColor(startColor, endColor, progress) {
    const parseColor = (str) => {
        const match = str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
        if (match) {
            return {
                r: parseInt(match[1]),
                g: parseInt(match[2]),
                b: parseInt(match[3]),
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
 * Create animation for a single transform property (translate, scale, or rotate)
 */
function createTransformPropertyAnimation(element, property) {
    const duration = property.duration;
    const easing = property.easing;
    const easingKeyframes = property.easingKeyframes;

    const currentTransform = getCurrentTransform(element);

    let startTransform, endTransform;

    switch (property.type) {
        case 'translate':
            const startX = property.startX ?? property.defaultX ?? currentTransform.x;
            const startY = property.startY ?? property.defaultY ?? currentTransform.y;
            const startZ = property.startZ ?? property.defaultZ ?? currentTransform.z;
            const endX = property.endX ?? currentTransform.x;
            const endY = property.endY ?? currentTransform.y;
            const endZ = property.endZ ?? currentTransform.z;

            startTransform = buildTransformString(startX, startY, startZ,
                currentTransform.scaleX, currentTransform.scaleY, currentTransform.scaleZ,
                currentTransform.rotateX, currentTransform.rotateY, currentTransform.rotateZ);
            endTransform = buildTransformString(endX, endY, endZ,
                currentTransform.scaleX, currentTransform.scaleY, currentTransform.scaleZ,
                currentTransform.rotateX, currentTransform.rotateY, currentTransform.rotateZ);
            break;

        case 'scale':
            const startScaleX = property.startX ?? property.defaultX ?? currentTransform.scaleX;
            const startScaleY = property.startY ?? property.defaultY ?? currentTransform.scaleY;
            const startScaleZ = property.startZ ?? property.defaultZ ?? currentTransform.scaleZ;
            const endScaleX = property.endX ?? currentTransform.scaleX;
            const endScaleY = property.endY ?? currentTransform.scaleY;
            const endScaleZ = property.endZ ?? currentTransform.scaleZ;

            startTransform = buildTransformString(currentTransform.x, currentTransform.y, currentTransform.z,
                startScaleX, startScaleY, startScaleZ,
                currentTransform.rotateX, currentTransform.rotateY, currentTransform.rotateZ);
            endTransform = buildTransformString(currentTransform.x, currentTransform.y, currentTransform.z,
                endScaleX, endScaleY, endScaleZ,
                currentTransform.rotateX, currentTransform.rotateY, currentTransform.rotateZ);
            break;

        case 'rotate':
            const startRotX = property.startX ?? property.defaultX ?? currentTransform.rotateX;
            const startRotY = property.startY ?? property.defaultY ?? currentTransform.rotateY;
            const startRotZ = property.startZ ?? property.defaultZ ?? currentTransform.rotateZ;
            const endRotX = property.endX ?? currentTransform.rotateX;
            const endRotY = property.endY ?? currentTransform.rotateY;
            const endRotZ = property.endZ ?? currentTransform.rotateZ;

            startTransform = buildTransformString(currentTransform.x, currentTransform.y, currentTransform.z,
                currentTransform.scaleX, currentTransform.scaleY, currentTransform.scaleZ,
                startRotX, startRotY, startRotZ);
            endTransform = buildTransformString(currentTransform.x, currentTransform.y, currentTransform.z,
                currentTransform.scaleX, currentTransform.scaleY, currentTransform.scaleZ,
                endRotX, endRotY, endRotZ);
            break;

        default:
            console.warn(`ElmAnimateWAAPI: Unknown transform property type "${property.type}"`);
            return null;
    }

    let keyframes;
    let animationEasing;

    if (easingKeyframes) {
        keyframes = generateKeyframesWithEasing(startTransform, endTransform, easingKeyframes, 'transform');
        animationEasing = 'linear';
    } else {
        keyframes = [
            { transform: startTransform },
            { transform: endTransform }
        ];
        animationEasing = easingFunctions[easing] || easing;
    }

    return element.animate(keyframes, {
        duration: duration,
        easing: animationEasing,
        fill: 'forwards'
    });
}

/**
 * Create a single WAAPI animation for multiple transform sub-properties.
 * Merges translate, scale, and rotate into one animation with per-property
 * easing via generated keyframes.
 */
function createMergedTransformAnimation(element, transformProperties) {
    const currentTransform = getCurrentTransform(element);

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
        }
        if (p.duration > maxDuration) maxDuration = p.duration;
    });

    const activeProps = transformProperties.map(p => resolved[p.type]);
    const allSameEasing = activeProps.every(r => !r.easingKeyframes && r.easing === activeProps[0].easing);
    const allSameDuration = activeProps.every(r => r.duration === activeProps[0].duration);

    if (allSameEasing && allSameDuration) {
        const startTransform = buildTransformString(
            resolved.translate.startX, resolved.translate.startY, resolved.translate.startZ,
            resolved.scale.startX, resolved.scale.startY, resolved.scale.startZ,
            resolved.rotate.startX, resolved.rotate.startY, resolved.rotate.startZ
        );
        const endTransform = buildTransformString(
            resolved.translate.endX, resolved.translate.endY, resolved.translate.endZ,
            resolved.scale.endX, resolved.scale.endY, resolved.scale.endZ,
            resolved.rotate.endX, resolved.rotate.endY, resolved.rotate.endZ
        );

        const easing = activeProps[0].easing;
        const animationEasing = easingFunctions[easing] || easing;

        return element.animate([
            { transform: startTransform },
            { transform: endTransform }
        ], {
            duration: maxDuration,
            easing: animationEasing,
            fill: 'forwards'
        });
    }

    const KEYFRAME_COUNT = 30;
    const keyframes = [];

    for (let i = 0; i < KEYFRAME_COUNT; i++) {
        const globalProgress = i / (KEYFRAME_COUNT - 1);

        const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
        const interpScale = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
        const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);

        const transform = buildTransformString(
            interpTranslate.x, interpTranslate.y, interpTranslate.z,
            interpScale.x, interpScale.y, interpScale.z,
            interpRotate.x, interpRotate.y, interpRotate.z
        );

        keyframes.push({ transform });
    }

    return element.animate(keyframes, {
        duration: maxDuration,
        easing: 'linear',
        fill: 'forwards'
    });
}

/**
 * Interpolate a transform sub-property at a given global progress,
 * accounting for its own duration and easing.
 */
function interpolateSubProperty(subProp, globalProgress, maxDuration) {
    const durationRatio = subProp.duration > 0 ? subProp.duration / maxDuration : 1;
    const localProgress = Math.min(1.0, durationRatio > 0 ? globalProgress / durationRatio : 1.0);

    let easedProgress;
    if (subProp.easingKeyframes && Array.isArray(subProp.easingKeyframes)) {
        const idx = Math.min(
            Math.floor(localProgress * (subProp.easingKeyframes.length - 1)),
            subProp.easingKeyframes.length - 1
        );
        easedProgress = subProp.easingKeyframes[idx];
    } else {
        easedProgress = localProgress;
    }

    return {
        x: subProp.startX + (subProp.endX - subProp.startX) * easedProgress,
        y: subProp.startY + (subProp.endY - subProp.startY) * easedProgress,
        z: subProp.startZ + (subProp.endZ - subProp.startZ) * easedProgress
    };
}

/**
 * Create animation for non-transform properties
 */
function createPropertyAnimation(element, property) {
    const duration = property.duration;
    const easing = property.easing;
    const easingKeyframes = property.easingKeyframes;

    let keyframes = [];
    let animationEasing;

    switch (property.type) {
        case 'opacity':
            {
                const computedOpacity = parseFloat(window.getComputedStyle(element).opacity);
                const startValue = property.startValue ?? property.defaultValue ?? computedOpacity;
                const endValue = property.endValue;

                if (easingKeyframes) {
                    keyframes = easingKeyframes.map(progress => ({
                        opacity: (startValue + (endValue - startValue) * progress).toString()
                    }));
                    animationEasing = 'linear';
                } else {
                    keyframes = [
                        { opacity: startValue.toString() },
                        { opacity: endValue.toString() }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'backgroundColor':
            {
                const computedBgColor = window.getComputedStyle(element).backgroundColor;
                const startColor = property.startColor ?? property.defaultColor ?? computedBgColor;
                const endColor = property.endColor;

                if (easingKeyframes) {
                    keyframes = easingKeyframes.map(progress => ({
                        backgroundColor: interpolateColor(startColor, endColor, progress)
                    }));
                    animationEasing = 'linear';
                } else {
                    keyframes = [
                        { backgroundColor: startColor },
                        { backgroundColor: endColor }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'color':
            {
                const computedColor = window.getComputedStyle(element).color;
                const startColor = property.startColor ?? property.defaultColor ?? computedColor;
                const endColor = property.endColor;

                if (easingKeyframes) {
                    keyframes = easingKeyframes.map(progress => ({
                        color: interpolateColor(startColor, endColor, progress)
                    }));
                    animationEasing = 'linear';
                } else {
                    keyframes = [
                        { color: startColor },
                        { color: endColor }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'size':
            {
                const computedStyle = window.getComputedStyle(element);
                const startWidth = property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width);
                const startHeight = property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height);

                if (easingKeyframes) {
                    keyframes = easingKeyframes.map(progress => ({
                        width: `${startWidth + (property.endWidth - startWidth) * progress}px`,
                        height: `${startHeight + (property.endHeight - startHeight) * progress}px`
                    }));
                    animationEasing = 'linear';
                } else {
                    keyframes = [
                        {
                            width: `${startWidth}px`,
                            height: `${startHeight}px`
                        },
                        {
                            width: `${property.endWidth}px`,
                            height: `${property.endHeight}px`
                        }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        default:
            console.warn(`ElmAnimateWAAPI: Unknown property type "${property.type}"`);
            return null;
    }

    return element.animate(keyframes, {
        duration: duration,
        easing: animationEasing,
        fill: 'forwards'
    });
}

/**
 * Build a complete transform string with 3D support
 */
function buildTransformString(x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ) {
    const parts = [];

    if (x !== 0 || y !== 0 || z !== 0) {
        parts.push(`translate3d(${x}px, ${y}px, ${z}px)`);
    }

    if (rotateX !== 0) {
        parts.push(`rotateX(${rotateX}deg)`);
    }
    if (rotateY !== 0) {
        parts.push(`rotateY(${rotateY}deg)`);
    }
    if (rotateZ !== 0) {
        parts.push(`rotateZ(${rotateZ}deg)`);
    }

    if (scaleX !== 1) {
        parts.push(`scaleX(${scaleX})`);
    }
    if (scaleY !== 1) {
        parts.push(`scaleY(${scaleY})`);
    }
    if (scaleZ !== 1) {
        parts.push(`scaleZ(${scaleZ})`);
    }

    return parts.join(' ') || 'none';
}

/**
 * Get current transform state of an element with 3D support.
 * Prefers parsing the inline style (element.style.transform) which preserves
 * individual transform functions (rotateX, rotateY, etc.) rather than decomposing
 * the computed matrix3d which loses axis-specific rotation information.
 * Falls back to matrix decomposition when no inline style is available.
 */
export function getCurrentTransform(element) {
    // First try to parse the inline style - it preserves individual transform functions
    const inlineTransform = element.style.transform;
    if (inlineTransform && inlineTransform !== 'none') {
        return parseTransformString(inlineTransform);
    }

    // Fall back to computed style with matrix decomposition
    const style = window.getComputedStyle(element);
    const transform = style.transform;

    if (transform === 'none' || !transform) {
        return {
            transform: 'none',
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0
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

            const scaleX = Math.sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2]);
            const scaleY = Math.sqrt(values[4] * values[4] + values[5] * values[5] + values[6] * values[6]);
            const scaleZ = Math.sqrt(values[8] * values[8] + values[9] * values[9] + values[10] * values[10]);

            let rotateZ = 0;
            if (scaleX !== 0 && scaleY !== 0) {
                rotateZ = Math.atan2(values[1] / scaleX, values[0] / scaleX) * (180 / Math.PI);
            }

            return { transform, x: tx, y: ty, z: tz, scaleX, scaleY, scaleZ, rotateX: 0, rotateY: 0, rotateZ };
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
                rotateX: 0, rotateY: 0, rotateZ
            };
        }
    }

    return {
        transform,
        x: 0, y: 0, z: 0,
        scaleX: 1, scaleY: 1, scaleZ: 1,
        rotateX: 0, rotateY: 0, rotateZ: 0
    };
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
        rotateX: 0, rotateY: 0, rotateZ: 0
    };

    // translate3d(Xpx, Ypx, Zpx)
    const translate3d = transformStr.match(/translate3d\(\s*([\-\d.]+)px\s*,\s*([\-\d.]+)px\s*,\s*([\-\d.]+)px\s*\)/);
    if (translate3d) {
        result.x = parseFloat(translate3d[1]);
        result.y = parseFloat(translate3d[2]);
        result.z = parseFloat(translate3d[3]);
    }

    // translateX(Xpx), translateY(Ypx), translateZ(Zpx)
    const translateX = transformStr.match(/translateX\(\s*([\-\d.]+)px\s*\)/);
    const translateY = transformStr.match(/translateY\(\s*([\-\d.]+)px\s*\)/);
    const translateZ = transformStr.match(/translateZ\(\s*([\-\d.]+)px\s*\)/);
    if (translateX) result.x = parseFloat(translateX[1]);
    if (translateY) result.y = parseFloat(translateY[1]);
    if (translateZ) result.z = parseFloat(translateZ[1]);

    // rotateX(Xdeg), rotateY(Ydeg), rotateZ(Zdeg)
    const rotateX = transformStr.match(/rotateX\(\s*([\-\d.]+)deg\s*\)/);
    const rotateY = transformStr.match(/rotateY\(\s*([\-\d.]+)deg\s*\)/);
    const rotateZ = transformStr.match(/rotateZ\(\s*([\-\d.]+)deg\s*\)/);
    if (rotateX) result.rotateX = parseFloat(rotateX[1]);
    if (rotateY) result.rotateY = parseFloat(rotateY[1]);
    if (rotateZ) result.rotateZ = parseFloat(rotateZ[1]);

    // scale3d(X, Y, Z)
    const scale3d = transformStr.match(/scale3d\(\s*([\-\d.]+)\s*,\s*([\-\d.]+)\s*,\s*([\-\d.]+)\s*\)/);
    if (scale3d) {
        result.scaleX = parseFloat(scale3d[1]);
        result.scaleY = parseFloat(scale3d[2]);
        result.scaleZ = parseFloat(scale3d[3]);
    }

    // scaleX(X), scaleY(Y), scaleZ(Z)
    const scaleX = transformStr.match(/scaleX\(\s*([\-\d.]+)\s*\)/);
    const scaleY = transformStr.match(/scaleY\(\s*([\-\d.]+)\s*\)/);
    const scaleZ = transformStr.match(/scaleZ\(\s*([\-\d.]+)\s*\)/);
    if (scaleX) result.scaleX = parseFloat(scaleX[1]);
    if (scaleY) result.scaleY = parseFloat(scaleY[1]);
    if (scaleZ) result.scaleZ = parseFloat(scaleZ[1]);

    // scale(X, Y) - 2D shorthand
    const scale2d = transformStr.match(/scale\(\s*([\-\d.]+)\s*(?:,\s*([\-\d.]+)\s*)?\)/);
    if (scale2d && !scale3d) {
        result.scaleX = parseFloat(scale2d[1]);
        result.scaleY = scale2d[2] ? parseFloat(scale2d[2]) : parseFloat(scale2d[1]);
    }

    return result;
}

/**
 * Set up animation event listeners and property updates with version tracking
 */
function setupAnimationEvents(elementId, propertyType, element, animation, version) {
    let lastTime = 0;
    const updateInterval = 16;
    let rafId = null;

    function sendAnimationUpdate() {
        const now = performance.now();
        if (now - lastTime >= updateInterval) {
            const transformState = getCurrentTransform(element);
            const computedStyle = window.getComputedStyle(element);

            if (portsRef && portsRef.waapiEvent) {
                const propertyVersions = {};
                const elementAnims = activeAnimations.get(elementId);
                if (elementAnims) {
                    elementAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }

                const propertyData = {
                    elementId: elementId,
                    translate: {
                        x: transformState.x,
                        y: transformState.y,
                        z: transformState.z
                    },
                    opacity: parseFloat(computedStyle.opacity),
                    rotate: {
                        x: transformState.rotateX,
                        y: transformState.rotateY,
                        z: transformState.rotateZ
                    },
                    scale: {
                        x: transformState.scaleX,
                        y: transformState.scaleY,
                        z: transformState.scaleZ
                    },
                    backgroundColor: computedStyle.backgroundColor,
                    color: computedStyle.color,
                    size: {
                        width: parseFloat(computedStyle.width),
                        height: parseFloat(computedStyle.height)
                    },
                    isAnimating: true,
                    propertyVersions: propertyVersions
                };
                sendEventToElm('propertyUpdate', elementId, propertyData);
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

    animation.addEventListener('finish', () => {
        if (rafId !== null) {
            cancelAnimationFrame(rafId);
            rafId = null;
        }

        try {
            animation.commitStyles();
            animation.cancel();
        } catch (e) {
            console.warn('ElmAnimateWAAPI: commitStyles/cancel failed:', e);
        }

        const elementAnims = activeAnimations.get(elementId);
        if (elementAnims) {
            const current = elementAnims.get(propertyType);
            if (current && current.version === version) {
                elementAnims.delete(propertyType);

                if (elementAnims.size === 0) {
                    activeAnimations.delete(elementId);
                }
            }
        }

        if (portsRef && portsRef.waapiEvent) {
            const finalState = getCurrentTransform(element);
            const computedStyle = window.getComputedStyle(element);

            const propertyVersions = {};
            const remainingAnims = activeAnimations.get(elementId);
            if (remainingAnims) {
                remainingAnims.forEach((animData, propType) => {
                    propertyVersions[propType] = animData.version;
                });
            }
            propertyVersions[propertyType] = version;

            const finalPropertyData = {
                elementId: elementId,
                translate: {
                    x: finalState.x,
                    y: finalState.y,
                    z: finalState.z
                },
                opacity: parseFloat(computedStyle.opacity),
                rotate: {
                    x: finalState.rotateX,
                    y: finalState.rotateY,
                    z: finalState.rotateZ
                },
                scale: {
                    x: finalState.scaleX,
                    y: finalState.scaleY,
                    z: finalState.scaleZ
                },
                backgroundColor: computedStyle.backgroundColor,
                color: computedStyle.color,
                size: {
                    width: parseFloat(computedStyle.width),
                    height: parseFloat(computedStyle.height)
                },
                isAnimating: false,
                propertyVersions: propertyVersions
            };
            sendEventToElm('propertyUpdate', elementId, finalPropertyData);
        }
    });

    animation.addEventListener('cancel', () => {
        const elementAnims = activeAnimations.get(elementId);
        if (elementAnims) {
            const current = elementAnims.get(propertyType);
            if (current && current.version === version) {
                elementAnims.delete(propertyType);

                if (elementAnims.size === 0) {
                    activeAnimations.delete(elementId);
                }
            }
        }

        if (portsRef && portsRef.waapiEvent) {
            const currentState = getCurrentTransform(element);
            const computedStyle = window.getComputedStyle(element);

            const propertyVersions = {};
            const remainingAnims = activeAnimations.get(elementId);
            if (remainingAnims) {
                remainingAnims.forEach((animData, propType) => {
                    propertyVersions[propType] = animData.version;
                });
            }
            propertyVersions[propertyType] = version;

            const currentPropertyData = {
                elementId: elementId,
                translate: {
                    x: currentState.x,
                    y: currentState.y,
                    z: currentState.z
                },
                opacity: parseFloat(computedStyle.opacity),
                rotate: {
                    x: currentState.rotateX,
                    y: currentState.rotateY,
                    z: currentState.rotateZ
                },
                scale: {
                    x: currentState.scaleX,
                    y: currentState.scaleY,
                    z: currentState.scaleZ
                },
                backgroundColor: computedStyle.backgroundColor,
                color: computedStyle.color,
                size: {
                    width: parseFloat(computedStyle.width),
                    height: parseFloat(computedStyle.height)
                },
                isAnimating: false,
                propertyVersions: propertyVersions
            };
            sendEventToElm('propertyUpdate', elementId, currentPropertyData);
        }
    });

    return sendAnimationUpdate;
}

/**
 * Send event to Elm via waapiEvent port
 */
function sendEventToElm(eventType, elementId, payload) {
    if (portsRef && portsRef.waapiEvent) {
        const eventData = {
            type: eventType,
            elementId: elementId,
            payload: payload || null
        };
        portsRef.waapiEvent.send(eventData);
    }
}

/**
 * Stop animation by jumping to end state
 */
export function stopAnimation(elementId) {
    const elementAnims = activeAnimations.get(elementId);
    if (elementAnims) {
        elementAnims.forEach((animData) => {
            animData.animation.finish();
        });
        activeAnimations.delete(elementId);
        sendEventToElm('animationUpdate', elementId, { status: 'stopped' });
    }
}

/**
 * Reset animation by jumping to start state
 */
export function resetAnimation(elementId) {
    const elementAnims = activeAnimations.get(elementId);
    if (elementAnims) {
        elementAnims.forEach((animData) => {
            animData.animation.cancel();
        });
        activeAnimations.delete(elementId);
        sendEventToElm('animationUpdate', elementId, { status: 'reset' });
    }
}

/**
 * Restart animation from beginning
 */
export function restartAnimation(elementId) {
    const elementAnims = activeAnimations.get(elementId);
    if (elementAnims) {
        elementAnims.forEach((animData) => {
            animData.animation.cancel();
            animData.animation.play();
        });
        sendEventToElm('animationUpdate', elementId, { status: 'restarted' });
    }
}

/**
 * Pause animation for specific element
 */
export function pauseAnimation(elementId) {
    const element = findAnimTarget(elementId);
    const elementAnims = activeAnimations.get(elementId);
    if (elementAnims && element) {
        elementAnims.forEach((animData) => {
            animData.animation.pause();
        });
        sendEventToElm('animationUpdate', elementId, { status: 'paused' });
    }
}

/**
 * Resume animation for specific element
 */
export function resumeAnimation(elementId) {
    const elementAnims = activeAnimations.get(elementId);
    if (elementAnims) {
        elementAnims.forEach((animData) => {
            animData.animation.play();
            if (animData.updateFn) {
                animData.updateFn();
            }
        });
        sendEventToElm('animationUpdate', elementId, { status: 'resumed' });
    }
}

/**
 * Update animation targets for elements with active translate animations
 */
function handleResize(updates) {
    updates.forEach(update => {
        const element = findAnimTarget(update.elementId);
        if (!element) {
            console.warn(`ElmAnimateWAAPI: Element "${update.elementId}" not found`);
            return;
        }

        const elementAnims = activeAnimations.get(update.elementId);
        // Look for merged 'transform' animation (new) or legacy 'translate' (old)
        const transformKey = elementAnims?.has('transform') ? 'transform' : (elementAnims?.has('translate') ? 'translate' : null);
        if (!elementAnims || !transformKey) {
            console.warn(`No transform animation found for ${update.elementId} - Elm state may be out of sync`);
            return;
        }

        const animData = elementAnims.get(transformKey);
        const animation = animData.animation;
        const cachedEasingKeyframes = animData.easingKeyframes;

        const startPos = update.startPosition;
        const endPos = update.endPosition;

        const fromTransform = buildTransformString(
            startPos.x, startPos.y, startPos.z,
            startPos.scaleX, startPos.scaleY, startPos.scaleZ,
            startPos.rotateX, startPos.rotateY, startPos.rotateZ
        );

        const toTransform = buildTransformString(
            endPos.x, endPos.y, endPos.z,
            endPos.scaleX, endPos.scaleY, endPos.scaleZ,
            endPos.rotateX, endPos.rotateY, endPos.rotateZ
        );

        const keyframes = generateKeyframesWithEasing(
            fromTransform,
            toTransform,
            cachedEasingKeyframes,
            'transform'
        );

        animation.effect.setKeyframes(keyframes);
    });
}

/**
 * Set all properties directly for elements (initialization)
 */
function setProperties(updates) {
    updates.forEach(update => {
        const element = findAnimTarget(update.elementId);
        if (!element) {
            console.warn(`ElmAnimateWAAPI: Element "${update.elementId}" not found`);
            return;
        }

        const tracked = activeAnimations.get(update.elementId);
        if (tracked && tracked.size > 0) {
            console.warn(`ElmAnimateWAAPI: setProperties called but element "${update.elementId}" has active animations. Should use handleResize instead.`);
        }

        const animations = element.getAnimations();
        animations.forEach((anim) => {
            anim.cancel();
        });

        activeAnimations.delete(update.elementId);

        const props = update.properties;

        if (props.x !== undefined || props.y !== undefined || props.z !== undefined ||
            props.scaleX !== undefined || props.scaleY !== undefined || props.scaleZ !== undefined ||
            props.rotateX !== undefined || props.rotateY !== undefined || props.rotateZ !== undefined) {

            const transform = buildTransformString(
                props.x || 0,
                props.y || 0,
                props.z || 0,
                props.scaleX !== undefined ? props.scaleX : 1,
                props.scaleY !== undefined ? props.scaleY : 1,
                props.scaleZ !== undefined ? props.scaleZ : 1,
                props.rotateX || 0,
                props.rotateY || 0,
                props.rotateZ || 0
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
 * Initialize the WAAPI system with Elm ports
 */
export function init(ports) {
    if (!ports) {
        console.error('ElmAnimateWAAPI: No ports provided to init()');
        return;
    }

    portsRef = ports;

    if (ports.waapiCommand && ports.waapiCommand.subscribe) {
        ports.waapiCommand.subscribe(function (commandData) {
            try {
                if (!commandData) {
                    console.warn('ElmAnimateWAAPI: No command data received');
                    return;
                }

                if (!commandData.type) {
                    console.warn('ElmAnimateWAAPI: Command missing type field:', commandData);
                    return;
                }

                const commandType = commandData.type;
                console.log('ElmAnimateWAAPI: Received command:', commandType, commandData);

                switch (commandType) {
                    case 'animate':
                        processAnimationData(commandData);
                        break;

                    case 'handleResize':
                        handleResize(commandData.updates);
                        break;

                    case 'setProperties':
                        setProperties(commandData.updates);
                        break;

                    case 'stop':
                        stopAnimation(commandData.elementId);
                        break;

                    case 'pause':
                        pauseAnimation(commandData.elementId);
                        break;

                    case 'resume':
                        resumeAnimation(commandData.elementId);
                        break;

                    default:
                        console.warn('ElmAnimateWAAPI: Unknown command type:', commandType);
                }
            } catch (error) {
                console.error('ElmAnimateWAAPI: Error processing WAAPI command:', error);
            }
        });
    } else {
        console.warn('ElmAnimateWAAPI: waapiCommand port not found or not subscribeable');
    }
}

/**
 * Add custom easing function
 */
export function addEasingFunction(name, cssValue) {
    easingFunctions[name] = cssValue;
}

// Export the activeAnimations map for advanced usage
export { activeAnimations };

// Default export for simpler imports
export default {
    init,
    addEasingFunction,
    activeAnimations
};
