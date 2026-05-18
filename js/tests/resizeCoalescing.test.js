/* eslint-env node */
/* global global */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { resizeTransformAnimation, flushPendingResizes } from '../src/animations.js';
import {
    activeAnimations,
    animationGroups,
    elementTransformOrders,
    lastKnownPerspectiveOrigins,
    lastKnownTransforms
} from '../src/state.js';
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
    lastKnownPerspectiveOrigins.clear();
    lastKnownTransforms.clear();
}

function seedRunningTransform(animGroup, element, liveAnim) {
    const elementAnims = new Map();
    elementAnims.set('transform', {
        animation: liveAnim,
        version: 1,
        animGroup,
        easingKeyframes: null,
        transformProperties: [],
        resolvedValues: defaultResolved(),
        generation: 1,
        propertyIndex: 0,
        updateFn: vi.fn()
    });
    activeAnimations.set(animGroup, elementAnims);
    animationGroups.set(animGroup, {
        totalProperties: 1,
        completedProperties: 0,
        started: true,
        generation: 1,
        nextPropertyIndex: 1,
        lastIteration: 0,
        propertyIterations: [0],
        propertyConfigs: []
    });
}

beforeEach(clearGlobalState);
afterEach(() => {
    cleanupDom();
    clearGlobalState();
    flushPendingResizes();
});

describe('resizeTransformAnimation rAF-coalescing', () => {
    it('collapses N same-frame resize commands into a single cancel+recreate per (animGroup, property)', () => {
        // Repro for the Perspective3D dot-freeze bug: drag-resize fires
        // ~30 resize commands per displayed frame. Without coalescing,
        // each command does an immediate cancel+recreate, leaving the
        // compositor-accelerated `transform` layer snapped to its base
        // value for most of each frame. With coalescing, only the last
        // payload per key is applied per rAF tick.
        const liveAnim = createFakeAnimation({ duration: 1000 });
        liveAnim.playState = 'running';
        liveAnim.currentTime = 250;
        const newAnim = createFakeAnimation({ duration: 800 });
        const animateMock = vi.fn(() => newAnim);
        const element = makeElement('dot', animateMock);
        installDom({ element, targetId: 'dot' });
        seedRunningTransform('dot', element, liveAnim);

        // Flood: 30 commands in a single synchronous burst.
        for (let i = 0; i < 30; i++) {
            resizeTransformAnimation({
                elementId: 'dot',
                startX: 0, startY: 0, startZ: 0,
                endX: 400 + i, endY: 0, endZ: 0,
                currentX: 100 + i, currentY: 0, currentZ: 0,
                duration: 800
            });
        }

        // Nothing happens yet — work is deferred to the rAF callback.
        expect(liveAnim.cancelCalls).toBe(0);
        expect(animateMock).not.toHaveBeenCalled();

        flushPendingResizes();

        // Exactly one cancel+recreate, using the most-recent payload.
        expect(liveAnim.cancelCalls).toBe(1);
        expect(animateMock).toHaveBeenCalledTimes(1);
    });

    it('keeps resizes for different (animGroup, property) keys independent', () => {
        // Two animations in the same frame must each get exactly one
        // cancel+recreate — coalescing dedupes per key, not globally.
        const dotAnim = createFakeAnimation({ duration: 1000 });
        dotAnim.playState = 'running';
        dotAnim.currentTime = 100;
        const dotNew = createFakeAnimation({ duration: 1000 });
        const dotAnimate = vi.fn(() => dotNew);
        const dot = makeElement('dot', dotAnimate);

        const boxAnim = createFakeAnimation({ duration: 1000 });
        boxAnim.playState = 'running';
        boxAnim.currentTime = 100;
        const boxNew = createFakeAnimation({ duration: 1000 });
        const boxAnimate = vi.fn(() => boxNew);
        const box = makeElement('box', boxAnimate);

        // Install the "dot" via the standard helper, then patch the
        // shared document stub so "box" also resolves via findAnimTarget.
        installDom({ element: dot, targetId: 'dot' });
        const originalQuery = global.document.querySelector;
        global.document.querySelector = (selector) => {
            if (selector === '[data-anim-target="box"]') return box;
            return originalQuery(selector);
        };

        seedRunningTransform('dot', dot, dotAnim);
        seedRunningTransform('box', box, boxAnim);

        for (let i = 0; i < 10; i++) {
            resizeTransformAnimation({
                elementId: 'dot',
                startX: 0, startY: 0, startZ: 0,
                endX: 400, endY: 0, endZ: 0,
                currentX: 100, currentY: 0, currentZ: 0,
                duration: 1000
            });
            resizeTransformAnimation({
                elementId: 'box',
                startX: 0, startY: 0, startZ: 0,
                endX: 400, endY: 0, endZ: 0,
                currentX: 100, currentY: 0, currentZ: 0,
                duration: 1000
            });
        }

        flushPendingResizes();

        expect(dotAnim.cancelCalls).toBe(1);
        expect(boxAnim.cancelCalls).toBe(1);
        expect(dotAnimate).toHaveBeenCalledTimes(1);
        expect(boxAnimate).toHaveBeenCalledTimes(1);
    });
});
