import resolve from '@rollup/plugin-node-resolve';

export default {
    input: 'js/src/index.js',
    plugins: [resolve()],
    // Inline the dynamically-imported scroll-timeline polyfill into the bundle
    // rather than emitting a separate chunk. This keeps the published artifact
    // self-contained (no runtime CDN fetch, no extra files to host) and works
    // for both ESM and IIFE outputs. The polyfill IIFE only runs when a
    // ScrollTimeline / ViewTimeline command first arrives, so no overhead for
    // consumers that only use the WAAPI engine.
    output: [
        {
            file: 'dist/elm-motion.mjs',
            format: 'es',
            exports: 'named',
            inlineDynamicImports: true,
            sourcemap: true
        },
        {
            file: 'dist/elm-motion.js',
            format: 'iife',
            name: 'ElmMotion',
            exports: 'named',
            inlineDynamicImports: true,
            sourcemap: true
        }
    ]
};
