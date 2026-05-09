// Shared mutable state for all animation tracking.

// Active WAAPI animations per animation group.
// Map<animGroup, Map<propertyType, { animation, version, updateFn, animGroup, ... }>>
export const activeAnimations = new Map();

// Animation group lifecycle tracking.
// Map<animGroup, { totalProperties, completedProperties, started, generation,
//                  nextPropertyIndex, lastIteration, propertyIterations, propertyConfigs }>
export const animationGroups = new Map();

// Last-known correct transform values per animation group (in original CSS units).
// Avoids matrix decomposition normalisation (360° → 0°, 270° → -90°).
// Map<animGroup, { x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY }>
export const lastKnownTransforms = new Map();

// Last-known perspectiveOrigin end values per animation group in original units.
// commitStyles() bakes resolved pixels into inline style, causing unit mismatch.
// Map<animGroup, { x: number, y: number, unit: string }>
export const lastKnownPerspectiveOrigins = new Map();

// Group-level iteration counts for scroll-driven animations.
// Deduplicates iteration events: N properties fire N native events per loop, we emit one.
// Map<animGroup, number>
export const scrollDrivenIterationCounts = new Map();

// Per-element transform order for consistent CSS transform rendering.
// Map<animGroup, string[]>  e.g. ['translate', 'rotate', 'skew', 'scale']
export const elementTransformOrders = new Map();

// Reference to the Elm app's ports object, set by init() in index.js.
// Module-scoped instead of window-scoped to avoid global pollution and
// silent collisions with host code that already uses `window.app`.
// { ports: object | null }
export const portsRef = { ports: null };

/**
 * Drop every per-`animGroup` entry from every Map. Called when an animation
 * group's lifecycle ends (completed / cancelled / stopped / reset / replaced
 * by direct property update). Without this, the per-group caches grow
 * without bound for the lifetime of the page.
 */
export function cleanupAnimGroup(animGroup) {
    activeAnimations.delete(animGroup);
    animationGroups.delete(animGroup);
    lastKnownTransforms.delete(animGroup);
    lastKnownPerspectiveOrigins.delete(animGroup);
    scrollDrivenIterationCounts.delete(animGroup);
    elementTransformOrders.delete(animGroup);
}

/**
 * Clear every Map. Called by `dispose()` when the host Elm app is being
 * torn down (typical SPA teardown / hot-reload).
 */
export function clearAllState() {
    activeAnimations.clear();
    animationGroups.clear();
    lastKnownTransforms.clear();
    lastKnownPerspectiveOrigins.clear();
    scrollDrivenIterationCounts.clear();
    elementTransformOrders.clear();
}
