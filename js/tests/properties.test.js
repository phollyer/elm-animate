import { describe, expect, it } from 'vitest';
import {
    interpolateColor,
    buildSimplePropertyKeyframes,
    buildComplexPropertyKeyframes,
    buildPropertyKeyframes,
    resolveScrollDrivenTransformValues
} from '../src/properties.js';

describe('interpolateColor', () => {
    it('returns the start color at progress 0', () => {
        const r = interpolateColor('rgb(0, 0, 0)', 'rgb(255, 255, 255)', 0);
        expect(r).toBe('rgba(0, 0, 0, 1)');
    });

    it('returns the end color at progress 1', () => {
        const r = interpolateColor('rgb(0, 0, 0)', 'rgb(255, 255, 255)', 1);
        expect(r).toBe('rgba(255, 255, 255, 1)');
    });

    it('interpolates rgb channels at the midpoint', () => {
        const r = interpolateColor('rgb(0, 0, 0)', 'rgb(100, 200, 50)', 0.5);
        expect(r).toBe('rgba(50, 100, 25, 1)');
    });

    it('interpolates rgba alpha channels', () => {
        const r = interpolateColor('rgba(0, 0, 0, 0)', 'rgba(0, 0, 0, 1)', 0.5);
        expect(r).toBe('rgba(0, 0, 0, 0.5)');
    });

    it('parses hex colors', () => {
        const r = interpolateColor('#000000', '#ffffff', 0.5);
        // 255 * 0.5 = 127.5 -> rounded to 128
        expect(r).toBe('rgba(128, 128, 128, 1)');
    });

    it('rounds rgb channels to integers', () => {
        const r = interpolateColor('rgb(0, 0, 0)', 'rgb(1, 1, 1)', 0.5);
        // 0.5 -> rounded to 1
        expect(r).toBe('rgba(1, 1, 1, 1)');
    });

    it('falls back to transparent black for unrecognised colors', () => {
        const r = interpolateColor('not-a-color', 'also-not', 0.5);
        expect(r).toBe('rgba(0, 0, 0, 1)');
    });
});

describe('buildSimplePropertyKeyframes', () => {
    it('builds opacity keyframes as strings', () => {
        const k = buildSimplePropertyKeyframes({ type: 'opacity', startValue: 0, endValue: 1 });
        expect(k).toEqual([{ opacity: '0' }, { opacity: '1' }]);
    });

    it('builds size keyframes with px units', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'size',
            startWidth: 10, startHeight: 20,
            endWidth: 30, endHeight: 40
        });
        expect(k).toEqual([
            { width: '10px', height: '20px' },
            { width: '30px', height: '40px' }
        ]);
    });

    it('builds customProperty keyframes with camelCased property name and unit', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'customProperty',
            cssProperty: 'border-radius',
            startValue: 0,
            endValue: 50,
            unit: 'px'
        });
        expect(k).toEqual([
            { borderRadius: '0px' },
            { borderRadius: '50px' }
        ]);
    });

    it('builds customColorProperty keyframes with raw color strings', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'customColorProperty',
            cssProperty: 'background-color',
            startColor: 'rgb(0, 0, 0)',
            endColor: 'rgb(255, 0, 0)'
        });
        expect(k).toEqual([
            { backgroundColor: 'rgb(0, 0, 0)' },
            { backgroundColor: 'rgb(255, 0, 0)' }
        ]);
    });

    it('builds perspectiveOrigin keyframes', () => {
        const k = buildSimplePropertyKeyframes({
            type: 'perspectiveOrigin',
            startX: 0, startY: 0,
            endX: 100, endY: 100,
            unit: '%'
        });
        expect(k).toEqual([
            { perspectiveOrigin: '0% 0%' },
            { perspectiveOrigin: '100% 100%' }
        ]);
    });

    it('returns null for unknown property types', () => {
        expect(buildSimplePropertyKeyframes({ type: 'translate' })).toBeNull();
        expect(buildSimplePropertyKeyframes({ type: 'unknown' })).toBeNull();
    });
});

describe('buildComplexPropertyKeyframes', () => {
    it('emits one keyframe per easing keyframe entry for opacity', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'opacity', startValue: 0, endValue: 1 },
            [0, 0.5, 1]
        );
        expect(k).toEqual([
            { opacity: '0' },
            { opacity: '0.5' },
            { opacity: '1' }
        ]);
    });

    it('emits per-keyframe size values', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'size', startWidth: 0, startHeight: 0, endWidth: 100, endHeight: 100 },
            [0, 0.5, 1]
        );
        expect(k).toEqual([
            { width: '0px', height: '0px' },
            { width: '50px', height: '50px' },
            { width: '100px', height: '100px' }
        ]);
    });

    it('emits per-keyframe customProperty values with unit', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'customProperty', cssProperty: 'border-width', startValue: 0, endValue: 10, unit: 'px' },
            [0, 0.25, 1]
        );
        expect(k).toEqual([
            { borderWidth: '0px' },
            { borderWidth: '2.5px' },
            { borderWidth: '10px' }
        ]);
    });

    it('emits per-keyframe interpolated colors for customColorProperty', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'customColorProperty', cssProperty: 'color', startColor: 'rgb(0, 0, 0)', endColor: 'rgb(100, 100, 100)' },
            [0, 0.5, 1]
        );
        expect(k).toEqual([
            { color: 'rgba(0, 0, 0, 1)' },
            { color: 'rgba(50, 50, 50, 1)' },
            { color: 'rgba(100, 100, 100, 1)' }
        ]);
    });

    it('emits per-keyframe perspectiveOrigin values', () => {
        const k = buildComplexPropertyKeyframes(
            { type: 'perspectiveOrigin', startX: 0, startY: 0, endX: 100, endY: 100, unit: '%' },
            [0, 0.5, 1]
        );
        expect(k).toEqual([
            { perspectiveOrigin: '0% 0%' },
            { perspectiveOrigin: '50% 50%' },
            { perspectiveOrigin: '100% 100%' }
        ]);
    });

    it('returns null for unknown property types', () => {
        expect(buildComplexPropertyKeyframes({ type: 'translate' }, [0, 1])).toBeNull();
    });
});

