import { describe, expect, it } from 'vitest';
import { parseIterations, camelCase } from '../src/index.js';

describe('parseIterations', () => {
    it('returns 1 for missing config', () => {
        expect(parseIterations(undefined)).toBe(1);
        expect(parseIterations(null)).toBe(1);
    });

    it('parses finite count', () => {
        expect(parseIterations({ type: 'times', count: 5 })).toBe(5);
    });

    it('parses infinite', () => {
        expect(parseIterations({ type: 'infinite' })).toBe(Infinity);
    });

    it('defaults to once', () => {
        expect(parseIterations({ type: 'once' })).toBe(1);
    });
});

describe('camelCase', () => {
    it('converts kebab-case to camelCase', () => {
        expect(camelCase('background-color')).toBe('backgroundColor');
        expect(camelCase('perspective-origin')).toBe('perspectiveOrigin');
    });
});
