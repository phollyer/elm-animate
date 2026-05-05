import { describe, expect, it } from 'vitest';
import { buildTransformString } from '../src/index.js';

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

    it('supports custom transform order', () => {
        const value = buildTransformString(1, 2, 3, 1, 1, 1, 4, 5, 6, 0, 0, ['rotate', 'translate', 'scale']);
        expect(value.indexOf('rotateX')).toBeLessThan(value.indexOf('translate3d'));
    });
});
