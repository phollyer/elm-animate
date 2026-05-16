import { afterEach, describe, expect, it, vi } from 'vitest';
import { commitAnimatedStyles, needsComputedStyle, setupAnimationEvents } from '../src/animationEvents.js';
import { activeAnimations, animationGroups, clearAllState, portsRef } from '../src/state.js';
import { cleanupDom, createFakeAnimation, installDom } from './_publicApiHelpers.js';

describe('needsComputedStyle', () => {
    it('returns false for empty propertyVersions', () => {
        expect(needsComputedStyle({})).toBe(false);
    });

    it('returns false for transform-only animations', () => {
        expect(needsComputedStyle({ transform: 1 })).toBe(false);
    });

    it('returns true when opacity is animated', () => {
        expect(needsComputedStyle({ opacity: 1 })).toBe(true);
    });

    it('returns true when size is animated', () => {
        expect(needsComputedStyle({ size: 1 })).toBe(true);
    });

    it('returns true when perspectiveOrigin is animated', () => {
        expect(needsComputedStyle({ perspectiveOrigin: 1 })).toBe(true);
    });

    it('returns true alongside transform when any non-transform key is present', () => {
        expect(needsComputedStyle({ transform: 1, opacity: 2 })).toBe(true);
    });

    it('returns true for custom numeric properties', () => {
        expect(needsComputedStyle({ 'custom:--my-var': 1 })).toBe(true);
    });

    it('returns true for custom color properties', () => {
        expect(needsComputedStyle({ 'customColor:background-color': 1 })).toBe(true);
    });

    it('does not match unrelated keys with similar prefixes', () => {
        expect(needsComputedStyle({ customary: 1, transformative: 2 })).toBe(false);
    });
});

describe('commitAnimatedStyles', () => {
    function makeElement() {
        const inline = {};
        return {
            style: {
                setProperty(name, value) { inline[name] = value; }
            },
            inline
        };
    }

    function makeAnimation({ keyframes, hasCommitStyles = false }) {
        const animation = {
            effect: keyframes == null ? null : { getKeyframes: () => keyframes }
        };
        if (hasCommitStyles) {
            animation.commitStyles = vi.fn();
        }
        return animation;
    }

    it('delegates to native commitStyles when available', () => {
        const element = makeElement();
        const animation = makeAnimation({ keyframes: [{ width: '160px' }], hasCommitStyles: true });

        commitAnimatedStyles(element, animation);

        expect(animation.commitStyles).toHaveBeenCalledTimes(1);
        expect(element.inline).toEqual({});
    });

    it('writes the final keyframe to inline style when commitStyles is missing', () => {
        const element = makeElement();
        const animation = makeAnimation({
            keyframes: [
                { width: '180px', height: '56px', offset: 0 },
                { width: '160px', height: '50px', offset: 1 }
            ]
        });

        commitAnimatedStyles(element, animation);

        expect(element.inline).toEqual({ width: '160px', height: '50px' });
    });

    it('converts camelCase keyframe properties to kebab-case', () => {
        const element = makeElement();
        const animation = makeAnimation({
            keyframes: [{ backgroundColor: 'red', perspectiveOrigin: '50% 50%' }]
        });

        commitAnimatedStyles(element, animation);

        expect(element.inline).toEqual({
            'background-color': 'red',
            'perspective-origin': '50% 50%'
        });
    });

    it('preserves CSS custom properties (--var) without case mangling', () => {
        const element = makeElement();
        const animation = makeAnimation({
            keyframes: [{ '--my-var': '42px' }]
        });

        commitAnimatedStyles(element, animation);

        expect(element.inline).toEqual({ '--my-var': '42px' });
    });

    it('skips composite, easing, offset, and computedOffset pseudo-keys', () => {
        const element = makeElement();
        const animation = makeAnimation({
            keyframes: [{
                width: '160px',
                composite: 'replace',
                easing: 'linear',
                offset: 1,
                computedOffset: 1
            }]
        });

        commitAnimatedStyles(element, animation);

        expect(element.inline).toEqual({ width: '160px' });
    });

    it('skips null and undefined keyframe values', () => {
        const element = makeElement();
        const animation = makeAnimation({
            keyframes: [{ width: '160px', height: null, opacity: undefined }]
        });

        commitAnimatedStyles(element, animation);

        expect(element.inline).toEqual({ width: '160px' });
    });

    it('is a no-op when the animation has no effect', () => {
        const element = makeElement();
        const animation = makeAnimation({ keyframes: null });

        expect(() => commitAnimatedStyles(element, animation)).not.toThrow();
        expect(element.inline).toEqual({});
    });

    it('is a no-op when keyframes are empty', () => {
        const element = makeElement();
        const animation = makeAnimation({ keyframes: [] });

        expect(() => commitAnimatedStyles(element, animation)).not.toThrow();
        expect(element.inline).toEqual({});
    });
});

