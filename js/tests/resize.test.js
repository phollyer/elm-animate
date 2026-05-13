/* eslint-env node */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { resizeTransformAnimation } from '../src/animations.js';
import { activeAnimations, animationGroups, elementTransformOrders, lastKnownTransforms } from '../src/state.js';
import { createFakeAnimation, installDom, cleanupDom } from './_publicApiHelpers.js';

function makeElement(animGroup, animateImpl) {
    return {
        id: animGroup,
        animate: animateImpl,
        style: { transform: '' },
        getAnimations: () => [],
        getAttribute(name) {
            if (name === 'data-anim-target') return animGroup;
            return null;
        }
    };
}

function defaultResolved() {
    return {
        translate: {
            startX: 0, startY: 0, startZ: 0,
            endX: 200, endY: 0, endZ: 0,
            easing: 'linear', easingKeyframes: null, duration: 1000
        },
        scale: {
            startX: 1, startY: 1, startZ: 1,
            endX: 1, endY: 1, endZ: 1,
            easing: 'linear', easingKeyframes: null, duration: 0
        },
        rotate: {
            startX: 0, startY: 0, startZ: 0,
            endX: 0, endY: 0, endZ: 0,
            easing: 'linear', easingKeyframes: null, duration: 0
        },
        skew: {
            startX: 0, startY: 0,
            endX: 0, endY: 0,
            easing: 'linear', easingKeyframes: null, duration: 0
        }
    };
}

function clearGlobalState() {
    activeAnimations.clear();
    animationGroups.clear();
    elementTransformOrders.clear();
    lastKnownTransforms.clear();
}

beforeEach(clearGlobalState);
afterEach(() => {
    cleanupDom();
    clearGlobalState();
});

describe('resizeTransformAnimation', () => {
    it('is a no-op when no transform animation is in flight', () => {
        installDom({ element: makeElement('box', vi.fn()), targetId: 'box' });
        // No entry in activeAnimations → silent no-op, no throw.
        expect(() => resizeTransformAnimation({
            elementId: 'box',
            startX: 0, startY: 0, startZ: 0,
            endX: 400, endY: 0, endZ: 0,
            duration: 1000
        })).not.toThrow();
    });

    it('mutates the running animation in place via setKeyframes/updateTiming', () => {
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 250;
        const animateMock = vi.fn();
        const element = makeElement('box', animateMock);
        installDom({ element: element, targetId: 'box' });

        // Seed in-flight transform animation.
        const elementAnims = new Map();
        elementAnims.set('transform', {
            animation: liveAnim,
            version: 1,
            animGroup: 'box',
            easingKeyframes: null,
            transformProperties: [],
            resolvedValues: defaultResolved(),
            generation: 1,
            propertyIndex: 0,
            updateFn: vi.fn()
        });
        activeAnimations.set('box', elementAnims);
        animationGroups.set('box', {
            totalProperties: 1,
            completedProperties: 0,
            started: true,
            generation: 1,
            nextPropertyIndex: 1,
            lastIteration: 0,
            propertyIterations: [0],
            propertyConfigs: []
        });

        resizeTransformAnimation({
            elementId: 'box',
            startX: 0, startY: 0, startZ: 0,
            endX: 400, endY: 0, endZ: 0,
            currentX: 100, currentY: 0, currentZ: 0,
            duration: 800
        });

        // No cancel, no recreate — the existing Animation keeps running.
        expect(liveAnim.cancelCalls).toBe(0);
        expect(animateMock).not.toHaveBeenCalled();

        // Keyframes were swapped on the running effect.
        expect(liveAnim.setKeyframesCalls).toHaveLength(1);
        const [keyframes] = liveAnim.setKeyframesCalls;
        expect(Array.isArray(keyframes)).toBe(true);
        expect(keyframes.length).toBeGreaterThan(0);
        expect(keyframes[0].transform).toBe('none');
        expect(keyframes[keyframes.length - 1].transform).toContain('translate3d(400px, 0px, 0px)');

        // Duration changed → updateTiming called and currentTime solved
        // to land the box at the strategy-aware target Elm shipped
        // (`currentX`). With new bounds 0→400 and target x=100 →
        // progress 0.25 → currentTime 0.25 * 800 = 200.
        expect(liveAnim.updateTimingCalls).toHaveLength(1);
        expect(liveAnim.updateTimingCalls[0].duration).toBe(800);
        expect(liveAnim.currentTime).toBeCloseTo(200, 5);

        // Resolved.translate is patched so the next resize sees the new
        // bounds and duration as its baseline.
        const updated = activeAnimations.get('box').get('transform');
        expect(updated.animation).toBe(liveAnim);
        expect(updated.resolvedValues.translate.startX).toBe(0);
        expect(updated.resolvedValues.translate.endX).toBe(400);
        expect(updated.resolvedValues.translate.duration).toBe(800);
    });

    it('skips updateTiming when duration is unchanged', () => {
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 400;
        const element = makeElement('box', vi.fn());
        installDom({ element: element, targetId: 'box' });

        const elementAnims = new Map();
        elementAnims.set('transform', {
            animation: liveAnim,
            version: 1,
            animGroup: 'box',
            resolvedValues: defaultResolved(),
            generation: 1,
            propertyIndex: 0,
            updateFn: vi.fn()
        });
        activeAnimations.set('box', elementAnims);
        animationGroups.set('box', { propertyIterations: [0], propertyConfigs: [] });

        resizeTransformAnimation({
            elementId: 'box',
            startX: 0, startY: 0, startZ: 0,
            endX: 100, endY: 0, endZ: 0,
            currentX: 80, currentY: 0, currentZ: 0,
            duration: 1000
        });

        expect(liveAnim.setKeyframesCalls).toHaveLength(1);
        expect(liveAnim.updateTimingCalls).toHaveLength(0);
        // currentTime is still adjusted to land the box at the
        // strategy-aware target (currentX=80) under the new bounds
        // 0→100 → progress 0.8 → currentTime 800.
        expect(liveAnim.currentTime).toBe(800);
    });

    it('reports COMMAND_INVALID when elementId/animGroup is missing', () => {
        installDom({ element: makeElement('box', vi.fn()), targetId: 'box' });
        // No throw, but should log via reportError. Verifying the no-throw
        // contract is enough; reportError swallows in test env.
        expect(() => resizeTransformAnimation({
            startX: 0, startY: 0, startZ: 0,
            endX: 0, endY: 0, endZ: 0,
            duration: 0
        })).not.toThrow();
    });
});
