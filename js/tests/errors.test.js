/* eslint-env node */
import { afterEach, describe, expect, it, vi } from 'vitest';
import {
    onError,
    useConsoleReporter,
    reportError,
    _resetSubscribers
} from '../src/errors.js';

afterEach(() => {
    _resetSubscribers();
});

describe('errors module', () => {
    it('is silent when no subscribers are registered', () => {
        // No throw, no console output (we don't spy on console here because
        // reportError must not touch it without a subscriber).
        expect(() => reportError('boom', { source: 'test' })).not.toThrow();
    });

    it('delivers errors to a registered subscriber', () => {
        const handler = vi.fn();
        onError(handler);

        reportError('boom', { source: 'test', code: 'TEST_CODE' });

        expect(handler).toHaveBeenCalledTimes(1);
        const [errorArg, ctxArg] = handler.mock.calls[0];
        expect(errorArg).toBeInstanceOf(Error);
        expect(errorArg.message).toBe('boom');
        expect(ctxArg).toMatchObject({
            source: 'test',
            severity: 'error',
            code: 'TEST_CODE'
        });
    });

    it('preserves Error instances and their stack', () => {
        const handler = vi.fn();
        onError(handler);

        const original = new Error('original');
        reportError(original, { source: 'test' });

        expect(handler.mock.calls[0][0]).toBe(original);
    });

    it('defaults severity to "error" and source to "unknown"', () => {
        const handler = vi.fn();
        onError(handler);

        reportError('plain');

        const ctxArg = handler.mock.calls[0][1];
        expect(ctxArg.severity).toBe('error');
        expect(ctxArg.source).toBe('unknown');
    });

    it('returns an unsubscribe function from onError', () => {
        const handler = vi.fn();
        const off = onError(handler);

        reportError('first', { source: 'test' });
        off();
        reportError('second', { source: 'test' });

        expect(handler).toHaveBeenCalledTimes(1);
    });

    it('supports multiple subscribers, all receive each report', () => {
        const a = vi.fn();
        const b = vi.fn();
        onError(a);
        onError(b);

        reportError('boom', { source: 'test' });

        expect(a).toHaveBeenCalledTimes(1);
        expect(b).toHaveBeenCalledTimes(1);
    });

    it('isolates a throwing subscriber: other subscribers still run', () => {
        const bad = vi.fn(() => { throw new Error('handler crashed'); });
        const good = vi.fn();
        onError(bad);
        onError(good);

        expect(() => reportError('boom', { source: 'test' })).not.toThrow();
        expect(good).toHaveBeenCalledTimes(1);
    });

    it('ignores non-function handlers', () => {
        // @ts-expect-error - intentional misuse
        const off = onError('not a function');
        expect(typeof off).toBe('function');
        // No subscribers should be registered
        expect(() => reportError('boom', { source: 'test' })).not.toThrow();
    });

    describe('useConsoleReporter', () => {
        it('logs error reports via console.error by default', () => {
            const target = { warn: vi.fn(), error: vi.fn() };
            useConsoleReporter({ target });

            reportError('boom', { source: 'test', code: 'TEST_CODE', engine: 'WAAPI' });

            expect(target.error).toHaveBeenCalledTimes(1);
            expect(target.warn).not.toHaveBeenCalled();
            const [label, message, summary] = target.error.mock.calls[0];
            expect(label).toBe('[ElmMotion:test]');
            expect(message).toBe('boom');
            expect(summary).toMatchObject({ code: 'TEST_CODE', engine: 'WAAPI' });
        });

        it('logs warning reports via console.warn', () => {
            const target = { warn: vi.fn(), error: vi.fn() };
            useConsoleReporter({ target });

            reportError('soft', { source: 'test', severity: 'warning' });

            expect(target.warn).toHaveBeenCalledTimes(1);
            expect(target.error).not.toHaveBeenCalled();
        });

        it('emits the full error and context when verbose=true', () => {
            const target = { warn: vi.fn(), error: vi.fn() };
            useConsoleReporter({ target, verbose: true });

            const original = new Error('boom');
            reportError(original, { source: 'test', code: 'TEST_CODE' });

            const [label, errorArg, ctxArg] = target.error.mock.calls[0];
            expect(label).toBe('[ElmMotion:test]');
            expect(errorArg).toBe(original);
            expect(ctxArg).toMatchObject({ source: 'test', code: 'TEST_CODE', severity: 'error' });
        });

        it('returns an unsubscribe function', () => {
            const target = { warn: vi.fn(), error: vi.fn() };
            const off = useConsoleReporter({ target });

            reportError('first', { source: 'test' });
            off();
            reportError('second', { source: 'test' });

            expect(target.error).toHaveBeenCalledTimes(1);
        });
    });
});