describe('setupAnimationEvents propertyUpdate isAnimating', () => {
    afterEach(() => {
        clearAllState();
        portsRef.ports = null;
        cleanupDom();
    });

    function installAndCapture({ playState }) {
        // Capture the rAF callback scheduled by setupAnimationEvents so we
        // can invoke it deterministically, then capture every motionMsg
        // payload sent back through the port.
        const scheduled = [];
        const element = {
            id: 'box',
            style: { setProperty() { } },
            getBoundingClientRect: () => ({ width: 100, height: 50 })
        };
        installDom({ element, targetId: 'box' });
        global.requestAnimationFrame = vi.fn((cb) => {
            scheduled.push(cb);
            return scheduled.length;
        });

        const sent = [];
        portsRef.ports = { motionMsg: { send: (msg) => sent.push(msg) } };

        const animation = createFakeAnimation({ duration: 1000 });
        animation.playState = playState;
        animation.currentTime = 500;

        const elementAnims = new Map();
        elementAnims.set('transform', {
            animation,
            version: 1,
            animGroup: 'box',
            resolvedValues: null,
            generation: 1,
            propertyIndex: 0,
            updateFn: vi.fn()
        });
        activeAnimations.set('box', elementAnims);
        animationGroups.set('box', {
            generation: 1,
            propertyIterations: [0],
            lastIteration: 0,
            propertyConfigs: [{ duration: 1000 }]
        });

        const resolvedTransformValues = {
            translate: { startX: 0, startY: 0, startZ: 0, endX: 100, endY: 0, endZ: 0, duration: 1000 },
            rotate: { startX: 0, startY: 0, startZ: 0, endX: 0, endY: 0, endZ: 0, duration: 0 },
            scale: { startX: 1, startY: 1, startZ: 1, endX: 1, endY: 1, endZ: 1, duration: 0 },
            skew: { startX: 0, startY: 0, endX: 0, endY: 0, duration: 0 }
        };
        setupAnimationEvents('box', 'transform', element, animation, 1, resolvedTransformValues);

        return { scheduled, sent };
    }

    it('reports isAnimating=false when the animation is paused', () => {
        // Regression for Bug 5: after a resize, JS re-creates the WAAPI
        // animation already paused and setupAnimationEvents schedules a
        // single rAF tick. If that tick hardcodes isAnimating=true it
        // flips Elm's AnimGroup back to Running and the next resize's
        // computeResizePayload follows the wrong (mid-flight) code path.
        const { scheduled, sent } = installAndCapture({ playState: 'paused' });

        expect(scheduled).toHaveLength(1);
        scheduled[0]();

        const propertyUpdates = sent.filter((m) => m.type === 'propertyUpdate');
        expect(propertyUpdates).toHaveLength(1);
        expect(propertyUpdates[0].isAnimating).toBe(false);
    });

    it('reports isAnimating=true when the animation is running', () => {
        const { scheduled, sent } = installAndCapture({ playState: 'running' });

        expect(scheduled).toHaveLength(1);
        scheduled[0]();

        const propertyUpdates = sent.filter((m) => m.type === 'propertyUpdate');
        expect(propertyUpdates).toHaveLength(1);
        expect(propertyUpdates[0].isAnimating).toBe(true);
    });
});
