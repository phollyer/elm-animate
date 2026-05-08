import resolve from '@rollup/plugin-node-resolve';

export default {
    input: 'js/src/index.js',
    plugins: [resolve()],
    output: [
        {
            file: 'dist/elm-motion.mjs',
            format: 'es',
            exports: 'named',
            sourcemap: false
        },
        {
            file: 'dist/elm-motion.js',
            format: 'iife',
            name: 'ElmMotion',
            exports: 'named',
            sourcemap: false
        }
    ]
};
