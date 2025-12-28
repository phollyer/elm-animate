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
    globalTiming?: TimingConfig;
    globalEasing?: string;
    globalDelay?: number;
}

export interface ElementConfig {
    properties: PropertyAnimation[];
}

export interface PropertyAnimation {
    type: 'position' | 'scale' | 'rotate' | 'opacity' | 'color' | 'size';
    target: PositionTarget | ScaleTarget | RotateTarget | number | string | SizeTarget; // Typed targets
    timing?: TimingConfig;
    easing?: string;
    delay?: number;
}

export interface TimingConfig {
    value: number;
}

export interface PositionTarget {
    x: number;
    y: number;
    z?: number; // Optional for 3D positioning
}

export interface ScaleTarget {
    x: number;
    y: number;
    z?: number; // Optional for 3D scaling
}

export interface RotateTarget {
    x?: number; // Optional X-axis rotation in degrees
    y?: number; // Optional Y-axis rotation in degrees
    z?: number; // Optional Z-axis rotation in degrees
}

export interface SizeTarget {
    width: number;
    height: number;
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