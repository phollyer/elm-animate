import { describe, expect, it } from 'vitest';
import {
    getDefaultTransformState,
    normalizeTransformState,
    buildTransformString,
    parseTransformString,
    interpolateSubProperty,
    computeTransformFromResolved
} from '../src/transform.js';

describe('getDefaultTransformState', () => {
    it('returns the identity transform', () => {
        expect(getDefaultTransformState()).toEqual({
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0
        });
    });

    it('returns a fresh object on each call (no shared mutation)', () => {
        const a = getDefaultTransformState();
        a.x = 99;
        expect(getDefaultTransformState().x).toBe(0);
    });
});

describe('normalizeTransformState', () => {
    it('returns identity when input is null', () => {
        expect(normalizeTransformState(null)).toEqual(getDefaultTransformState());
    });

    it('returns identity when input is undefined', () => {
        expect(normalizeTransformState(undefined)).toEqual(getDefaultTransformState());
    });

    it('preserves all numeric fields verbatim', () => {
        const input = {
            x: 10, y: 20, z: 30,
            scaleX: 2, scaleY: 3, scaleZ: 4,
            rotateX: 45, rotateY: 90, rotateZ: 180,
            skewX: 5, skewY: 6
        };
        expect(normalizeTransformState(input)).toEqual(input);
    });

    it('falls back to default for missing skew fields (partial cached state)', () => {
        const partial = { x: 1, y: 2, z: 3, scaleX: 1, scaleY: 1, scaleZ: 1, rotateX: 0, rotateY: 0, rotateZ: 0 };
        const result = normalizeTransformState(partial);
        expect(result.skewX).toBe(0);
        expect(result.skewY).toBe(0);
        expect(result.x).toBe(1);
    });

    it('replaces NaN values with defaults', () => {
        const result = normalizeTransformState({ x: NaN, y: 5, scaleX: NaN });
        expect(result.x).toBe(0);
        expect(result.y).toBe(5);
        expect(result.scaleX).toBe(1);
    });

    it('replaces Infinity with defaults (not finite)', () => {
        const result = normalizeTransformState({ x: Infinity, y: -Infinity });
        expect(result.x).toBe(0);
        expect(result.y).toBe(0);
    });
});

describe('buildTransformString', () => {
    it('builds a transform string in default order', () => {
        const value = buildTransformString(10, 20, 30, 2, 3, 4, 15, 25, 35, 5, 6);
        expect(value).toContain('translate3d(10px, 20px, 30px)');
        expect(value).toContain('rotateX(15deg)');
        expect(value).toContain('rotateY(25deg)');
        expect(value).toContain('rotateZ(35deg)');
        expect(value).toContain('skewX(5deg)');
        expect(value).toContain('skewY(6deg)');
        expect(value).toContain('scaleX(2)');
        expect(value).toContain('scaleY(3)');
        expect(value).toContain('scaleZ(4)');
    });

    it('respects default order: translate then rotate then skew then scale', () => {
        const value = buildTransformString(10, 0, 0, 2, 1, 1, 15, 0, 0, 5, 0);
        expect(value.indexOf('translate3d')).toBeLessThan(value.indexOf('rotateX'));
        expect(value.indexOf('rotateX')).toBeLessThan(value.indexOf('skewX'));
        expect(value.indexOf('skewX')).toBeLessThan(value.indexOf('scaleX'));
    });

    it('supports custom transform order', () => {
        const value = buildTransformString(1, 2, 3, 1, 1, 1, 4, 5, 6, 0, 0, ['rotate', 'translate', 'scale']);
        expect(value.indexOf('rotateX')).toBeLessThan(value.indexOf('translate3d'));
    });

    it('omits identity-valued translate', () => {
        const value = buildTransformString(0, 0, 0, 2, 1, 1, 0, 0, 0, 0, 0);
        expect(value).not.toContain('translate3d');
        expect(value).toContain('scaleX(2)');
    });

    it('omits identity-valued rotate axes individually', () => {
        const value = buildTransformString(0, 0, 0, 1, 1, 1, 0, 90, 0, 0, 0);
        expect(value).not.toContain('rotateX');
        expect(value).toContain('rotateY(90deg)');
        expect(value).not.toContain('rotateZ');
    });

    it('omits identity-valued scale axes individually', () => {
        const value = buildTransformString(0, 0, 0, 2, 1, 1, 0, 0, 0, 0, 0);
        expect(value).toContain('scaleX(2)');
        expect(value).not.toContain('scaleY');
        expect(value).not.toContain('scaleZ');
    });

    it('omits identity-valued skew axes individually', () => {
        const value = buildTransformString(0, 0, 0, 1, 1, 1, 0, 0, 0, 5, 0);
        expect(value).toContain('skewX(5deg)');
        expect(value).not.toContain('skewY');
    });

    it('returns "none" when all values are identity', () => {
        expect(buildTransformString(0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0)).toBe('none');
    });

    it('coerces NaN inputs to identity defaults', () => {
        const value = buildTransformString(NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN);
        expect(value).toBe('none');
    });

    it('emits negative translate values correctly', () => {
        const value = buildTransformString(-10, -20, 0, 1, 1, 1, 0, 0, 0, 0, 0);
        expect(value).toContain('translate3d(-10px, -20px, 0px)');
    });
});

