/* eslint-env browser */
/* global window, document, console, CSS, ScrollTimeline, ViewTimeline */
import { parseIterations, updateGroupIteration, easingFunctions } from './utils.js';
import { scrollDrivenIterationCounts, elementTransformOrders } from './state.js';
import { getTransformState, buildTransformString } from './transform.js';
import { resolveNonTransformValues, buildPropertyKeyframes, resolveScrollDrivenTransformValues } from './properties.js';
import { sendScrollLifecycleEvent } from './ports.js';
import { findAnimTarget } from './animations.js';

// Shared load guard so multiple timeline commands do not trigger duplicate loads.
let timelinePolyfillLoadPromise = null;

/**
 * Returns true if the named timeline API is available in the current window.
 */
function hasTimelineApi(apiName) {
    return typeof window !== 'undefined' && typeof window[apiName] !== 'undefined';
}

/**
 * Lazy-load the scroll-timeline polyfill script the first time it is needed.
 * Subsequent calls return the same Promise.
 */
function loadTimelinePolyfill() {
    if (timelinePolyfillLoadPromise) {
        return timelinePolyfillLoadPromise;
    }

    timelinePolyfillLoadPromise = new Promise((resolve, reject) => {
        if (typeof document === 'undefined') {
            reject(new Error('No document available to load timeline polyfill script'));
            return;
        }

        const existing = document.querySelector('script[data-elm-motion-timeline-polyfill="true"]');
        if (existing) {
            existing.addEventListener('load', () => resolve(), { once: true });
            existing.addEventListener('error', () => reject(new Error('Failed to load existing timeline polyfill script')), { once: true });
            return;
        }

        const script = document.createElement('script');
        script.src = 'https://unpkg.com/scroll-timeline-polyfill/dist/scroll-timeline.js';
        script.async = true;
        script.setAttribute('data-elm-motion-timeline-polyfill', 'true');
        script.onload = () => resolve();
        script.onerror = () => reject(new Error('Failed to load scroll-timeline polyfill'));
        document.head.appendChild(script);
    });

    return timelinePolyfillLoadPromise;
}

/**
 * Ensure a timeline API is available, loading the polyfill if necessary.
 * Returns true if the API is available after this call, false otherwise.
 */
export async function ensureTimelineApi(apiName) {
    if (hasTimelineApi(apiName)) {
        return true;
    }

    try {
        await loadTimelinePolyfill();
    } catch (error) {
        console.warn('ElmMotion: Unable to load timeline polyfill:', error);
        return false;
    }

    if (!hasTimelineApi(apiName)) {
        console.warn('ElmMotion: Timeline polyfill loaded but ' + apiName + ' is still unavailable');
        return false;
    }

    return true;
}

/**
 * Read the current progress (0.0–1.0) of a scroll-driven Animation object.
 * Unlike time-based animations, currentTime is a CSSUnitValue, not a number.
 * getComputedTiming().progress is always a plain number in [0, 1] or null.
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
 * Attach finish, cancel, and iteration listeners to a group of scroll-driven animations.
 * Emits port events to Elm matching the 'animationUpdate' format used by the WAAPI engine.
 */
