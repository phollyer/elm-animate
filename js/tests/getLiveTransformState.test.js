/* eslint-env node */
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { getLiveTransformState, getAnimationProgress } from '../src/animationEvents.js';
import { animationGroups, lastKnownTransforms } from '../src/state.js';

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

describe('getAnimationProgress', () => {
    beforeEach(() => animationGroups.clear());
    afterEach(() => animationGroups.clear());

    it('returns per-iteration raw progress on the first iteration', () => {
        const animation = makeAnimation({ currentTime: 250, duration: 1000 });
        expect(getAnimationProgress('box', animation)).toBeCloseTo(0.25, 5);
    });

    it('wraps progress on subsequent iterations of a looping animation', () => {
        // Regression for proportional-resize bug: WAAPI's `currentTime` keeps
        // growing forever on looping animations, so a naive `currentTime /
        // duration` saturates at 1.0 after the first iteration and Elm's
        // resize math (`(oldIter + progress) * newDuration`) lands exactly on
        // the next iteration boundary - snapping the box to start of the
        // next leg.
        const animation = makeAnimation({ currentTime: 3250, duration: 1000, currentIteration: 3 });
        expect(getAnimationProgress('box', animation)).toBeCloseTo(0.25, 5);
    });

    it('returns 0 at an iteration boundary (looping animation)', () => {
        const animation = makeAnimation({ currentTime: 5000, duration: 1000, currentIteration: 5 });
        expect(getAnimationProgress('box', animation)).toBe(0);
    });

    it('returns raw progress on the reverse leg of `alternate` (not flipped)', () => {
        // Elm expects raw per-iteration progress and applies any direction
        // semantics itself - JS must NOT alternate-flip the value here.
        const animation = makeAnimation({ currentTime: 1250, duration: 1000, direction: 'alternate', currentIteration: 1 });
        expect(getAnimationProgress('box', animation)).toBeCloseTo(0.25, 5);
    });

    it('returns 0 when maxDuration is 0', () => {
        const animation = makeAnimation({ currentTime: 500, duration: 0 });
        expect(getAnimationProgress('box', animation)).toBe(0);
    });

    it('falls back to the registered group `maxDuration` when live timing is unavailable', () => {
        // If `effect.getTiming().duration` is missing or 0 (e.g. malformed
        // animation), use the longest property duration registered on the
        // group as a safety net.
        animationGroups.set('box', {
            propertyConfigs: [{ duration: 500 }, { duration: 2000 }]
        });
        const animation = {
            currentTime: 2500,
            effect: { getTiming() { return { duration: 0 }; } }
        };
        // 2500 % 2000 = 500 → 500 / 2000 = 0.25
        expect(getAnimationProgress('box', animation)).toBeCloseTo(0.25, 5);
    });

    it('prefers the LIVE effect duration over a stale `propertyConfigs` duration (resize regression)', () => {
        // Bug 4 regression: `resizeTransformAnimation` recreates the
        // animation with a new `duration` on every resize, but
        // `groupInfo.propertyConfigs` is populated only once at setup time
        // and is never refreshed. Reading the stale config duration wraps
        // the just-seeked `currentTime` through the OLD per-iteration
        // length, returning the wrong progress and drifting the box on
        // every subsequent orientation switch.
        //
        // Scenario: portrait animation (duration 1435) was paused at 50%,
        // then orientation switched to landscape and the animation was
        // recreated with duration 2895 and currentTime seeked to 1630
        // (= 0.5632 × 2895). The reported progress MUST be ~0.5632, not
        // (1630 % 1435) / 1435 ≈ 0.136.
        animationGroups.set('box', {
            propertyConfigs: [{ duration: 1435 }]
        });
        const animation = makeAnimation({ currentTime: 1630.587, duration: 2895 });
        expect(getAnimationProgress('box', animation)).toBeCloseTo(0.5632, 4);
    });
});
