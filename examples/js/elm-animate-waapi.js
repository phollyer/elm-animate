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
        }
    }

    /**
     * Create combined transform animation for position, scale, and rotate
     */
    function createTransformAnimation(element, transformProperties) {
        const currentTransform = getCurrentTransform(element);
        let startTransform = '';
        let endTransform = '';

        // Default values - now including z-axis
        let translateX = currentTransform.x;
        let translateY = currentTransform.y;
        let translateZ = currentTransform.z;
        let scaleX = currentTransform.scaleX;
        let scaleY = currentTransform.scaleY;
        let scaleZ = currentTransform.scaleZ;
        let rotationX = currentTransform.rotationX;
        let rotationY = currentTransform.rotationY;
        let rotationZ = currentTransform.rotationZ;

        // Get animation config from first property (they should all be similar)
        const firstProperty = transformProperties[0];
        const duration = firstProperty.duration;
        const easing = firstProperty.easing;

        // Apply property changes
        transformProperties.forEach(property => {
            switch (property.type) {
                case 'position':
                    translateX = property.x !== undefined ? property.x : translateX;
                    translateY = property.y !== undefined ? property.y : translateY;
                    translateZ = property.z !== undefined ? property.z : translateZ;
                    break;
                case 'scale':
                    scaleX = property.x !== undefined ? property.x : scaleX;
                    scaleY = property.y !== undefined ? property.y : scaleY;
                    scaleZ = property.z !== undefined ? property.z : scaleZ;
                    break;
                case 'rotate':
                    rotationX = property.x !== undefined ? property.x : rotationX;
                    rotationY = property.y !== undefined ? property.y : rotationY;
                    rotationZ = property.z !== undefined ? property.z : rotationZ;
                    break;
            }
        });

        // Build transform strings
        startTransform = buildTransformString(currentTransform.x, currentTransform.y, currentTransform.z,
            currentTransform.scaleX, currentTransform.scaleY, currentTransform.scaleZ,
            currentTransform.rotationX, currentTransform.rotationY, currentTransform.rotationZ);
        endTransform = buildTransformString(translateX, translateY, translateZ, scaleX, scaleY, scaleZ,
            rotationX, rotationY, rotationZ);

        const keyframes = [
            { transform: startTransform },
            { transform: endTransform }
        ];

        return element.animate(keyframes, {
            duration: duration,
            easing: easingFunctions[easing] || easing,
            fill: 'forwards'
        });
    }

    /**
     * Create animation for non-transform properties
     */
    function createPropertyAnimation(element, property) {
        const duration = property.duration;
        const easing = property.easing;

        let keyframes = [];

        switch (property.type) {
            case 'opacity':
                keyframes = [
                    { opacity: window.getComputedStyle(element).opacity || '1' },
                    { opacity: property.value.toString() }
                ];
                break;

            case 'backgroundColor':
                keyframes = [
                    { backgroundColor: window.getComputedStyle(element).backgroundColor || 'transparent' },
                    { backgroundColor: property.color }
                ];
                break;

            case 'size':
                keyframes = [
                    {
                        width: window.getComputedStyle(element).width,
                        height: window.getComputedStyle(element).height
                    },
                    {
                        width: `${property.width}px`,
                        height: `${property.height}px`
                    }
                ];
                break;

            default:
                console.warn(`ElmAnimateWAAPI: Unknown property type "${property.type}"`);
                return null;
        }

        return element.animate(keyframes, {
            duration: duration,
            easing: easingFunctions[easing] || easing,
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
            window.app.ports.positionUpdates &&
            typeof window.app.ports.positionUpdates.send === 'function') {
            updatePort = window.app.ports.positionUpdates;
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
                    updatePort.send({
                        elementId: elementId,
                        x: transformState.x,
                        y: transformState.y,
                        z: transformState.z,
                        opacity: parseFloat(computedStyle.opacity),
                        rotationX: transformState.rotationX,
                        rotationY: transformState.rotationY,
                        rotationZ: transformState.rotationZ,
                        scaleX: transformState.scaleX,
                        scaleY: transformState.scaleY,
                        scaleZ: transformState.scaleZ,
                        backgroundColor: computedStyle.backgroundColor,
                        isAnimating: true
                    });
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

            if (updatePort) {
                const finalState = getCurrentTransform(element);
                const computedStyle = window.getComputedStyle(element);

                updatePort.send({
                    elementId: elementId,
                    x: finalState.x,
                    y: finalState.y,
                    z: finalState.z,
                    opacity: parseFloat(computedStyle.opacity),
                    rotationX: finalState.rotationX,
                    rotationY: finalState.rotationY,
                    rotationZ: finalState.rotationZ,
                    scaleX: finalState.scaleX,
                    scaleY: finalState.scaleY,
                    scaleZ: finalState.scaleZ,
                    backgroundColor: computedStyle.backgroundColor,
                    isAnimating: false
                });
            }
        });

        animation.addEventListener('cancel', () => {
            activeAnimations.delete(elementId);

            if (updatePort) {
                const currentState = getCurrentTransform(element);
                const computedStyle = window.getComputedStyle(element);

                updatePort.send({
                    elementId: elementId,
                    x: currentState.x,
                    y: currentState.y,
                    z: currentState.z,
                    opacity: parseFloat(computedStyle.opacity),
                    rotationX: currentState.rotationX,
                    rotationY: currentState.rotationY,
                    rotationZ: currentState.rotationZ,
                    scaleX: currentState.scaleX,
                    scaleY: currentState.scaleY,
                    scaleZ: currentState.scaleZ,
                    backgroundColor: computedStyle.backgroundColor,
                    isAnimating: false
                });
            }
        });
    }

    /**
     * Stop animation for specific element
     */
    function stopAnimation(elementId) {
        const animations = activeAnimations.get(elementId);
        if (animations) {
            if (Array.isArray(animations)) {
                animations.forEach(animation => animation.cancel());
            } else {
                animations.cancel();
            }
            activeAnimations.delete(elementId);
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

        // Subscribe to animation commands from Elm
        if (ports.animateElement && ports.animateElement.subscribe) {
            ports.animateElement.subscribe(function (animationData) {
                processAnimationData(animationData);
            });
        } else {
            console.warn('ElmAnimateWAAPI: animateElement port not found or not subscribeable');
        }

        // Subscribe to stop commands from Elm
        if (ports.stopElementAnimation && ports.stopElementAnimation.subscribe) {
            ports.stopElementAnimation.subscribe(function (elementId) {
                stopAnimation(elementId);
            });
        } else {
            console.warn('ElmAnimateWAAPI: stopElementAnimation port not found or not subscribeable');
        }

        console.log('ElmAnimateWAAPI initialized successfully with full property support');
    }

    /**
     * Public API
     */
    return {
        init: init,

        // Expose utilities for advanced usage
        getCurrentTransform: getCurrentTransform,
        stopAnimation: stopAnimation,
        activeAnimations: activeAnimations,

        // Allow custom easing functions
        addEasingFunction: function (name, cssValue) {
            easingFunctions[name] = cssValue;
        }
    };
})();