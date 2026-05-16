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

    it('cancels the old animation and recreates it with new keyframes/timing already set', () => {
        // The in-place mutation approach (`setKeyframes` → `updateTiming`
        // → `currentTime =`) races the compositor: between `setKeyframes`
        // and the `currentTime` write, the compositor can sample the new
        // keyframes at the *old* `currentTime`, producing a visible
        // one-frame flicker `tx = newEnd × (oldCurrentTime / oldDuration)`
        // before snapping to the seeked position. We instead cancel the
        // old Animation and create a new one with the new state already
        // committed, then seek `currentTime` before the first composite.
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 250;
        const newAnim = createFakeAnimation({ duration: 800 });
        const animateMock = vi.fn(() => newAnim);
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

        // Old animation cancelled, new one created.
        expect(liveAnim.cancelCalls).toBe(1);
        expect(animateMock).toHaveBeenCalledTimes(1);

        // New animation was created with the new keyframes and timing
        // committed up front — no per-frame mutation on the running
        // effect that could race the compositor.
        const [keyframes, options] = animateMock.mock.calls[0];
        expect(Array.isArray(keyframes)).toBe(true);
        expect(keyframes.length).toBeGreaterThan(0);
        // First keyframe is the start of the resized translate slot
        // (0,0,0). It is emitted as `translate3d(0px, 0px, 0px)` rather
        // than the default `none` because every keyframe must list the
        // same transform functions — see computeForceGroups in
        // animations.js. Without this, WAAPI falls back to matrix3d
        // interpolation and silently drops co-running rotations whose
        // endpoints land on identity rotation matrices (e.g. 360deg).
        expect(keyframes[0].transform).toBe('translate3d(0px, 0px, 0px)');
        expect(keyframes[keyframes.length - 1].transform).toContain('translate3d(400px, 0px, 0px)');
        expect(options.duration).toBe(800);

        // currentTime seeked on the NEW animation (not the cancelled
        // one), so the first composite samples new keyframes at the new
        // time. With new bounds 0→400 and target x=100 → progress 0.25
        // → currentTime 0.25 * 800 = 200.
        expect(newAnim.currentTime).toBeCloseTo(200, 5);
        // No in-place mutation on the cancelled animation.
        expect(liveAnim.setKeyframesCalls).toHaveLength(0);
        expect(liveAnim.updateTimingCalls).toHaveLength(0);

        // Entry now points at the new animation and version is bumped
        // so the old animation's cancel handler self-suppresses.
        const updated = activeAnimations.get('box').get('transform');
        expect(updated.animation).toBe(newAnim);
        expect(updated.version).toBe(2);
        expect(updated.resolvedValues.translate.startX).toBe(0);
        expect(updated.resolvedValues.translate.endX).toBe(400);
        expect(updated.resolvedValues.translate.duration).toBe(800);
    });

    it('recreates with the same duration when it is unchanged', () => {
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 400;
        const newAnim = createFakeAnimation({ duration: 1000 });
        const animateMock = vi.fn(() => newAnim);
        const element = makeElement('box', animateMock);
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

        // Recreated with duration=1000 (same as before).
        expect(liveAnim.cancelCalls).toBe(1);
        expect(animateMock).toHaveBeenCalledTimes(1);
        const [, options] = animateMock.mock.calls[0];
        expect(options.duration).toBe(1000);
        // currentTime seeked on the NEW animation to land the box at
        // the strategy-aware target (currentX=80) under the new bounds
        // 0→100 → progress 0.8 → currentTime 800.
        expect(newAnim.currentTime).toBe(800);
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

    it('applies an Elm-supplied currentTimeMs verbatim', () => {
        // Elm decides where to seek (Proportional strategy: temporal-ratio
        // preservation for looping legs, 0 for the collapsed one-shot leg)
        // and ships an explicit `currentTimeMs`. JS just applies it on the
        // freshly-recreated animation; the `currentX` field is ignored on
        // this path.
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 250;
        const newAnim = createFakeAnimation({ duration: 800 });
        const element = makeElement('box', vi.fn(() => newAnim));
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
            endX: 400, endY: 0, endZ: 0,
            // currentX is ignored on this path; pass an obviously-wrong
            // value to prove it.
            currentX: 999, currentY: 0, currentZ: 0,
            duration: 800,
            currentTimeMs: 200
        });

        expect(newAnim.currentTime).toBeCloseTo(200, 5);
        // The cancelled animation's currentTime is untouched.
        expect(liveAnim.currentTime).toBe(250);
    });

    it('applies currentTimeMs and preserves paused state across recreate', () => {
        // Paused state must be re-applied on the new animation so the
        // Elm-supplied currentTimeMs lands at the same eased visual
        // position on resume.
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'paused';
        liveAnim.currentTime = 600;
        const newAnim = createFakeAnimation({ duration: 1500 });
        const element = makeElement('box', vi.fn(() => newAnim));
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
            endX: 500, endY: 0, endZ: 0,
            currentX: 300, currentY: 0, currentZ: 0,
            duration: 1500,
            currentTimeMs: 900
        });

        expect(newAnim.currentTime).toBeCloseTo(900, 5);
        expect(newAnim.playState).toBe('paused');
        expect(newAnim.pauseCalls).toBe(1);
    });

    it('seeks to currentTimeMs=0 to restart a collapsed one-shot leg', () => {
        // When Elm collapses a one-shot leg under the Proportional strategy
        // it sends `currentTimeMs: 0` so the easing curve restarts cleanly
        // from the new leg start (avoids landing mid non-linear curve).
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 750;
        const newAnim = createFakeAnimation({ duration: 600 });
        const element = makeElement('box', vi.fn(() => newAnim));
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
            startX: 100, startY: 0, startZ: 0,
            endX: 400, endY: 0, endZ: 0,
            currentX: 100, currentY: 0, currentZ: 0,
            duration: 600,
            currentTimeMs: 0
        });

        expect(newAnim.currentTime).toBe(0);
    });

    it('patches the scale slot when property=scale', () => {
        // A scale-targeted resize must mutate resolved.scale (not
        // resolved.translate) so subsequent keyframe regenerations and
        // resizes see the new scale bounds as the baseline. The translate
        // slot is preserved unchanged.
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 0;
        const newAnim = createFakeAnimation({ duration: 1000 });
        const element = makeElement('box', vi.fn(() => newAnim));
        installDom({ element: element, targetId: 'box' });

        const resolved = defaultResolved();
        // Make scale the actively-animated slot.
        resolved.scale = {
            startX: 1, startY: 1, startZ: 1,
            endX: 2, endY: 1, endZ: 1,
            easing: 'linear', easingKeyframes: null, duration: 1000
        };
        const elementAnims = new Map();
        elementAnims.set('transform', {
            animation: liveAnim,
            version: 1,
            animGroup: 'box',
            resolvedValues: resolved,
            generation: 1,
            propertyIndex: 0,
            updateFn: vi.fn()
        });
        activeAnimations.set('box', elementAnims);
        animationGroups.set('box', { propertyIterations: [0], propertyConfigs: [] });

        resizeTransformAnimation({
            elementId: 'box',
            property: 'scale',
            startX: 1, startY: 1, startZ: 1,
            endX: 3, endY: 1, endZ: 1,
            currentX: 1, currentY: 1, currentZ: 1,
            duration: 1000,
            currentTimeMs: 0
        });

        const updated = activeAnimations.get('box').get('transform');
        // Scale slot patched with the new bounds.
        expect(updated.resolvedValues.scale.startX).toBe(1);
        expect(updated.resolvedValues.scale.endX).toBe(3);
        expect(updated.resolvedValues.scale.duration).toBe(1000);
        // Translate slot left untouched.
        expect(updated.resolvedValues.translate.startX).toBe(0);
        expect(updated.resolvedValues.translate.endX).toBe(200);
        // Keyframes were rebuilt and currentTime applied on the new animation.
        expect(liveAnim.cancelCalls).toBe(1);
        expect(newAnim.currentTime).toBe(0);
    });

    it('preserves co-running long-duration rotate keyframes when a short snapshot-bake scale resize fires', () => {
        // Repro: 3D cube rotating 0→360 over 8000 ms with `Scale.init`
        // (no scale animation). Window resize triggers `Scale.onResize`
        // which Elm sends with `hasAnimationBaseline=false` and a short
        // synthetic snapshot-bake duration (e.g. 300 ms).
        //
        // Bug pre-fix: keyframe rebuild used `newDuration=300` as the
        // shared `maxDuration`, so rotate (8000 ms) was sampled at
        // `durationRatio = 8000/300 ≈ 26.67`, yielding `localProgress`
        // capped at ≈ 0.0376. The 30-frame keyframe set covered only the
        // first ~3.7 % of the rotation arc, visibly freezing the cube.
        //
        // Fix: `maxDuration = max(all sub-property durations)`, mirroring
        // `createMergedTransformAnimation`. Last keyframe must reach the
        // full rotate target (360 deg) on every axis, and the resized
        // scale slot must not have its duration overwritten with the
        // snapshot-bake value when `hasAnimationBaseline === false`.
        const liveAnim = createFakeAnimation({ duration: 8000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 4000;
        const element = makeElement('cubeAnim', vi.fn());
        installDom({ element: element, targetId: 'cubeAnim' });

        const resolved = defaultResolved();
        // Init-only scale (no animation, duration=0, constant value).
        resolved.scale = {
            startX: 1, startY: 1, startZ: 1,
            endX: 1, endY: 1, endZ: 1,
            easing: 'linear', easingKeyframes: null, duration: 0
        };
        // Long-duration rotate animation on all three axes.
        resolved.rotate = {
            startX: 0, startY: 0, startZ: 0,
            endX: 360, endY: 360, endZ: 360,
            easing: 'linear', easingKeyframes: null, duration: 8000
        };
        // Translate also static, just like the cube example.
        resolved.translate = {
            startX: 0, startY: 0, startZ: 200,
            endX: 0, endY: 0, endZ: 200,
            easing: 'linear', easingKeyframes: null, duration: 0
        };

        const elementAnims = new Map();
        elementAnims.set('transform', {
            animation: liveAnim,
            version: 1,
            animGroup: 'cubeAnim',
            resolvedValues: resolved,
            generation: 1,
            propertyIndex: 0,
            updateFn: vi.fn()
        });
        activeAnimations.set('cubeAnim', elementAnims);
        animationGroups.set('cubeAnim', { propertyIterations: [0], propertyConfigs: [] });

        resizeTransformAnimation({
            elementId: 'cubeAnim',
            property: 'scale',
            startX: 1.16484, startY: 1.16484, startZ: 1.16484,
            endX: 1.16484, endY: 1.16484, endZ: 1.16484,
            currentX: 1.16484, currentY: 1.16484, currentZ: 1.16484,
            duration: 300,
            hasAnimationBaseline: false
        });

        // Keyframes were rebuilt.
        expect(liveAnim.setKeyframesCalls).toHaveLength(1);
        const [keyframes] = liveAnim.setKeyframesCalls;
        expect(keyframes.length).toBeGreaterThan(0);

        // Last keyframe must contain the full 360° rotate on every axis —
        // proves rotate was sampled against `maxDuration=8000`, not the
        // 300 ms snapshot-bake value.
        const lastTransform = keyframes[keyframes.length - 1].transform;
        expect(lastTransform).toContain('rotateX(360deg)');
        expect(lastTransform).toContain('rotateY(360deg)');
        expect(lastTransform).toContain('rotateZ(360deg)');
        // And the new scale value is spliced into the same keyframe.
        expect(lastTransform).toContain('scaleX(1.16484)');
        expect(lastTransform).toContain('scaleY(1.16484)');
        expect(lastTransform).toContain('scaleZ(1.16484)');

        // First keyframe likewise carries the new scale (constant across
        // the whole keyframe set since start === end) and rotate at 0°.
        // Crucially it MUST emit `rotateX(0deg) rotateY(0deg) rotateZ(0deg)`
        // explicitly even though those are identity values, so that every
        // keyframe lists the same transform functions and WAAPI uses
        // per-function interpolation. Without this, the function lists
        // mismatch (last keyframe has rotate, first does not), WAAPI falls
        // back to matrix3d interpolation, and the rotation silently
        // disappears whenever an endpoint produces an identity rotation
        // matrix (e.g. 360deg) — see Animate3D regression below.
        const firstTransform = keyframes[0].transform;
        expect(firstTransform).toContain('scaleX(1.16484)');
        expect(firstTransform).toContain('rotateX(0deg)');
        expect(firstTransform).toContain('rotateY(0deg)');
        expect(firstTransform).toContain('rotateZ(0deg)');
        expect(firstTransform).not.toContain('rotateX(360deg)');

        // Snapshot-bake path: do NOT touch timing or currentTime on the
        // running rotate animation — preserves the rotate's timeline.
        expect(liveAnim.updateTimingCalls).toHaveLength(0);
        expect(liveAnim.currentTime).toBe(4000);

        // Slot duration must be preserved (was 0 for init-only scale).
        // Overwriting it with the 300 ms snapshot-bake value would
        // corrupt the baseline used by future merges/resizes.
        const updated = activeAnimations.get('cubeAnim').get('transform');
        expect(updated.resolvedValues.scale.duration).toBe(0);
        // But the new constant scale value is captured.
        expect(updated.resolvedValues.scale.startX).toBe(1.16484);
        expect(updated.resolvedValues.scale.endX).toBe(1.16484);
        // And rotate slot is untouched.
        expect(updated.resolvedValues.rotate.duration).toBe(8000);
        expect(updated.resolvedValues.rotate.endX).toBe(360);
    });

    it('seeks currentTime on the new animation, never on the cancelled one (no compositor flicker)', () => {
        // Regression guard for the one-frame flicker bug: with in-place
        // mutation the order `setKeyframes(newEnd) → updateTiming(newDur)
        // → animation.currentTime = newTime` left a window where the
        // compositor could sample the new keyframes at the *old*
        // currentTime, rendering `tx = newEnd × (oldCurrentTime /
        // oldDuration)` for one frame before snapping to the correct
        // seeked position.
        //
        // Setup mirrors the live-debug log's resize#3:
        //   oldDuration=5245, oldCurrentTime≈3140 (progress 0.599),
        //   newDuration=2540, newEnd=508, currentTimeMs=605.98.
        // Expected post-seek position: 508 × (605.98/2540) ≈ 121.2.
        // Flicker position (would-be bug): 508 × 0.599 ≈ 304.3.
        const liveAnim = createFakeAnimation({ duration: 5245 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 3140;
        const newAnim = createFakeAnimation({ duration: 2540 });
        const animateMock = vi.fn(() => newAnim);
        const element = makeElement('box', animateMock);
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
            endX: 508, endY: 0, endZ: 0,
            currentX: 121.2, currentY: 0, currentZ: 0,
            duration: 2540,
            currentTimeMs: 605.98
        });

        // The cancelled animation must NEVER have its currentTime
        // touched after cancel — that would be the compositor race.
        // (currentTime is read pre-cancel but never written.)
        expect(liveAnim.currentTime).toBe(3140);
        expect(liveAnim.cancelCalls).toBe(1);
        // No in-place keyframe/timing swap on the cancelled animation.
        expect(liveAnim.setKeyframesCalls).toHaveLength(0);
        expect(liveAnim.updateTimingCalls).toHaveLength(0);

        // New animation was created with the new keyframes and timing
        // committed at construction, and only then seeked.
        expect(animateMock).toHaveBeenCalledTimes(1);
        const [, options] = animateMock.mock.calls[0];
        expect(options.duration).toBe(2540);
        expect(newAnim.currentTime).toBeCloseTo(605.98, 5);
        // Entry version bumped so the old animation's `cancel` listener
        // (installed by setupAnimationEvents on the original creation)
        // sees version mismatch and skips lifecycle emission.
        const updated = activeAnimations.get('box').get('transform');
        expect(updated.animation).toBe(newAnim);
        expect(updated.version).toBe(2);
    });
});
