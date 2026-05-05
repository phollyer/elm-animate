/**
 * ElmAnimateWAAPI JavaScript Integration (ES Module source)
 * Canonical source for bundling ESM and IIFE distributions.
 */


// Track active animations for cleanup and management
// Structure: Map<animGroup, Map<propertyType, { animation, version, animGroup }>>
const activeAnimations = new Map();

// Track animation groups for Started/Ended events
// Structure: Map<animGroup, { totalProperties, completedProperties, started }>
const animationGroups = new Map();

// Track last-known correct transform values per animation group.
// Used to avoid reading DOM via getCurrentTransform() which normalises
// angles through matrix decomposition (360° → 0°, 270° → -90°).
// Structure: Map<animGroup, { x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY }>
const lastKnownTransforms = new Map();

// Track last-known perspectiveOrigin end values per animation group in their
// original units. commitStyles() bakes the final value as resolved pixels into
// the element's inline style, so reading computedStyle after an animation ends
// returns pixels regardless of the unit used in the animation. Tracking the end
// values here avoids the pixel/percent unit mismatch on the next animation.
// Structure: Map<animGroup, { x: number, y: number, unit: string }>
const lastKnownPerspectiveOrigins = new Map();

// Track group-level iteration counts for scroll-driven animation groups.
// Each entry holds the number of full group loops completed so far.
// Used to deduplicate iteration events: a group with N properties fires N
// native 'iteration' events per loop, but we emit only one to Elm.
// Structure: Map<animGroup, number>
const scrollDrivenIterationCounts = new Map();

/**
 * Get the current transform state for an element, preferring cached
 * values from lastKnownTransforms over DOM reads via getCurrentTransform().
 * This avoids matrix decomposition normalisation that loses angle information.
 */
function getTransformState(animGroup, element) {
    const cached = lastKnownTransforms.get(animGroup);
    if (cached) {
        return normalizeTransformState(cached);
    }
    return normalizeTransformState(getCurrentTransform(element));
}

/**
 * Ensure transform state is complete and numeric.
 * Guards against partial cached objects (missing skew fields) and NaN values.
 */
function normalizeTransformState(state) {
    const defaults = getDefaultTransformState();
    const source = state || defaults;

    const num = (value, fallback) => Number.isFinite(value) ? value : fallback;

    return {
        x: num(source.x, defaults.x),
        y: num(source.y, defaults.y),
        z: num(source.z, defaults.z),
        scaleX: num(source.scaleX, defaults.scaleX),
        scaleY: num(source.scaleY, defaults.scaleY),
        scaleZ: num(source.scaleZ, defaults.scaleZ),
        rotateX: num(source.rotateX, defaults.rotateX),
        rotateY: num(source.rotateY, defaults.rotateY),
        rotateZ: num(source.rotateZ, defaults.rotateZ),
        skewX: num(source.skewX, defaults.skewX),
        skewY: num(source.skewY, defaults.skewY)
    };
}

// Track per-animation-group transform order for consistent rendering
// Structure: Map<animGroup, string[]>  e.g. ['translate', 'rotate', 'skew', 'scale']
const elementTransformOrders = new Map();

// Default transform order: Translate → Rotate → Skew → Scale
const DEFAULT_TRANSFORM_ORDER = ['translate', 'rotate', 'skew', 'scale'];

/**
 * Get the stored transform order for a DOM element.
 */
function getElementOrder(element) {
    const id = element.getAttribute('data-anim-target') || element.id;
    return elementTransformOrders.get(id) || DEFAULT_TRANSFORM_ORDER;
}

// Default easing functions mapping for Web Animations API
const easingFunctions = {
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

// Shared load guard so multiple timeline commands do not trigger duplicate loads.
let timelinePolyfillLoadPromise = null;

function hasTimelineApi(apiName) {
    return typeof window !== 'undefined' && typeof window[apiName] !== 'undefined';
}

function loadTimelinePolyfill() {
    if (timelinePolyfillLoadPromise) {
        return timelinePolyfillLoadPromise;
    }

    timelinePolyfillLoadPromise = new Promise((resolve, reject) => {
        if (typeof document === 'undefined') {
            reject(new Error('No document available to load timeline polyfill script'));
            return;
        }

        const existing = document.querySelector('script[data-elm-animate-timeline-polyfill="true"]');
        if (existing) {
            existing.addEventListener('load', () => resolve(), { once: true });
            existing.addEventListener('error', () => reject(new Error('Failed to load existing timeline polyfill script')), { once: true });
            return;
        }

        const script = document.createElement('script');
        script.src = 'https://unpkg.com/scroll-timeline-polyfill/dist/scroll-timeline.js';
        script.async = true;
        script.setAttribute('data-elm-animate-timeline-polyfill', 'true');
        script.onload = () => resolve();
        script.onerror = () => reject(new Error('Failed to load scroll-timeline polyfill'));
        document.head.appendChild(script);
    });

    return timelinePolyfillLoadPromise;
}

async function ensureTimelineApi(apiName) {
    if (hasTimelineApi(apiName)) {
        return true;
    }

    try {
        await loadTimelinePolyfill();
    } catch (error) {
        console.warn('ElmAnimateWAAPI: Unable to load timeline polyfill:', error);
        return false;
    }

    if (!hasTimelineApi(apiName)) {
        console.warn('ElmAnimateWAAPI: Timeline polyfill loaded but ' + apiName + ' is still unavailable');
        return false;
    }

    return true;
}

/**
 * Process animation data received from Elm
 */
function processAnimationData(animationData) {
    if (animationData && animationData.elements) {
        // Extract global animation options
        const globalOptions = {
            iterations: parseIterations(animationData.iterations),
            direction: animationData.direction || 'normal'
        };
        const isRestart = animationData.isRestart || false;

        // Process element animations (keys are animation group names)
        Object.entries(animationData.elements).forEach(([animGroup, elementConfig]) => {
            // Find all matching DOM elements with data-anim-target attribute.
            // If multiple DOM elements share the same data-anim-target,
            // run the animation on each element.
            const targets = findAllAnimTargets(animGroup);
            if (targets.length <= 1) {
                // Single target (or none) - standard path
                processElementAnimation(animGroup, elementConfig, globalOptions, isRestart);
            } else {
                // Multiple DOM elements share this data-anim-target.
                // Run the animation on each element, using the element's own id
                // (or the shared key with index suffix) for unique tracking.
                targets.forEach((el, idx) => {
                    const uniqueId = el.id || (animGroup + '__multi_' + idx);
                    processElementAnimation(uniqueId, elementConfig, globalOptions, isRestart, el);
                });
            }
        });
    } else {
        console.warn('ElmAnimateWAAPI: Invalid animation data format received');
    }
}

/**
 * Process a scroll-driven animation using ScrollTimeline.
 */
function processScrollDrivenData(commandData) {
    if (!commandData || !commandData.elements) {
        console.warn('ElmAnimateWAAPI: Invalid scrollDriven data');
        return;
    }

    if (typeof ScrollTimeline === 'undefined') {
        console.warn('ElmAnimateWAAPI: ScrollTimeline is not supported in this browser');
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const sourceId = timelineConfig.source || 'document';
    const axis = timelineConfig.axis || 'block';

    const sourceElement = (sourceId === 'document')
        ? document.documentElement
        : (document.querySelector('[data-anim-target="' + CSS.escape(sourceId) + '"]')
            || document.getElementById(sourceId));

    if (!sourceElement) {
        console.warn('ElmAnimateWAAPI: Scroll source element "' + sourceId + '" not found');
        return;
    }

    const timeline = new ScrollTimeline({ source: sourceElement, axis: axis });
    const playbackOptions = {
        iterations: parseIterations(commandData.iterations),
        direction: commandData.direction || 'normal'
    };

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const targetId = elementConfig.target || animGroup;
        const element = findAnimTarget(targetId);
        if (!element) {
            console.warn('ElmAnimateWAAPI: Element target "' + targetId + '" not found for scroll-driven animation (animGroup: "' + animGroup + '")');
            return;
        }
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, null, playbackOptions, 'scrollTimeline');
    });
}

/**
 * Process a view-driven animation using ViewTimeline.
 */
function processViewDrivenData(commandData) {
    if (!commandData || !commandData.elements) {
        console.warn('ElmAnimateWAAPI: Invalid viewDriven data');
        return;
    }

    if (typeof ViewTimeline === 'undefined') {
        console.warn('ElmAnimateWAAPI: ViewTimeline is not supported in this browser');
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const axis = timelineConfig.axis || 'block';

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const targetId = elementConfig.target || animGroup;
        const element = findAnimTarget(targetId);
        if (!element) {
            console.warn('ElmAnimateWAAPI: Element target "' + targetId + '" not found for view-driven animation (animGroup: "' + animGroup + '")');
            return;
        }

        const timeline = new ViewTimeline({ subject: element, axis: axis });
        const rangeOptions = {};
        if (timelineConfig.rangeStart) rangeOptions.rangeStart = timelineConfig.rangeStart;
        if (timelineConfig.rangeEnd) rangeOptions.rangeEnd = timelineConfig.rangeEnd;
        const playbackOptions = {
            iterations: parseIterations(commandData.iterations),
            direction: commandData.direction || 'normal'
        };
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, 'viewTimeline');
    });
}

/**
 * Apply a scroll/view-driven animation to a single element using the given timeline.
 * Builds start/end keyframes from each property config and calls element.animate().
 * rangeOptions may contain rangeStart/rangeEnd for ViewTimeline range restriction.
 * playbackOptions may contain iterations and direction.
 * engine identifies the source engine ('scrollTimeline' or 'viewTimeline') for port events.
 */
function applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, engine) {
    const baseTimingOptions = Object.assign(
        { timeline: timeline, fill: 'both' },
        rangeOptions || {},
        playbackOptions ? { iterations: playbackOptions.iterations, direction: playbackOptions.direction } : {}
    );
    const properties = elementConfig.properties || [];

    const transformProperties = properties.filter(function (p) {
        return p.type === 'translate' || p.type === 'scale' || p.type === 'rotate' || p.type === 'skew';
    });
    const nonTransformProperties = properties.filter(function (p) {
        return p.type !== 'translate' && p.type !== 'scale' && p.type !== 'rotate' && p.type !== 'skew';
    });

    // Collect all Animation objects so we can attach lifecycle listeners.
    const animations = [];

    nonTransformProperties.forEach(function (property) {
        const resolved = resolveNonTransformValues(animGroup, element, property);
        if (!resolved) return;

        let keyframes;
        const propertyTimingOptions = Object.assign({}, baseTimingOptions);

        if (property.easingKeyframes && Array.isArray(property.easingKeyframes)) {
            keyframes = buildScrollDrivenKeyframesWithEasing(resolved, property.easingKeyframes);
            if (keyframes) {
                propertyTimingOptions.easing = 'linear';
            } else {
                // Complex easing not supported for this type; fall back to 2-keyframe
                keyframes = buildScrollDrivenKeyframes(resolved);
            }
        } else {
            keyframes = buildScrollDrivenKeyframes(resolved);
            if (property.easing) {
                propertyTimingOptions.easing = property.easing;
            }
        }

        if (!keyframes) return;
        animations.push(element.animate(keyframes, propertyTimingOptions));
    });

    if (transformProperties.length > 0) {
        const currentTransform = getTransformState(animGroup, element);
        const order = (elementConfig.transformOrder && elementConfig.transformOrder.length > 0)
            ? elementConfig.transformOrder
            : (elementTransformOrders.get(animGroup) || ['translate', 'rotate', 'skew', 'scale']);

        const sv = resolveScrollDrivenTransformStart(transformProperties, currentTransform);
        const ev = resolveScrollDrivenTransformEnd(transformProperties, currentTransform);

        const transformTimingOptions = Object.assign({}, baseTimingOptions);
        const firstTransform = transformProperties[0];

        let transformKeyframes;
        if (firstTransform.easingKeyframes && Array.isArray(firstTransform.easingKeyframes)) {
            transformKeyframes = firstTransform.easingKeyframes.map(function (p) {
                return {
                    transform: buildTransformString(
                        sv.x + (ev.x - sv.x) * p,
                        sv.y + (ev.y - sv.y) * p,
                        sv.z + (ev.z - sv.z) * p,
                        sv.scaleX + (ev.scaleX - sv.scaleX) * p,
                        sv.scaleY + (ev.scaleY - sv.scaleY) * p,
                        sv.scaleZ + (ev.scaleZ - sv.scaleZ) * p,
                        sv.rotateX + (ev.rotateX - sv.rotateX) * p,
                        sv.rotateY + (ev.rotateY - sv.rotateY) * p,
                        sv.rotateZ + (ev.rotateZ - sv.rotateZ) * p,
                        sv.skewX + (ev.skewX - sv.skewX) * p,
                        sv.skewY + (ev.skewY - sv.skewY) * p,
                        order
                    )
                };
            });
            transformTimingOptions.easing = 'linear';
        } else {
            const startTransform = buildTransformString(
                sv.x, sv.y, sv.z,
                sv.scaleX, sv.scaleY, sv.scaleZ,
                sv.rotateX, sv.rotateY, sv.rotateZ,
                sv.skewX, sv.skewY, order
            );
            const endTransform = buildTransformString(
                ev.x, ev.y, ev.z,
                ev.scaleX, ev.scaleY, ev.scaleZ,
                ev.rotateX, ev.rotateY, ev.rotateZ,
                ev.skewX, ev.skewY, order
            );
            transformKeyframes = [{ transform: startTransform }, { transform: endTransform }];
            if (firstTransform.easing) {
                transformTimingOptions.easing = firstTransform.easing;
            }
        }

        animations.push(element.animate(transformKeyframes, transformTimingOptions));
    }

    // Attach lifecycle event listeners to all collected Animation objects.
    if (animations.length > 0 && engine) {
        attachScrollDrivenListeners(animGroup, animations, engine);
    }
}

/**
 * Attach finish, cancel, and iteration listeners to a group of scroll-driven animations.
 * Emits port events to Elm matching the 'animationUpdate' format used by the WAAPI engine,
 * with an additional 'engine' field so the Elm decoder can filter to its own events.
 *
 * @param {string} animGroup - Animation group identifier
 * @param {Animation[]} animations - All Animation objects for this group
 * @param {string} engine - 'scrollTimeline' or 'viewTimeline'
 */
function attachScrollDrivenListeners(animGroup, animations, engine) {
    const total = animations.length;
    let finishedCount = 0;
    let cancelFired = false;

    // Initialise group iteration counter (reset on each animate call).
    scrollDrivenIterationCounts.set(animGroup, 0);

    // Per-animation iteration counts used to deduplicate the group event:
    // a group with N properties fires N native 'iteration' events per loop.
    // We only emit one Elm event per loop, when the last animation catches up.
    const perAnimIterations = new Array(total).fill(0);

    animations.forEach(function (animation, i) {
        animation.addEventListener('finish', function () {
            finishedCount++;
            if (finishedCount === total) {
                sendScrollLifecycleEvent('completed', animGroup, 1.0, engine);
            }
        }, { once: true });

        animation.addEventListener('cancel', function () {
            if (cancelFired) return;
            cancelFired = true;
            const progress = getScrollAnimationProgress(animation);
            sendScrollLifecycleEvent('cancelled', animGroup, progress, engine);
        }, { once: true });

        animation.addEventListener('iteration', function () {
            perAnimIterations[i]++;
            const storedCount = scrollDrivenIterationCounts.get(animGroup) || 0;
            const nextGroupIteration = updateGroupIteration(perAnimIterations, i, perAnimIterations[i], storedCount);
            if (nextGroupIteration != null) {
                scrollDrivenIterationCounts.set(animGroup, nextGroupIteration);
                sendScrollLifecycleEvent('iteration', animGroup, nextGroupIteration, engine);
            }
        });
    });
}

/**
 * Read the current progress (0.0–1.0) of a scroll-driven Animation object.
 * Unlike time-based animations, currentTime is a CSSUnitValue, not a number.
 * getComputedTiming().progress is always a plain number in [0, 1] or null.
 *
 * @param {Animation} animation
 * @returns {number}
 */
function getScrollAnimationProgress(animation) {
    try {
        const timing = animation.effect && animation.effect.getComputedTiming();
        if (timing && timing.progress !== null && timing.progress !== undefined) {
            return Math.min(1.0, Math.max(0.0, timing.progress));
        }
    } catch (_) { /* ignore */ }
    return 0;
}

/**
 * Send a lifecycle event for a scroll-driven animation group to Elm.
 * Payload matches the 'animationUpdate' shape used by the WAAPI engine, plus
 * an 'engine' field so Elm decoders can filter to their own events.
 *
 * @param {string} status - 'completed', 'cancelled', or 'iteration'
 * @param {string} animGroup - Animation group identifier
 * @param {number} progress - Progress value (0.0–1.0 for completed/cancelled; iteration count for iteration)
 * @param {string} engine - 'scrollTimeline' or 'viewTimeline'
 */
function sendScrollLifecycleEvent(status, animGroup, progress, engine) {
    if (window.app && window.app.ports && window.app.ports.waapiEvent) {
        window.app.ports.waapiEvent.send({
            type: 'animationUpdate',
            engine: engine,
            payload: {
                elementId: animGroup,
                animGroup: animGroup,
                status: status,
                progress: progress
            }
        });
    }
}

/**
 * Build a two-keyframe array (start → end) for a resolved non-transform property.
 */
function buildScrollDrivenKeyframes(resolved) {
    switch (resolved.type) {
        case 'opacity':
            return [
                { opacity: String(resolved.startValue) },
                { opacity: String(resolved.endValue) }
            ];
        case 'backgroundColor':
            return [
                { backgroundColor: resolved.startColor },
                { backgroundColor: resolved.endColor }
            ];
        case 'color':
            return [
                { color: resolved.startColor },
                { color: resolved.endColor }
            ];
        case 'size':
            return [
                { width: resolved.startWidth + 'px', height: resolved.startHeight + 'px' },
                { width: resolved.endWidth + 'px', height: resolved.endHeight + 'px' }
            ];
        case 'customProperty':
            return [
                { [camelCase(resolved.cssProperty)]: resolved.startValue + resolved.unit },
                { [camelCase(resolved.cssProperty)]: resolved.endValue + resolved.unit }
            ];
        case 'customColorProperty':
            return [
                { [camelCase(resolved.cssProperty)]: resolved.startColor },
                { [camelCase(resolved.cssProperty)]: resolved.endColor }
            ];
        case 'perspectiveOrigin':
            return [
                { perspectiveOrigin: resolved.startX + resolved.unit + ' ' + resolved.startY + resolved.unit },
                { perspectiveOrigin: resolved.endX + resolved.unit + ' ' + resolved.endY + resolved.unit }
            ];
        default:
            return null;
    }
}

/**
 * Build a multi-keyframe array for a resolved non-transform property using pre-computed
 * easing progress values (for bounce/elastic easings).
 * Returns null for color properties where numeric interpolation is not straightforward.
 */
function buildScrollDrivenKeyframesWithEasing(resolved, easingKeyframes) {
    switch (resolved.type) {
        case 'opacity':
            return easingKeyframes.map(function (p) {
                return { opacity: String(resolved.startValue + (resolved.endValue - resolved.startValue) * p) };
            });
        case 'size':
            return easingKeyframes.map(function (p) {
                return {
                    width: (resolved.startWidth + (resolved.endWidth - resolved.startWidth) * p) + 'px',
                    height: (resolved.startHeight + (resolved.endHeight - resolved.startHeight) * p) + 'px'
                };
            });
        case 'customProperty':
            return easingKeyframes.map(function (p) {
                const v = resolved.startValue + (resolved.endValue - resolved.startValue) * p;
                return { [camelCase(resolved.cssProperty)]: v + resolved.unit };
            });
        case 'perspectiveOrigin':
            return easingKeyframes.map(function (p) {
                const x = resolved.startX + (resolved.endX - resolved.startX) * p;
                const y = resolved.startY + (resolved.endY - resolved.startY) * p;
                return { perspectiveOrigin: x + resolved.unit + ' ' + y + resolved.unit };
            });
        // Color types: fall back to 2-keyframe (caller handles null return)
        default:
            return null;
    }
}

/**
 * Resolve start transform component values for scroll-driven animations.
 */
function resolveScrollDrivenTransformStart(transformProperties, currentTransform) {
    const v = {
        x: currentTransform.x, y: currentTransform.y, z: currentTransform.z,
        scaleX: currentTransform.scaleX, scaleY: currentTransform.scaleY, scaleZ: currentTransform.scaleZ,
        rotateX: currentTransform.rotateX, rotateY: currentTransform.rotateY, rotateZ: currentTransform.rotateZ,
        skewX: currentTransform.skewX, skewY: currentTransform.skewY
    };
    transformProperties.forEach(function (p) {
        switch (p.type) {
            case 'translate':
                v.x = p.startX ?? p.defaultX ?? currentTransform.x;
                v.y = p.startY ?? p.defaultY ?? currentTransform.y;
                v.z = p.startZ ?? p.defaultZ ?? currentTransform.z;
                break;
            case 'scale':
                v.scaleX = p.startX ?? p.defaultX ?? currentTransform.scaleX;
                v.scaleY = p.startY ?? p.defaultY ?? currentTransform.scaleY;
                v.scaleZ = p.startZ ?? p.defaultZ ?? currentTransform.scaleZ;
                break;
            case 'rotate':
                v.rotateX = p.startX ?? p.defaultX ?? currentTransform.rotateX;
                v.rotateY = p.startY ?? p.defaultY ?? currentTransform.rotateY;
                v.rotateZ = p.startZ ?? p.defaultZ ?? currentTransform.rotateZ;
                break;
            case 'skew':
                v.skewX = p.startX ?? currentTransform.skewX;
                v.skewY = p.startY ?? currentTransform.skewY;
                break;
        }
    });
    return v;
}

/**
 * Resolve end transform component values for scroll-driven animations.
 */
function resolveScrollDrivenTransformEnd(transformProperties, currentTransform) {
    const v = {
        x: currentTransform.x, y: currentTransform.y, z: currentTransform.z,
        scaleX: currentTransform.scaleX, scaleY: currentTransform.scaleY, scaleZ: currentTransform.scaleZ,
        rotateX: currentTransform.rotateX, rotateY: currentTransform.rotateY, rotateZ: currentTransform.rotateZ,
        skewX: currentTransform.skewX, skewY: currentTransform.skewY
    };
    transformProperties.forEach(function (p) {
        switch (p.type) {
            case 'translate':
                v.x = p.endX ?? currentTransform.x;
                v.y = p.endY ?? currentTransform.y;
                v.z = p.endZ ?? currentTransform.z;
                break;
            case 'scale':
                v.scaleX = p.endX ?? currentTransform.scaleX;
                v.scaleY = p.endY ?? currentTransform.scaleY;
                v.scaleZ = p.endZ ?? currentTransform.scaleZ;
                break;
            case 'rotate':
                v.rotateX = p.endX ?? currentTransform.rotateX;
                v.rotateY = p.endY ?? currentTransform.rotateY;
                v.rotateZ = p.endZ ?? currentTransform.rotateZ;
                break;
            case 'skew':
                v.skewX = p.endX ?? currentTransform.skewX;
                v.skewY = p.endY ?? currentTransform.skewY;
                break;
        }
    });
    return v;
}

