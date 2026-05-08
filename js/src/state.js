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
