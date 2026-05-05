import { defineConfig } from 'vitest/config';

export default defineConfig({
    test: {
        environment: 'node',
        include: ['js/tests/**/*.test.js'],
        coverage: {
            provider: 'v8',
            reporter: ['text', 'html', 'json-summary'],
            reportsDirectory: 'coverage/js',
            include: ['js/src/**/*.js'],
            thresholds: {
                lines: 44,
                statements: 44,
                functions: 56,
                branches: 44
            }
        }
    }
});