/**
 * Parse iterations config from Elm format to Web Animations API format
 */
function parseIterations(iterations) {
    if (!iterations) return 1;

    switch (iterations.type) {
        case 'infinite':
            return Infinity;
        case 'times':
            return iterations.count;
        case 'once':
        default:
            return 1;
    }
}

function updateGroupIteration(perAnimIterations, propertyIndex, currentIteration, storedCount) {
    if (currentIteration == null || propertyIndex < 0 || propertyIndex >= perAnimIterations.length) {
        return null;
    }

    perAnimIterations[propertyIndex] = currentIteration;
    const minIteration = Math.min.apply(null, perAnimIterations);
    return minIteration > storedCount ? minIteration : null;
}

/**
 * Find a DOM element by its animation target identifier.
 * Looks for data-anim-target attribute first (set by Elm's WAAPI.attributes),
 * then falls back to getElementById for backward compatibility.
 *
 * @param {string} targetId - The animation target identifier
 * @returns {Element|null} The DOM element, or null if not found
 */
function findAnimTarget(targetId) {
    return document.querySelector('[data-anim-target="' + CSS.escape(targetId) + '"]')
        || document.getElementById(targetId);
}

/**
 * Find all DOM elements matching an animation target identifier.
 * Returns all elements with the matching data-anim-target attribute.
 * Falls back to getElementById (returns single-element array) if no
 * data-anim-target matches are found.
 *
 * @param {string} targetId - The animation target identifier
 * @returns {Element[]} Array of matching DOM elements (may be empty)
 */
function findAllAnimTargets(targetId) {
    const elements = Array.from(
        document.querySelectorAll('[data-anim-target="' + CSS.escape(targetId) + '"]')
    );
    if (elements.length > 0) return elements;
    const byId = document.getElementById(targetId);
    return byId ? [byId] : [];
}

/**
 * Process animation for a single element with all its properties.
 * Supports property-level animation tracking with version control.
 * 
 * @param {string} animGroup - The animation group name (used as key and data-anim-target value)
 * @param {object} elementConfig - Configuration with properties to animate
 * @param {object} globalOptions - Global animation options (iterations, direction)
 * @param {boolean} isRestart - Whether this animation is a restart (skip start-value patching)
 * @param {Element} [resolvedElement] - Optional pre-resolved DOM element (for multi-element targeting)
 */
function processElementAnimation(animGroup, elementConfig, globalOptions = { iterations: 1, direction: 'normal' }, isRestart = false, resolvedElement = null) {
    const element = resolvedElement || findAnimTarget(animGroup);
    if (!element) {
        console.warn(`ElmAnimateWAAPI: Element with data-anim-target="${animGroup}" not found. Ensure WAAPI.attributes is applied to the target element.`);
        return;
    }

    // Store transform order for this animation group (persists across animations)
    if (elementConfig.transformOrder && Array.isArray(elementConfig.transformOrder)) {
        elementTransformOrders.set(animGroup, elementConfig.transformOrder);
    }

    // Get or create element animation tracking map
    if (!activeAnimations.has(animGroup)) {
        activeAnimations.set(animGroup, new Map());
    }
    const elementAnims = activeAnimations.get(animGroup);

    // Separate transform properties from non-transform properties.
    // Transform sub-properties (translate, scale, rotate, skew) must be merged into a
    // single WAAPI animation because they all target the CSS 'transform' property.
    // Multiple element.animate() calls on 'transform' would replace each other.
    const transformProperties = [];
    const nonTransformProperties = [];

    elementConfig.properties.forEach(property => {
        if (property.type === 'translate' || property.type === 'scale' || property.type === 'rotate' || property.type === 'skew') {
            transformProperties.push(property);
        } else {
            nonTransformProperties.push(property);
        }
    });

    // Count total animation units for group tracking
    // Transform properties are merged into 1 animation, non-transform are 1 each
    const animationCount = (transformProperties.length > 0 ? 1 : 0) + nonTransformProperties.length;

    // If there's an existing started group, emit 'cancelled' before resetting.
    // This gives the Elm side a clear lifecycle: Started → Cancelled → (new) Started
    const previousGroup = animationGroups.get(animGroup);
    if (previousGroup && previousGroup.started) {
        sendLifecycleEvent('cancelled', animGroup);
    }

    // Initialize or reset animation group tracking
    animationGroups.set(animGroup, {
        animGroup: animGroup,
        totalProperties: animationCount,
        completedProperties: 0,
        cancelledProperties: 0,
        started: false,
        propertyConfigs: [],
        generation: (previousGroup?.generation || 0) + 1,
        lastIteration: 0,
        propertyIterations: new Array(animationCount).fill(0),
        nextPropertyIndex: 0
    });

    // Process merged transform properties as a single animation
    if (transformProperties.length > 0) {
        // Carry forward transform sub-properties from the existing animation
        // that aren't in the new call, so they continue to their original targets
        let mergedTransformProperties = transformProperties;

        if (elementAnims.has('transform')) {
            const existing = elementAnims.get('transform');

            // For restarts, skip start-value patching and carry-forward - we want
            // to replay the original animation from its defined start position.
            if (!isRestart) {
                // Compute the exact real-time position before cancelling.
                // Elm's baseline comes from the last ~60fps property update and may be
                // a few frames behind the actual WAAPI-driven position.
                if (existing.resolvedValues && existing.animation.currentTime != null) {
                    const currentTime = existing.animation.currentTime;
                    const duration = existing.animation.effect?.getTiming()?.duration || 0;
                    const progress = duration > 0 ? Math.min(1, Math.max(0, currentTime / duration)) : 1;
                    const freshTransform = computeTransformFromResolved(existing.resolvedValues, progress, duration);
                    lastKnownTransforms.set(animGroup, freshTransform);

                    // Patch incoming transform properties with fresh start values
                    // so they begin from the actual on-screen position, not the stale baseline
                    transformProperties.forEach(p => {
                        switch (p.type) {
                            case 'translate':
                                if (p.startX != null) p.startX = freshTransform.x;
                                if (p.startY != null) p.startY = freshTransform.y;
                                if (p.startZ != null) p.startZ = freshTransform.z;
                                break;
                            case 'scale':
                                if (p.startX != null) p.startX = freshTransform.scaleX;
                                if (p.startY != null) p.startY = freshTransform.scaleY;
                                if (p.startZ != null) p.startZ = freshTransform.scaleZ;
                                break;
                            case 'rotate':
                                if (p.startX != null) p.startX = freshTransform.rotateX;
                                if (p.startY != null) p.startY = freshTransform.rotateY;
                                if (p.startZ != null) p.startZ = freshTransform.rotateZ;
                                break;
                            case 'skew':
                                if (p.startX != null) p.startX = freshTransform.skewX;
                                if (p.startY != null) p.startY = freshTransform.skewY;
                                break;
                        }
                    });
                }

                if (existing.transformProperties) {
                    const incomingTypes = new Set(transformProperties.map(p => p.type));
                    const carried = existing.transformProperties
                        .filter(prevProp => !incomingTypes.has(prevProp.type))
                        .map(prevProp => {
                            // Clear explicit start values so createMergedTransformAnimation
                            // uses currentTransform (mid-flight position) as the start
                            const cont = Object.assign({}, prevProp);
                            delete cont.startX;
                            delete cont.startY;
                            delete cont.startZ;
                            delete cont.defaultX;
                            delete cont.defaultY;
                            delete cont.defaultZ;
                            return cont;
                        });

                    if (carried.length > 0) {
                        mergedTransformProperties = [...transformProperties, ...carried];
                    }
                }
            }

            // Cancel existing transform animation
            existing.animation.cancel();
        }
        // Also cancel individual sub-property animations from older code paths
        ['translate', 'scale', 'rotate', 'skew'].forEach(propType => {
            if (elementAnims.has(propType)) {
                const existing = elementAnims.get(propType);
                existing.animation.cancel();
                elementAnims.delete(propType);
            }
        });

        const maxVersion = Math.max(...mergedTransformProperties.map(p => p.version || 1));
        const mergeResult = createMergedTransformAnimation(animGroup, element, mergedTransformProperties, globalOptions);

        if (mergeResult) {
            const { animation, resolved: resolvedTransformValues } = mergeResult;
            const updateFn = setupAnimationEvents(animGroup, 'transform', element, animation, maxVersion, animGroup, resolvedTransformValues);
            elementAnims.set('transform', {
                animation: animation,
                version: maxVersion,
                updateFn: updateFn,
                animGroup: animGroup,
                easingKeyframes: null, // merged animations always use keyframe-based interpolation
                transformProperties: mergedTransformProperties, // cache for resize and carry-forward
                resolvedValues: resolvedTransformValues // cached start/end for computing interpolated values
            });

            // Store property configs for lifecycle events
            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                transformProperties.forEach(property => {
                    groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
                });
            }

            // Emit Started event
            const groupInfo2 = animationGroups.get(animGroup);
            if (groupInfo2 && !groupInfo2.started) {
                groupInfo2.started = true;
                sendLifecycleEvent('started', animGroup);
            }
        }
    }

    // Process non-transform properties independently (opacity, color, etc.)
    nonTransformProperties.forEach(property => {
        const propType = property.type;
        const newVersion = property.version || 1;

        if (elementAnims.has(propType)) {
            elementAnims.get(propType).animation.cancel();
        }

        const resolvedNonTransform = resolveNonTransformValues(animGroup, element, property);
        const animation = createPropertyAnimation(element, property, globalOptions);

        if (animation) {
            const updateFn = setupAnimationEvents(animGroup, propType, element, animation, newVersion, animGroup, null);
            elementAnims.set(propType, {
                animation: animation,
                version: newVersion,
                updateFn: updateFn,
                animGroup: animGroup,
                easingKeyframes: property.easingKeyframes || null,
                resolvedNonTransform: resolvedNonTransform
            });

            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo) {
                groupInfo.propertyConfigs.push(extractPropertyConfig(animGroup, element, property));
            }

            if (groupInfo && !groupInfo.started) {
                groupInfo.started = true;
                sendLifecycleEvent('started', animGroup);
            }
        }
    });

    // Clean up element entry if no animations remain
    if (elementAnims.size === 0) {
        activeAnimations.delete(animGroup);
    }
}

/**
 * Interpolate between two color strings.
 */
function interpolateColor(startColor, endColor, progress) {
    // Parse rgb/rgba colors
    const parseColor = (str) => {
        const match = str.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
        if (match) {
            return {
                r: parseInt(match[1]),
                g: parseInt(match[2]),
                b: parseInt(match[3]),
                a: match[4] !== undefined ? parseFloat(match[4]) : 1
            };
        }
        // Fallback for hex colors (convert to rgb)
        if (str.startsWith('#')) {
            const hex = str.substring(1);
            return {
                r: parseInt(hex.substring(0, 2), 16),
                g: parseInt(hex.substring(2, 4), 16),
                b: parseInt(hex.substring(4, 6), 16),
                a: 1
            };
        }
        return { r: 0, g: 0, b: 0, a: 1 };
    };

    const start = parseColor(startColor);
    const end = parseColor(endColor);

    const r = Math.round(start.r + (end.r - start.r) * progress);
    const g = Math.round(start.g + (end.g - start.g) * progress);
    const b = Math.round(start.b + (end.b - start.b) * progress);
    const a = start.a + (end.a - start.a) * progress;

    return `rgba(${r}, ${g}, ${b}, ${a})`;
}

/**
 * Convert a kebab-case CSS property name to camelCase for WAAPI keyframes.
 * e.g. "border-radius" → "borderRadius"
 */
