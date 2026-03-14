/* eslint-env browser */
/* global window, console, document, performance, requestAnimationFrame, CSS */
/**
 * ElmAnimateWAAPI JavaScript Integration
 * 
 * This file provides the JavaScript side of port-based animations for the
 * ElmAnimateWAAPI Elm module. It uses the Web Animations API for high-performance
 * hardware-accelerated animations supporting all animation properties.
 * 
 * Usage:
 * 1. Include this file in your HTML
 * 2. Call ElmAnimateWAAPI.init(app.ports) after initializing your Elm app
 * 3. Define the required ports in your Elm application
 */

window.ElmAnimateWAAPI = (function () {
    'use strict';

    // Track active animations for cleanup and management
    // Structure: Map<elementId, Map<propertyType, { animation, version, animGroup }>>
    const activeAnimations = new Map();

    // Track animation groups for Started/Ended events
    // Structure: Map<animGroup, { elementId, totalProperties, completedProperties, started }>
    const animationGroups = new Map();

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

    /**
     * Process animation data received from Elm
     */
    function processAnimationData(animationData) {
        if (animationData && animationData.elements) {
            // Extract global animation options
            const globalOptions = {
                iterations: parseIterationCount(animationData.iterationCount),
                direction: animationData.direction || 'normal'
            };

            // Process element animations (keys are element IDs)
            Object.entries(animationData.elements).forEach(([elementId, elementConfig]) => {
                processElementAnimation(elementId, elementConfig, globalOptions);
            });
        } else {
            console.warn('ElmAnimateWAAPI: Invalid animation data format received');
        }
    }

    /**
     * Parse iteration count from Elm format to Web Animations API format
     */
    function parseIterationCount(iterationCount) {
        if (!iterationCount) return 1;

        switch (iterationCount.type) {
            case 'infinite':
                return Infinity;
            case 'times':
                return iterationCount.count;
            case 'once':
            default:
                return 1;
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
     * Now supports property-level animation tracking with version control
     * 
     * @param {string} elementId - The DOM element ID (from Elm)
     * @param {object} elementConfig - Configuration with properties to animate
     * @param {object} globalOptions - Global animation options (iterations, direction)
     */
    function processElementAnimation(elementId, elementConfig, globalOptions = { iterations: 1, direction: 'normal' }) {
        // Check if forElement was used - if not, warn and skip animation
        if (elementConfig.hasExplicitTarget === false) {
            console.warn(
                `%cMISSING ELEMENT TARGET%c

I received an animation with key "${elementId}" but no DOM element target was set.

%cHint:%c When using WAAPI.animate, you need to specify which DOM element to animate 
using WAAPI.forElement at the start of your animation pipeline:

    WAAPI.animate animState <|
        WAAPI.forElement "your-element-id"  -- Add this line
            >> Translate.for "${elementId}"
            >> Translate.toX 100
            >> Translate.build`,
                'color: #cc0000; font-weight: bold; font-size: 14px',
                '',
                'color: #4a9f4a; font-weight: bold',
                ''
            );
            return;
        }

        const element = findAnimTarget(elementId);
        if (!element) {
            console.warn(`ElmAnimateWAAPI: Element "${elementId}" not found. Ensure WAAPI.attributes is applied to the target element.`);
            return;
        }

        // Get animGroup from config (defaults to elementId for backwards compatibility)
        const animGroup = elementConfig.animGroup || elementId;
        const compositeKey = `${elementId}:${animGroup}`;

        // Get or create element animation tracking map
        if (!activeAnimations.has(compositeKey)) {
            activeAnimations.set(compositeKey, new Map());
        }
        const elementAnims = activeAnimations.get(compositeKey);

        // Separate transform properties from non-transform properties.
        // Transform sub-properties (translate, scale, rotate) must be merged into a
        // single WAAPI animation because they all target the CSS 'transform' property.
        // Multiple element.animate() calls on 'transform' would replace each other.
        const transformProperties = [];
        const nonTransformProperties = [];

        elementConfig.properties.forEach(property => {
            if (property.type === 'translate' || property.type === 'scale' || property.type === 'rotate') {
                transformProperties.push(property);
            } else {
                nonTransformProperties.push(property);
            }
        });

        // Count total animation units for group tracking
        // Transform properties are merged into 1 animation, non-transform are 1 each
        const animationCount = (transformProperties.length > 0 ? 1 : 0) + nonTransformProperties.length;

        // Initialize or reset animation group tracking
        animationGroups.set(compositeKey, {
            elementId: elementId,
            animGroup: animGroup,
            totalProperties: animationCount,
            completedProperties: 0,
            cancelledProperties: 0,
            started: false,
            propertyConfigs: []
        });

        // Process merged transform properties as a single animation
        if (transformProperties.length > 0) {
            // Cancel existing transform animation if any
            if (elementAnims.has('transform')) {
                const existing = elementAnims.get('transform');
                existing.animation.cancel();
            }
            // Also cancel individual sub-property animations from older code paths
            ['translate', 'scale', 'rotate'].forEach(propType => {
                if (elementAnims.has(propType)) {
                    const existing = elementAnims.get(propType);
                    existing.animation.cancel();
                    elementAnims.delete(propType);
                }
            });

            const maxVersion = Math.max(...transformProperties.map(p => p.version || 1));
            const animation = createMergedTransformAnimation(element, transformProperties, globalOptions);

            if (animation) {
                const updateFn = setupAnimationEvents(elementId, 'transform', element, animation, maxVersion, animGroup);
                elementAnims.set('transform', {
                    animation: animation,
                    version: maxVersion,
                    updateFn: updateFn,
                    animGroup: animGroup,
                    easingKeyframes: null, // merged animations always use keyframe-based interpolation
                    transformProperties: transformProperties // cache for resize
                });

                // Store property configs for lifecycle events
                const groupInfo = animationGroups.get(compositeKey);
                if (groupInfo) {
                    transformProperties.forEach(property => {
                        groupInfo.propertyConfigs.push(extractPropertyConfig(element, property));
                    });
                }

                // Emit Started event
                const groupInfo2 = animationGroups.get(compositeKey);
                if (groupInfo2 && !groupInfo2.started) {
                    groupInfo2.started = true;
                    sendLifecycleEvent('started', animGroup, elementId);
                }
            }
        }

        // Process non-transform properties independently (opacity, color, etc.)
        nonTransformProperties.forEach(property => {
            const propType = property.type;
            const newVersion = property.version || 1;

            if (elementAnims.has(propType)) {
                const existing = elementAnims.get(propType);
                existing.animation.cancel();
            }

            const animation = createPropertyAnimation(element, property, globalOptions);

            if (animation) {
                const updateFn = setupAnimationEvents(elementId, propType, element, animation, newVersion, animGroup);
                elementAnims.set(propType, {
                    animation: animation,
                    version: newVersion,
                    updateFn: updateFn,
                    animGroup: animGroup,
                    easingKeyframes: property.easingKeyframes || null
                });

                const groupInfo = animationGroups.get(compositeKey);
                if (groupInfo) {
                    groupInfo.propertyConfigs.push(extractPropertyConfig(element, property));
                }

                if (groupInfo && !groupInfo.started) {
                    groupInfo.started = true;
                    sendLifecycleEvent('started', animGroup, elementId);
                }
            }
        });

        // Clean up element entry if no animations remain
        if (elementAnims.size === 0) {
            activeAnimations.delete(compositeKey);
        }
    }

    /**
     * Helper to generate keyframes with easing applied.
     * If easingKeyframes is provided (for Bounce/Elastic), generates 30 keyframes with linear interpolation.
     * Otherwise, returns 2 keyframes with the specified easing.
     */
    function generateKeyframesWithEasing(startValue, endValue, easingKeyframes, propertyName) {
        if (easingKeyframes && Array.isArray(easingKeyframes)) {
            // Complex easing: generate 30 keyframes using pre-computed easing values
            return easingKeyframes.map(easingProgress => {
                // Interpolate between start and end using the easing progress
                const interpolatedValue = interpolateValue(startValue, endValue, easingProgress);
                return { [propertyName]: interpolatedValue };
            });
        } else {
            // Simple easing: use standard 2-keyframe animation
            return [
                { [propertyName]: startValue },
                { [propertyName]: endValue }
            ];
        }
    }

    /**
     * Interpolate between start and end values based on progress (0.0 to 1.0).
     * Handles both strings (transforms, colors) and numbers.
     */
    function interpolateValue(start, end, progress) {
        // For transform strings, interpolate each component
        // Check for 'none' or any transform function (translate, scale, rotate)
        if (typeof start === 'string' && typeof end === 'string' &&
            (start === 'none' || end === 'none' ||
                start.includes('translate') || start.includes('scale') || start.includes('rotate'))) {
            return interpolateTransform(start, end, progress);
        }

        // For numeric values (opacity)
        if (typeof start === 'number' && typeof end === 'number') {
            return start + (end - start) * progress;
        }

        // For color strings
        if (typeof start === 'string' && (start.startsWith('rgb') || start.startsWith('#'))) {
            return interpolateColor(start, end, progress);
        }

        // Fallback: return end value
        return end;
    }

    /**
     * Interpolate between two transform strings.
     */
    function interpolateTransform(startTransform, endTransform, progress) {
        // Parse transform components using regex
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

        // Interpolate each component
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
        // Parse rgb/rgba colors
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
     * Extract property configuration for lifecycle events.
     * Returns a normalized config object with from/to values as strings.
     * @param {Element} element - The DOM element
     * @param {object} property - The property configuration from Elm
     * @returns {object} Normalized property config
     */
    function extractPropertyConfig(element, property) {
        const config = {
            property: property.type,
            duration: property.duration,
            easing: property.easing,
            from: '',
            to: ''
        };

        const computedStyle = window.getComputedStyle(element);

        switch (property.type) {
            case 'translate': {
                const currentTransform = getCurrentTransform(element);
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
            case 'scale': {
                const currentTransform = getCurrentTransform(element);
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
            case 'rotate': {
                const currentTransform = getCurrentTransform(element);
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
            case 'opacity': {
                const computedOpacity = parseFloat(computedStyle.opacity);
                const fromVal = property.startValue ?? property.defaultValue ?? computedOpacity;
                config.from = `${fromVal}`;
                config.to = `${property.endValue}`;
                break;
            }
            case 'backgroundColor':
            case 'color': {
                const cssProp = property.type === 'backgroundColor' ? 'backgroundColor' : 'color';
                const computedColor = computedStyle[cssProp];
                config.from = property.startColor ?? property.defaultColor ?? computedColor;
                config.to = property.endColor;
                break;
            }
            case 'size': {
                const startWidth = property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width);
                const startHeight = property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height);
                config.from = `${startWidth},${startHeight}`;
                config.to = `${property.endWidth},${property.endHeight}`;
                break;
            }
        }

        return config;
    }

    /**
     * Create animation for a single transform property (translate, scale, or rotate)
     * Used for property-level tracking where each transform property is animated independently
     */
    function createTransformPropertyAnimation(element, property, globalOptions = { iterations: 1, direction: 'normal' }) {
        const duration = property.duration;
        const easing = property.easing;
        const easingKeyframes = property.easingKeyframes;

        // Get current transform state to preserve other transform properties
        const currentTransform = getCurrentTransform(element);

        // Build start and end transforms based on property type
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
            // Complex easing: generate keyframes with linear interpolation
            keyframes = generateKeyframesWithEasing(startTransform, endTransform, easingKeyframes, 'transform');
            animationEasing = 'linear';
        } else {
            // Simple easing: use 2 keyframes with easing curve
            keyframes = [
                { transform: startTransform },
                { transform: endTransform }
            ];
            animationEasing = easingFunctions[easing] || easing;
        }

        return element.animate(keyframes, {
            duration: duration,
            easing: animationEasing,
            fill: 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        });
    }

    /**
     * Create a single WAAPI animation for multiple transform sub-properties.
     * Merges translate, scale, and rotate into one animation with per-property
     * easing via generated keyframes. This avoids the WAAPI cascade issue where
     * multiple animations on 'transform' replace each other.
     */
    function createMergedTransformAnimation(element, transformProperties, globalOptions = { iterations: 1, direction: 'normal' }) {
        const currentTransform = getCurrentTransform(element);

        // Resolve start/end values for each sub-property
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

        // Check if all sub-properties share the same simple easing (no easingKeyframes)
        const activeProps = transformProperties.map(p => resolved[p.type]);
        const allSameEasing = activeProps.every(r => !r.easingKeyframes && r.easing === activeProps[0].easing);
        const allSameDuration = activeProps.every(r => r.duration === activeProps[0].duration);

        if (allSameEasing && allSameDuration) {
            // Simple case: same easing and duration, use 2-keyframe animation
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
                fill: 'forwards',
                iterations: globalOptions.iterations,
                direction: globalOptions.direction
            });
        }

        // Complex case: different easings or durations per sub-property.
        // Generate keyframes where each sub-property is independently eased.
        const KEYFRAME_COUNT = 30;
        const keyframes = [];

        for (let i = 0; i < KEYFRAME_COUNT; i++) {
            const globalProgress = i / (KEYFRAME_COUNT - 1); // 0.0 to 1.0

            // For each sub-property, compute its local progress considering duration ratio
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
            easing: 'linear', // easing is baked into keyframes
            fill: 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        });
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
        if (subProp.easingKeyframes && Array.isArray(subProp.easingKeyframes)) {
            // Complex easing (bounce, elastic): lookup in pre-computed keyframes
            const idx = Math.min(
                Math.floor(localProgress * (subProp.easingKeyframes.length - 1)),
                subProp.easingKeyframes.length - 1
            );
            easedProgress = subProp.easingKeyframes[idx];
        } else {
            // Simple easing: approximate with linear (the per-property easing difference
            // is typically subtle enough that linear interpolation at 30 keyframes is acceptable)
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
    function createPropertyAnimation(element, property, globalOptions = { iterations: 1, direction: 'normal' }) {
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
                        // Complex easing: generate keyframes with easing applied
                        keyframes = easingKeyframes.map(progress => ({
                            opacity: (startValue + (endValue - startValue) * progress).toString()
                        }));
                        animationEasing = 'linear';
                    } else {
                        // Simple easing: use 2 keyframes
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
                        // Complex easing: generate keyframes with easing applied
                        keyframes = easingKeyframes.map(progress => ({
                            backgroundColor: interpolateColor(startColor, endColor, progress)
                        }));
                        animationEasing = 'linear';
                    } else {
                        // Simple easing: use 2 keyframes
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
                        // Complex easing: generate keyframes with easing applied
                        keyframes = easingKeyframes.map(progress => ({
                            color: interpolateColor(startColor, endColor, progress)
                        }));
                        animationEasing = 'linear';
                    } else {
                        // Simple easing: use 2 keyframes
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
                        // Complex easing: generate keyframes with easing applied
                        keyframes = easingKeyframes.map(progress => ({
                            width: `${startWidth + (property.endWidth - startWidth) * progress}px`,
                            height: `${startHeight + (property.endHeight - startHeight) * progress}px`
                        }));
                        animationEasing = 'linear';
                    } else {
                        // Simple easing: use 2 keyframes
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
            fill: 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        });
    }

    /**
     * Build a complete transform string with 3D support
     */
    function buildTransformString(x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ) {
        const parts = [];

        // Translate: use translate3d for hardware acceleration
        if (x !== 0 || y !== 0 || z !== 0) {
            parts.push(`translate3d(${x}px, ${y}px, ${z}px)`);
        }

        // Rotation: apply in order X, Y, Z for consistent results
        if (rotateX !== 0) {
            parts.push(`rotateX(${rotateX}deg)`);
        }
        if (rotateY !== 0) {
            parts.push(`rotateY(${rotateY}deg)`);
        }
        if (rotateZ !== 0) {
            parts.push(`rotateZ(${rotateZ}deg)`);
        }

        // Scale: use individual scale functions for better control
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

                // Extract scale from column vector lengths
                const scaleX = Math.sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2]);
                const scaleY = Math.sqrt(values[4] * values[4] + values[5] * values[5] + values[6] * values[6]);
                const scaleZ = Math.sqrt(values[8] * values[8] + values[9] * values[9] + values[10] * values[10]);

                // Extract rotation matrix by dividing out scale
                // R[row][col] = values[col*4 + row] / scale for that column
                const r00 = scaleX !== 0 ? values[0] / scaleX : 0;
                const r10 = scaleX !== 0 ? values[1] / scaleX : 0;
                const r20 = scaleX !== 0 ? values[2] / scaleX : 0;
                const r01 = scaleY !== 0 ? values[4] / scaleY : 0;
                const r11 = scaleY !== 0 ? values[5] / scaleY : 0;
                const r21 = scaleY !== 0 ? values[6] / scaleY : 0;
                const r02 = scaleZ !== 0 ? values[8] / scaleZ : 0;
                const r12 = scaleZ !== 0 ? values[9] / scaleZ : 0;
                const r22 = scaleZ !== 0 ? values[10] / scaleZ : 0;

                // Euler angles (XYZ convention) from rotation matrix
                const RAD_TO_DEG = 180 / Math.PI;
                let rotateX, rotateY, rotateZ;

                const sy = -r20;
                if (sy >= 1) {
                    // Gimbal lock at +90 degrees
                    rotateY = 90;
                    rotateX = Math.atan2(r01, r11) * RAD_TO_DEG;
                    rotateZ = 0;
                } else if (sy <= -1) {
                    // Gimbal lock at -90 degrees
                    rotateY = -90;
                    rotateX = Math.atan2(r01, r11) * RAD_TO_DEG;
                    rotateZ = 0;
                } else {
                    rotateY = Math.asin(sy) * RAD_TO_DEG;
                    rotateX = Math.atan2(r21, r22) * RAD_TO_DEG;
                    rotateZ = Math.atan2(r10, r00) * RAD_TO_DEG;
                }

                return { transform, x: tx, y: ty, z: tz, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ };
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
     * Set up animation event listeners and property updates with version tracking
     */
    function setupAnimationEvents(elementId, propertyType, element, animation, version, animGroup) {
        const compositeKey = `${elementId}:${animGroup}`;
        let updatePort = null;

        // Find the update port
        if (typeof window.app !== 'undefined' &&
            window.app.ports &&
            window.app.ports.waapiEvent &&
            typeof window.app.ports.waapiEvent.send === 'function') {
            updatePort = window.app.ports.waapiEvent;
        }

        // Send updates during animation
        let lastTime = 0;
        const updateInterval = 16; // ~60fps
        let rafId = null;

        function sendAnimationUpdate() {
            const now = performance.now();
            if (now - lastTime >= updateInterval) {
                const transformState = getCurrentTransform(element);
                const computedStyle = window.getComputedStyle(element);

                if (updatePort) {
                    // Collect property versions from all active animations for this element
                    const propertyVersions = {};
                    const elementAnims = activeAnimations.get(compositeKey);
                    if (elementAnims) {
                        elementAnims.forEach((animData, propType) => {
                            propertyVersions[propType] = animData.version;
                        });
                    }

                    // Calculate progress from animation currentTime/duration
                    const groupInfo = animationGroups.get(compositeKey);
                    const maxDuration = groupInfo?.propertyConfigs?.length > 0
                        ? Math.max(...groupInfo.propertyConfigs.map(p => p.duration))
                        : animation.effect?.getTiming()?.duration || 0;
                    const currentTime = animation.currentTime || 0;
                    const progress = maxDuration > 0
                        ? Math.min(1.0, Math.max(0.0, currentTime / maxDuration))
                        : 0;

                    const propertyData = {
                        elementId: elementId,
                        animGroup: animGroup,
                        progress: progress,
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
                    // Send property update during animation
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

        // Handle animation completion
        animation.addEventListener('finish', () => {
            // Stop update loop
            if (rafId !== null) {
                cancelAnimationFrame(rafId);
                rafId = null;
            }
            // CRITICAL: Commit the animated styles to inline styles, then cancel
            // MDN: After commitStyles(), you must cancel() to fully remove the animation
            // Without cancel(), the finished animation can still affect the cascade
            try {
                animation.commitStyles();
                animation.cancel();
            } catch (_) {
                // commitStyles can fail if the element is not rendered
                // (e.g. inside a hidden iframe tab). This is harmless —
                // the animation is already finished and the element is not visible.
                try { animation.cancel(); } catch (_) { /* ignore */ }
            }

            // Only remove THIS property's animation if version matches
            // (prevents removing newer animation if finish event fires late)
            const elementAnims = activeAnimations.get(compositeKey);
            if (elementAnims) {
                const current = elementAnims.get(propertyType);
                if (current && current.version === version) {
                    elementAnims.delete(propertyType);

                    // If no more properties animating, clean up element entry
                    if (elementAnims.size === 0) {
                        activeAnimations.delete(compositeKey);
                    }
                }
            }

            // Track completion for animGroup - emit 'completed' when all properties done
            const groupInfo = animationGroups.get(compositeKey);
            if (groupInfo) {
                groupInfo.completedProperties++;
                const allComplete = groupInfo.completedProperties >= groupInfo.totalProperties;

                if (updatePort) {
                    const finalState = getCurrentTransform(element);
                    const computedStyle = window.getComputedStyle(element);

                    // Collect remaining property versions
                    const propertyVersions = {};
                    const remainingAnims = activeAnimations.get(compositeKey);
                    if (remainingAnims) {
                        remainingAnims.forEach((animData, propType) => {
                            propertyVersions[propType] = animData.version;
                        });
                    }
                    // Include the completed property with its version one last time
                    propertyVersions[propertyType] = version;

                    const finalPropertyData = {
                        elementId: elementId,
                        animGroup: animGroup,
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
                        isAnimating: !allComplete,
                        propertyVersions: propertyVersions
                    };
                    // Send final state property update
                    sendPropertyUpdate(finalPropertyData);
                }

                // Emit 'completed' when all properties in the group have finished
                if (allComplete) {
                    sendLifecycleEvent('completed', animGroup, elementId);
                    animationGroups.delete(compositeKey);
                }
            }
        });

        animation.addEventListener('cancel', () => {
            // Only remove THIS property's animation if version matches
            // (prevents removing newer animation if cancel event fires late)
            const elementAnims = activeAnimations.get(compositeKey);
            if (elementAnims) {
                const current = elementAnims.get(propertyType);
                if (current && current.version === version) {
                    elementAnims.delete(propertyType);

                    // If no more properties animating, clean up element entry
                    if (elementAnims.size === 0) {
                        activeAnimations.delete(compositeKey);
                    }
                }
            }

            // Track cancellation for animGroup
            const groupInfo = animationGroups.get(compositeKey);
            if (groupInfo) {
                groupInfo.completedProperties++;
                const allCancelled = groupInfo.completedProperties >= groupInfo.totalProperties;

                if (updatePort) {
                    const currentState = getCurrentTransform(element);
                    const computedStyle = window.getComputedStyle(element);

                    // Collect remaining property versions
                    const propertyVersions = {};
                    const remainingAnims = activeAnimations.get(compositeKey);
                    if (remainingAnims) {
                        remainingAnims.forEach((animData, propType) => {
                            propertyVersions[propType] = animData.version;
                        });
                    }
                    // Include the cancelled property with its version one last time
                    propertyVersions[propertyType] = version;

                    const currentPropertyData = {
                        elementId: elementId,
                        animGroup: animGroup,
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
                        isAnimating: !allCancelled,
                        propertyVersions: propertyVersions
                    };
                    sendPropertyUpdate(currentPropertyData);
                }

                // Emit 'cancelled' when all properties in the group have been cancelled
                if (allCancelled) {
                    sendLifecycleEvent('cancelled', animGroup, elementId);
                    animationGroups.delete(compositeKey);
                }
            }
        });

        // Return the update function so it can be restarted on resume
        return sendAnimationUpdate;
    }

    /**
     * Send lifecycle event to Elm (started, completed, cancelled, etc.)
     * Uses 'animationUpdate' type which Elm routes to AnimEvent handling
     * Includes property configurations and current progress for rich event data.
     * @param {string} status - Lifecycle status ('started', 'completed', 'cancelled', 'paused', 'resumed', 'stopped', 'reset', 'restarted')
     * @param {string} animGroup - The animation group identifier
     * @param {string} elementId - The DOM element ID
     */
    function sendLifecycleEvent(status, animGroup, elementId) {
        if (window.app && window.app.ports && window.app.ports.waapiEvent) {
            const compositeKey = `${elementId}:${animGroup}`;
            const groupInfo = animationGroups.get(compositeKey);

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
                const elementAnims = activeAnimations.get(compositeKey);
                if (elementAnims && elementAnims.size > 0) {
                    // Get progress from any active animation (they should be in sync)
                    const firstAnim = elementAnims.values().next().value;
                    if (firstAnim && firstAnim.animation && maxDuration > 0) {
                        const currentTime = firstAnim.animation.currentTime || 0;
                        progress = Math.min(1.0, Math.max(0.0, currentTime / maxDuration));
                    }
                }
            }

            const eventData = {
                type: 'animationUpdate',
                payload: {
                    elementId: elementId,
                    animGroup: animGroup,
                    status: status,
                    progress: progress
                }
            };
            window.app.ports.waapiEvent.send(eventData);
        }
    }

    /**
     * Send property update to Elm (during animation)
     * Uses 'propertyUpdate' type which Elm routes to PropertyUpdate handling
     * @param {object} propertyData - The current property values and metadata
     */
    function sendPropertyUpdate(propertyData) {
        if (window.app && window.app.ports && window.app.ports.waapiEvent) {
            const eventData = {
                type: 'propertyUpdate',
                ...propertyData
            };
            window.app.ports.waapiEvent.send(eventData);
        }
    }

    /**
     * Find all composite keys in activeAnimations that match an element ID
     * @param {string} elementId - The DOM element ID to match
     * @returns {string[]} Array of composite keys (elementId:animGroup) that match
     */
    function findCompositeKeysForElement(elementId) {
        const keys = [];
        const prefix = `${elementId}:`;
        activeAnimations.forEach((_, compositeKey) => {
            if (compositeKey.startsWith(prefix)) {
                keys.push(compositeKey);
            }
        });
        return keys;
    }

    /**
     * Stop animation by jumping to end state
     * @param {string} elementId - The DOM element ID
     * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
     */
    function stopAnimation(elementId, properties) {
        const compositeKeys = findCompositeKeysForElement(elementId);
        const propsToAffect = properties ? new Set(properties) : null;

        compositeKeys.forEach(compositeKey => {
            const elementAnims = activeAnimations.get(compositeKey);
            if (!elementAnims) return;

            const animGroup = compositeKey.split(':').slice(1).join(':');
            let affectedCount = 0;

            elementAnims.forEach((animData, propertyType) => {
                if (!propsToAffect || propsToAffect.has(propertyType)) {
                    animData.animation.finish(); // Jump to end state
                    affectedCount++;
                }
            });

            // If we affected all properties, delete the entry and clean up group tracking
            if (!propsToAffect || affectedCount === elementAnims.size) {
                activeAnimations.delete(compositeKey);
                animationGroups.delete(compositeKey);
            }

            // Send stopped event to Elm for this animGroup
            sendLifecycleEvent('stopped', animGroup, elementId);
        });
    }

    /**
     * Reset animation by jumping to start state
     * @param {string} elementId - The DOM element ID
     * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
     */
    function resetAnimation(elementId, properties) {
        const compositeKeys = findCompositeKeysForElement(elementId);
        const propsToAffect = properties ? new Set(properties) : null;

        compositeKeys.forEach(compositeKey => {
            const elementAnims = activeAnimations.get(compositeKey);
            if (!elementAnims) return;

            const animGroup = compositeKey.split(':').slice(1).join(':');
            let affectedCount = 0;

            elementAnims.forEach((animData, propertyType) => {
                if (!propsToAffect || propsToAffect.has(propertyType)) {
                    animData.animation.cancel(); // Cancel to jump to start
                    affectedCount++;
                }
            });

            // If we affected all properties, delete the entry and clean up group tracking
            if (!propsToAffect || affectedCount === elementAnims.size) {
                activeAnimations.delete(compositeKey);
                animationGroups.delete(compositeKey);
            }

            // Send reset event to Elm for this animGroup
            sendLifecycleEvent('reset', animGroup, elementId);
        });
    }

    /**
     * Restart animation from beginning
     * @param {string} elementId - The DOM element ID
     * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
     */
    function restartAnimation(elementId, properties) {
        const compositeKeys = findCompositeKeysForElement(elementId);
        const propsToAffect = properties ? new Set(properties) : null;

        compositeKeys.forEach(compositeKey => {
            const elementAnims = activeAnimations.get(compositeKey);
            if (!elementAnims) return;

            const animGroup = compositeKey.split(':').slice(1).join(':');

            elementAnims.forEach((animData, propertyType) => {
                if (!propsToAffect || propsToAffect.has(propertyType)) {
                    animData.animation.cancel(); // Cancel first
                    animData.animation.play();   // Then replay
                }
            });

            // Reset group tracking for restart
            const groupTracking = animationGroups.get(compositeKey);
            if (groupTracking) {
                groupTracking.completedProperties = 0;
                groupTracking.started = false;
            }

            // Send restarted event to Elm for this animGroup
            sendLifecycleEvent('restarted', animGroup, elementId);
        });
    }

    /**
     * Pause animation for specific element
     * @param {string} elementId - The DOM element ID
     * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
     */
    function pauseAnimation(elementId, properties) {
        const element = findAnimTarget(elementId);
        if (!element) return;

        const compositeKeys = findCompositeKeysForElement(elementId);
        const propsToAffect = properties ? new Set(properties) : null;

        compositeKeys.forEach(compositeKey => {
            const elementAnims = activeAnimations.get(compositeKey);
            if (!elementAnims) return;

            const animGroup = compositeKey.split(':').slice(1).join(':');

            elementAnims.forEach((animData, propertyType) => {
                if (!propsToAffect || propsToAffect.has(propertyType)) {
                    animData.animation.pause();
                }
            });

            // Send paused event to Elm for this animGroup
            sendLifecycleEvent('paused', animGroup, elementId);
        });
    }

    /**
     * Resume animation for specific element
     * @param {string} elementId - The DOM element ID
     * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
     */
    function resumeAnimation(elementId, properties) {
        const compositeKeys = findCompositeKeysForElement(elementId);
        const propsToAffect = properties ? new Set(properties) : null;

        compositeKeys.forEach(compositeKey => {
            const elementAnims = activeAnimations.get(compositeKey);
            if (!elementAnims) return;

            const animGroup = compositeKey.split(':').slice(1).join(':');

            elementAnims.forEach((animData, propertyType) => {
                if (!propsToAffect || propsToAffect.has(propertyType)) {
                    animData.animation.play();
                    // Restart the RAF update loop
                    if (animData.updateFn) {
                        animData.updateFn();
                    }
                }
            });

            // Send resumed event to Elm for this animGroup
            sendLifecycleEvent('resumed', animGroup, elementId);
        });
    }


    /**
     * Update animation targets for elements with active translate animations
     * Called during resize when animations are running/paused
     * ARCHITECTURE: Uses setKeyframes() to update animation with fully scaled start and end positions
     * This preserves playState, currentTime, and event listeners automatically
     * The browser interpolates correctly at the current animation progress using the new keyframes
     */
    function handleResize(updates) {
        updates.forEach(update => {
            const element = findAnimTarget(update.elementId);
            if (!element) {
                console.warn(`ElmAnimateWAAPI: Element "${update.elementId}" not found`);
                return;
            }

            // Find all composite keys for this element
            const compositeKeys = findCompositeKeysForElement(update.elementId);
            let foundTransform = false;

            compositeKeys.forEach(compositeKey => {
                const elementAnims = activeAnimations.get(compositeKey);
                // Look for merged 'transform' animation (new) or legacy 'translate' (old)
                const transformKey = elementAnims?.has('transform') ? 'transform' : (elementAnims?.has('translate') ? 'translate' : null);
                if (!elementAnims || !transformKey) return;

                foundTransform = true;

                const animData = elementAnims.get(transformKey);
                const animation = animData.animation;
                const cachedEasingKeyframes = animData.easingKeyframes;

                // Extract scaled start and end positions from Elm
                const startPos = update.startPosition;
                const endPos = update.endPosition;

                // Build full animation keyframes from scaled start to scaled end
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

                // Generate keyframes using cached easing (preserves bounce/elastic during resize)
                const keyframes = generateKeyframesWithEasing(
                    fromTransform,
                    toTransform,
                    cachedEasingKeyframes,
                    'transform'
                );

                // Update keyframes in-place - animation continues seamlessly
                animation.effect.setKeyframes(keyframes);
            });

            if (!foundTransform) {
                console.warn(`No transform animation found for ${update.elementId} - Elm state may be out of sync`);
            }
        });
    }

    /**
     * Set all properties directly for elements (initialization)
     * Called during initProperties to synchronize Elm, JS, and inline styles
     * ARCHITECTURE: Elm sends all property values - no defaults in JS
     */
    function setProperties(updates) {
        updates.forEach(update => {
            const element = findAnimTarget(update.elementId);
            if (!element) {
                console.warn(`ElmAnimateWAAPI: Element "${update.elementId}" not found`);
                return;
            }

            // Check if Elm mistakenly sent setProperties instead of handleResize
            const compositeKeys = findCompositeKeysForElement(update.elementId);
            const hasActiveAnimations = compositeKeys.some(key => {
                const anims = activeAnimations.get(key);
                return anims && anims.size > 0;
            });
            if (hasActiveAnimations) {
                console.warn(`ElmAnimateWAAPI: setProperties called but element "${update.elementId}" has active animations. Should use handleResize instead.`);
            }

            // CRITICAL: Cancel all existing animations
            const animations = element.getAnimations();
            animations.forEach((anim) => {
                anim.cancel();
            });

            // Clean up tracking for this element (all composite keys)
            compositeKeys.forEach(key => {
                activeAnimations.delete(key);
                animationGroups.delete(key);
            });

            const props = update.properties;

            // Transform properties - use direct inline style assignment
            // No animations are active at this point, so inline styles work fine
            // Active animations have higher precedence, but we've cancelled all animations above
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

                // Direct inline style assignment - no animation needed
                element.style.transform = transform;
            }

            // Opacity
            if (props.opacity !== undefined) {
                element.style.opacity = props.opacity.toString();
            }

            // Background color
            if (props.backgroundColor !== undefined) {
                element.style.backgroundColor = props.backgroundColor;
            }

            // Font color
            if (props.color !== undefined) {
                element.style.color = props.color;
            }

            // Size
            if (props.width !== undefined && props.height !== undefined) {
                element.style.width = `${props.width}px`;
                element.style.height = `${props.height}px`;
            }
        });
    }

    /**
     * Initialize the WAAPI system with Elm ports
     */
    function init(ports) {
        if (!ports) {
            console.error('ElmAnimateWAAPI: No ports provided to init()');
            return;
        }

        // Store reference for updates
        window.app = { ports: ports };

        // Subscribe to consolidated command port from Elm
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
                    switch (commandType) {
                        case 'animate':
                            // Animation data with elements
                            processAnimationData(commandData);
                            break;

                        case 'handleResize':
                            // Resize during active animation
                            handleResize(commandData.updates);
                            break;

                        case 'setProperties':
                            setProperties(commandData.updates);
                            break;

                        case 'stop':
                            stopAnimation(commandData.elementId, commandData.properties);
                            break;

                        case 'pause':
                            pauseAnimation(commandData.elementId, commandData.properties);
                            break;

                        case 'resume':
                            resumeAnimation(commandData.elementId, commandData.properties);
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
     * Public API
     */
    return {
        init: init,

        // Expose utilities for advanced usage
        getCurrentTransform: getCurrentTransform,
        stopAnimation: stopAnimation,
        resetAnimation: resetAnimation,
        restartAnimation: restartAnimation,
        pauseAnimation: pauseAnimation,
        resumeAnimation: resumeAnimation,
        activeAnimations: activeAnimations,

        // Allow custom easing functions
        addEasingFunction: function (name, cssValue) {
            easingFunctions[name] = cssValue;
        }
    };
})();