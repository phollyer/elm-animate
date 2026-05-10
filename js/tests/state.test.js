import { afterEach, describe, expect, it } from 'vitest';
import {
    activeAnimations,
    animationGroups,
    cleanupAnimGroup,
    clearAllState,
    elementTransformOrders,
    lastKnownPerspectiveOrigins,
    lastKnownTransforms,
    scrollDrivenIterationCounts
} from '../src/state.js';

afterEach(() => {
    clearAllState();
});

describe('cleanupAnimGroup', () => {
    it('drops per-group entries from every Map except lastKnownPerspectiveOrigins', () => {
        const group = 'grp';
        activeAnimations.set(group, new Map());
        animationGroups.set(group, {});
        lastKnownTransforms.set(group, {});
        lastKnownPerspectiveOrigins.set(group, { x: 100, y: 0, unit: '%' });
        scrollDrivenIterationCounts.set(group, 1);
        elementTransformOrders.set(group, []);

        cleanupAnimGroup(group);

        expect(activeAnimations.has(group)).toBe(false);
        expect(animationGroups.has(group)).toBe(false);
        expect(lastKnownTransforms.has(group)).toBe(false);
        expect(scrollDrivenIterationCounts.has(group)).toBe(false);
        expect(elementTransformOrders.has(group)).toBe(false);

        // lastKnownPerspectiveOrigins must persist so a subsequent
        // animation in the same group keeps the user's chosen unit.
        // CSS getComputedStyle(...).perspectiveOrigin always reports
        // pixels, so without the cached unit the runtime baseline
        // reported back to Elm would silently switch to px and the
        // next animation would be encoded with mismatched start (px)
        // and end (%) values.
        expect(lastKnownPerspectiveOrigins.get(group)).toEqual({ x: 100, y: 0, unit: '%' });
    });
});

describe('clearAllState', () => {
    it('drops every entry from every Map including lastKnownPerspectiveOrigins', () => {
        const group = 'grp';
        activeAnimations.set(group, new Map());
        animationGroups.set(group, {});
        lastKnownTransforms.set(group, {});
        lastKnownPerspectiveOrigins.set(group, { x: 100, y: 0, unit: '%' });
        scrollDrivenIterationCounts.set(group, 1);
        elementTransformOrders.set(group, []);

        clearAllState();

        expect(activeAnimations.size).toBe(0);
        expect(animationGroups.size).toBe(0);
        expect(lastKnownTransforms.size).toBe(0);
        expect(lastKnownPerspectiveOrigins.size).toBe(0);
        expect(scrollDrivenIterationCounts.size).toBe(0);
        expect(elementTransformOrders.size).toBe(0);
    });
});
