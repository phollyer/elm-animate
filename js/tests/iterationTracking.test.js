import { describe, expect, it } from 'vitest';
import { updateGroupIteration } from '../src/utils.js';

describe('updateGroupIteration', () => {
    it('fires immediately for single-property groups', () => {
        const perProperty = [0];
        const next = updateGroupIteration(perProperty, 0, 1, 0);
        expect(next).toBe(1);
    });

    it('waits for the slowest property before advancing', () => {
        const perProperty = [0, 0, 0];

        expect(updateGroupIteration(perProperty, 0, 1, 0)).toBeNull();
        expect(updateGroupIteration(perProperty, 1, 1, 0)).toBeNull();
        expect(updateGroupIteration(perProperty, 2, 1, 0)).toBe(1);
    });

    it('does not overcount across properties', () => {
        const perProperty = [0, 0, 0];
        let stored = 0;

        let next = updateGroupIteration(perProperty, 0, 1, stored);
        expect(next).toBeNull();

        next = updateGroupIteration(perProperty, 1, 1, stored);
        expect(next).toBeNull();

        next = updateGroupIteration(perProperty, 2, 1, stored);
        expect(next).toBe(1);
        stored = next;

        next = updateGroupIteration(perProperty, 0, 2, stored);
        expect(next).toBeNull();

        next = updateGroupIteration(perProperty, 1, 2, stored);
        expect(next).toBeNull();

        next = updateGroupIteration(perProperty, 2, 2, stored);
        expect(next).toBe(2);
    });

    it('ignores invalid property indexes', () => {
        const perProperty = [0, 0];
        expect(updateGroupIteration(perProperty, -1, 1, 0)).toBeNull();
        expect(updateGroupIteration(perProperty, 2, 1, 0)).toBeNull();
    });
});