function camelCase(str) {
    return str.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
}

/**
 * Resolve start/end values for a non-transform property so they can be
 * used to compute interpolated values without reading the DOM later.
 */
function resolveNonTransformValues(animGroup, element, property) {
    const computedStyle = window.getComputedStyle(element);
    switch (property.type) {
        case 'opacity': {
            const computedOpacity = parseFloat(computedStyle.opacity);
            return {
                type: 'opacity',
                startValue: property.startValue ?? property.defaultValue ?? computedOpacity,
                endValue: property.endValue
            };
        }
        case 'backgroundColor': {
            return {
                type: 'backgroundColor',
                startColor: property.startColor ?? property.defaultColor ?? computedStyle.backgroundColor,
                endColor: property.endColor
            };
        }
        case 'color': {
            return {
                type: 'color',
                startColor: property.startColor ?? property.defaultColor ?? computedStyle.color,
                endColor: property.endColor
            };
        }
        case 'size': {
            return {
                type: 'size',
                startWidth: property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width),
                startHeight: property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height),
                endWidth: property.endWidth,
                endHeight: property.endHeight
            };
        }
        case 'customProperty': {
            camelCase(property.cssProperty);
            const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
            return {
                type: 'customProperty',
                cssProperty: property.cssProperty,
                unit: property.unit,
                startValue: property.startValue ?? computedValue,
                endValue: property.endValue
            };
        }
        case 'customColorProperty': {
            camelCase(property.cssProperty);
            const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
            return {
                type: 'customColorProperty',
                cssProperty: property.cssProperty,
                startColor: property.startColor ?? computedColor,
                endColor: property.endColor
            };
        }
        case 'perspectiveOrigin': {
            // Prefer last-known end values (tracked in original units) over
            // computedStyle, which returns resolved pixels after commitStyles()
            // causing a unit mismatch when the animation uses percent.
            const cached = lastKnownPerspectiveOrigins.get(animGroup);
            let fallbackX, fallbackY;
            if (cached && cached.unit === property.unit) {
                fallbackX = cached.x;
                fallbackY = cached.y;
            } else {
                const computedOrigin = computedStyle.perspectiveOrigin || '50% 50%';
                const parts = computedOrigin.split(' ');
                fallbackX = parseFloat(parts[0]) || 50;
                fallbackY = parseFloat(parts[1] ?? parts[0]) || 50;
            }
            const resolved = {
                type: 'perspectiveOrigin',
                startX: property.startX ?? fallbackX,
                startY: property.startY ?? fallbackY,
                endX: property.endX,
                endY: property.endY,
                unit: property.unit
            };
            // Record the end value so the next animation can use it as its start.
            lastKnownPerspectiveOrigins.set(animGroup, { x: property.endX, y: property.endY, unit: property.unit });
            return resolved;
        }
        default:
            return null;
    }
}

/**
 * Extract property configuration for lifecycle events.
 * Returns a normalized config object with from/to values as strings.
 * @param {Element} element - The DOM element
 * @param {object} property - The property configuration from Elm
 * @returns {object} Normalized property config
 */
function extractPropertyConfig(animGroup, element, property) {
    const config = {
        property: property.type,
        duration: property.duration,
        easing: property.easing,
        from: '',
        to: ''
    };

    const computedStyle = window.getComputedStyle(element);

    switch (property.type) {
        case 'translate': {
            const currentTransform = getTransformState(animGroup, element);
            const fromX = property.startX ?? property.defaultX ?? currentTransform.x;
            const fromY = property.startY ?? property.defaultY ?? currentTransform.y;
            const fromZ = property.startZ ?? property.defaultZ ?? currentTransform.z;
            const toX = property.endX ?? currentTransform.x;
            const toY = property.endY ?? currentTransform.y;
            const toZ = property.endZ ?? currentTransform.z;
            config.from = `${fromX},${fromY},${fromZ}`;
            config.to = `${toX},${toY},${toZ}`;
            break;
        }
        case 'scale': {
            const currentTransform = getTransformState(animGroup, element);
            const fromX = property.startX ?? property.defaultX ?? currentTransform.scaleX;
            const fromY = property.startY ?? property.defaultY ?? currentTransform.scaleY;
            const fromZ = property.startZ ?? property.defaultZ ?? currentTransform.scaleZ;
            const toX = property.endX ?? currentTransform.scaleX;
            const toY = property.endY ?? currentTransform.scaleY;
            const toZ = property.endZ ?? currentTransform.scaleZ;
            config.from = `${fromX},${fromY},${fromZ}`;
            config.to = `${toX},${toY},${toZ}`;
            break;
        }
        case 'rotate': {
            const currentTransform = getTransformState(animGroup, element);
            const fromX = property.startX ?? property.defaultX ?? currentTransform.rotateX;
            const fromY = property.startY ?? property.defaultY ?? currentTransform.rotateY;
            const fromZ = property.startZ ?? property.defaultZ ?? currentTransform.rotateZ;
            const toX = property.endX ?? currentTransform.rotateX;
            const toY = property.endY ?? currentTransform.rotateY;
            const toZ = property.endZ ?? currentTransform.rotateZ;
            config.from = `${fromX},${fromY},${fromZ}`;
            config.to = `${toX},${toY},${toZ}`;
            break;
        }
        case 'skew': {
            const currentTransform = getTransformState(animGroup, element);
            const fromX = property.startX ?? currentTransform.skewX;
            const fromY = property.startY ?? currentTransform.skewY;
            const toX = property.endX ?? currentTransform.skewX;
            const toY = property.endY ?? currentTransform.skewY;
            config.from = `${fromX},${fromY}`;
            config.to = `${toX},${toY}`;
            break;
        }
        case 'opacity': {
            const computedOpacity = parseFloat(computedStyle.opacity);
            const fromVal = property.startValue ?? property.defaultValue ?? computedOpacity;
            config.from = `${fromVal}`;
            config.to = `${property.endValue}`;
            break;
        }
        case 'backgroundColor':
        case 'color': {
            const cssProp = property.type === 'backgroundColor' ? 'backgroundColor' : 'color';
            const computedColor = computedStyle[cssProp];
            config.from = property.startColor ?? property.defaultColor ?? computedColor;
            config.to = property.endColor;
            break;
        }
        case 'size': {
            const startWidth = property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width);
            const startHeight = property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height);
            config.from = `${startWidth},${startHeight}`;
            config.to = `${property.endWidth},${property.endHeight}`;
            break;
        }
        case 'customProperty': {
            const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
            const fromVal = property.startValue ?? computedValue;
            config.property = property.cssProperty;
            config.from = `${fromVal}${property.unit}`;
            config.to = `${property.endValue}${property.unit}`;
            break;
        }
        case 'customColorProperty': {
            const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
            config.property = property.cssProperty;
            config.from = property.startColor ?? computedColor;
            config.to = property.endColor;
            break;
        }
        case 'perspectiveOrigin': {
            config.from = `${property.startX}${property.unit} ${property.startY}${property.unit}`;
            config.to = `${property.endX}${property.unit} ${property.endY}${property.unit}`;
            break;
        }
    }

    return config;
}

/**
 * Create a single WAAPI animation for multiple transform sub-properties.
* Merges translate, scale, rotate, and skew into one animation with per-property
 * easing via generated keyframes. This avoids the WAAPI cascade issue where
 * multiple animations on 'transform' replace each other.
 */
function createMergedTransformAnimation(animGroup, element, transformProperties, globalOptions = { iterations: 1, direction: 'normal' }) {
    const currentTransform = getTransformState(animGroup, element);
    const order = getElementOrder(element);

    // Resolve start/end values for each sub-property.
    // These resolved values are also returned so callers can store them
    // for computing interpolated values without reading the DOM.
    const resolved = {
        translate: {
            startX: currentTransform.x, startY: currentTransform.y, startZ: currentTransform.z,
            endX: currentTransform.x, endY: currentTransform.y, endZ: currentTransform.z,
            easing: null, easingKeyframes: null, duration: 0
        },
        scale: {
            startX: currentTransform.scaleX, startY: currentTransform.scaleY, startZ: currentTransform.scaleZ,
            endX: currentTransform.scaleX, endY: currentTransform.scaleY, endZ: currentTransform.scaleZ,
            easing: null, easingKeyframes: null, duration: 0
        },
        rotate: {
            startX: currentTransform.rotateX, startY: currentTransform.rotateY, startZ: currentTransform.rotateZ,
            endX: currentTransform.rotateX, endY: currentTransform.rotateY, endZ: currentTransform.rotateZ,
            easing: null, easingKeyframes: null, duration: 0
        },
        skew: {
            startX: currentTransform.skewX, startY: currentTransform.skewY,
            endX: currentTransform.skewX, endY: currentTransform.skewY,
            easing: null, easingKeyframes: null, duration: 0
        }
    };

    let maxDuration = 0;

    transformProperties.forEach(property => {
        const p = property;
        switch (p.type) {
            case 'translate':
                resolved.translate.startX = p.startX ?? p.defaultX ?? currentTransform.x;
                resolved.translate.startY = p.startY ?? p.defaultY ?? currentTransform.y;
                resolved.translate.startZ = p.startZ ?? p.defaultZ ?? currentTransform.z;
                resolved.translate.endX = p.endX ?? currentTransform.x;
                resolved.translate.endY = p.endY ?? currentTransform.y;
                resolved.translate.endZ = p.endZ ?? currentTransform.z;
                resolved.translate.easing = p.easing;
                resolved.translate.easingKeyframes = p.easingKeyframes;
                resolved.translate.duration = p.duration;
                break;
            case 'scale':
                resolved.scale.startX = p.startX ?? p.defaultX ?? currentTransform.scaleX;
                resolved.scale.startY = p.startY ?? p.defaultY ?? currentTransform.scaleY;
                resolved.scale.startZ = p.startZ ?? p.defaultZ ?? currentTransform.scaleZ;
                resolved.scale.endX = p.endX ?? currentTransform.scaleX;
                resolved.scale.endY = p.endY ?? currentTransform.scaleY;
                resolved.scale.endZ = p.endZ ?? currentTransform.scaleZ;
                resolved.scale.easing = p.easing;
                resolved.scale.easingKeyframes = p.easingKeyframes;
                resolved.scale.duration = p.duration;
                break;
            case 'rotate':
                resolved.rotate.startX = p.startX ?? p.defaultX ?? currentTransform.rotateX;
                resolved.rotate.startY = p.startY ?? p.defaultY ?? currentTransform.rotateY;
                resolved.rotate.startZ = p.startZ ?? p.defaultZ ?? currentTransform.rotateZ;
                resolved.rotate.endX = p.endX ?? currentTransform.rotateX;
                resolved.rotate.endY = p.endY ?? currentTransform.rotateY;
                resolved.rotate.endZ = p.endZ ?? currentTransform.rotateZ;
                resolved.rotate.easing = p.easing;
                resolved.rotate.easingKeyframes = p.easingKeyframes;
                resolved.rotate.duration = p.duration;
                break;
            case 'skew':
                resolved.skew.startX = p.startX ?? currentTransform.skewX;
                resolved.skew.startY = p.startY ?? currentTransform.skewY;
                resolved.skew.endX = p.endX ?? currentTransform.skewX;
                resolved.skew.endY = p.endY ?? currentTransform.skewY;
                resolved.skew.easing = p.easing;
                resolved.skew.easingKeyframes = p.easingKeyframes;
                resolved.skew.duration = p.duration;
                break;
        }
        if (p.duration > maxDuration) maxDuration = p.duration;
    });

    // Check if all sub-properties share the same simple easing (no easingKeyframes)
    const activeProps = transformProperties.map(p => resolved[p.type]);
    const allSameEasing = activeProps.every(r => !r.easingKeyframes && r.easing === activeProps[0].easing);
    const allSameDuration = activeProps.every(r => r.duration === activeProps[0].duration);

    if (allSameEasing && allSameDuration) {
        // Simple case: same easing and duration, use 2-keyframe animation
        const startTransform = buildTransformString(
            resolved.translate.startX, resolved.translate.startY, resolved.translate.startZ,
            resolved.scale.startX, resolved.scale.startY, resolved.scale.startZ,
            resolved.rotate.startX, resolved.rotate.startY, resolved.rotate.startZ,
            resolved.skew.startX, resolved.skew.startY, order
        );
        const endTransform = buildTransformString(
            resolved.translate.endX, resolved.translate.endY, resolved.translate.endZ,
            resolved.scale.endX, resolved.scale.endY, resolved.scale.endZ,
            resolved.rotate.endX, resolved.rotate.endY, resolved.rotate.endZ,
            resolved.skew.endX, resolved.skew.endY, order
        );

        const easing = activeProps[0].easing;
        const animationEasing = easingFunctions[easing] || easing;

        return {
            animation: element.animate([
                { transform: startTransform },
                { transform: endTransform }
            ], {
                duration: maxDuration,
                easing: animationEasing,
                fill: 'forwards',
                iterations: globalOptions.iterations,
                direction: globalOptions.direction
            }),
            resolved: resolved
        };
    }

    // Complex case: different easings or durations per sub-property.
    // Generate keyframes where each sub-property is independently eased.
    const KEYFRAME_COUNT = 30;
    const keyframes = [];

    for (let i = 0; i < KEYFRAME_COUNT; i++) {
        const globalProgress = i / (KEYFRAME_COUNT - 1); // 0.0 to 1.0

        // For each sub-property, compute its local progress considering duration ratio
        const interpTranslate = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
        const interpScale = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
        const interpRotate = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
        const interpSkew = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);

        const transform = buildTransformString(
            interpTranslate.x, interpTranslate.y, interpTranslate.z,
            interpScale.x, interpScale.y, interpScale.z,
            interpRotate.x, interpRotate.y, interpRotate.z,
            interpSkew.x, interpSkew.y, order
        );

        keyframes.push({ transform });
    }

    return {
        animation: element.animate(keyframes, {
            duration: maxDuration,
            easing: 'linear', // easing is baked into keyframes
            fill: 'forwards',
            iterations: globalOptions.iterations,
            direction: globalOptions.direction
        }),
        resolved: resolved
    };
}