describe('parseTransformString', () => {
    it('parses translate3d', () => {
        const r = parseTransformString('translate3d(10px, 20px, 30px)');
        expect(r.x).toBe(10);
        expect(r.y).toBe(20);
        expect(r.z).toBe(30);
    });

    it('parses individual translateX/Y/Z (overriding translate3d)', () => {
        const r = parseTransformString('translateX(5px) translateY(15px) translateZ(25px)');
        expect(r.x).toBe(5);
        expect(r.y).toBe(15);
        expect(r.z).toBe(25);
    });

    it('parses rotateX/Y/Z', () => {
        const r = parseTransformString('rotateX(10deg) rotateY(20deg) rotateZ(30deg)');
        expect(r.rotateX).toBe(10);
        expect(r.rotateY).toBe(20);
        expect(r.rotateZ).toBe(30);
    });

    it('parses skewX/Y individually', () => {
        const r = parseTransformString('skewX(5deg) skewY(7deg)');
        expect(r.skewX).toBe(5);
        expect(r.skewY).toBe(7);
    });

    it('parses skew(x, y) 2D shorthand when individual skewX/Y absent', () => {
        const r = parseTransformString('skew(10deg, 20deg)');
        expect(r.skewX).toBe(10);
        expect(r.skewY).toBe(20);
    });

    it('parses skew(x) shorthand and treats y as 0', () => {
        const r = parseTransformString('skew(10deg)');
        expect(r.skewX).toBe(10);
        expect(r.skewY).toBe(0);
    });

    it('parses scale3d', () => {
        const r = parseTransformString('scale3d(2, 3, 4)');
        expect(r.scaleX).toBe(2);
        expect(r.scaleY).toBe(3);
        expect(r.scaleZ).toBe(4);
    });

    it('parses individual scaleX/Y/Z (overriding scale3d)', () => {
        const r = parseTransformString('scaleX(5) scaleY(6) scaleZ(7)');
        expect(r.scaleX).toBe(5);
        expect(r.scaleY).toBe(6);
        expect(r.scaleZ).toBe(7);
    });

    it('parses scale(x, y) 2D shorthand', () => {
        const r = parseTransformString('scale(2, 3)');
        expect(r.scaleX).toBe(2);
        expect(r.scaleY).toBe(3);
    });

    it('parses scale(x) shorthand and applies x to y', () => {
        const r = parseTransformString('scale(2)');
        expect(r.scaleX).toBe(2);
        expect(r.scaleY).toBe(2);
    });

    it('returns identity defaults for empty input', () => {
        const r = parseTransformString('');
        expect(r.x).toBe(0);
        expect(r.scaleX).toBe(1);
        expect(r.rotateX).toBe(0);
        expect(r.skewX).toBe(0);
    });

    it('preserves the original transform string in the result', () => {
        const r = parseTransformString('translate3d(1px, 2px, 3px)');
        expect(r.transform).toBe('translate3d(1px, 2px, 3px)');
    });

    it('parses negative and decimal values', () => {
        const r = parseTransformString('translate3d(-1.5px, -2.25px, 0px) rotateX(-45.5deg) scale(0.5)');
        expect(r.x).toBe(-1.5);
        expect(r.y).toBe(-2.25);
        expect(r.rotateX).toBe(-45.5);
        expect(r.scaleX).toBe(0.5);
    });
});

