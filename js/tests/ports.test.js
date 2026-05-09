import { describe, expect, it } from 'vitest';
import { buildAnimatedPropertyData } from '../src/ports.js';

describe('buildAnimatedPropertyData (null computedStyle)', () => {
    const transformState = {
        x: 10, y: 20, z: 30,
        rotateX: 0, rotateY: 0, rotateZ: 45,
        skewX: 0, skewY: 0,
        scaleX: 1, scaleY: 1, scaleZ: 1
    };

    it('returns transform-only data when computedStyle is null', () => {
        const data = buildAnimatedPropertyData('grp', { transform: 1 }, transformState, null, null);
        expect(data.translate).toEqual({ x: 10, y: 20, z: 30 });
        expect(data.rotate).toEqual({ x: 0, y: 0, z: 45 });
        expect(data.skew).toEqual({ x: 0, y: 0 });
        expect(data.scale).toEqual({ x: 1, y: 1, z: 1 });
        expect(data.opacity).toBeUndefined();
        expect(data.size).toBeUndefined();
    });

    it('returns empty object when no properties versioned and no computedStyle', () => {
        expect(buildAnimatedPropertyData('grp', {}, transformState, null, null)).toEqual({});
    });

    it('does not throw when non-transform keys are present but computedStyle is null', () => {
        // Defensive: callers should never pass non-transform keys with null
        // computedStyle, but verify the early-return guard prevents NPEs.
        expect(() =>
            buildAnimatedPropertyData('grp', { transform: 1, opacity: 1 }, transformState, null, null)
        ).not.toThrow();
    });

    it('reads from computedStyle when provided', () => {
        const computedStyle = { opacity: '0.5', width: '100px', height: '200px' };
        const data = buildAnimatedPropertyData('grp', { opacity: 1, size: 1 }, transformState, null, computedStyle);
        expect(data.opacity).toBe(0.5);
        expect(data.size).toEqual({ width: 100, height: 200 });
        expect(data.translate).toBeUndefined();
    });
});
