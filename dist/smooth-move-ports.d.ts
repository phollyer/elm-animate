/**
 * Elm Smooth Move Ports - JavaScript companion for Web Animations API integration
 * 
 * This file provides TypeScript definitions for the smooth-move-ports.js library
 * that enables Elm applications to use the Web Animations API via ports.
 */

export interface ElmApp {
    ports?: {
        smoothMoveAnimate?: {
            subscribe: (callback: (data: AnimationData) => void) => void;
        };
        smoothMoveAnimateBatch?: {
            subscribe: (callback: (data: AnimationData[]) => void) => void;
        };
        smoothMoveStop?: {
            subscribe: (callback: (elementId: string) => void) => void;
        };
        smoothMoveStopBatch?: {
            subscribe: (callback: (elementIds: string[]) => void) => void;
        };
    };
}

export interface AnimationData {
    elementId: string;
    x: number;
    y: number;
    duration?: number;
    easing?: string;
}

export interface SmoothMovePorts {
    /**
     * Initialize the SmoothMovePorts system with an Elm app
     * @param app - The Elm application with ports defined
     */
    init(app: ElmApp): void;

    /**
     * Animate a single element to a new position
     * @param elementId - The ID of the element to animate
     * @param x - Target X position
     * @param y - Target Y position
     * @param duration - Animation duration in milliseconds (optional)
     * @param easing - CSS easing function (optional)
     */
    animateElement(
        elementId: string,
        x: number,
        y: number,
        duration?: number,
        easing?: string
    ): void;

    /**
     * Stop animation for a specific element
     * @param elementId - The ID of the element to stop
     */
    stopElement(elementId: string): void;

    /**
     * Stop all running animations
     */
    stopAll(): void;
}

declare global {
    interface Window {
        SmoothMovePorts: SmoothMovePorts;
    }
}

export default SmoothMovePorts;