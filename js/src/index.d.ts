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
    type: 'translate' | 'scale' | 'rotate' | 'skew' | 'opacity' | 'size' | 'customProperty' | 'customColorProperty' | 'perspectiveOrigin';
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
    // Opacity/custom color properties
    endValue?: number;
    startValue?: number;
    cssProperty?: string;
    unit?: string;
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

export type ErrorSeverity = 'error' | 'warning';

export type ErrorSource =
    | 'init'
    | 'waapiCommand'
    | 'animation'
    | 'scrollDriven'
    | 'viewDriven'
    | 'polyfill'
    | 'unknown';

export interface ErrorContext {
    source: ErrorSource | string;
    severity: ErrorSeverity;
    code?: string;
    commandType?: string;
    elementId?: string;
    engine?: 'WAAPI' | 'ScrollTimeline' | 'ViewTimeline';
    details?: Record<string, unknown>;
}

export type ErrorHandler = (error: Error, context: ErrorContext) => void;

export type Unsubscribe = () => void;

export interface ConsoleReporterOptions {
    /** When true, log the full Error and context object. Defaults to false (compact summary). */
    verbose?: boolean;
    /** Console-like target. Defaults to the global `console`. */
    target?: Pick<Console, 'warn' | 'error'>;
}

export interface ElmMotion {
    init(ports: ElmPorts): void;
    /**
     * Register a subscriber to receive ElmMotion error reports.
     * Returns an unsubscribe function. Multiple subscribers may be registered.
     */
    onError(handler: ErrorHandler): Unsubscribe;
    /**
     * Enable the built-in console reporter. Opt-in; the package is silent by default.
     * Returns an unsubscribe function.
     */
    useConsoleReporter(options?: ConsoleReporterOptions): Unsubscribe;
}

declare global {
    interface Window {
        ElmMotion: ElmMotion;
        app?: ElmApp;
    }
}

export default ElmMotion;