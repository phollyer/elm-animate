/* eslint-env node */
/* global global */
import { vi } from 'vitest';

export function createFakeAnimation({ duration = 1000, currentIteration = 0, progress = 0 } = {}) {
    const listeners = new Map();

    return {
        currentTime: 0,
        playState: 'idle',
        pauseCalls: 0,
        playCalls: 0,
        finishCalls: 0,
        cancelCalls: 0,
        effect: {
            getTiming() {
                return { duration };
            },
            getComputedTiming() {
                return { currentIteration, progress };
            }
        },
        addEventListener(type, handler) {
            if (!listeners.has(type)) {
                listeners.set(type, []);
            }
            listeners.get(type).push(handler);
        },
        trigger(type) {
            const handlers = listeners.get(type) || [];
            handlers.forEach((handler) => handler());
        },
        cancel() {
            this.cancelCalls++;
            this.playState = 'idle';
            this.trigger('cancel');
        },
        pause() {
            this.pauseCalls++;
            this.playState = 'paused';
        },
        play() {
            this.playCalls++;
            this.playState = 'running';
        },
        finish() {
            this.finishCalls++;
            this.playState = 'finished';
            this.trigger('finish');
        },
        commitStyles() { }
    };
}

export function installDom({ element, queryAll = [], targetId = 'box', sourceId = 'source' } = {}) {
    global.CSS = { escape: (value) => value };
    global.performance = { now: () => 100 };
    global.requestAnimationFrame = vi.fn(() => 1);
    global.cancelAnimationFrame = vi.fn();

    global.document = {
        documentElement: { id: 'document' },
        head: {
            appendChild() { }
        },
        createElement() {
            return {
                setAttribute() { },
                addEventListener() { },
                onload: null,
                onerror: null
            };
        },
        querySelector(selector) {
            if (selector === `[data-anim-target="${targetId}"]`) return element;
            if (selector === `[data-anim-target="${sourceId}"]`) return { id: sourceId };
            return null;
        },
        querySelectorAll(selector) {
            if (selector === `[data-anim-target="${targetId}"]`) return queryAll;
            return [];
        },
        getElementById(id) {
            if (id === targetId) return element;
            if (id === sourceId) return { id: sourceId };
            return null;
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
        },
        ScrollTimeline: global.ScrollTimeline,
        ViewTimeline: global.ViewTimeline
    };
}

export function createPorts(eventSink) {
    let subscriber = null;

    return {
        ports: {
            waapiCommand: {
                subscribe(fn) {
                    subscriber = fn;
                }
            },
            waapiEvent: {
                send: eventSink
            }
        },
        send(command) {
            return subscriber(command);
        }
    };
}

export function cleanupDom() {
    delete global.window;
    delete global.document;
    delete global.CSS;
    delete global.performance;
    delete global.requestAnimationFrame;
    delete global.cancelAnimationFrame;
    delete global.ScrollTimeline;
    delete global.ViewTimeline;
}
