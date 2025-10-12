/**
 * SmoothMovePorts JavaScript Integration
 * 
 * This file provides the JavaScript side of port-based animations for the
 * SmoothMovePorts Elm module. It uses the Web Animations API for high-performance
 * hardware-accelerated animations.
 * 
 * Usage:
 * 1. Include this file in your HTML
 * 2. Call SmoothMovePorts.init(app.ports) after initializing your Elm app
 * 3. Define the required ports in your Elm application
 */

window.SmoothMovePorts = (function () {
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
     * Parse animation command string from Elm
     * Format: "elementId:targetX:targetY:duration:easing:axis"
     */
    function parseAnimationCommand(commandString) {
        const parts = commandString.split(':');
        return {
            elementId: parts[0],
            targetX: parseFloat(parts[1]),
            targetY: parseFloat(parts[2]),
            duration: parseFloat(parts[3]),
            easing: parts[4],
            axis: parts[5]
        };
    }

    /**
     * Get element's current position
     */
    function getCurrentPosition(element) {
        const style = window.getComputedStyle(element);
        const transform = style.transform;

        if (transform === 'none') {
            return { x: 0, y: 0 };
        }

        // Parse transform matrix
        const matrix = transform.match(/matrix.*\((.+)\)/);
        if (matrix) {
            const values = matrix[1].split(', ');
            return {
                x: parseFloat(values[4]) || 0,
                y: parseFloat(values[5]) || 0
            };
        }

        return { x: 0, y: 0 };
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
     * Create keyframes for animation based on axis constraint
     */
    function createKeyframes(currentPos, targetX, targetY, axis) {
        const startFrame = {
            left: currentPos.x + 'px',
            top: currentPos.y + 'px'
        };

        let endFrame;
        switch (axis) {
            case 'x':
                endFrame = {
                    left: targetX + 'px',
                    top: currentPos.y + 'px'
                };
                break;
            case 'y':
                endFrame = {
                    left: currentPos.x + 'px',
                    top: targetY + 'px'
                };
                break;
            case 'both':
            default:
                endFrame = {
                    left: targetX + 'px',
                    top: targetY + 'px'
                };
                break;
        }

        return [startFrame, endFrame];
    }

    /**
     * Animate element using Web Animations API
     */
    function animateElement(command, positionUpdatePort) {
        const element = document.getElementById(command.elementId);
        if (!element) {
            console.warn(`SmoothMovePorts: Element with id "${command.elementId}" not found`);
            return;
        }

        // Stop any existing animation for this element
        stopAnimation(command.elementId);

        // Get current position from the element's style (container-relative)
        const currentPos = getCurrentElementPosition(element);
        const keyframes = createKeyframes(currentPos, command.targetX, command.targetY, command.axis);

        // Get easing function
        const easing = easingFunctions[command.easing] || command.easing;

        // Create animation
        const animation = element.animate(keyframes, {
            duration: command.duration,
            easing: easing,
            fill: 'forwards'
        });

        // Store animation reference
        activeAnimations.set(command.elementId, animation);

        // Send position updates during animation (optional, for smooth integration)
        let lastTime = 0;
        const updateInterval = 16; // ~60fps

        function sendPositionUpdate() {
            const now = performance.now();
            if (now - lastTime >= updateInterval) {
                const currentPos = getCurrentElementPosition(element);
                if (positionUpdatePort) {
                    positionUpdatePort.send({
                        elementId: command.elementId,
                        x: currentPos.x,
                        y: currentPos.y,
                        isAnimating: true
                    });
                }
                lastTime = now;
            }

            if (animation.playState === 'running') {
                requestAnimationFrame(sendPositionUpdate);
            }
        }

        // Start position updates
        requestAnimationFrame(sendPositionUpdate);

        // Handle animation completion
        animation.addEventListener('finish', () => {
            activeAnimations.delete(command.elementId);

            // Send final position update
            if (positionUpdatePort) {
                positionUpdatePort.send({
                    elementId: command.elementId,
                    x: command.targetX,
                    y: command.targetY,
                    isAnimating: false
                });
            }
        });

        animation.addEventListener('cancel', () => {
            activeAnimations.delete(command.elementId);

            // Send current position when cancelled
            if (positionUpdatePort) {
                const currentPos = getCurrentElementPosition(element);
                positionUpdatePort.send({
                    elementId: command.elementId,
                    x: currentPos.x,
                    y: currentPos.y,
                    isAnimating: false
                });
            }
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
     * Initialize SmoothMovePorts with Elm ports
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
            throw new Error('SmoothMovePorts.init() requires the Elm ports object');
        }

        // Check for Web Animations API support
        if (!Element.prototype.animate) {
            console.warn('SmoothMovePorts: Web Animations API not supported. Consider using a polyfill.');
            return;
        }

        // Subscribe to animation commands from Elm
        if (ports.animateElement && ports.animateElement.subscribe) {
            ports.animateElement.subscribe(function (commandString) {
                const command = parseAnimationCommand(commandString);
                animateElement(command, ports.positionUpdates);
            });
        } else {
            console.warn('SmoothMovePorts: animateElement port not found or not subscribeable');
        }

        // Subscribe to stop commands from Elm
        if (ports.stopElementAnimation && ports.stopElementAnimation.subscribe) {
            ports.stopElementAnimation.subscribe(function (elementId) {
                stopAnimation(elementId);
            });
        } else {
            console.warn('SmoothMovePorts: stopElementAnimation port not found or not subscribeable');
        }

        console.log('SmoothMovePorts initialized successfully');
    }

    /**
     * Public API
     */
    return {
        init: init,

        // Expose utilities for advanced usage
        getCurrentPosition: getCurrentPosition,
        stopAnimation: stopAnimation,
        activeAnimations: activeAnimations,

        // Allow custom easing functions
        addEasingFunction: function (name, cssValue) {
            easingFunctions[name] = cssValue;
        }
    };
})();