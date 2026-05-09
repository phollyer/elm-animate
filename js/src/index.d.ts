/**
 * @phollyer/elm-motion - JavaScript companion for the phollyer/elm-motion Elm package.
 *
 * Source-of-truth TypeScript declarations.
 * Synced to dist/elm-motion.d.ts during npm run build.
 */

// ---------------------------------------------------------------------------
// Elm port plumbing
// ---------------------------------------------------------------------------

/** A single value emitted to Elm via the `waapiEvent` outbound port. */
export type WaapiEvent = AnimationUpdateEvent | PropertyUpdateEvent;

export interface ElmPorts {
    /** Outbound from Elm: animation/scroll commands the companion should execute. */
    waapiCommand?: {
        subscribe: (callback: (data: WaapiCommand) => void) => void;
    };
    /** Inbound to Elm: lifecycle events and per-frame property updates. */
    waapiEvent?: {
        send: (update: WaapiEvent) => void;
    };
}

export interface ElmApp {
    ports: ElmPorts;
}

// ---------------------------------------------------------------------------
// Inbound commands (Elm -> JS)
// ---------------------------------------------------------------------------

export type WaapiCommand =
    | AnimateCommand
    | ScrollDrivenCommand
    | ViewDrivenCommand
    | SetPropertiesCommand
    | ControlCommand;

export interface AnimateCommand {
    type: 'animate';
    elements: { [elementId: string]: ElementConfig };
    globalPerspective?: PerspectiveConfig;
}

export interface ScrollDrivenCommand {
    type: 'scrollDriven';
    [key: string]: unknown;
}

export interface ViewDrivenCommand {
    type: 'viewDriven';
    [key: string]: unknown;
}

export interface SetPropertiesCommand {
    type: 'setProperties';
    updates: unknown[];
}

export interface ControlCommand {
    type: 'stop' | 'reset' | 'restart' | 'pause' | 'resume';
    elementId: string;
    properties?: string[];
}

export interface ElementConfig {
    properties: PropertyAnimation[];
}

export interface PerspectiveConfig {
    containerId: string;
    value: number;
}

export interface PropertyAnimation {
    type:
    | 'translate'
    | 'scale'
    | 'rotate'
    | 'skew'
    | 'opacity'
    | 'size'
    | 'customProperty'
    | 'customColorProperty'
    | 'perspectiveOrigin';
    // 3D axis properties (translate/scale/rotate/skew share the same fields)
    endX?: number;
    endY?: number;
    endZ?: number;
    startX?: number;
    startY?: number;
    startZ?: number;
    // Size
    endWidth?: number;
    endHeight?: number;
    startWidth?: number;
    startHeight?: number;
    // Opacity / numeric custom properties
    endValue?: number;
    startValue?: number;
    cssProperty?: string;
    unit?: string;
    // Color custom properties
    endColor?: string;
    startColor?: string;
    // Animation settings
    duration: number;
    easing: string;
    easingKeyframes?: number[];
    perspective?: PerspectiveConfig;
}

// ---------------------------------------------------------------------------
// Outbound events (JS -> Elm)
// ---------------------------------------------------------------------------

export type AnimationStatus =
    | 'started'
    | 'completed'
    | 'cancelled'
    | 'paused'
    | 'resumed'
    | 'stopped'
    | 'reset'
    | 'restarted'
    | 'iteration';

/** Lifecycle / iteration events for time-based and scroll-based animations. */
export interface AnimationUpdateEvent {
    type: 'animationUpdate';
    /** Present for WAAPI ('waapi') and scroll/view-driven engines. */
    engine?: 'waapi' | 'scrollDriven' | 'viewDriven' | string;
    payload: {
        elementId: string;
        animGroup: string;
        status: AnimationStatus;
        /** 0..1 for lifecycle events; iteration count (integer) for `iteration` status. */
        progress: number;
    };
}

/** Per-frame snapshot of currently animated properties. Only animated keys are present. */
export interface PropertyUpdateEvent {
    type: 'propertyUpdate';
    elementId: string;
    animGroup: string;
    translate?: Vec3;
    rotate?: Vec3;
    skew?: Vec2;
    scale?: Vec3;
    opacity?: number;
    size?: { width: number; height: number };
    perspectiveOrigin?: { x: number; y: number; unit: 'percent' | 'px' };
    customProperties?: { [cssName: string]: number };
    customColorProperties?: { [cssName: string]: string };
    isAnimating: boolean;
    propertyVersions: { [propertyKey: string]: number };
    progress?: number;
}

export interface Vec2 {
    x: number;
    y: number;
}

export interface Vec3 {
    x: number;
    y: number;
    z: number;
}

/**
 * Internal transform-state snapshot used by `buildAnimatedPropertyData`.
 * Exposed for consumers that wrap the companion; not part of the port wire format.
 */
export interface TransformState {
    transform: string;
    x: number;
    y: number;
    z: number;
    scaleX: number;
    scaleY: number;
    scaleZ: number;
    rotateX: number;
    rotateY: number;
    rotateZ: number;
    skewX: number;
    skewY: number;
}

// ---------------------------------------------------------------------------
// Error reporting
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/**
 * Initialize the ElmMotion WAAPI companion with an Elm app's ports.
 * Subscribes to `waapiCommand` and starts driving animations.
 */
export function init(ports: ElmPorts): void;

/**
 * Tear down the JS-side state. Releases per-animation-group caches and
 * stops attempting to send events to a stale ports object. Call this when
 * the host Elm app is being unmounted (typical SPA teardown / hot-reload).
 * After dispose(), call init() again with a fresh ports object to resume.
 */
export function dispose(): void;

/**
 * Register a subscriber to receive ElmMotion error reports.
 * Returns an unsubscribe function. Multiple subscribers may be registered.
 */
export function onError(handler: ErrorHandler): Unsubscribe;

/**
 * Enable the built-in console reporter. Opt-in; the package is silent by default.
 * Returns an unsubscribe function.
 */
export function useConsoleReporter(options?: ConsoleReporterOptions): Unsubscribe;

/**
 * Set the minimum interval (in milliseconds) between per-frame `propertyUpdate`
 * events emitted to Elm during an animation.
 *
 * Pass 0 (the default) to disable throttling - one event is emitted per
 * requestAnimationFrame tick, matching the display refresh rate (60 / 120 / 144 Hz).
 *
 * Pass a positive number to cap the emission rate, e.g. 16 for ~60 Hz, 33 for
 * ~30 Hz. The visual animation runs on the browser compositor and is never
 * affected by this value; only the rate at which Elm subscribers see live
 * mid-animation values changes.
 */
export function setPropertyUpdateThrottle(intervalMs: number): void;

export interface ElmMotion {
    init(ports: ElmPorts): void;
    dispose(): void;
    onError(handler: ErrorHandler): Unsubscribe;
    useConsoleReporter(options?: ConsoleReporterOptions): Unsubscribe;
    setPropertyUpdateThrottle(intervalMs: number): void;
}

declare global {
    interface Window {
        ElmMotion: ElmMotion;
    }
}

declare const _default: ElmMotion;
export default _default;
