/**
 * Elm Motion WAAPI - JavaScript companion for Web Animations API integration
 *
 * Source-of-truth TypeScript declarations.
 * Synced to dist/elm-motion.d.ts during npm run build.
 */

export interface ElmPorts {
    waapiCommand?: {
        subscribe: (callback: (data: any) => void) => void;
    };
    waapiEvent?: {
        send: (update: any) => void;
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
    easingKeyframes?: number[];
    perspective?: PerspectiveConfig;
}

export interface AnimationUpdate {
    elementId: string;
    positionX: number;
    positionY: number;
    positionZ: number;
    opacity: number;
    rotationX: number;
    rotationY: number;
    rotationZ: number;
    scaleX: number;
    scaleY: number;
    scaleZ: number;
    backgroundColor: string;
    color: string;
    width: number;
    height: number;
    isAnimating: boolean;
}

export interface TransformState {
    transform: string;
    x: number;
    y: number;
    z: number;
    scaleX: number;
    scaleY: number;
    scaleZ: number;
    rotationX: number;
    rotationY: number;
    rotationZ: number;
}

export interface ElmMotion {
    init(ports: ElmPorts): void;
    getCurrentTransform(element: Element): TransformState;
    stopAnimation(elementId: string): void;
    resetAnimation(elementId: string): void;
    restartAnimation(elementId: string): void;
    pauseAnimation(elementId: string): void;
    resumeAnimation(elementId: string): void;
    activeAnimations: Map<string, Map<string, { animation: Animation; version: number; updateFn: () => void }>>;
    addEasingFunction(name: string, cssValue: string): void;
}

declare global {
    interface Window {
        ElmMotion: ElmMotion;
        app?: ElmApp;
    }
}

export default ElmMotion;