/**
 * Interpolate a transform sub-property at a given global progress,
 * accounting for its own duration and easing.
 */
function interpolateSubProperty(subProp, globalProgress, maxDuration) {
    // Scale progress by duration ratio (shorter animations complete before globalProgress=1)
    const durationRatio = subProp.duration > 0 ? subProp.duration / maxDuration : 1;
    const localProgress = Math.min(1.0, durationRatio > 0 ? globalProgress / durationRatio : 1.0);

    // Apply easing
    let easedProgress;
    if (subProp.easingKeyframes && Array.isArray(subProp.easingKeyframes) && subProp.easingKeyframes.length > 1) {
        // Complex easing (bounce, elastic): linearly interpolate between
        // pre-computed keyframes to match the browser's linear interpolation
        // within the 30-keyframe WAAPI animation.
        const len = subProp.easingKeyframes.length;
        const rawIdx = localProgress * (len - 1);
        const idx = Math.min(Math.floor(rawIdx), len - 2);
        const fraction = rawIdx - idx;
        easedProgress = subProp.easingKeyframes[idx] +
            (subProp.easingKeyframes[idx + 1] - subProp.easingKeyframes[idx]) * fraction;
    } else {
        // Simple easing: the browser handles easing via CSS animation-timing-function.
        // Use linear here since the CSS easing is applied by the browser, not by us.
        easedProgress = localProgress;
    }

    return {
        x: subProp.startX + (subProp.endX - subProp.startX) * easedProgress,
        y: subProp.startY + (subProp.endY - subProp.startY) * easedProgress,
        z: subProp.startZ + (subProp.endZ - subProp.startZ) * easedProgress
    };
}

/**
 * Create animation for non-transform properties
 */
