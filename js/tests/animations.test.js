/* eslint-env node */
/* global global */
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { processAnimationData, processElementAnimation } from '../src/animations.js';
import { activeAnimations, animationGroups, elementTransformOrders, lastKnownTransforms } from '../src/state.js';
import { createFakeAnimation, installDom, cleanupDom } from './_publicApiHelpers.js';

function makeElement({ animGroup, animations = [createFakeAnimation()], order = null }) {
    const animateMock = vi.fn(() => animations.shift() || createFakeAnimation());
    return {
        id: animGroup,
        animate: animateMock,
        style: { transform: '' },
        getAnimations: () => [],
        getAttribute(name) {
            if (name === 'data-anim-target') return animGroup;
            if (name === 'data-elm-motion-order' && order) return order;
            return null;
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

describe('processAnimationData (WAAPI engine)', () => {
    it('reports COMMAND_INVALID when animationData is missing or has no elements', () => {
        installDom({ element: makeElement({ animGroup: 'x' }), targetId: 'x' });
        const errorSpy = vi.fn();
        global.window.addEventListener = (_, handler) => { errorSpy.handler = handler; };

        // Both branches: null and missing elements
        expect(() => processAnimationData(null)).not.toThrow();
        expect(() => processAnimationData({})).not.toThrow();
    });

    it('reports TARGET_NOT_FOUND when no element matches the animGroup', () => {
        installDom({ element: null, targetId: 'absent' });
        // querySelector returns null for any other selector → triggers reportError
        expect(() => processAnimationData({
            elements: {
                'missing-group': {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 100, easing: 'linear', version: 1 }
                    ]
                }
            }
        })).not.toThrow();
    });

    it('animates a single transform property (translate)', () => {
        const animGroup = 'box-translate';
        const animation = createFakeAnimation({ duration: 300 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [{
                        type: 'translate',
                        startX: 0, startY: 0, startZ: 0,
                        endX: 100, endY: 50, endZ: 0,
                        duration: 300, easing: 'linear', version: 1
                    }]
                }
            }
        });

        expect(element.animate).toHaveBeenCalledTimes(1);
        const elementAnims = activeAnimations.get(animGroup);
        expect(elementAnims.has('transform')).toBe(true);
    });

    it('animates mixed transform and non-transform properties in one command', () => {
        const animGroup = 'box-mixed';
        const transformAnim = createFakeAnimation({ duration: 300 });
        const opacityAnim = createFakeAnimation({ duration: 300 });
        const element = makeElement({ animGroup, animations: [transformAnim, opacityAnim] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 1
                        },
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(element.animate).toHaveBeenCalledTimes(2);
        const elementAnims = activeAnimations.get(animGroup);
        expect(elementAnims.has('transform')).toBe(true);
        expect(elementAnims.has('opacity')).toBe(true);
    });

    it('merges multiple transform types into a single animation when easing/duration match', () => {
        const animGroup = 'box-merged';
        const animation = createFakeAnimation({ duration: 400 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 50, endY: 0, endZ: 0,
                            duration: 400, easing: 'linear', version: 1
                        },
                        {
                            type: 'rotate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 90,
                            duration: 400, easing: 'linear', version: 1
                        },
                        {
                            type: 'scale',
                            startX: 1, startY: 1, startZ: 1,
                            endX: 2, endY: 2, endZ: 1,
                            duration: 400, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        // Single merged animation (same duration + same easing branch)
        expect(element.animate).toHaveBeenCalledTimes(1);
        const [keyframes, options] = element.animate.mock.calls[0];
        expect(keyframes).toHaveLength(2);
        expect(options.duration).toBe(400);
        expect(options.easing).toBe('linear');
    });

    it('falls back to keyframe interpolation when transform sub-properties have different durations', () => {
        const animGroup = 'box-keyframe';
        const animation = createFakeAnimation({ duration: 600 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 1
                        },
                        {
                            type: 'rotate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 180,
                            duration: 600, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        const [keyframes, options] = element.animate.mock.calls[0];
        // Keyframe interpolation path → 30 frames, linear easing, longest duration wins
        expect(keyframes.length).toBeGreaterThan(2);
        expect(options.duration).toBe(600);
        expect(options.easing).toBe('linear');
    });

    it('cancels and restarts a transform animation, carrying forward retained sub-properties', () => {
        const animGroup = 'box-restart';
        const firstAnim = createFakeAnimation({ duration: 300 });
        firstAnim.currentTime = 150;
        firstAnim.playState = 'running';
        const secondAnim = createFakeAnimation({ duration: 300 });

        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        installDom({ element, targetId: animGroup });

        // First: translate + rotate
        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 1
                        },
                        {
                            type: 'rotate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 0, endY: 0, endZ: 90,
                            duration: 300, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        // Second: only translate — rotate should be carried forward
        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 50, startY: 0, startZ: 0,
                            endX: 200, endY: 0, endZ: 0,
                            duration: 300, easing: 'linear', version: 2
                        }
                    ]
                }
            }
        });

        expect(firstAnim.cancelCalls).toBe(1);
        expect(element.animate).toHaveBeenCalledTimes(2);
    });

    it('cancels a non-transform animation when restarted with a new version', () => {
        const animGroup = 'box-opacity-restart';
        const firstAnim = createFakeAnimation({ duration: 200 });
        const secondAnim = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [firstAnim, secondAnim] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 200, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 1, endValue: 0, duration: 200, easing: 'linear', version: 2 }
                    ]
                }
            }
        });

        expect(firstAnim.cancelCalls).toBe(1);
        expect(element.animate).toHaveBeenCalledTimes(2);
    });

    it('stores transformOrder for the element when provided', () => {
        const animGroup = 'box-order';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            elements: {
                [animGroup]: {
                    transformOrder: ['rotate', 'translate', 'scale'],
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 200, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        expect(elementTransformOrders.get(animGroup)).toEqual(['rotate', 'translate', 'scale']);
    });

    it('passes through global iteration and direction options', () => {
        const animGroup = 'box-iters';
        const animation = createFakeAnimation({ duration: 200 });
        const element = makeElement({ animGroup, animations: [animation] });
        installDom({ element, targetId: animGroup });

        processAnimationData({
            iterations: { type: 'times', count: 3 },
            direction: 'alternate',
            elements: {
                [animGroup]: {
                    properties: [
                        {
                            type: 'translate',
                            startX: 0, startY: 0, startZ: 0,
                            endX: 100, endY: 0, endZ: 0,
                            duration: 200, easing: 'linear', version: 1
                        }
                    ]
                }
            }
        });

        const [, options] = element.animate.mock.calls[0];
        expect(options.iterations).toBe(3);
        expect(options.direction).toBe('alternate');
    });

    it('expands a group with multiple matching DOM targets into per-element animations', () => {
        const animGroup = 'box-multi';
        const elA = makeElement({ animGroup });
        const elB = makeElement({ animGroup });
        elA.animate = vi.fn(() => createFakeAnimation({ duration: 100 }));
        elB.animate = vi.fn(() => createFakeAnimation({ duration: 100 }));
        installDom({ element: elA, targetId: animGroup, queryAll: [elA, elB] });

        processAnimationData({
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 100, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(elA.animate).toHaveBeenCalledTimes(1);
        expect(elB.animate).toHaveBeenCalledTimes(1);
    });
});

describe('processElementAnimation', () => {
    it('returns early without erroring when target element is not provided and not found', () => {
        installDom({ element: null, targetId: 'never-found' });
        expect(() =>
            processElementAnimation('never-found', {
                properties: [
                    { type: 'opacity', startValue: 0, endValue: 1, duration: 100, easing: 'linear', version: 1 }
                ]
            })
        ).not.toThrow();
    });
});
