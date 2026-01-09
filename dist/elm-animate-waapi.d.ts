/**
 * Elm Animate WAAPI - JavaScript companion for Web Animations API integration
 * 
 * This file provides TypeScript definitions for the elm-animate-waapi.js library
 * that enables Elm applications to use the Web Animations API via ports with
 * support for all animation properties including position, scale, rotation,
 * opacity, backgroundColor, and size.
 */

export interface ElmPorts {
    animateElement?: {
        subscribe: (callback: (data: AnimationData) => void) => void;
    };
    stopElementAnimation?: {
        subscribe: (callback: (elementId: string) => void) => void;
    };
    positionUpdates?: {
        send: (update: AnimationUpdate) => void;
    };
}

export interface ElmApp {
    ports: ElmPorts;
}

export interface AnimationData {
    elements: { [elementId: string]: ElementConfig };
    globalPerspective?: PerspectiveConfig;
}

export interface PerspectiveConfig {
    containerId: string;
    value: number;
}

export interface ElementConfig {
    properties: PropertyAnimation[];
}

export interface PropertyAnimation {
    type: 'position' | 'scale' | 'rotate' | 'opacity' | 'backgroundColor' | 'color' | 'size';
    // Position properties
    endX?: number;
    endY?: number;
    endZ?: number;
    startX?: number;
    startY?: number;
    startZ?: number;
    // Scale properties (using same endX/endY/endZ and startX/startY/startZ)
    // Rotation properties (using same endX/endY/endZ and startX/startY/startZ)
    // Size properties
    endWidth?: number;
    endHeight?: number;
    startWidth?: number;
    startHeight?: number;
    // Opacity/color properties
    endValue?: number;
    startValue?: number;
    endColor?: string;
    startColor?: string;
    // Animation settings
    duration: number;
    easing: string;
    easingKeyframes?: number[];  // Pre-computed keyframes for complex easings (Bounce, Elastic)
    perspective?: PerspectiveConfig;
}

export interface AnimationUpdate {
    elementId: string;
    x: number;
    y: number;
    z: number;  // 3D position support
    opacity: number;
    rotationX: number;  // 3D rotation X-axis
    rotationY: number;  // 3D rotation Y-axis
    rotationZ: number;  // 3D rotation Z-axis (backward compatible)
    scaleX: number;
    scaleY: number;
    scaleZ: number;     // 3D scale support
    backgroundColor: string;
    color: string;      // Font color updates from animations
    width: number;      // Size width updates from animations
    height: number;     // Size height updates from animations
    isAnimating: boolean;
}

export interface TransformState {
    transform: string;
    x: number;
    y: number;
    z: number;          // 3D position support
    scaleX: number;
    scaleY: number;
    scaleZ: number;     // 3D scale support
    rotationX: number;  // 3D rotation X-axis
    rotationY: number;  // 3D rotation Y-axis
    rotationZ: number;  // 3D rotation Z-axis (backward compatible)
}

export interface ElmAnimateWAAPI {
    /**
     * Initialize the WAAPI system with Elm ports
     * @param ports - The Elm application ports object
     */
    init(ports: ElmPorts): void;

    /**
     * Get current transform state of an element
     * @param element - The DOM element to analyze
     * @returns Transform state including position, scale, and rotation
     */
    getCurrentTransform(element: Element): TransformState;

    /**
     * Stop animation for a specific element
     * @param elementId - The ID of the element to stop animating
     */
    stopAnimation(elementId: string): void;

    /**
     * Map of currently active animations
     */
    activeAnimations: Map<string, Animation | Animation[]>;

    /**
     * Add a custom easing function
     * @param name - Name of the easing function
     * @param cssValue - CSS easing function value (e.g., cubic-bezier)
     */
    addEasingFunction(name: string, cssValue: string): void;
}

declare global {
    interface Window {
        ElmAnimateWAAPI: ElmAnimateWAAPI;
        app?: ElmApp;
    }
}

export default ElmAnimateWAAPI;