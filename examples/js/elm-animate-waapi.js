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
     */
    function processElementAnimation(elementId, elementConfig) {
        const element = document.getElementById(elementId);
        if (!element) {
            console.warn(`ElmAnimateWAAPI: Element with id "${elementId}" not found`);
            return;
        }

        // Stop any existing animation for this element
        stopAnimation(elementId);

        // Group properties that can be animated together (transforms)
        const transforms = [];
        const separateAnimations = [];

        elementConfig.properties.forEach(property => {
            if (property.type === 'position' || property.type === 'scale' || property.type === 'rotate') {
                transforms.push(property);
            } else {
                separateAnimations.push(property);
            }
        });

        const animations = [];

        // Create combined transform animation if we have transform properties
        if (transforms.length > 0) {
            const transformAnimation = createTransformAnimation(element, transforms);
            if (transformAnimation) {
                animations.push(transformAnimation);
            }
        }

        // Create separate animations for non-transform properties
        separateAnimations.forEach(property => {
            const animation = createPropertyAnimation(element, property);
            if (animation) {
                animations.push(animation);
            }
        });

        // Store and set up animations
        if (animations.length > 0) {
            activeAnimations.set(elementId, animations);
            setupAnimationEvents(elementId, element, animations[0]); // Use first animation for events

            // Send AnimationStart event to Elm
            sendEventToElm('animationUpdate', elementId, { status: 'started' });
        } else {
            // Clear any existing animations for this element
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
     * Set up animation event listeners and property updates
     */
    function setupAnimationEvents(elementId, element, animation) {
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

        function sendAnimationUpdate() {
            const now = performance.now();
            if (now - lastTime >= updateInterval) {
                const transformState = getCurrentTransform(element);
                const computedStyle = window.getComputedStyle(element);

                if (updatePort) {
                    const propertyData = {
                        elementId: elementId,
                        positionX: transformState.x,
                        positionY: transformState.y,
                        positionZ: transformState.z,
                        opacity: parseFloat(computedStyle.opacity),
                        rotationX: transformState.rotationX,
                        rotationY: transformState.rotationY,
                        rotationZ: transformState.rotationZ,
                        scaleX: transformState.scaleX,
                        scaleY: transformState.scaleY,
                        scaleZ: transformState.scaleZ,
                        backgroundColor: computedStyle.backgroundColor,
                        color: computedStyle.color,
                        width: parseFloat(computedStyle.width),
                        height: parseFloat(computedStyle.height),
                        isAnimating: true
                    };
                    sendEventToElm('propertyUpdate', elementId, propertyData);
                }
                lastTime = now;
            }

            if (animation.playState === 'running') {
                requestAnimationFrame(sendAnimationUpdate);
            }
        }

        // Start sending updates
        requestAnimationFrame(sendAnimationUpdate);

        // Handle animation completion
        animation.addEventListener('finish', () => {
            activeAnimations.delete(elementId);

            sendEventToElm('animationUpdate', elementId, { status: 'completed' });

            if (updatePort) {
                const finalState = getCurrentTransform(element);
                const computedStyle = window.getComputedStyle(element);

                const finalPropertyData = {
                    elementId: elementId,
                    positionX: finalState.x,
                    positionY: finalState.y,
                    positionZ: finalState.z,
                    opacity: parseFloat(computedStyle.opacity),
                    rotationX: finalState.rotationX,
                    rotationY: finalState.rotationY,
                    rotationZ: finalState.rotationZ,
                    scaleX: finalState.scaleX,
                    scaleY: finalState.scaleY,
                    scaleZ: finalState.scaleZ,
                    backgroundColor: computedStyle.backgroundColor,
                    color: computedStyle.color,
                    width: parseFloat(computedStyle.width),
                    height: parseFloat(computedStyle.height),
                    isAnimating: false
                };
                sendEventToElm('propertyUpdate', elementId, finalPropertyData);
            }
        });

        animation.addEventListener('cancel', () => {
            activeAnimations.delete(elementId);

            if (updatePort) {
                const currentState = getCurrentTransform(element);
                const computedStyle = window.getComputedStyle(element);

                const currentPropertyData = {
                    elementId: elementId,
                    positionX: currentState.x,
                    positionY: currentState.y,
                    positionZ: currentState.z,
                    opacity: parseFloat(computedStyle.opacity),
                    rotationX: currentState.rotationX,
                    rotationY: currentState.rotationY,
                    rotationZ: currentState.rotationZ,
                    scaleX: currentState.scaleX,
                    scaleY: currentState.scaleY,
                    scaleZ: currentState.scaleZ,
                    backgroundColor: computedStyle.backgroundColor,
                    color: computedStyle.color,
                    width: parseFloat(computedStyle.width),
                    height: parseFloat(computedStyle.height),
                    isAnimating: false
                };
                sendEventToElm('propertyUpdate', elementId, currentPropertyData);
            }
        });
    }

    /**
     * Stop animation for specific element
     */
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
        } else {
            console.warn('❌ DEBUG: waapiEvent port not found or not available');
        }
    }

    /**
     * Stop animation by jumping to end state
     */
    function stopAnimation(elementId) {
        const animations = activeAnimations.get(elementId);
        if (animations) {
            if (Array.isArray(animations)) {
                animations.forEach(animation => {
                    animation.finish(); // Jump to end state
                });
            } else {
                animations.finish();
            }
            activeAnimations.delete(elementId);

            // Send AnimationCancel event to Elm
            sendEventToElm('animationUpdate', elementId, { status: 'canceled' });
        }
    }

    /**
     * Reset animation by jumping to start state
     */
    function resetAnimation(elementId) {
        const animations = activeAnimations.get(elementId);
        if (animations) {
            if (Array.isArray(animations)) {
                animations.forEach(animation => {
                    animation.cancel(); // Cancel to jump to start
                });
            } else {
                animations.cancel();
            }
            activeAnimations.delete(elementId);
            // Send event to notify Elm that animation was reset
            sendEventToElm('animationUpdate', elementId, { status: 'canceled' });
        }
    }

    /**
     * Restart animation from beginning
     */
    function restartAnimation(elementId) {
        const animations = activeAnimations.get(elementId);
        if (animations) {
            if (Array.isArray(animations)) {
                animations.forEach(animation => {
                    animation.cancel(); // Cancel first
                    animation.play();   // Then replay
                });
            } else {
                animations.cancel();
                animations.play();
            }
            sendEventToElm('animationUpdate', elementId, { status: 'restarted' });
        } else {
            // No active animation to restart - just send a completed event
            sendEventToElm('animationUpdate', elementId, { status: 'completed' });
        }
    }

    /**
     * Pause animation for specific element
     */
    function pauseAnimation(elementId) {
        const animations = activeAnimations.get(elementId);
        if (animations) {
            if (Array.isArray(animations)) {
                animations.forEach(animation => {
                    animation.pause();
                });
            } else {
                animations.pause();
            }
            sendEventToElm('animationUpdate', elementId, { status: 'paused' });
        }
    }

    /**
     * Resume animation for specific element
     */
    function resumeAnimation(elementId) {
        const animations = activeAnimations.get(elementId);
        if (animations) {
            if (Array.isArray(animations)) {
                animations.forEach(animation => {
                    animation.play();
                });
            } else {
                animations.play();
            }
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
                console.log('🔍 WAAPI Command Received:', JSON.stringify(commandData, null, 2));
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

        console.log('ElmAnimateWAAPI initialized successfully with consolidated ports');
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