function attachScrollDrivenListeners(animGroup, animations, engine, element, discreteExit) {
    const total = animations.length;
    let finishedCount = 0;
    let cancelFired = false;

    // Initialise group iteration counter (reset on each animate call).
    scrollDrivenIterationCounts.set(animGroup, 0);

    // Per-animation iteration counts used to deduplicate the group event:
    // a group with N properties fires N native 'iteration' events per loop.
    const perAnimIterations = new Array(total).fill(0);

    animations.forEach(function (animation, i) {
        animation.addEventListener('finish', function () {
            finishedCount++;
            if (finishedCount === total) {
                if (element && discreteExit) {
                    Object.entries(discreteExit).forEach(function ([prop, values]) {
                        element.style[prop] = values.to;
                    });
                }
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
 * Apply a scroll/view-driven animation to a single element using the given timeline.
 * Builds start/end keyframes from each property config and calls element.animate().
 */
function applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, engine, discreteEntry, discreteExit) {
    // Apply discrete entry styles immediately so the element is in the correct
    // state when the animation begins.
    if (discreteEntry) {
        Object.entries(discreteEntry).forEach(function ([prop, value]) {
            element.style[prop] = value;
        });
    }
    const baseTimingOptions = Object.assign(
        { timeline: timeline, fill: 'both' },
        rangeOptions || {},
        playbackOptions ? { iterations: playbackOptions.iterations, direction: playbackOptions.direction } : {}
    );
    const properties = elementConfig.properties || [];

    const transformProperties = properties.filter(p =>
        p.type === 'translate' || p.type === 'scale' || p.type === 'rotate' || p.type === 'skew'
    );
    const nonTransformProperties = properties.filter(p =>
        p.type !== 'translate' && p.type !== 'scale' && p.type !== 'rotate' && p.type !== 'skew'
    );

    const animations = [];

    nonTransformProperties.forEach(function (property) {
        const resolved = resolveNonTransformValues(animGroup, element, property);
        if (!resolved) return;

        const { keyframes, animationEasing } = buildPropertyKeyframes(resolved, property.easingKeyframes, property.easing);
        if (!keyframes) return;

        const propertyTimingOptions = Object.assign({}, baseTimingOptions, { easing: animationEasing });
        animations.push(element.animate(keyframes, propertyTimingOptions));
    });

    if (transformProperties.length > 0) {
        const currentTransform = getTransformState(animGroup, element);
        const order = (elementConfig.transformOrder && elementConfig.transformOrder.length > 0)
            ? elementConfig.transformOrder
            : (elementTransformOrders.get(animGroup) || ['translate', 'rotate', 'skew', 'scale']);

        const { start: sv, end: ev } = resolveScrollDrivenTransformValues(transformProperties, currentTransform);

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
                transformTimingOptions.easing = easingFunctions[firstTransform.easing] || firstTransform.easing;
            }
        }

        animations.push(element.animate(transformKeyframes, transformTimingOptions));
    }

    if (animations.length > 0 && engine) {
        attachScrollDrivenListeners(animGroup, animations, engine, element, discreteExit || {});
    }
}

/**
 * Process a scroll-driven animation using ScrollTimeline.
 */
export function processScrollDrivenData(commandData) {
    if (!commandData || !commandData.elements) {
        console.warn('ElmMotion: Invalid scrollDriven data');
        return;
    }

    if (typeof ScrollTimeline === 'undefined') {
        console.warn('ElmMotion: ScrollTimeline is not supported in this browser');
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
        console.warn('ElmMotion: Scroll source element "' + sourceId + '" not found');
        return;
    }

    const timeline = new ScrollTimeline({ source: sourceElement, axis: axis });
    const playbackOptions = {
        iterations: parseIterations(commandData.iterations),
        direction: commandData.direction || 'normal'
    };
    const discreteEntry = commandData.discreteEntry || {};
    const discreteExit = commandData.discreteExit || {};

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const targetId = elementConfig.target || animGroup;
        const element = findAnimTarget(targetId);
        if (!element) {
            console.warn('ElmMotion: Element target "' + targetId + '" not found for scroll-driven animation (animGroup: "' + animGroup + '")');
            return;
        }
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, null, playbackOptions, 'scrollTimeline', discreteEntry, discreteExit);
    });
}

/**
 * Process a view-driven animation using ViewTimeline.
 */
export function processViewDrivenData(commandData) {
    if (!commandData || !commandData.elements) {
        console.warn('ElmMotion: Invalid viewDriven data');
        return;
    }

    if (typeof ViewTimeline === 'undefined') {
        console.warn('ElmMotion: ViewTimeline is not supported in this browser');
        return;
    }

    const timelineConfig = commandData.timeline || {};
    const axis = timelineConfig.axis || 'block';

    Object.entries(commandData.elements).forEach(function ([animGroup, elementConfig]) {
        const targetId = elementConfig.target || animGroup;
        const element = findAnimTarget(targetId);
        if (!element) {
            console.warn('ElmMotion: Element target "' + targetId + '" not found for view-driven animation (animGroup: "' + animGroup + '")');
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
        const discreteEntry = commandData.discreteEntry || {};
        const discreteExit = commandData.discreteExit || {};
        applyScrollDrivenAnimation(animGroup, element, elementConfig, timeline, rangeOptions, playbackOptions, 'viewTimeline', discreteEntry, discreteExit);
    });
}
