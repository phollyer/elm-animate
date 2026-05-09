// Pure utility functions — no browser globals, no DOM access, no side effects.

/** Default CSS transform property order. */
export const DEFAULT_TRANSFORM_ORDER = ['translate', 'rotate', 'skew', 'scale'];

/** CSS easing function map: Elm name → WAAPI CSS value. */
export const easingFunctions = {
    'linear': 'linear',
    'ease': 'ease',
    'ease-in': 'ease-in',
    'ease-out': 'ease-out',
    'ease-in-out': 'ease-in-out',
    'ease-in-cubic': 'cubic-bezier(0.55, 0.055, 0.675, 0.19)',
    'ease-out-cubic': 'cubic-bezier(0.215, 0.61, 0.355, 1)',
    'ease-in-out-cubic': 'cubic-bezier(0.645, 0.045, 0.355, 1)',
    'ease-in-back': 'cubic-bezier(0.6, -0.28, 0.735, 0.045)',
    'ease-out-back': 'cubic-bezier(0.175, 0.885, 0.32, 1.275)',
    'ease-in-out-back': 'cubic-bezier(0.68, -0.55, 0.265, 1.55)'
};

/**
 * Returns true if the property type is a CSS transform sub-property.
 * @param {string} type
 */
export function isTransformProperty(type) {
    return type === 'translate' || type === 'scale' || type === 'rotate' || type === 'skew';
}

/**
 * Parse an Elm iterations config object to a WAAPI iterations value.
 * @param {object|undefined} iterations
 * @returns {number}
 */
export function parseIterations(iterations) {
    if (!iterations) return 1;
    switch (iterations.type) {
        case 'infinite': return Infinity;
        case 'times': return iterations.count;
        case 'once':
        default: return 1;
    }
}

/**
 * Convert a kebab-case CSS property name to camelCase for WAAPI keyframes.
 * e.g. "border-radius" → "borderRadius"
 * @param {string} str
 */
export function camelCase(str) {
    return str.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

/**
 * Slowest-wins group iteration tracking.
 * Each property updates its own slot in perAnimIterations. The group iteration
 * event fires only when ALL properties have completed the same loop
 * (i.e. Math.min of all slots advances past storedCount).
 * @param {number[]} perAnimIterations - Per-property iteration slots (mutated)
 * @param {number} propertyIndex - Index of the updating property
 * @param {number|undefined} currentIteration - Current iteration from WAAPI timing
 * @param {number} storedCount - Last emitted iteration count
 * @returns {number|null} New group iteration count, or null if unchanged
 */
export function updateGroupIteration(perAnimIterations, propertyIndex, currentIteration, storedCount) {
    if (currentIteration == null || propertyIndex < 0 || propertyIndex >= perAnimIterations.length) {
        return null;
    }
    perAnimIterations[propertyIndex] = currentIteration;
    const minIteration = Math.min.apply(null, perAnimIterations);
    return minIteration > storedCount ? minIteration : null;
}
