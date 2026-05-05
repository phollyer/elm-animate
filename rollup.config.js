import resolve from '@rollup/plugin-node-resolve';

export default {
    input: 'js/src/index.js',
    plugins: [resolve()],
    output: [
        {
            file: 'dist/elm-animate-waapi.mjs',
            format: 'es',
            exports: 'named',
            sourcemap: false
        },
        {
            file: 'dist/elm-animate-waapi.js',
            format: 'iife',
            name: 'ElmAnimateWAAPI',
            exports: 'named',
            sourcemap: false
        }
    ]
};
