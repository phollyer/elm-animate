import { describe, expect, it } from 'vitest';
import { needsComputedStyle } from '../src/animationEvents.js';

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