describe('buildPropertyKeyframes', () => {
    it('returns simple keyframes and a CSS easing string when no easingKeyframes are given', () => {
        const r = buildPropertyKeyframes({ type: 'opacity', startValue: 0, endValue: 1 }, undefined, 'ease-in');
        expect(r.keyframes).toEqual([{ opacity: '0' }, { opacity: '1' }]);
        expect(r.animationEasing).toBe('ease-in');
    });

    it('maps named easings to their cubic-bezier equivalents', () => {
        const r = buildPropertyKeyframes({ type: 'opacity', startValue: 0, endValue: 1 }, undefined, 'ease-in-cubic');
        expect(r.animationEasing).toBe('cubic-bezier(0.55, 0.055, 0.675, 0.19)');
    });

    it('passes through unknown easing strings verbatim', () => {
        const r = buildPropertyKeyframes({ type: 'opacity', startValue: 0, endValue: 1 }, undefined, 'cubic-bezier(0.1, 0.2, 0.3, 0.4)');
        expect(r.animationEasing).toBe('cubic-bezier(0.1, 0.2, 0.3, 0.4)');
    });

    it('builds complex keyframes and forces linear easing when easingKeyframes are given', () => {
        const r = buildPropertyKeyframes(
            { type: 'opacity', startValue: 0, endValue: 1 },
            [0, 0.5, 1],
            'ease-in'
        );
        expect(r.keyframes).toEqual([{ opacity: '0' }, { opacity: '0.5' }, { opacity: '1' }]);
        expect(r.animationEasing).toBe('linear');
    });

    it('falls back to simple keyframes when complex builder returns null', () => {
        // 'translate' has no SIMPLE_KEYFRAME_BUILDERS entry, so simple build also returns null
        const r = buildPropertyKeyframes({ type: 'translate' }, [0, 1], 'linear');
        expect(r.keyframes).toBeNull();
        expect(r.animationEasing).toBe('linear');
    });
});

describe('resolveScrollDrivenTransformValues', () => {
    const currentTransform = {
        x: 0, y: 0, z: 0,
        scaleX: 1, scaleY: 1, scaleZ: 1,
        rotateX: 0, rotateY: 0, rotateZ: 0,
        skewX: 0, skewY: 0
    };

    it('returns the current transform as both start and end when given no properties', () => {
        const { start, end } = resolveScrollDrivenTransformValues([], currentTransform);
        expect(start).toEqual(currentTransform);
        expect(end).toEqual(currentTransform);
    });

    it('returns independent start and end objects (no shared reference)', () => {
        const { start, end } = resolveScrollDrivenTransformValues([], currentTransform);
        start.x = 99;
        expect(end.x).toBe(0);
    });

    it('applies a translate property to the end state on resolved axes', () => {
        const props = [{ type: 'translate', startX: 0, endX: 100, startY: 0, endY: 50, startZ: 0, endZ: 0 }];
        const { start, end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(start.x).toBe(0);
        expect(end.x).toBe(100);
        expect(end.y).toBe(50);
        expect(end.z).toBe(0);
    });

    it('applies a scale property to the end state', () => {
        const props = [{ type: 'scale', startX: 1, endX: 2, startY: 1, endY: 2, startZ: 1, endZ: 1 }];
        const { end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(end.scaleX).toBe(2);
        expect(end.scaleY).toBe(2);
        expect(end.scaleZ).toBe(1);
    });

    it('applies multiple transform properties together', () => {
        const props = [
            { type: 'translate', startX: 0, endX: 10, startY: 0, endY: 0, startZ: 0, endZ: 0 },
            { type: 'rotate', startX: 0, endX: 0, startY: 0, endY: 0, startZ: 0, endZ: 90 }
        ];
        const { end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(end.x).toBe(10);
        expect(end.rotateZ).toBe(90);
    });

    it('ignores properties of unknown type', () => {
        const props = [{ type: 'opacity', startValue: 0, endValue: 1 }];
        const { start, end } = resolveScrollDrivenTransformValues(props, currentTransform);
        expect(start).toEqual(currentTransform);
        expect(end).toEqual(currentTransform);
    });
});