function createPropertyAnimation(element, property, globalOptions = { iterations: 1, direction: 'normal' }) {
    const duration = property.duration;
    const easing = property.easing;
    const easingKeyframes = property.easingKeyframes;

    let keyframes = [];
    let animationEasing;

    switch (property.type) {
        case 'opacity':
            {
                const computedOpacity = parseFloat(window.getComputedStyle(element).opacity);
                const startValue = property.startValue ?? property.defaultValue ?? computedOpacity;
                const endValue = property.endValue;

                if (easingKeyframes) {
                    // Complex easing: generate keyframes with easing applied
                    keyframes = easingKeyframes.map(progress => ({
                        opacity: (startValue + (endValue - startValue) * progress).toString()
                    }));
                    animationEasing = 'linear';
                } else {
                    // Simple easing: use 2 keyframes
                    keyframes = [
                        { opacity: startValue.toString() },
                        { opacity: endValue.toString() }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'backgroundColor':
            {
                const computedBgColor = window.getComputedStyle(element).backgroundColor;
                const startColor = property.startColor ?? property.defaultColor ?? computedBgColor;
                const endColor = property.endColor;

                if (easingKeyframes) {
                    // Complex easing: generate keyframes with easing applied
                    keyframes = easingKeyframes.map(progress => ({
                        backgroundColor: interpolateColor(startColor, endColor, progress)
                    }));
                    animationEasing = 'linear';
                } else {
                    // Simple easing: use 2 keyframes
                    keyframes = [
                        { backgroundColor: startColor },
                        { backgroundColor: endColor }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'color':
            {
                const computedColor = window.getComputedStyle(element).color;
                const startColor = property.startColor ?? property.defaultColor ?? computedColor;
                const endColor = property.endColor;

                if (easingKeyframes) {
                    // Complex easing: generate keyframes with easing applied
                    keyframes = easingKeyframes.map(progress => ({
                        color: interpolateColor(startColor, endColor, progress)
                    }));
                    animationEasing = 'linear';
                } else {
                    // Simple easing: use 2 keyframes
                    keyframes = [
                        { color: startColor },
                        { color: endColor }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'size':
            {
                const computedStyle = window.getComputedStyle(element);
                const startWidth = property.startWidth != null ? property.startWidth : parseFloat(computedStyle.width);
                const startHeight = property.startHeight != null ? property.startHeight : parseFloat(computedStyle.height);

                if (easingKeyframes) {
                    // Complex easing: generate keyframes with easing applied
                    keyframes = easingKeyframes.map(progress => ({
                        width: `${startWidth + (property.endWidth - startWidth) * progress}px`,
                        height: `${startHeight + (property.endHeight - startHeight) * progress}px`
                    }));
                    animationEasing = 'linear';
                } else {
                    // Simple easing: use 2 keyframes
                    keyframes = [
                        {
                            width: `${startWidth}px`,
                            height: `${startHeight}px`
                        },
                        {
                            width: `${property.endWidth}px`,
                            height: `${property.endHeight}px`
                        }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'customProperty':
            {
                const cssPropName = camelCase(property.cssProperty);
                const computedStyle = window.getComputedStyle(element);
                const computedValue = parseFloat(computedStyle.getPropertyValue(property.cssProperty)) || 0;
                const startValue = property.startValue ?? computedValue;
                const endValue = property.endValue;
                const unit = property.unit;

                if (easingKeyframes) {
                    keyframes = easingKeyframes.map(progress => ({
                        [cssPropName]: `${startValue + (endValue - startValue) * progress}${unit}`
                    }));
                    animationEasing = 'linear';
                } else {
                    keyframes = [
                        { [cssPropName]: `${startValue}${unit}` },
                        { [cssPropName]: `${endValue}${unit}` }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'customColorProperty':
            {
                const cssPropName = camelCase(property.cssProperty);
                const computedStyle = window.getComputedStyle(element);
                const computedColor = computedStyle.getPropertyValue(property.cssProperty) || 'rgba(0, 0, 0, 1)';
                const startColor = property.startColor ?? computedColor;
                const endColor = property.endColor;

                if (easingKeyframes) {
                    keyframes = easingKeyframes.map(progress => ({
                        [cssPropName]: interpolateColor(startColor, endColor, progress)
                    }));
                    animationEasing = 'linear';
                } else {
                    keyframes = [
                        { [cssPropName]: startColor },
                        { [cssPropName]: endColor }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        case 'perspectiveOrigin':
            {
                const startX = property.startX;
                const startY = property.startY;
                const endX = property.endX;
                const endY = property.endY;
                const unit = property.unit;

                if (easingKeyframes) {
                    keyframes = easingKeyframes.map(progress => ({
                        perspectiveOrigin: `${startX + (endX - startX) * progress}${unit} ${startY + (endY - startY) * progress}${unit}`
                    }));
                    animationEasing = 'linear';
                } else {
                    keyframes = [
                        { perspectiveOrigin: `${startX}${unit} ${startY}${unit}` },
                        { perspectiveOrigin: `${endX}${unit} ${endY}${unit}` }
                    ];
                    animationEasing = easingFunctions[easing] || easing;
                }
            }
            break;

        default:
            console.warn(`ElmAnimateWAAPI: Unknown property type "${property.type}"`);
            return null;
    }

    return element.animate(keyframes, {
        duration: duration,
        easing: animationEasing,
        fill: 'forwards',
        iterations: globalOptions.iterations,
        direction: globalOptions.direction
    });
}

/**
 * Build a complete transform string with 3D support.
 * The order parameter controls the order of translate, rotate, and scale
 * in the output string. Rotation axes are always applied X → Y → Z within
 * the rotate group.
 */
function buildTransformString(x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY, order) {
    const asNumber = (value, fallback) => Number.isFinite(value) ? value : fallback;
    const tx = asNumber(x, 0);
    const ty = asNumber(y, 0);
    const tz = asNumber(z, 0);
    const sx = asNumber(scaleX, 1);
    const sy = asNumber(scaleY, 1);
    const sz = asNumber(scaleZ, 1);
    const rx = asNumber(rotateX, 0);
    const ry = asNumber(rotateY, 0);
    const rz = asNumber(rotateZ, 0);
    const kx = asNumber(skewX, 0);
    const ky = asNumber(skewY, 0);

    const transformOrder = order || DEFAULT_TRANSFORM_ORDER;
    const parts = [];

    for (const group of transformOrder) {
        switch (group) {
            case 'translate':
                if (tx !== 0 || ty !== 0 || tz !== 0) {
                    parts.push(`translate3d(${tx}px, ${ty}px, ${tz}px)`);
                }
                break;
            case 'rotate':
                if (rx !== 0) {
                    parts.push(`rotateX(${rx}deg)`);
                }
                if (ry !== 0) {
                    parts.push(`rotateY(${ry}deg)`);
                }
                if (rz !== 0) {
                    parts.push(`rotateZ(${rz}deg)`);
                }
                break;
            case 'skew':
                if (kx !== 0) {
                    parts.push(`skewX(${kx}deg)`);
                }
                if (ky !== 0) {
                    parts.push(`skewY(${ky}deg)`);
                }
                break;
            case 'scale':
                if (sx !== 1) {
                    parts.push(`scaleX(${sx})`);
                }
                if (sy !== 1) {
                    parts.push(`scaleY(${sy})`);
                }
                if (sz !== 1) {
                    parts.push(`scaleZ(${sz})`);
                }
                break;
        }
    }

    return parts.join(' ') || 'none';
}

/**
 * Get current transform state of an element with 3D support.
 * When a WAAPI animation is active, uses getComputedStyle which reflects the
 * real animated values (including the WAAPI compositing layer). When no animation
 * is running, falls back to reading the inline style which preserves committed
 * final values with individual transform functions (rotateX, rotateY, etc.).
 */
function getCurrentTransform(element) {
    // Check if this element has active WAAPI animations.
    // If so, getComputedStyle reflects the real animated state (including the
    // WAAPI layer), while inline style only has the optimistic end values from Elm.
    const hasActiveAnimation = element.getAnimations && element.getAnimations().length > 0;

    if (!hasActiveAnimation) {
        // No WAAPI animation running - parse inline style which preserves
        // individual transform functions (rotateX, rotateY, etc.) from commitStyles
        const inlineTransform = element.style.transform;
        if (inlineTransform && inlineTransform !== 'none') {
            return parseTransformString(inlineTransform);
        }
    }

    // Use computed style - this reflects the actual animated transform
    const style = window.getComputedStyle(element);
    const transform = style.transform;

    if (transform === 'none' || !transform) {
        return {
            transform: 'none',
            x: 0, y: 0, z: 0,
            scaleX: 1, scaleY: 1, scaleZ: 1,
            rotateX: 0, rotateY: 0, rotateZ: 0,
            skewX: 0, skewY: 0
        };
    }

    // Parse transform matrix (2D or 3D)
    const matrix2d = transform.match(/matrix\((.+)\)/);
    const matrix3d = transform.match(/matrix3d\((.+)\)/);

    if (matrix3d) {
        const values = matrix3d[1].split(', ').map(parseFloat);

        if (values.length === 16) {
            const tx = values[12] || 0;
            const ty = values[13] || 0;
            const tz = values[14] || 0;

            // Extract scale from column vector lengths
            const scaleX = Math.sqrt(values[0] * values[0] + values[1] * values[1] + values[2] * values[2]);
            const scaleY = Math.sqrt(values[4] * values[4] + values[5] * values[5] + values[6] * values[6]);
            const scaleZ = Math.sqrt(values[8] * values[8] + values[9] * values[9] + values[10] * values[10]);

            // Extract rotation matrix by dividing out scale
            // R[row][col] = values[col*4 + row] / scale for that column
            const r00 = scaleX !== 0 ? values[0] / scaleX : 0;
            const r10 = scaleX !== 0 ? values[1] / scaleX : 0;
            const r20 = scaleX !== 0 ? values[2] / scaleX : 0;
            const r01 = scaleY !== 0 ? values[4] / scaleY : 0;
            const r11 = scaleY !== 0 ? values[5] / scaleY : 0;
            const r21 = scaleY !== 0 ? values[6] / scaleY : 0;
            scaleZ !== 0 ? values[8] / scaleZ : 0;
            scaleZ !== 0 ? values[9] / scaleZ : 0;
            const r22 = scaleZ !== 0 ? values[10] / scaleZ : 0;

            // Euler angles (XYZ convention) from rotation matrix
            const RAD_TO_DEG = 180 / Math.PI;
            let rotateX, rotateY, rotateZ;

            const sy = -r20;
            if (sy >= 1) {
                // Gimbal lock at +90 degrees
                rotateY = 90;
                rotateX = Math.atan2(r01, r11) * RAD_TO_DEG;
                rotateZ = 0;
            } else if (sy <= -1) {
                // Gimbal lock at -90 degrees
                rotateY = -90;
                rotateX = Math.atan2(r01, r11) * RAD_TO_DEG;
                rotateZ = 0;
            } else {
                rotateY = Math.asin(sy) * RAD_TO_DEG;
                rotateX = Math.atan2(r21, r22) * RAD_TO_DEG;
                rotateZ = Math.atan2(r10, r00) * RAD_TO_DEG;
            }

            return { transform, x: tx, y: ty, z: tz, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX: 0, skewY: 0 };
        }
    } else if (matrix2d) {
        const values = matrix2d[1].split(', ').map(parseFloat);

        if (values.length === 6) {
            const a = values[0];
            const b = values[1];
            const c = values[2];
            const d = values[3];
            const tx = values[4] || 0;
            const ty = values[5] || 0;

            const scaleX = Math.sqrt(a * a + b * b);
            const scaleY = Math.sqrt(c * c + d * d);
            const rotateZ = Math.atan2(b, a) * (180 / Math.PI);

            return {
                transform,
                x: tx, y: ty, z: 0,
                scaleX, scaleY, scaleZ: 1,
                rotateX: 0, rotateY: 0, rotateZ,
                skewX: 0, skewY: 0
            };
        }
    }

    return {
        transform,
        x: 0, y: 0, z: 0,
        scaleX: 1, scaleY: 1, scaleZ: 1,
        rotateX: 0, rotateY: 0, rotateZ: 0,
        skewX: 0, skewY: 0
    };
}

/**
 * Parse a CSS transform string (e.g. "translate3d(10px, 20px, 30px) rotateY(90deg)")
 * into individual transform components. This preserves axis-specific values that
 * are lost when the browser computes a matrix3d.
 */
function parseTransformString(transformStr) {
    const result = {
        transform: transformStr,
        x: 0, y: 0, z: 0,
        scaleX: 1, scaleY: 1, scaleZ: 1,
        rotateX: 0, rotateY: 0, rotateZ: 0,
        skewX: 0, skewY: 0
    };

    // translate3d(Xpx, Ypx, Zpx)
    const translate3d = transformStr.match(/translate3d\(\s*([-\d.]+)px\s*,\s*([-\d.]+)px\s*,\s*([-\d.]+)px\s*\)/);
    if (translate3d) {
        result.x = parseFloat(translate3d[1]);
        result.y = parseFloat(translate3d[2]);
        result.z = parseFloat(translate3d[3]);
    }

    // translateX(Xpx), translateY(Ypx), translateZ(Zpx)
    const translateX = transformStr.match(/translateX\(\s*([-\d.]+)px\s*\)/);
    const translateY = transformStr.match(/translateY\(\s*([-\d.]+)px\s*\)/);
    const translateZ = transformStr.match(/translateZ\(\s*([-\d.]+)px\s*\)/);
    if (translateX) result.x = parseFloat(translateX[1]);
    if (translateY) result.y = parseFloat(translateY[1]);
    if (translateZ) result.z = parseFloat(translateZ[1]);

    // rotateX(Xdeg), rotateY(Ydeg), rotateZ(Zdeg)
    const rotateX = transformStr.match(/rotateX\(\s*([-\d.]+)deg\s*\)/);
    const rotateY = transformStr.match(/rotateY\(\s*([-\d.]+)deg\s*\)/);
    const rotateZ = transformStr.match(/rotateZ\(\s*([-\d.]+)deg\s*\)/);
    if (rotateX) result.rotateX = parseFloat(rotateX[1]);
    if (rotateY) result.rotateY = parseFloat(rotateY[1]);
    if (rotateZ) result.rotateZ = parseFloat(rotateZ[1]);

    // skewX(Xdeg), skewY(Ydeg)
    const skewX = transformStr.match(/skewX\(\s*([-\d.]+)deg\s*\)/);
    const skewY = transformStr.match(/skewY\(\s*([-\d.]+)deg\s*\)/);
    if (skewX) result.skewX = parseFloat(skewX[1]);
    if (skewY) result.skewY = parseFloat(skewY[1]);

    // skew(Xdeg, Ydeg) - 2D shorthand
    const skew2d = transformStr.match(/skew\(\s*([-\d.]+)deg\s*(?:,\s*([-\d.]+)deg\s*)?\)/);
    if (skew2d && !skewX && !skewY) {
        result.skewX = parseFloat(skew2d[1]);
        result.skewY = skew2d[2] ? parseFloat(skew2d[2]) : 0;
    }

    // scale3d(X, Y, Z)
    const scale3d = transformStr.match(/scale3d\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)/);
    if (scale3d) {
        result.scaleX = parseFloat(scale3d[1]);
        result.scaleY = parseFloat(scale3d[2]);
        result.scaleZ = parseFloat(scale3d[3]);
    }

    // scaleX(X), scaleY(Y), scaleZ(Z)
    const scaleX = transformStr.match(/scaleX\(\s*([-\d.]+)\s*\)/);
    const scaleY = transformStr.match(/scaleY\(\s*([-\d.]+)\s*\)/);
    const scaleZ = transformStr.match(/scaleZ\(\s*([-\d.]+)\s*\)/);
    if (scaleX) result.scaleX = parseFloat(scaleX[1]);
    if (scaleY) result.scaleY = parseFloat(scaleY[1]);
    if (scaleZ) result.scaleZ = parseFloat(scaleZ[1]);

    // scale(X, Y) - 2D shorthand
    const scale2d = transformStr.match(/scale\(\s*([-\d.]+)\s*(?:,\s*([-\d.]+)\s*)?\)/);
    if (scale2d && !scale3d) {
        result.scaleX = parseFloat(scale2d[1]);
        result.scaleY = scale2d[2] ? parseFloat(scale2d[2]) : parseFloat(scale2d[1]);
    }

    return result;
}

/**
 * Compute transform state from resolved start/end values at a given progress.
 * Uses interpolateSubProperty so per-sub-property duration and easing are
 * respected (important for the complex multi-easing case).
 * @returns {{ x, y, z, scaleX, scaleY, scaleZ, rotateX, rotateY, rotateZ, skewX, skewY }}
 */
function computeTransformFromResolved(resolved, globalProgress, maxDuration) {
    const t = interpolateSubProperty(resolved.translate, globalProgress, maxDuration);
    const s = interpolateSubProperty(resolved.scale, globalProgress, maxDuration);
    const r = interpolateSubProperty(resolved.rotate, globalProgress, maxDuration);
    const k = interpolateSubProperty(resolved.skew, globalProgress, maxDuration);
    return {
        x: t.x, y: t.y, z: t.z,
        scaleX: s.x, scaleY: s.y, scaleZ: s.z,
        rotateX: r.x, rotateY: r.y, rotateZ: r.z,
        skewX: k.x, skewY: k.y
    };
}

/**
 * Get the default identity transform state (no translation, no rotation,
 * unit scale). Used as a fallback when no prior transform state is known.
 */
function getDefaultTransformState() {
    return { x: 0, y: 0, z: 0, scaleX: 1, scaleY: 1, scaleZ: 1, rotateX: 0, rotateY: 0, rotateZ: 0, skewX: 0, skewY: 0 };
}

/**
 * Set up animation event listeners and property updates with version tracking
 */
function setupAnimationEvents(animGroup, propertyType, element, animation, version, animGroupName, resolvedTransformValues, resolvedNonTransform) {
    // Capture the current group generation so that old animation handlers
    // (from previous animate calls) don't corrupt the new group's tracking.
    const groupGeneration = animationGroups.get(animGroup)?.generation || 0;

    // Claim a property index for iteration tracking (slowest-wins: the group
    // iteration event fires only when all properties have completed the loop).
    const groupInfoForIndex = animationGroups.get(animGroup);
    const propertyIndex = groupInfoForIndex ? groupInfoForIndex.nextPropertyIndex++ : 0;
    let updatePort = null;

    // Find the update port
    if (typeof window.app !== 'undefined' &&
        window.app.ports &&
        window.app.ports.waapiEvent &&
        typeof window.app.ports.waapiEvent.send === 'function') {
        updatePort = window.app.ports.waapiEvent;
    }

    // Duration of the transform animation (for computing interpolated values).
    // For non-transform animations this is 0 — transform values come from
    // lastKnownTransforms instead.
    const transformAnimDuration = resolvedTransformValues
        ? (animation.effect?.getTiming()?.duration || 0)
        : 0;

    // Track last computed transform state during animation.
    // Used by the cancel handler since animation.currentTime is null after cancel.
    let lastComputedTransformState = resolvedTransformValues
        ? computeTransformFromResolved(resolvedTransformValues, 0, transformAnimDuration)
        : null;

    // Send updates during animation
    let lastTime = 0;
    const updateInterval = 16; // ~60fps
    let rafId = null;

    function sendAnimationUpdate() {
        const now = performance.now();
        if (now - lastTime >= updateInterval) {
            // Detect iteration boundary changes (slowest-wins).
            // Each property updates its own slot; the group event fires only when
            // ALL properties have completed the same loop (Math.min advances).
            const groupInfo = animationGroups.get(animGroup);
            if (groupInfo && groupInfo.generation === groupGeneration) {
                try {
                    const currentIteration = animation.effect?.getComputedTiming()?.currentIteration;
                    const nextGroupIteration = updateGroupIteration(
                        groupInfo.propertyIterations,
                        propertyIndex,
                        currentIteration,
                        groupInfo.lastIteration
                    );
                    if (nextGroupIteration != null) {
                        groupInfo.lastIteration = nextGroupIteration;
                        sendIterationEvent(animGroup, nextGroupIteration);
                    }
                } catch (_) { /* ignore timing errors */ }
            }

            const computedStyle = window.getComputedStyle(element);

            // Get transform values from resolved data (avoids matrix decomposition
            // which normalises angles: 360° → 0°, 270° → -90°)
            let transformState;
            if (resolvedTransformValues) {
                const currentTime = animation.currentTime || 0;
                const animProgress = transformAnimDuration > 0
                    ? Math.min(1.0, Math.max(0.0, currentTime / transformAnimDuration))
                    : 0;
                transformState = computeTransformFromResolved(resolvedTransformValues, animProgress, transformAnimDuration);
                lastComputedTransformState = transformState;
                lastKnownTransforms.set(animGroup, transformState);
            } else {
                transformState = lastKnownTransforms.get(animGroup) || getDefaultTransformState();
            }

            if (updatePort) {
                // Collect property versions from all active animations for this element
                const propertyVersions = {};
                const elementAnims = activeAnimations.get(animGroup);
                if (elementAnims) {
                    elementAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }

                // Calculate progress from animation currentTime/duration
                const groupInfo = animationGroups.get(animGroup);
                const maxDuration = groupInfo?.propertyConfigs?.length > 0
                    ? Math.max(...groupInfo.propertyConfigs.map(p => p.duration))
                    : animation.effect?.getTiming()?.duration || 0;
                const currentTime = animation.currentTime || 0;
                const progress = maxDuration > 0
                    ? Math.min(1.0, Math.max(0.0, currentTime / maxDuration))
                    : 0;

                const propertyData = {
                    elementId: animGroup,
                    animGroup: animGroup,
                    progress: progress,
                    ...buildAnimatedPropertyData(animGroup, propertyVersions, transformState, element, computedStyle),
                    isAnimating: true,
                    propertyVersions: propertyVersions
                };
                // Send property update during animation
                sendPropertyUpdate(propertyData);
            }
            lastTime = now;
        }

        if (animation.playState === 'running') {
            rafId = requestAnimationFrame(sendAnimationUpdate);
        } else {
            rafId = null;
        }
    }

    // Start sending updates
    rafId = requestAnimationFrame(sendAnimationUpdate);

    // Track whether finish handler already processed this animation.
    // animation.cancel() inside finish triggers the cancel event — this
    // flag prevents the cancel handler from double-counting completions.
    let finishHandled = false;

    // Handle animation completion
    animation.addEventListener('finish', () => {
        finishHandled = true;

        // Stop update loop
        if (rafId !== null) {
            cancelAnimationFrame(rafId);
            rafId = null;
        }
        // CRITICAL: Commit the animated styles to inline styles, then cancel
        // MDN: After commitStyles(), you must cancel() to fully remove the animation
        // Without cancel(), the finished animation can still affect the cascade
        try {
            animation.commitStyles();
            animation.cancel();
        } catch (_) {
            // commitStyles can fail if the element is not rendered
            // (e.g. inside a hidden iframe tab). This is harmless —
            // the animation is already finished and the element is not visible.
            try { animation.cancel(); } catch (_) { /* ignore */ }
        }

        // Only remove THIS property's animation if version matches
        // (prevents removing newer animation if finish event fires late)
        const elementAnims = activeAnimations.get(animGroup);
        if (elementAnims) {
            const current = elementAnims.get(propertyType);
            if (current && current.version === version) {
                elementAnims.delete(propertyType);

                // If no more properties animating, clean up element entry
                if (elementAnims.size === 0) {
                    activeAnimations.delete(animGroup);
                }
            }
        }

        // Track completion for animGroup - emit 'completed' when all properties done
        const groupInfo = animationGroups.get(animGroup);
        if (groupInfo && groupInfo.generation === groupGeneration) {
            groupInfo.completedProperties++;
            const allComplete = groupInfo.completedProperties >= groupInfo.totalProperties;

            if (updatePort) {
                // Use resolved end values for transforms (avoids matrix decomposition
                // which normalises angles: 360° → 0°, 270° → -90°)
                let finalTransformState;
                if (resolvedTransformValues) {
                    finalTransformState = {
                        x: resolvedTransformValues.translate.endX,
                        y: resolvedTransformValues.translate.endY,
                        z: resolvedTransformValues.translate.endZ,
                        scaleX: resolvedTransformValues.scale.endX,
                        scaleY: resolvedTransformValues.scale.endY,
                        scaleZ: resolvedTransformValues.scale.endZ,
                        rotateX: resolvedTransformValues.rotate.endX,
                        rotateY: resolvedTransformValues.rotate.endY,
                        rotateZ: resolvedTransformValues.rotate.endZ,
                        skewX: resolvedTransformValues.skew.endX,
                        skewY: resolvedTransformValues.skew.endY
                    };
                    lastKnownTransforms.set(animGroup, finalTransformState);
                } else {
                    finalTransformState = lastKnownTransforms.get(animGroup) || getDefaultTransformState();
                }
                const computedStyle = window.getComputedStyle(element);

                // Collect remaining property versions
                const propertyVersions = {};
                const remainingAnims = activeAnimations.get(animGroup);
                if (remainingAnims) {
                    remainingAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }
                // Include the completed property with its version one last time
                propertyVersions[propertyType] = version;

                const finalPropertyData = {
                    elementId: animGroup,
                    animGroup: animGroup,
                    ...buildAnimatedPropertyData(animGroup, propertyVersions, finalTransformState, element, computedStyle),
                    isAnimating: !allComplete,
                    propertyVersions: propertyVersions
                };
                // Send final state property update
                sendPropertyUpdate(finalPropertyData);
            }

            // Emit 'completed' when all properties in the group have finished
            if (allComplete) {
                sendLifecycleEvent('completed', animGroup);
                animationGroups.delete(animGroup);
            }
        }
    });

    animation.addEventListener('cancel', () => {
        // Skip if this cancel was triggered by animation.cancel() inside the
        // finish handler (commitStyles → cancel flow). The finish handler
        // already handled group tracking and cleanup.
        if (finishHandled) return;

        // Only remove THIS property's animation if version matches
        // (prevents removing newer animation if cancel event fires late)
        const elementAnims = activeAnimations.get(animGroup);
        if (elementAnims) {
            const current = elementAnims.get(propertyType);
            if (current && current.version === version) {
                elementAnims.delete(propertyType);

                // If no more properties animating, clean up element entry
                if (elementAnims.size === 0) {
                    activeAnimations.delete(animGroup);
                }
            }
        }

        // Track cancellation for animGroup
        const groupInfo = animationGroups.get(animGroup);
        if (groupInfo && groupInfo.generation === groupGeneration) {
            groupInfo.completedProperties++;
            const allCancelled = groupInfo.completedProperties >= groupInfo.totalProperties;

            if (updatePort) {
                let cancelTransformState;
                if (resolvedTransformValues) {
                    cancelTransformState = lastComputedTransformState || getDefaultTransformState();
                    lastKnownTransforms.set(animGroup, cancelTransformState);
                } else {
                    cancelTransformState = lastKnownTransforms.get(animGroup) || getDefaultTransformState();
                }
                const computedStyle = window.getComputedStyle(element);

                // Collect remaining property versions
                const propertyVersions = {};
                const remainingAnims = activeAnimations.get(animGroup);
                if (remainingAnims) {
                    remainingAnims.forEach((animData, propType) => {
                        propertyVersions[propType] = animData.version;
                    });
                }
                // Include the cancelled property with its version one last time
                propertyVersions[propertyType] = version;

                const currentPropertyData = {
                    elementId: animGroup,
                    animGroup: animGroup,
                    ...buildAnimatedPropertyData(animGroup, propertyVersions, cancelTransformState, element, computedStyle),
                    isAnimating: !allCancelled,
                    propertyVersions: propertyVersions
                };
                sendPropertyUpdate(currentPropertyData);
            }

            // Emit 'cancelled' when all properties in the group have been cancelled
            if (allCancelled) {
                sendLifecycleEvent('cancelled', animGroup);
                animationGroups.delete(animGroup);
            }
        }
    });

    // Return the update function so it can be restarted on resume
    return sendAnimationUpdate;
}

/**
 * Send iteration event to Elm when an animation crosses an iteration boundary.
 * The iteration count is sent as the progress value so Elm can decode it
 * via: Iteration animGroupName (round progress)
 * @param {string} animGroup - The animation group identifier
 * @param {number} iterationNumber - The current iteration number (1-based)
 */
function sendIterationEvent(animGroup, iterationNumber) {
    if (window.app && window.app.ports && window.app.ports.waapiEvent) {
        window.app.ports.waapiEvent.send({
            type: 'animationUpdate',
            payload: {
                elementId: animGroup,
                animGroup: animGroup,
                status: 'iteration',
                progress: iterationNumber
            }
        });
    }
}

/**
 * Send lifecycle event to Elm (started, completed, cancelled, etc.)
 * Uses 'animationUpdate' type which Elm routes to AnimEvent handling
 * Includes property configurations and current progress for rich event data.
 * @param {string} status - Lifecycle status ('started', 'completed', 'cancelled', 'paused', 'resumed', 'stopped', 'reset', 'restarted')
 * @param {string} animGroup - The animation group identifier
 */
function sendLifecycleEvent(status, animGroup) {
    if (window.app && window.app.ports && window.app.ports.waapiEvent) {
        const groupInfo = animationGroups.get(animGroup);

        // Get property configs to calculate max duration for progress
        const properties = groupInfo?.propertyConfigs || [];
        const maxDuration = properties.length > 0
            ? Math.max(...properties.map(p => p.duration))
            : 0;

        // Calculate progress based on event type
        let progress = 0;
        if (status === 'completed' || status === 'stopped') {
            progress = 1.0;
        } else if (status === 'started' || status === 'reset' || status === 'restarted') {
            progress = 0.0;
        } else {
            // For paused, resumed, cancelled - calculate actual progress
            const elementAnims = activeAnimations.get(animGroup);
            if (elementAnims && elementAnims.size > 0) {
                // Get progress from any active animation (they should be in sync)
                const firstAnim = elementAnims.values().next().value;
                if (firstAnim && firstAnim.animation && maxDuration > 0) {
                    const currentTime = firstAnim.animation.currentTime || 0;
                    progress = Math.min(1.0, Math.max(0.0, currentTime / maxDuration));
                }
            }
        }

        const eventData = {
            type: 'animationUpdate',
            engine: 'waapi',
            payload: {
                elementId: animGroup,
                animGroup: animGroup,
                status: status,
                progress: progress
            }
        };
        window.app.ports.waapiEvent.send(eventData);
    }
}

/**
 * Build property data containing only the properties that are currently animated.
 * Uses propertyVersions keys to determine which properties to include,
 * so only animated values are sent to Elm (reducing decoder work per frame).
 * @param {object} propertyVersions - Maps property type to version number
 * @param {object} transformState - Current transform values (x, y, z, rotateX, etc.)
 * @param {CSSStyleDeclaration} computedStyle - Element's computed style
 * @returns {object} Filtered property data with only animated properties
 */
function buildAnimatedPropertyData(animGroup, propertyVersions, transformState, element, computedStyle) {
    const data = {};
    if ('transform' in propertyVersions) {
        data.translate = { x: transformState.x, y: transformState.y, z: transformState.z };
        data.rotate = { x: transformState.rotateX, y: transformState.rotateY, z: transformState.rotateZ };
        data.skew = { x: transformState.skewX, y: transformState.skewY };
        data.scale = { x: transformState.scaleX, y: transformState.scaleY, z: transformState.scaleZ };
    }
    if ('opacity' in propertyVersions) {
        data.opacity = parseFloat(computedStyle.opacity);
    }
    if ('size' in propertyVersions) {
        data.size = { width: parseFloat(computedStyle.width), height: parseFloat(computedStyle.height) };
    }
    if ('perspectiveOrigin' in propertyVersions) {
        const computedOrigin = computedStyle.perspectiveOrigin || '50% 50%';
        const parts = computedOrigin.trim().split(/\s+/);

        const parsePart = (part) => {
            const match = String(part || '').trim().match(/^(-?\d*\.?\d+)(px|%)$/);
            if (!match) return null;
            return { value: parseFloat(match[1]), unit: match[2] };
        };

        const parsedX = parsePart(parts[0]);
        const parsedY = parsePart(parts[1] || parts[0]);
        const cached = lastKnownPerspectiveOrigins.get(animGroup);
        const targetUnit = cached?.unit || parsedX?.unit || '%';

        let x = parsedX?.value ?? cached?.x ?? 50;
        let y = parsedY?.value ?? cached?.y ?? 50;

        const width = element?.clientWidth || element?.offsetWidth || 1;
        const height = element?.clientHeight || element?.offsetHeight || 1;
        const parsedUnit = parsedX?.unit || parsedY?.unit;

        if (parsedUnit && parsedUnit !== targetUnit) {
            if (parsedUnit === 'px' && targetUnit === '%') {
                x = (x / width) * 100;
                y = (y / height) * 100;
            } else if (parsedUnit === '%' && targetUnit === 'px') {
                x = (x / 100) * width;
                y = (y / 100) * height;
            }
        }

        data.perspectiveOrigin = {
            x: x,
            y: y,
            unit: targetUnit === '%' ? 'percent' : 'px'
        };
    }
    const customProps = {};
    const customColorProps = {};
    for (const key of Object.keys(propertyVersions)) {
        if (key.startsWith('custom:')) {
            const cssName = key.slice(7);
            customProps[cssName] = parseFloat(computedStyle.getPropertyValue(cssName)) || 0;
        } else if (key.startsWith('customColor:')) {
            const cssName = key.slice(12);
            customColorProps[cssName] = computedStyle.getPropertyValue(cssName) || 'rgba(0, 0, 0, 1)';
        }
    }
    if (Object.keys(customProps).length > 0) {
        data.customProperties = customProps;
    }
    if (Object.keys(customColorProps).length > 0) {
        data.customColorProperties = customColorProps;
    }
    return data;
}

/**
 * Send property update to Elm (during animation)
 * Uses 'propertyUpdate' type which Elm routes to PropertyUpdate handling
 * @param {object} propertyData - The current property values and metadata
 */
function sendPropertyUpdate(propertyData) {
    if (window.app && window.app.ports && window.app.ports.waapiEvent) {
        const eventData = {
            type: 'propertyUpdate',
            ...propertyData
        };
        window.app.ports.waapiEvent.send(eventData);
    }
}

/**
 * Stop animation by jumping to end state
 * @param {string} animGroup - The animation group name
 * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
 */
function stopAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;

    const propsToAffect = properties ? new Set(properties) : null;
    let affectedCount = 0;

    elementAnims.forEach((animData, propertyType) => {
        if (!propsToAffect || propsToAffect.has(propertyType)) {
            animData.animation.finish(); // Jump to end state
            affectedCount++;
        }
    });

    // If we affected all properties, delete the entry and clean up group tracking
    if (!propsToAffect || affectedCount === elementAnims.size) {
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);
    }

    sendLifecycleEvent('stopped', animGroup);
}

/**
 * Reset animation by jumping to start state
 * @param {string} animGroup - The animation group name
 * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
 */
function resetAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;

    const propsToAffect = properties ? new Set(properties) : null;
    let affectedCount = 0;

    elementAnims.forEach((animData, propertyType) => {
        if (!propsToAffect || propsToAffect.has(propertyType)) {
            animData.animation.cancel(); // Cancel to jump to start
            affectedCount++;
        }
    });

    // If we affected all properties, delete the entry and clean up group tracking
    if (!propsToAffect || affectedCount === elementAnims.size) {
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);
    }

    sendLifecycleEvent('reset', animGroup);
}

/**
 * Restart animation from beginning
 * @param {string} animGroup - The animation group name
 * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
 */
function restartAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;

    const propsToAffect = properties ? new Set(properties) : null;

    elementAnims.forEach((animData, propertyType) => {
        if (!propsToAffect || propsToAffect.has(propertyType)) {
            animData.animation.cancel(); // Cancel first
            animData.animation.play();   // Then replay
        }
    });

    // Reset group tracking for restart
    const groupTracking = animationGroups.get(animGroup);
    if (groupTracking) {
        groupTracking.completedProperties = 0;
        groupTracking.started = false;
    }

    sendLifecycleEvent('restarted', animGroup);
}

/**
 * Pause animation for specific animation group
 * @param {string} animGroup - The animation group name
 * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
 */
function pauseAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;

    const propsToAffect = properties ? new Set(properties) : null;

    elementAnims.forEach((animData, propertyType) => {
        if (!propsToAffect || propsToAffect.has(propertyType)) {
            animData.animation.pause();
        }
    });

    sendLifecycleEvent('paused', animGroup);
}

/**
 * Resume animation for specific animation group
 * @param {string} animGroup - The animation group name
 * @param {string[]|undefined} properties - Optional array of property types to affect. If undefined, affects all.
 */
function resumeAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;

    const propsToAffect = properties ? new Set(properties) : null;

    elementAnims.forEach((animData, propertyType) => {
        if (!propsToAffect || propsToAffect.has(propertyType)) {
            animData.animation.play();
            // Restart the RAF update loop
            if (animData.updateFn) {
                animData.updateFn();
            }
        }
    });

    sendLifecycleEvent('resumed', animGroup);
}


/**
 * Set all properties directly for elements (initialization)
 * Called during initProperties to synchronize Elm, JS, and inline styles
 * ARCHITECTURE: Elm sends all property values - no defaults in JS
 */
function setProperties(updates) {
    updates.forEach(update => {
        const animGroup = update.elementId;
        const element = findAnimTarget(animGroup);
        if (!element) {
            console.warn(`ElmAnimateWAAPI: Element with data-anim-target="${animGroup}" not found`);
            return;
        }

        // CRITICAL: Cancel all existing animations
        const animations = element.getAnimations();
        animations.forEach((anim) => {
            anim.cancel();
        });

        // Clean up tracking for this animation group
        activeAnimations.delete(animGroup);
        animationGroups.delete(animGroup);

        const props = update.properties;

        // Transform properties - use direct inline style assignment
        // No animations are active at this point, so inline styles work fine
        // Active animations have higher precedence, but we've cancelled all animations above
        if (props.x !== undefined || props.y !== undefined || props.z !== undefined ||
            props.scaleX !== undefined || props.scaleY !== undefined || props.scaleZ !== undefined ||
            props.rotateX !== undefined || props.rotateY !== undefined || props.rotateZ !== undefined ||
            props.skewX !== undefined || props.skewY !== undefined) {

            const order = elementTransformOrders.get(animGroup) || DEFAULT_TRANSFORM_ORDER;
            const transform = buildTransformString(
                props.x || 0,
                props.y || 0,
                props.z || 0,
                props.scaleX !== undefined ? props.scaleX : 1,
                props.scaleY !== undefined ? props.scaleY : 1,
                props.scaleZ !== undefined ? props.scaleZ : 1,
                props.rotateX || 0,
                props.rotateY || 0,
                props.rotateZ || 0,
                props.skewX || 0,
                props.skewY || 0,
                order
            );

            // Direct inline style assignment - no animation needed
            element.style.transform = transform;
        }

        // Opacity
        if (props.opacity !== undefined) {
            element.style.opacity = props.opacity.toString();
        }

        // Background color
        if (props.backgroundColor !== undefined) {
            element.style.backgroundColor = props.backgroundColor;
        }

        // Font color
        if (props.color !== undefined) {
            element.style.color = props.color;
        }

        // Size
        if (props.width !== undefined && props.height !== undefined) {
            element.style.width = `${props.width}px`;
            element.style.height = `${props.height}px`;
        }
    });
}

/**
 * Initialize the WAAPI system with Elm ports
 */
function init(ports) {
    if (!ports) {
        console.error('ElmAnimateWAAPI: No ports provided to init()');
        return;
    }

    // Store reference for updates
    window.app = { ports: ports };

    // Subscribe to consolidated command port from Elm
    if (ports.waapiCommand && ports.waapiCommand.subscribe) {
        ports.waapiCommand.subscribe(async function (commandData) {
            try {
                if (!commandData) {
                    console.warn('ElmAnimateWAAPI: No command data received');
                    return;
                }

                if (!commandData.type) {
                    console.warn('ElmAnimateWAAPI: Command missing type field:', commandData);
                    return;
                }

                const commandType = commandData.type;

                switch (commandType) {
                    case 'animate':
                        // Animation data with elements
                        processAnimationData(commandData);
                        break;

                    case 'scrollDriven':
                        if (await ensureTimelineApi('ScrollTimeline')) {
                            processScrollDrivenData(commandData);
                        }
                        break;

                    case 'viewDriven':
                        if (await ensureTimelineApi('ViewTimeline')) {
                            processViewDrivenData(commandData);
                        }
                        break;

                    case 'setProperties':
                        setProperties(commandData.updates);
                        break;

                    case 'stop':
                        stopAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'reset':
                        resetAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'restart':
                        restartAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'pause':
                        pauseAnimation(commandData.elementId, commandData.properties);
                        break;

                    case 'resume':
                        resumeAnimation(commandData.elementId, commandData.properties);
                        break;

                    default:
                        console.warn('ElmAnimateWAAPI: Unknown command type:', commandType);
                }
            } catch (error) {
                console.error('ElmAnimateWAAPI: Error processing WAAPI command:', error);
            }
        });
    } else {
        console.warn('ElmAnimateWAAPI: waapiCommand port not found or not subscribeable');
    }
}

/**
 * Public API
 */

function addEasingFunction(name, cssValue) {
    easingFunctions[name] = cssValue;
}

var index = {
    init,
    getCurrentTransform,
    stopAnimation,
    resetAnimation,
    restartAnimation,
    pauseAnimation,
    resumeAnimation,
    addEasingFunction,
    activeAnimations
};

export { activeAnimations, addEasingFunction, buildTransformString, camelCase, index as default, getCurrentTransform, init, parseIterations, pauseAnimation, resetAnimation, restartAnimation, resumeAnimation, stopAnimation, updateGroupIteration };