describe('interpolateSubProperty', () => {
    const linearSubProp = {
        startX: 0, startY: 0, startZ: 0,
        endX: 100, endY: 200, endZ: 300,
        duration: 1000
    };

    it('returns start values at progress 0', () => {
        const r = interpolateSubProperty(linearSubProp, 0, 1000);
        expect(r.x).toBe(0);
        expect(r.y).toBe(0);
        expect(r.z).toBe(0);
    });

    it('returns end values at progress 1', () => {
        const r = interpolateSubProperty(linearSubProp, 1, 1000);
        expect(r.x).toBe(100);
        expect(r.y).toBe(200);
        expect(r.z).toBe(300);
    });

    it('interpolates linearly at the midpoint when no easingKeyframes', () => {
        const r = interpolateSubProperty(linearSubProp, 0.5, 1000);
        expect(r.x).toBe(50);
        expect(r.y).toBe(100);
        expect(r.z).toBe(150);
    });

    it('clamps local progress to 1 when sub-prop duration is shorter than max', () => {
        const shortSubProp = { ...linearSubProp, duration: 500 };
        // Global progress 0.6 -> local progress 0.6 / 0.5 = 1.2 -> clamped to 1
        const r = interpolateSubProperty(shortSubProp, 0.6, 1000);
        expect(r.x).toBe(100);
    });

    it('treats duration <= 0 as ratio 1 (no scaling, falls back to linear by globalProgress)', () => {
        const zeroDur = { ...linearSubProp, duration: 0 };
        const r = interpolateSubProperty(zeroDur, 0.5, 1000);
        // durationRatio fallback = 1 -> localProgress = globalProgress = 0.5
        expect(r.x).toBe(50);
    });

    it('uses easingKeyframes when provided', () => {
        const sub = { ...linearSubProp, easingKeyframes: [0, 0.25, 1] };
        // At globalProgress 0.5, len=3, rawIdx = 1, idx=1, fraction=0
        // easedProgress = easingKeyframes[1] = 0.25
        const r = interpolateSubProperty(sub, 0.5, 1000);
        expect(r.x).toBe(25);
    });

    it('linearly interpolates between easingKeyframes entries', () => {
        const sub = { ...linearSubProp, easingKeyframes: [0, 0.5, 1] };
        // globalProgress 0.25, rawIdx = 0.5, idx=0, fraction=0.5
        // easedProgress = 0 + (0.5 - 0) * 0.5 = 0.25
        const r = interpolateSubProperty(sub, 0.25, 1000);
        expect(r.x).toBe(25);
    });

    it('falls back to linear when easingKeyframes has 0 or 1 entries', () => {
        const sub = { ...linearSubProp, easingKeyframes: [0.5] };
        const r = interpolateSubProperty(sub, 0.5, 1000);
        expect(r.x).toBe(50);
    });
});

describe('computeTransformFromResolved', () => {
    const resolved = {
        translate: { startX: 0, startY: 0, startZ: 0, endX: 100, endY: 0, endZ: 0, duration: 1000 },
        scale:     { startX: 1, startY: 1, startZ: 1, endX: 2,   endY: 2, endZ: 2, duration: 1000 },
        rotate:    { startX: 0, startY: 0, startZ: 0, endX: 90,  endY: 0, endZ: 0, duration: 1000 },
        skew:      { startX: 0, startY: 0, startZ: 0, endX: 10,  endY: 0, endZ: 0, duration: 1000 }
    };

    it('returns start state at progress 0', () => {
        const r = computeTransformFromResolved(resolved, 0, 1000);
        expect(r.x).toBe(0);
        expect(r.scaleX).toBe(1);
        expect(r.rotateX).toBe(0);
        expect(r.skewX).toBe(0);
    });

    it('returns end state at progress 1', () => {
        const r = computeTransformFromResolved(resolved, 1, 1000);
        expect(r.x).toBe(100);
        expect(r.scaleX).toBe(2);
        expect(r.rotateX).toBe(90);
        expect(r.skewX).toBe(10);
    });

    it('returns midpoint values at progress 0.5', () => {
        const r = computeTransformFromResolved(resolved, 0.5, 1000);
        expect(r.x).toBe(50);
        expect(r.scaleX).toBe(1.5);
        expect(r.rotateX).toBe(45);
        expect(r.skewX).toBe(5);
    });

    it('flattens sub-property axes onto the unified state shape', () => {
        const r = computeTransformFromResolved(resolved, 0.5, 1000);
        expect(r).toHaveProperty('x');
        expect(r).toHaveProperty('y');
        expect(r).toHaveProperty('z');
        expect(r).toHaveProperty('scaleX');
        expect(r).toHaveProperty('rotateX');
        expect(r).toHaveProperty('skewX');
        expect(r).toHaveProperty('skewY');
    });
});
