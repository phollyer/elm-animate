/* eslint-env node */
import { afterEach, describe, expect, it, vi } from 'vitest';
import ElmMotion from '../src/index.js';
import { createFakeAnimation, installDom, createPorts, cleanupDom } from './_publicApiHelpers.js';

afterEach(cleanupDom);


describe('ElmMotion public API', () => {
    it('subscribes to motionCmd and emits started for animate commands', async () => {
        const animGroup = 'box-started';
        const animation = createFakeAnimation();
        const element = {
            id: animGroup,
            animate: vi.fn(() => animation)
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(element.animate).toHaveBeenCalledTimes(1);
        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({
                        animGroup,
                        status: 'started',
                        progress: 0
                    })
                })
            ])
        );
    });

    it('emits propertyUpdate payloads during WAAPI animation frames', async () => {
        const animGroup = 'box-property-update';
        const animation = createFakeAnimation({ duration: 300 });
        animation.currentTime = 150;
        animation.playState = 'running';

        const element = {
            id: animGroup,
            animate: vi.fn(() => animation)
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        const rafCallback = global.requestAnimationFrame.mock.calls[0][0];
        rafCallback();

        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'propertyUpdate',
                    animGroup,
                    opacity: 0.4,
                    progress: 0.5,
                    isAnimating: true
                })
            ])
        );
    });

    it('emits completed, paused, resumed, and cancelled events for WAAPI commands', async () => {
        const animGroup = 'box-controls';
        const animation = createFakeAnimation({ duration: 400 });
        animation.currentTime = 200;

        const element = {
            id: animGroup,
            animate: vi.fn(() => animation)
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 400, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        await ports.send({ type: 'pause', elementId: animGroup });
        await ports.send({ type: 'resume', elementId: animGroup });
        animation.finish();

        const lifecycleStatuses = events
            .filter((event) => event.type === 'animationUpdate')
            .map((event) => event.payload?.status);

        expect(lifecycleStatuses).toEqual(
            expect.arrayContaining(['started', 'paused', 'resumed', 'completed'])
        );
        expect(animation.pauseCalls).toBe(1);
        expect(animation.playCalls).toBe(1);

        const secondAnimation = createFakeAnimation({ duration: 400 });
        element.animate.mockImplementationOnce(() => secondAnimation);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 1, endValue: 0, duration: 400, easing: 'linear', version: 2 }
                    ]
                }
            }
        });

        secondAnimation.cancel();

        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({
                        animGroup,
                        status: 'cancelled'
                    })
                })
            ])
        );
    });

    it('emits a single scroll-driven iteration event when all property animations complete the loop', async () => {
        const animGroup = 'box-scroll';
        const sourceId = 'source-scroll';
        const animations = [createFakeAnimation(), createFakeAnimation()];
        const element = {
            id: animGroup,
            animate: vi.fn(() => animations.shift())
        };
        installDom({ element, targetId: animGroup, sourceId });
        global.ScrollTimeline = class ScrollTimeline {
            constructor(config) {
                this.config = config;
            }
        };
        global.window.ScrollTimeline = global.ScrollTimeline;

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'scrollDriven',
            iterations: { type: 'times', count: 3 },
            timeline: { source: sourceId, axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear' },
                        { type: 'customColorProperty', cssProperty: 'color', startColor: 'rgb(0, 0, 0)', endColor: 'rgb(255, 0, 0)', duration: 300, easing: 'linear' }
                    ]
                }
            }
        });

        const createdAnimations = element.animate.mock.results.map((result) => result.value);
        createdAnimations[0].trigger('iteration');
        expect(events.filter((event) => event.payload?.status === 'iteration')).toHaveLength(0);

        createdAnimations[1].trigger('iteration');
        const iterationEvents = events.filter((event) => event.payload?.status === 'iteration');
        expect(iterationEvents).toHaveLength(1);
        expect(iterationEvents[0]).toEqual(
            expect.objectContaining({
                type: 'animationUpdate',
                engine: 'scrollTimeline',
                payload: expect.objectContaining({
                    animGroup,
                    progress: 1
                })
            })
        );
    });

    it('emits view-driven lifecycle events through the public API', async () => {
        const animGroup = 'box-view';
        const animations = [createFakeAnimation(), createFakeAnimation()];
        const element = {
            id: animGroup,
            animate: vi.fn(() => animations.shift())
        };
        installDom({ element, targetId: animGroup });
        global.ViewTimeline = class ViewTimeline {
            constructor(config) {
                this.config = config;
            }
        };
        global.window.ViewTimeline = global.ViewTimeline;

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'viewDriven',
            iterations: { type: 'times', count: 2 },
            timeline: { axis: 'block' },
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear' },
                        { type: 'customColorProperty', cssProperty: 'color', startColor: 'rgb(0, 0, 0)', endColor: 'rgb(255, 0, 0)', duration: 300, easing: 'linear' }
                    ]
                }
            }
        });

        const createdAnimations = element.animate.mock.results.map((result) => result.value);
        createdAnimations.forEach((animation) => animation.finish());

        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'viewTimeline',
                    payload: expect.objectContaining({
                        animGroup,
                        status: 'completed',
                        progress: 1
                    })
                })
            ])
        );
    });

    it('handles stop, reset, and restart commands through the public API', async () => {
        const elements = new Map();
        const sourceMap = new Map();
        global.CSS = { escape: (value) => value };
        global.performance = { now: () => 100 };
        global.requestAnimationFrame = vi.fn(() => 1);
        global.cancelAnimationFrame = vi.fn();
        global.document = {
            documentElement: { id: 'document' },
            head: { appendChild() { } },
            createElement() {
                return {
                    setAttribute() { },
                    addEventListener() { },
                    onload: null,
                    onerror: null
                };
            },
            querySelector(selector) {
                const targetMatch = selector.match(/^\[data-anim-target="(.+)"\]$/);
                if (!targetMatch) return null;
                return elements.get(targetMatch[1]) || sourceMap.get(targetMatch[1]) || null;
            },
            querySelectorAll(selector) {
                const targetMatch = selector.match(/^\[data-anim-target="(.+)"\]$/);
                if (!targetMatch) return [];
                const element = elements.get(targetMatch[1]);
                return element ? [element] : [];
            },
            getElementById(id) {
                return elements.get(id) || sourceMap.get(id) || null;
            }
        };
        global.window = {
            getComputedStyle() {
                return {
                    opacity: '0.4',
                    width: '100px',
                    height: '50px',
                    getPropertyValue(prop) {
                        if (prop === '--progress') return '12';
                        if (prop === 'color') return 'rgb(255, 255, 255)';
                        if (prop === 'background-color') return 'rgb(0, 0, 0)';
                        return '';
                    }
                };
            }
        };

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        const stoppedGroup = 'box-stop';
        const stoppedAnimation = createFakeAnimation({ duration: 250 });
        const stoppedElement = {
            id: stoppedGroup,
            animate: vi.fn(() => stoppedAnimation)
        };
        elements.set(stoppedGroup, stoppedElement);

        await ports.send({
            type: 'animate',
            elements: {
                [stoppedGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 250, easing: 'linear', version: 1 }
                    ]
                }
            }
        });
        await ports.send({ type: 'stop', elementId: stoppedGroup });

        const resetGroup = 'box-reset';
        const resetAnimation = createFakeAnimation({ duration: 250 });
        const resetElement = {
            id: resetGroup,
            animate: vi.fn(() => resetAnimation)
        };
        elements.set(resetGroup, resetElement);

        await ports.send({
            type: 'animate',
            elements: {
                [resetGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 250, easing: 'linear', version: 1 }
                    ]
                }
            }
        });
        await ports.send({ type: 'reset', elementId: resetGroup });

        const restartGroup = 'box-restart';
        const restartAnimation = createFakeAnimation({ duration: 250 });
        const restartElement = {
            id: restartGroup,
            animate: vi.fn(() => restartAnimation)
        };
        elements.set(restartGroup, restartElement);

        await ports.send({
            type: 'animate',
            elements: {
                [restartGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 250, easing: 'linear', version: 1 }
                    ]
                }
            }
        });
        await ports.send({ type: 'restart', elementId: restartGroup });

        expect(stoppedAnimation.finishCalls).toBeGreaterThanOrEqual(1);
        expect(resetAnimation.cancelCalls).toBeGreaterThanOrEqual(1);
        expect(restartAnimation.cancelCalls).toBeGreaterThanOrEqual(1);
        expect(restartAnimation.playCalls).toBeGreaterThanOrEqual(1);

        expect(events).toEqual(
            expect.arrayContaining([
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({ animGroup: stoppedGroup, status: 'stopped' })
                }),
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({ animGroup: resetGroup, status: 'reset' })
                }),
                expect.objectContaining({
                    type: 'animationUpdate',
                    engine: 'waapi',
                    payload: expect.objectContaining({ animGroup: restartGroup, status: 'restarted' })
                })
            ])
        );
    });

    it('setProperties sets inline styles and cancels existing animations', async () => {
        const animGroup = 'box-set-props';
        const animation = createFakeAnimation({ duration: 300 });
        const element = {
            id: animGroup,
            style: {},
            animate: vi.fn(() => animation),
            getAnimations: vi.fn(() => [animation])
        };
        installDom({ element, targetId: animGroup });

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 300, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        await ports.send({
            type: 'setProperties',
            updates: [
                {
                    elementId: animGroup,
                    properties: {
                        opacity: 0.5,
                        x: 10, y: 20, z: 0,
                        scaleX: 1, scaleY: 1, scaleZ: 1,
                        rotateX: 0, rotateY: 0, rotateZ: 45,
                        skewX: 0, skewY: 0
                    }
                }
            ]
        });

        expect(animation.cancelCalls).toBeGreaterThanOrEqual(1);
        expect(element.style.opacity).toBe('0.5');
        expect(element.style.transform).toBeDefined();
    });

    it('runs animations on multiple elements sharing the same data-anim-target', async () => {
        const animGroup = 'box-multi';
        const animations = [createFakeAnimation({ duration: 200 }), createFakeAnimation({ duration: 200 })];
        const elements = [
            { id: animGroup + '__multi_0', animate: vi.fn(() => animations[0]) },
            { id: animGroup + '__multi_1', animate: vi.fn(() => animations[1]) }
        ];

        global.CSS = { escape: (value) => value };
        global.performance = { now: () => 100 };
        global.requestAnimationFrame = vi.fn(() => 1);
        global.cancelAnimationFrame = vi.fn();
        global.document = {
            documentElement: { id: 'document' },
            head: { appendChild() { } },
            createElement() {
                return { setAttribute() { }, addEventListener() { }, onload: null, onerror: null };
            },
            querySelector(selector) {
                if (selector === `[data-anim-target="${animGroup}"]`) return elements[0];
                return null;
            },
            querySelectorAll(selector) {
                if (selector === `[data-anim-target="${animGroup}"]`) return elements;
                return [];
            },
            getElementById() { return null; }
        };
        global.window = {
            getComputedStyle() {
                return {
                    opacity: '1',
                    width: '50px',
                    height: '50px',
                    getPropertyValue(prop) {
                        if (prop === 'color') return 'rgb(0,0,0)';
                        if (prop === 'background-color') return 'rgb(0,0,0)';
                        return '';
                    }
                };
            }
        };

        const events = [];
        const ports = createPorts((payload) => events.push(payload));
        ElmMotion.init(ports.ports);

        await ports.send({
            type: 'animate',
            elements: {
                [animGroup]: {
                    properties: [
                        { type: 'opacity', startValue: 0, endValue: 1, duration: 200, easing: 'linear', version: 1 }
                    ]
                }
            }
        });

        expect(elements[0].animate).toHaveBeenCalledTimes(1);
        expect(elements[1].animate).toHaveBeenCalledTimes(1);

        const startedEvents = events
            .filter((event) => event.type === 'animationUpdate' && event.payload?.status === 'started');
        expect(startedEvents).toHaveLength(2);

        const groups = startedEvents.map((event) => event.payload.animGroup);
        expect(groups).toContain(animGroup + '__multi_0');
        expect(groups).toContain(animGroup + '__multi_1');
    });
});
