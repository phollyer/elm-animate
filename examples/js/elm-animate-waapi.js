/**
 * ElmAnimateWAAPI JavaScript Integration
 * 
 * This file provides the JavaScript side of port-based animations for the
 * ElmAnimateWAAPI Elm module. It uses the Web Animations API for high-performance
 * hardware-accelerated animations.
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

    // Default easing functions mapping
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
     * Parse animation commands from Elm
     * Supports multiple property types: position, scale, rotation, color, opacity
     */
    function parseAnimationCommands(commandsArray) {
        return commandsArray.map(commandString => {
            const parts = commandString.split(':');
            const propertyType = parts[0];
            const elementId = parts[1];

            switch (propertyType) {
                case 'position':
                    return {
                        type: 'position',
                        elementId: elementId,
                        targetX: parseFloat(parts[2]),
                        targetY: parseFloat(parts[3]),
                        duration: parseFloat(parts[4]),
                        easing: parts[5],
                        axis: parts[6] || 'both'
                    };
                case 'scale':
                    return {
                        type: 'scale',
                        elementId: elementId,
                        targetX: parseFloat(parts[2]),
                        targetY: parseFloat(parts[3]),
                        duration: parseFloat(parts[4]),
                        easing: parts[5]
                    };
                case 'rotation':
                    return {
                        type: 'rotation',
                        elementId: elementId,
                        target: parseFloat(parts[2]),
                        duration: parseFloat(parts[3]),
                        easing: parts[4]
                    };
                case 'opacity':
                    return {
                        type: 'opacity',
                        elementId: elementId,
                        target: parseFloat(parts[2]),
                        duration: parseFloat(parts[3]),
                        easing: parts[4]
                    };
                case 'color':
                    return {
                        type: 'color',
                        elementId: elementId,
                        target: parts[2], // hex color string
                        duration: parseFloat(parts[3]),
                        easing: parts[4]
                    };
                default:
                    console.warn(`Unknown property type: ${propertyType}`);
                    return null;
            }
        }).filter(cmd => cmd !== null);
    }

    /**
     * Get element's current transform values
     */
    function getCurrentTransforms(element) {
        const style = window.getComputedStyle(element);
        const transform = style.transform;

        const defaults = {
            translateX: 0,
            translateY: 0,
            scaleX: 1,
            scaleY: 1,
            rotate: 0
        };

        if (transform === 'none') {
            return defaults;
        }

        // Parse transform matrix for current values
        const matrix = transform.match(/matrix.*\((.+)\)/);
        if (matrix) {
            const values = matrix[1].split(', ').map(parseFloat);
            if (values.length >= 6) {
                return {
                    translateX: values[4] || 0,
                    translateY: values[5] || 0,
                    scaleX: Math.sqrt(values[0] * values[0] + values[1] * values[1]) || 1,
                    scaleY: Math.sqrt(values[2] * values[2] + values[3] * values[3]) || 1,
                    rotate: Math.atan2(values[1], values[0]) * (180 / Math.PI) || 0
                };
            }
        }

        return defaults;
    }

    /**
     * Get element's current position from left/top style properties (container-relative)
     */
    function getCurrentElementPosition(element) {
        const style = window.getComputedStyle(element);
        return {
            x: parseFloat(style.left) || 0,
            y: parseFloat(style.top) || 0
        };
    }

    /**
     * Create keyframes for different animation types
     */
    function createKeyframes(element, command) {
        const style = window.getComputedStyle(element);

        switch (command.type) {
            case 'position':
                const currentPos = getCurrentElementPosition(element);
                const startFrame = {
                    left: currentPos.x + 'px',
                    top: currentPos.y + 'px'
                };

                let endFrame;
                switch (command.axis) {
                    case 'x':
                        endFrame = {
                            left: command.targetX + 'px',
                            top: currentPos.y + 'px'
                        };
                        break;
                    case 'y':
                        endFrame = {
                            left: currentPos.x + 'px',
                            top: command.targetY + 'px'
                        };
                        break;
                    case 'both':
                    default:
                        endFrame = {
                            left: command.targetX + 'px',
                            top: command.targetY + 'px'
                        };
                        break;
                }
                return [startFrame, endFrame];

            case 'scale':
                const currentTransforms = getCurrentTransforms(element);
                return [
                    { transform: `scale(${currentTransforms.scaleX}, ${currentTransforms.scaleY})` },
                    { transform: `scale(${command.targetX}, ${command.targetY})` }
                ];

            case 'rotation':
                const currentRotation = getCurrentTransforms(element).rotate;
                return [
                    { transform: `rotate(${currentRotation}deg)` },
                    { transform: `rotate(${command.target}deg)` }
                ];

            case 'opacity':
                const currentOpacity = parseFloat(style.opacity) || 1;
                return [
                    { opacity: currentOpacity },
                    { opacity: command.target }
                ];

            case 'color':
                const currentColor = style.backgroundColor || 'rgb(255, 255, 255)';
                return [
                    { backgroundColor: currentColor },
                    { backgroundColor: command.target }
                ];

            default:
                console.warn(`Unsupported animation type: ${command.type}`);
                return [{}];
        }
    }

    /**
     * Combine keyframes from multiple property commands
     */
    function combinePropertyKeyframes(element, commands) {
        const startFrame = {};
        const endFrame = {};

        commands.forEach(command => {
            const keyframes = createKeyframes(element, command);
            if (keyframes && keyframes.length >= 2) {
                Object.assign(startFrame, keyframes[0]);
                Object.assign(endFrame, keyframes[1]);
            }
        });

        return [startFrame, endFrame];
    }

    /**
     * Animate element using Web Animations API with multiple property support
     */
    function animateElement(commandsData, positionUpdatePort) {
        // Parse the commands array from Elm
        const commands = parseAnimationCommands(commandsData);

        // Group commands by element ID
        const elementCommands = new Map();
        commands.forEach(cmd => {
            if (!elementCommands.has(cmd.elementId)) {
                elementCommands.set(cmd.elementId, []);
            }
            elementCommands.get(cmd.elementId).push(cmd);
        });

        // Animate each element with its combined properties
        elementCommands.forEach((commands, elementId) => {
            const element = document.getElementById(elementId);
            if (!element) {
                console.warn(`ElmAnimateWAAPI: Element with id "${elementId}" not found`);
                return;
            }

            // Stop any existing animation for this element
            stopAnimation(elementId);

            // Combine all keyframes for multiple properties
            const combinedKeyframes = combinePropertyKeyframes(element, commands);

            // Get duration and easing (use first command's values)
            const duration = commands[0].duration;
            const easing = easingFunctions[commands[0].easing] || commands[0].easing;

            // Create animation
            const animation = element.animate(combinedKeyframes, {
                duration: duration,
                easing: easing,
                fill: 'forwards'
            });

            // Store animation reference
            activeAnimations.set(elementId, animation);

            // Send position updates during animation (for position properties only)
            const hasPositionCommand = commands.some(cmd => cmd.type === 'position');
            if (hasPositionCommand && positionUpdatePort) {
                let lastTime = 0;
                const updateInterval = 16; // ~60fps

                function sendPositionUpdate() {
                    const now = performance.now();
                    if (now - lastTime >= updateInterval) {
                        const currentPos = getCurrentElementPosition(element);
                        positionUpdatePort.send({
                            elementId: elementId,
                            x: currentPos.x,
                            y: currentPos.y,
                            isAnimating: true
                        });
                        lastTime = now;
                    }

                    if (animation.playState === 'running') {
                        requestAnimationFrame(sendPositionUpdate);
                    }
                }

                requestAnimationFrame(sendPositionUpdate);
            }

            // Handle animation completion
            animation.addEventListener('finish', function () {
                activeAnimations.delete(elementId);

                if (hasPositionCommand && positionUpdatePort) {
                    const currentPos = getCurrentElementPosition(element);
                    positionUpdatePort.send({
                        elementId: elementId,
                        x: currentPos.x,
                        y: currentPos.y,
                        isAnimating: false
                    });
                }
            });

            animation.addEventListener('cancel', function () {
                activeAnimations.delete(elementId);

                if (hasPositionCommand && positionUpdatePort) {
                    const currentPos = getCurrentElementPosition(element);
                    positionUpdatePort.send({
                        elementId: elementId,
                        x: currentPos.x,
                        y: currentPos.y,
                        isAnimating: false
                    });
                }
            });
        });
    }

    /**
     * Stop animation for specific element
     */
    function stopAnimation(elementId) {
        const animation = activeAnimations.get(elementId);
        if (animation) {
            animation.cancel();
            activeAnimations.delete(elementId);
        }
    }

    /**
     * Initialize ElmAnimateWAAPI with Elm ports
     * 
     * Required ports in your Elm app:
     * 
     * port animateElement : String -> Cmd msg
     * port stopElementAnimation : String -> Cmd msg  
     * port positionUpdates : (Value -> msg) -> Sub msg
     * 
     * @param {Object} ports - The Elm app's ports object
     */
    function init(ports) {
        if (!ports) {
            throw new Error('ElmAnimateWAAPI.init() requires the Elm ports object');
        }

        // Check for Web Animations API support
        if (!Element.prototype.animate) {
            console.warn('ElmAnimateWAAPI: Web Animations API not supported. Consider using a polyfill.');
            return;
        }

        // Subscribe to animation commands from Elm
        if (ports.animateElement && ports.animateElement.subscribe) {
            ports.animateElement.subscribe(function (commandsData) {
                animateElement(commandsData, ports.positionUpdates);
            });
        } else {
            console.warn('ElmAnimateWAAPI: animateElement port not found or not subscribeable');
        }

        // Subscribe to stop commands from Elm
        if (ports.stopElement && ports.stopElement.subscribe) {
            ports.stopElement.subscribe(function (elementId) {
                stopAnimation(elementId);
            });
        } else {
            console.warn('ElmAnimateWAAPI: stopElement port not found or not subscribeable');
        }

        console.log('ElmAnimateWAAPI initialized successfully');
    }

    /**
     * Public API
     */
    return {
        init: init,
        stopAnimation: stopAnimation,
        activeAnimations: activeAnimations,
        addEasingFunction: function (name, cssValue) {
            easingFunctions[name] = cssValue;
        }
    };
})();