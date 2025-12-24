/* eslint-env browser */
/* global window, console, document, performance, requestAnimationFrame, Element */
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
     * Process animation data received from Elm
     */
    function processAnimationData(animationData) {
        // Handle both old string format and new object format for backward compatibility
        if (Array.isArray(animationData)) {
            // Old string array format
            animationData.forEach(commandString => {
                const command = parseOldCommandString(commandString);
                if (command) {
                    processLegacyCommand(command);
                }
            });
        } else if (animationData && animationData.elements) {
            // New structured format from Elm Builder
            Object.entries(animationData.elements).forEach(([elementId, elementConfig]) => {
                processElementAnimation(elementId, elementConfig, animationData);
            });
        }
    }

    /**
     * Parse old command string format for backward compatibility
     */
    function parseOldCommandString(commandString) {
        const parts = commandString.split(':');
        if (parts.length < 6) return null;

        return {
            type: parts[0] || 'position',
            elementId: parts[1],
            values: parts.slice(2, -3),
            duration: parseFloat(parts[parts.length - 3]),
            easing: parts[parts.length - 2],
            extra: parts[parts.length - 1]
        };
    }

    /**
     * Process legacy command format
     */
    function processLegacyCommand(command) {
        const element = document.getElementById(command.elementId);
        if (!element) {
            console.warn(`ElmAnimateWAAPI: Element with id "${command.elementId}" not found`);
            return;
        }

        let keyframes = [{}];

        switch (command.type) {
            case 'position':
                const x = parseFloat(command.values[0]) || 0;
                const y = parseFloat(command.values[1]) || 0;
                keyframes = [
                    { transform: getCurrentTransform(element).transform || 'translate(0px, 0px)' },
                    { transform: `translate(${x}px, ${y}px)` }
                ];
                break;
            default:
                console.warn(`ElmAnimateWAAPI: Legacy command type "${command.type}" not fully supported`);
                return;
        }

        const animation = element.animate(keyframes, {
            duration: command.duration,
            easing: easingFunctions[command.easing] || command.easing,
            fill: 'forwards'
        });

        activeAnimations.set(command.elementId, [animation]);
        setupAnimationEvents(command.elementId, element, animation);
    }

    /**
     * Process animation for a single element with all its properties
     */
    function processElementAnimation(elementId, elementConfig, globalConfig) {
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
            const transformAnimation = createTransformAnimation(element, transforms, globalConfig);
            if (transformAnimation) {
                animations.push(transformAnimation);
            }
        }

        // Create separate animations for non-transform properties
        separateAnimations.forEach(property => {
            const animation = createPropertyAnimation(element, property, globalConfig);
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
    function createTransformAnimation(element, transformProperties, globalConfig) {
        const currentTransform = getCurrentTransform(element);
        let startTransform = '';
        let endTransform = '';

        // Default values
        let translateX = currentTransform.x;
        let translateY = currentTransform.y;
        let scaleX = currentTransform.scaleX;
        let scaleY = currentTransform.scaleY;
        let rotation = currentTransform.rotation;

        // Get animation config from first property (they should all be similar)
        const firstProperty = transformProperties[0];
        const duration = getPropertyDuration(firstProperty, globalConfig);
        const easing = getPropertyEasing(firstProperty, globalConfig);
        const delay = getPropertyDelay(firstProperty, globalConfig);

        // Apply property changes
        transformProperties.forEach(property => {
            switch (property.type) {
                case 'position':
                    translateX = property.target.x;
                    translateY = property.target.y;
                    break;
                case 'scale':
                    scaleX = property.target.x;
                    scaleY = property.target.y;
                    break;
                case 'rotate':
                    rotation = property.target;
                    break;
            }
        });

        // Build transform strings
        startTransform = buildTransformString(currentTransform.x, currentTransform.y, currentTransform.scaleX, currentTransform.scaleY, currentTransform.rotation);
        endTransform = buildTransformString(translateX, translateY, scaleX, scaleY, rotation);

        const keyframes = [
            { transform: startTransform },
            { transform: endTransform }
        ];

        return element.animate(keyframes, {
            duration: duration,
            easing: easingFunctions[easing] || easing,
            delay: delay,
            fill: 'forwards'
        });
    }

    /**
     * Create animation for non-transform properties
     */
    function createPropertyAnimation(element, property, globalConfig) {
        const duration = getPropertyDuration(property, globalConfig);
        const easing = getPropertyEasing(property, globalConfig);
        const delay = getPropertyDelay(property, globalConfig);

        let keyframes = [];

        switch (property.type) {
            case 'opacity':
                keyframes = [
                    { opacity: window.getComputedStyle(element).opacity || '1' },
                    { opacity: property.target.toString() }
                ];
                break;

            case 'color':
                keyframes = [
                    { backgroundColor: window.getComputedStyle(element).backgroundColor || 'transparent' },
                    { backgroundColor: property.target }
                ];
                break;

            case 'size':
                keyframes = [
                    {
                        width: window.getComputedStyle(element).width,
                        height: window.getComputedStyle(element).height
                    },
                    {
                        width: `${property.target.width}px`,
                        height: `${property.target.height}px`
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
            delay: delay,
            fill: 'forwards'
        });
    }

    /**
     * Build a complete transform string
     */
    function buildTransformString(x, y, scaleX, scaleY, rotation) {
        const parts = [];
        if (x !== 0 || y !== 0) {
            parts.push(`translate(${x}px, ${y}px)`);
        }
        if (rotation !== 0) {
            parts.push(`rotate(${rotation}deg)`);
        }
        if (scaleX !== 1 || scaleY !== 1) {
            parts.push(`scale(${scaleX}, ${scaleY})`);
        }
        return parts.join(' ') || 'none';
    }

    /**
     * Extract duration from property or global config
     */
    function getPropertyDuration(property, globalConfig) {
        if (property.timing && property.timing.value) {
            return property.timing.value;
        }
        if (globalConfig && globalConfig.globalTiming && globalConfig.globalTiming.value) {
            return globalConfig.globalTiming.value;
        }
        return 1000; // default
    }

    /**
     * Extract easing from property or global config
     */
    function getPropertyEasing(property, globalConfig) {
        if (property.easing) {
            return property.easing;
        }
        if (globalConfig && globalConfig.globalEasing) {
            return globalConfig.globalEasing;
        }
        return 'ease';
    }

    /**
     * Extract delay from property or global config
     */
    function getPropertyDelay(property, globalConfig) {
        if (property.delay) {
            return property.delay;
        }
        if (globalConfig && globalConfig.globalDelay) {
            return globalConfig.globalDelay;
        }
        return 0;
    }

    /**
     * Get current transform state of an element
     */
    function getCurrentTransform(element) {
        const style = window.getComputedStyle(element);
        const transform = style.transform;

        if (transform === 'none' || !transform) {
            return { transform: 'none', x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0 };
        }

        // Parse transform matrix
        const matrix = transform.match(/matrix.*\((.+)\)/);
        if (matrix) {
            const values = matrix[1].split(', ').map(parseFloat);

            if (values.length === 6) {
                // 2D matrix: matrix(a, b, c, d, tx, ty)
                const a = values[0];
                const b = values[1];
                const c = values[2];
                const d = values[3];
                const tx = values[4] || 0;
                const ty = values[5] || 0;

                const scaleX = Math.sqrt(a * a + b * b);
                const scaleY = Math.sqrt(c * c + d * d);
                const rotation = Math.atan2(b, a) * (180 / Math.PI);

                return { transform, x: tx, y: ty, scaleX, scaleY, rotation };
            }
        }

        return { transform, x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0 };
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
                        opacity: parseFloat(computedStyle.opacity),
                        rotation: transformState.rotation,
                        scaleX: transformState.scaleX,
                        scaleY: transformState.scaleY,
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
                    opacity: parseFloat(computedStyle.opacity),
                    rotation: finalState.rotation,
                    scaleX: finalState.scaleX,
                    scaleY: finalState.scaleY,
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
                    opacity: parseFloat(computedStyle.opacity),
                    rotation: currentState.rotation,
                    scaleX: currentState.scaleX,
                    scaleY: currentState.scaleY,
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