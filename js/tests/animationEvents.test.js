import { describe, expect, it, vi } from 'vitest';
import { commitAnimatedStyles, needsComputedStyle } from '../src/animationEvents.js';

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
