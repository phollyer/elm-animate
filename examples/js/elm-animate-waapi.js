/* eslint-env browser */
/* global window, console, document, performance, requestAnimationFrame */
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

    /**
     * Apply perspective to containers
     */
    function applyPerspective(animationData) {
        const perspectiveContainers = new Set();

        // Collect all perspective settings (global and property-level)
        const perspectiveSettings = {};

        // Global perspective
        if (animationData.globalPerspective) {
            const { containerId, value } = animationData.globalPerspective;
            perspectiveSettings[containerId] = value;
            perspectiveContainers.add(containerId);
        }

        // Property-level perspectives (override global)
        if (animationData.elements) {
            Object.values(animationData.elements).forEach(elementConfig => {
                elementConfig.properties.forEach(property => {
                    if (property.perspective) {
                        const { containerId, value } = property.perspective;
                        perspectiveSettings[containerId] = value;
                        perspectiveContainers.add(containerId);
                    }
                });
            });
        }

        // Apply perspective styles to containers
        perspectiveContainers.forEach(containerId => {
            const container = document.getElementById(containerId);
            if (container) {
                const perspectiveSource = container.getAttribute('data-perspective-source');

                // Only apply if:
                // - No perspective set yet, OR
                // - Perspective was set by JS (can be updated)
                // Never overwrite Elm-controlled perspective
                if (perspectiveSource !== 'elm') {
                    const perspectiveValue = perspectiveSettings[containerId];
                    container.style.perspective = `${perspectiveValue}px`;
                    container.style.transformStyle = 'preserve-3d';
                    container.setAttribute('data-perspective-source', 'js');
                }
            } else {
                console.warn(`ElmAnimateWAAPI: Container with id "${containerId}" not found for perspective`);
            }
        });
    }

    /**
     * Process animation data received from Elm
     */
    function processAnimationData(animationData) {
        if (animationData && animationData.elements) {
            // Apply perspective to containers first
            applyPerspective(animationData);

            // Then process element animations
            Object.entries(animationData.elements).forEach(([elementId, elementConfig]) => {
                processElementAnimation(elementId, elementConfig);
            });
        } else {
            console.warn('ElmAnimateWAAPI: Invalid animation data format received');
        }
    }

    /**
     * Process animation for a single element with all its properties
     * Now supports property-level animation tracking with version control
     */
    function processElementAnimation(elementId, elementConfig) {
        const element = document.getElementById(elementId);
        if (!element) {
            console.warn(`ElmAnimateWAAPI: Element with id "${elementId}" not found`);
            return;
        }

        // Get or create element animation tracking map
        if (!activeAnimations.has(elementId)) {
            activeAnimations.set(elementId, new Map());
        }
        const elementAnims = activeAnimations.get(elementId);

        // Process each property independently
        elementConfig.properties.forEach(property => {
            console.log(`ElmAnimateWAAPI: Processing property for element "${elementId}"`, property);
            const propType = property.type;
            const newVersion = property.version || 1;

            // Check if there's an existing animation for this property
            if (elementAnims.has(propType)) {
                const existing = elementAnims.get(propType);

                // Cancel the old animation for this specific property
                existing.animation.cancel();
            }

            // Create new animation for this property
            let animation;
            if (propType === 'position' || propType === 'scale' || propType === 'rotate') {
                // For transform properties, create individual transform animation
                animation = createTransformPropertyAnimation(element, property);
            } else {
                animation = createPropertyAnimation(element, property);
            }

            if (animation) {
                const updateFn = setupAnimationEvents(elementId, propType, element, animation, newVersion);
                elementAnims.set(propType, {
                    animation: animation,
                    version: newVersion,
                    updateFn: updateFn
                });
            }
        });

        // Clean up element entry if no animations remain
        if (elementAnims.size === 0) {
            activeAnimations.delete(elementId);
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
     * Create combined transform animation for position, scale, and rotate
     * Uses start values provided by Elm (source of truth) instead of reading from DOM
     */
    function createTransformAnimation(element, transformProperties) {
        let startTransform = '';
        let endTransform = '';

        // Initialize with identity values
        let startTranslateX = 0, startTranslateY = 0, startTranslateZ = 0;
        let endTranslateX = 0, endTranslateY = 0, endTranslateZ = 0;
        let startScaleX = 1, startScaleY = 1, startScaleZ = 1;
        let endScaleX = 1, endScaleY = 1, endScaleZ = 1;
        let startRotationX = 0, startRotationY = 0, startRotationZ = 0;
        let endRotationX = 0, endRotationY = 0, endRotationZ = 0;

        // Get animation config - use maximum duration from all properties
        const duration = Math.max(...transformProperties.map(p => p.duration));
        const firstProperty = transformProperties[0];
        const easing = firstProperty.easing;

        // Apply property values from Elm (Elm is source of truth)
        // For properties with duration=0, use the end value for both start and end (static preservation)
        transformProperties.forEach(property => {
            const isStatic = property.duration === 0;

            switch (property.type) {
                case 'position':
                    if (isStatic) {
                        // Static: use end value for both start and end
                        startTranslateX = property.endX !== undefined ? property.endX : startTranslateX;
                        startTranslateY = property.endY !== undefined ? property.endY : startTranslateY;
                        startTranslateZ = property.endZ !== undefined ? property.endZ : startTranslateZ;
                        endTranslateX = property.endX !== undefined ? property.endX : endTranslateX;
                        endTranslateY = property.endY !== undefined ? property.endY : endTranslateY;
                        endTranslateZ = property.endZ !== undefined ? property.endZ : endTranslateZ;
                    } else {
                        // Animating: use start and end values
                        startTranslateX = property.startX !== undefined ? property.startX : startTranslateX;
                        startTranslateY = property.startY !== undefined ? property.startY : startTranslateY;
                        startTranslateZ = property.startZ !== undefined ? property.startZ : startTranslateZ;
                        endTranslateX = property.endX !== undefined ? property.endX : endTranslateX;
                        endTranslateY = property.endY !== undefined ? property.endY : endTranslateY;
                        endTranslateZ = property.endZ !== undefined ? property.endZ : endTranslateZ;
                    }
                    break;
                case 'scale':
                    if (isStatic) {
                        startScaleX = property.endX !== undefined ? property.endX : startScaleX;
                        startScaleY = property.endY !== undefined ? property.endY : startScaleY;
                        startScaleZ = property.endZ !== undefined ? property.endZ : startScaleZ;
                        endScaleX = property.endX !== undefined ? property.endX : endScaleX;
                        endScaleY = property.endY !== undefined ? property.endY : endScaleY;
                        endScaleZ = property.endZ !== undefined ? property.endZ : endScaleZ;
                    } else {
                        startScaleX = property.startX !== undefined ? property.startX : startScaleX;
                        startScaleY = property.startY !== undefined ? property.startY : startScaleY;
                        startScaleZ = property.startZ !== undefined ? property.startZ : startScaleZ;
                        endScaleX = property.endX !== undefined ? property.endX : endScaleX;
                        endScaleY = property.endY !== undefined ? property.endY : endScaleY;
                        endScaleZ = property.endZ !== undefined ? property.endZ : endScaleZ;
                    }
                    break;
                case 'rotate':
                    if (isStatic) {
                        startRotationX = property.endX !== undefined ? property.endX : startRotationX;
                        startRotationY = property.endY !== undefined ? property.endY : startRotationY;
                        startRotationZ = property.endZ !== undefined ? property.endZ : startRotationZ;
                        endRotationX = property.endX !== undefined ? property.endX : endRotationX;
                        endRotationY = property.endY !== undefined ? property.endY : endRotationY;
                        endRotationZ = property.endZ !== undefined ? property.endZ : endRotationZ;
                    } else {
                        startRotationX = property.startX !== undefined ? property.startX : startRotationX;
                        startRotationY = property.startY !== undefined ? property.startY : startRotationY;
                        startRotationZ = property.startZ !== undefined ? property.startZ : startRotationZ;
                        endRotationX = property.endX !== undefined ? property.endX : endRotationX;
                        endRotationY = property.endY !== undefined ? property.endY : endRotationY;
                        endRotationZ = property.endZ !== undefined ? property.endZ : endRotationZ;
                    }
                    break;
            }
        });

        // Build transform strings
        startTransform = buildTransformString(startTranslateX, startTranslateY, startTranslateZ,
            startScaleX, startScaleY, startScaleZ,
            startRotationX, startRotationY, startRotationZ);
        endTransform = buildTransformString(endTranslateX, endTranslateY, endTranslateZ,
            endScaleX, endScaleY, endScaleZ,
            endRotationX, endRotationY, endRotationZ);

        // Check if any property has easingKeyframes (for complex easings like Bounce/Elastic)
        const easingKeyframes = transformProperties.find(p => p.easingKeyframes)?.easingKeyframes;

        let keyframes;
        let animationEasing;

        if (easingKeyframes) {
            // Complex easing: generate 30 keyframes with linear interpolation
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
            fill: 'forwards'
        });
    }

    /**
     * Create animation for a single transform property (position, scale, or rotate)
     * Used for property-level tracking where each transform property is animated independently
     */
    function createTransformPropertyAnimation(element, property) {
        const duration = property.duration;
        const easing = property.easing;
        const easingKeyframes = property.easingKeyframes;

        // Get current transform state to preserve other transform properties
        const currentTransform = getCurrentTransform(element);

        // Build start and end transforms based on property type
        let startTransform, endTransform;

        switch (property.type) {
            case 'position':
                const startX = property.startX !== undefined ? property.startX : currentTransform.x;
                const startY = property.startY !== undefined ? property.startY : currentTransform.y;
                const startZ = property.startZ !== undefined ? property.startZ : currentTransform.z;
                const endX = property.endX !== undefined ? property.endX : currentTransform.x;
                const endY = property.endY !== undefined ? property.endY : currentTransform.y;
                const endZ = property.endZ !== undefined ? property.endZ : currentTransform.z;

                startTransform = buildTransformString(startX, startY, startZ,
                    currentTransform.scaleX, currentTransform.scaleY, currentTransform.scaleZ,
                    currentTransform.rotationX, currentTransform.rotationY, currentTransform.rotationZ);
                endTransform = buildTransformString(endX, endY, endZ,
                    currentTransform.scaleX, currentTransform.scaleY, currentTransform.scaleZ,
                    currentTransform.rotationX, currentTransform.rotationY, currentTransform.rotationZ);
                break;

            case 'scale':
                const startScaleX = property.startX !== undefined ? property.startX : currentTransform.scaleX;
                const startScaleY = property.startY !== undefined ? property.startY : currentTransform.scaleY;
                const startScaleZ = property.startZ !== undefined ? property.startZ : currentTransform.scaleZ;
                const endScaleX = property.endX !== undefined ? property.endX : currentTransform.scaleX;
                const endScaleY = property.endY !== undefined ? property.endY : currentTransform.scaleY;
                const endScaleZ = property.endZ !== undefined ? property.endZ : currentTransform.scaleZ;

                startTransform = buildTransformString(currentTransform.x, currentTransform.y, currentTransform.z,
                    startScaleX, startScaleY, startScaleZ,
                    currentTransform.rotationX, currentTransform.rotationY, currentTransform.rotationZ);
                endTransform = buildTransformString(currentTransform.x, currentTransform.y, currentTransform.z,
                    endScaleX, endScaleY, endScaleZ,
                    currentTransform.rotationX, currentTransform.rotationY, currentTransform.rotationZ);
                break;

            case 'rotate':
                const startRotX = property.startX !== undefined ? property.startX : currentTransform.rotationX;
                const startRotY = property.startY !== undefined ? property.startY : currentTransform.rotationY;
                const startRotZ = property.startZ !== undefined ? property.startZ : currentTransform.rotationZ;
                const endRotX = property.endX !== undefined ? property.endX : currentTransform.rotationX;
                const endRotY = property.endY !== undefined ? property.endY : currentTransform.rotationY;
                const endRotZ = property.endZ !== undefined ? property.endZ : currentTransform.rotationZ;

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
            fill: 'forwards'
        });
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
                    const startValue = property.startValue !== undefined ? property.startValue : 1;
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
                    const startColor = property.startColor || 'transparent';
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
                    const startColor = property.startColor || 'rgba(0, 0, 0, 1)';
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
                keyframes = [
                    {
                        width: window.getComputedStyle(element).width,
                        height: window.getComputedStyle(element).height
                    },
                    {
                        width: `${property.endWidth}px`,
                        height: `${property.endHeight}px`
                    }
                ];
                animationEasing = easingFunctions[easing] || easing;
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
    function buildTransformString(x, y, z, scaleX, scaleY, scaleZ, rotationX, rotationY, rotationZ) {
        const parts = [];

        // Position: use translate3d for hardware acceleration
        if (x !== 0 || y !== 0 || z !== 0) {
            parts.push(`translate3d(${x}px, ${y}px, ${z}px)`);
        }

        // Rotation: apply in order X, Y, Z for consistent results
        if (rotationX !== 0) {
            parts.push(`rotateX(${rotationX}deg)`);
        }
        if (rotationY !== 0) {
            parts.push(`rotateY(${rotationY}deg)`);
        }
        if (rotationZ !== 0) {
            parts.push(`rotateZ(${rotationZ}deg)`);
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
     * Get current transform state of an element with 3D support
     */
    function getCurrentTransform(element) {
        const style = window.getComputedStyle(element);
        const transform = style.transform;

        if (transform === 'none' || !transform) {
            return {
                transform: 'none',
                x: 0, y: 0, z: 0,
                scaleX: 1, scaleY: 1, scaleZ: 1,
                rotationX: 0, rotationY: 0, rotationZ: 0
            };
        }

        // Parse transform matrix (2D or 3D)
        const matrix2d = transform.match(/matrix\((.+)\)/);
        const matrix3d = transform.match(/matrix3d\((.+)\)/);

        if (matrix3d) {
            // 3D matrix: matrix3d(m11, m12, m13, m14, m21, m22, m23, m24, m31, m32, m33, m34, m41, m42, m43, m44)
            const values = matrix3d[1].split(', ').map(parseFloat);

            if (values.length === 16) {
                // Extract translation (m41, m42, m43)
                const tx = values[12] || 0;
                const ty = values[13] || 0;
                const tz = values[14] || 0;

                // Extract scale (approximation from first 3 diagonal elements)
                const scaleX = Math.sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2]);
                const scaleY = Math.sqrt(values[4] * values[4] + values[5] * values[5] + values[6] * values[6]);
                const scaleZ = Math.sqrt(values[8] * values[8] + values[9] * values[9] + values[10] * values[10]);

                // For 3D rotations, we'll approximate with simple extraction
                // This is complex for full 3D rotation extraction, so we'll provide basic support
                let rotationX = 0, rotationY = 0, rotationZ = 0;

                // Simple Z rotation extraction (most common)
                if (scaleX !== 0 && scaleY !== 0) {
                    rotationZ = Math.atan2(values[1] / scaleX, values[0] / scaleX) * (180 / Math.PI);
                }

                return { transform, x: tx, y: ty, z: tz, scaleX, scaleY, scaleZ, rotationX, rotationY, rotationZ };
            }
        } else if (matrix2d) {
            // 2D matrix: matrix(a, b, c, d, tx, ty)
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
                const rotationZ = Math.atan2(b, a) * (180 / Math.PI);

                return {
                    transform,
                    x: tx, y: ty, z: 0,
                    scaleX, scaleY, scaleZ: 1,
                    rotationX: 0, rotationY: 0, rotationZ
                };
            }
        }

        return {
            transform,
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotationX: 0, rotationY: 0, rotationZ: 0
        };
    }

    /**
     * Set up animation event listeners and property updates with version tracking
     */
    function setupAnimationEvents(elementId, propertyType, element, animation, version) {
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
                    const elementAnims = activeAnimations.get(elementId);
                    if (elementAnims) {
                        elementAnims.forEach((animData, propType) => {
                            propertyVersions[propType] = animData.version;
                        });
                    }

                    const propertyData = {
                        elementId: elementId,
                        position: {
                            x: transformState.x,
                            y: transformState.y,
                            z: transformState.z
                        },
                        opacity: parseFloat(computedStyle.opacity),
                        rotation: {
                            x: transformState.rotationX,
                            y: transformState.rotationY,
                            z: transformState.rotationZ
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

        // Start sending updates
        rafId = requestAnimationFrame(sendAnimationUpdate);

        // Return the update function so it can be restarted on resume
        return sendAnimationUpdate;

        // Handle animation completion
        animation.addEventListener('finish', () => {
            // Only remove THIS property's animation if version matches
            // (prevents removing newer animation if finish event fires late)
            const elementAnims = activeAnimations.get(elementId);
            if (elementAnims) {
                const current = elementAnims.get(propertyType);
                if (current && current.version === version) {
                    elementAnims.delete(propertyType);

                    // If no more properties animating, clean up element entry
                    if (elementAnims.size === 0) {
                        activeAnimations.delete(elementId);
                    }
                }
            }

            if (updatePort) {
                const finalState = getCurrentTransform(element);
                const computedStyle = window.getComputedStyle(element);

                // Collect remaining property versions
                const propertyVersions = {};
                const remainingAnims = activeAnimations.get(elementId);
                if (remainingAnims) {
                    remainingAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }
                // Include the completed property with its version one last time
                propertyVersions[propertyType] = version;

                const finalPropertyData = {
                    elementId: elementId,
                    position: {
                        x: finalState.x,
                        y: finalState.y,
                        z: finalState.z
                    },
                    opacity: parseFloat(computedStyle.opacity),
                    rotation: {
                        x: finalState.rotationX,
                        y: finalState.rotationY,
                        z: finalState.rotationZ
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
            // Only remove THIS property's animation if version matches
            // (prevents removing newer animation if cancel event fires late)
            const elementAnims = activeAnimations.get(elementId);
            if (elementAnims) {
                const current = elementAnims.get(propertyType);
                if (current && current.version === version) {
                    elementAnims.delete(propertyType);

                    // If no more properties animating, clean up element entry
                    if (elementAnims.size === 0) {
                        activeAnimations.delete(elementId);
                    }
                }
            }

            if (updatePort) {
                const currentState = getCurrentTransform(element);
                const computedStyle = window.getComputedStyle(element);

                // Collect remaining property versions
                const propertyVersions = {};
                const remainingAnims = activeAnimations.get(elementId);
                if (remainingAnims) {
                    remainingAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }
                // Include the cancelled property with its version one last time
                propertyVersions[propertyType] = version;

                const currentPropertyData = {
                    elementId: elementId,
                    position: {
                        x: currentState.x,
                        y: currentState.y,
                        z: currentState.z
                    },
                    opacity: parseFloat(computedStyle.opacity),
                    rotation: {
                        x: currentState.rotationX,
                        y: currentState.rotationY,
                        z: currentState.rotationZ
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
    }
    /**
     * Send event to Elm via consolidated waapiEvent port
     */
    function sendEventToElm(eventType, elementId, payload) {
        if (window.app && window.app.ports && window.app.ports.waapiEvent) {
            const eventData = {
                type: eventType,
                elementId: elementId,
                payload: payload || null
            };
            window.app.ports.waapiEvent.send(eventData);
        }
    }

    /**
     * Stop animation by jumping to end state
     */
    function stopAnimation(elementId) {
        const elementAnims = activeAnimations.get(elementId);
        if (elementAnims) {
            elementAnims.forEach((animData, propertyType) => {
                animData.animation.finish(); // Jump to end state
            });
            activeAnimations.delete(elementId);
        }
    }

    /**
     * Reset animation by jumping to start state  
     */
    function resetAnimation(elementId) {
        const elementAnims = activeAnimations.get(elementId);
        if (elementAnims) {
            elementAnims.forEach((animData, propertyType) => {
                animData.animation.cancel(); // Cancel to jump to start
            });
            activeAnimations.delete(elementId);
        }
    }

    /**
     * Restart animation from beginning
     */
    function restartAnimation(elementId) {
        const elementAnims = activeAnimations.get(elementId);
        if (elementAnims) {
            elementAnims.forEach((animData, propertyType) => {
                animData.animation.cancel(); // Cancel first
                animData.animation.play();   // Then replay
            });
        }
    }

    /**
     * Pause animation for specific element
     */
    function pauseAnimation(elementId) {
        const elementAnims = activeAnimations.get(elementId);
        if (elementAnims) {
            elementAnims.forEach((animData, propertyType) => {
                animData.animation.pause();
            });
            // Send paused status to Elm
            sendEventToElm('animationUpdate', elementId, { status: 'paused' });
        }
    }

    /**
     * Resume animation for specific element
     */
    function resumeAnimation(elementId) {
        const elementAnims = activeAnimations.get(elementId);
        if (elementAnims) {
            elementAnims.forEach((animData, propertyType) => {
                animData.animation.play();
                // Restart the RAF update loop
                if (animData.updateFn) {
                    animData.updateFn();
                }
            });
            // Send resumed status to Elm
            sendEventToElm('animationUpdate', elementId, { status: 'resumed' });
        }
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
                    // Check if this is animation data structure (from animate, reset, restart)
                    if (commandData.elements) {
                        processAnimationData(commandData);
                    }
                    // Handle simple control commands
                    else if (commandData.type && commandData.elementId) {
                        const commandType = commandData.type;
                        const elementId = commandData.elementId;

                        switch (commandType) {
                            case 'stop':
                                stopAnimation(elementId);
                                break;
                            case 'pause':
                                pauseAnimation(elementId);
                                break;
                            case 'resume':
                                resumeAnimation(elementId);
                                break;
                            default:
                                console.warn('ElmAnimateWAAPI: Unknown control command type:', commandType);
                        }
                    } else {
                        console.warn('ElmAnimateWAAPI: Unknown command structure:', commandData);
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