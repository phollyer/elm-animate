/* eslint-env node */
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { getLiveTransformState } from '../src/animationEvents.js';
import { lastKnownTransforms } from '../src/state.js';

function makeResolvedX(startX, endX, duration) {
    return {
        translate: {
            startX, startY: 0, startZ: 0,
            endX, endY: 0, endZ: 0,
            easing: 'linear', easingKeyframes: null, duration
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

function makeAnimation({ currentTime, duration, direction = 'normal', currentIteration = 0, playState = 'running' }) {
    return {
        currentTime,
        playState,
        effect: {
            getTiming() { return { duration, direction }; },
            getComputedTiming() { return { currentIteration, duration, direction }; }
        }
    };
}

beforeEach(() => lastKnownTransforms.clear());
afterEach(() => lastKnownTransforms.clear());

describe('getLiveTransformState', () => {
    it('forward leg of `alternate` reads progress directly', () => {
        // duration 1000, currentTime 250, iter 0 → forward leg, progress 0.25
        const animation = makeAnimation({ currentTime: 250, duration: 1000, direction: 'alternate', currentIteration: 0 });
        const state = getLiveTransformState('box', animation, makeResolvedX(0, 200, 1000), 1000);
        expect(state.x).toBeCloseTo(50, 5);
    });

    it('reverse leg of `alternate` flips progress', () => {
        // duration 1000, currentTime 250, iter 1 → reverse leg, effective progress 0.75
        // Position from start=0 to end=200 at progress 0.75 = 150,
        // but visually on reverse leg the box should be at 200 - 150 = 50.
        // Actually `computeTransformFromResolved` lerps start→end with the
        // given progress; with progress=0.75 we get 150. The flip makes the
        // *snapshot* match where the box visually IS: after a quarter of the
        // reverse leg it's near the end (≈ end - 0.25*range = 150).
        const animation = makeAnimation({ currentTime: 250, duration: 1000, direction: 'alternate', currentIteration: 1 });
        const state = getLiveTransformState('box', animation, makeResolvedX(0, 200, 1000), 1000);
        expect(state.x).toBeCloseTo(150, 5);
    });

    it('end of reverse leg of `alternate` reads as start position', () => {
        // Reverse leg of iter 1 spans currentTime 1000..2000. Near its end
        // (e.g. currentTime ≈ 1990) the box is back near startX.
        const animation = makeAnimation({ currentTime: 1990, duration: 1000, direction: 'alternate', currentIteration: 1 });
        const state = getLiveTransformState('box', animation, makeResolvedX(0, 200, 1000), 1000);
        expect(state.x).toBeCloseTo(2, 5);
    });

    it('`alternate-reverse` starts on the reverse leg (iter 0 = reverse)', () => {
        const animation = makeAnimation({ currentTime: 250, duration: 1000, direction: 'alternate-reverse', currentIteration: 0 });
        const state = getLiveTransformState('box', animation, makeResolvedX(0, 200, 1000), 1000);
        expect(state.x).toBeCloseTo(150, 5);
    });

    it('`reverse` direction flips progress on every iteration', () => {
        const animation = makeAnimation({ currentTime: 250, duration: 1000, direction: 'reverse', currentIteration: 0 });
        const state = getLiveTransformState('box', animation, makeResolvedX(0, 200, 1000), 1000);
        expect(state.x).toBeCloseTo(150, 5);
    });

    it('`normal` direction is unaffected by iteration parity', () => {
        const animation = makeAnimation({ currentTime: 250, duration: 1000, direction: 'normal', currentIteration: 5 });
        const state = getLiveTransformState('box', animation, makeResolvedX(0, 200, 1000), 1000);
        expect(state.x).toBeCloseTo(50, 5);
    });

    it('caches the computed state in lastKnownTransforms', () => {
        const animation = makeAnimation({ currentTime: 500, duration: 1000, direction: 'normal', currentIteration: 0 });
        getLiveTransformState('box', animation, makeResolvedX(0, 200, 1000), 1000);
        const cached = lastKnownTransforms.get('box');
        expect(cached).toBeTruthy();
        expect(cached.x).toBeCloseTo(100, 5);
    });

    it('returns cached state while animation is `pending`', () => {
        // Seed cache with a known state from a previous (running) frame.
        const seed = makeAnimation({ currentTime: 400, duration: 1000, direction: 'normal', currentIteration: 0 });
        getLiveTransformState('box', seed, makeResolvedX(0, 200, 1000), 1000);
        expect(lastKnownTransforms.get('box').x).toBeCloseTo(80, 5);

        // A freshly-created replacement animation reports `pending` and
        // currentTime=0 even though we set a target time. We must not
        // overwrite the cache with x=0 — that produces a one-frame visual
        // snap to the keyframe[0] position.
        const pending = makeAnimation({ currentTime: 0, duration: 1000, direction: 'normal', currentIteration: 0, playState: 'pending' });
        const state = getLiveTransformState('box', pending, makeResolvedX(0, 200, 1000), 1000);
        expect(state.x).toBeCloseTo(80, 5);
    });
});
