/* eslint-env browser */
import { activeAnimations, animationGroups, elementTransformOrders, cleanupAnimGroup } from './state.js';
import { buildTransformString } from './transform.js';
import { sendLifecycleEvent } from './ports.js';
import { findAnimTarget } from './targets.js';
import { reportError } from './errors.js';
import { DEFAULT_TRANSFORM_ORDER } from './utils.js';

const DIRECT_TRANSFORM_KEYS = [
    'x', 'y', 'z',
    'scaleX', 'scaleY', 'scaleZ',
    'rotateX', 'rotateY', 'rotateZ',
    'skewX', 'skewY'
];

const DIRECT_STYLE_APPLIERS = {
    opacity(style, value) {
        style.opacity = String(value);
    }
};

function forEachAffectedAnimation(animGroup, properties, fn) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return { affected: 0, total: 0 };
    const filter = properties ? new Set(properties) : null;
    let affected = 0;
    elementAnims.forEach((animData, propertyType) => {
        if (!filter || filter.has(propertyType)) {
            fn(animData, propertyType);
            affected++;
        }
    });
    return { affected, total: elementAnims.size };
}

function hasDirectTransformUpdates(props) {
    return DIRECT_TRANSFORM_KEYS.some(key => props[key] !== undefined);
}

function clearTrackedAnimations(animGroup, element) {
    element.getAnimations().forEach(anim => {
        anim.cancel();
    });
    cleanupAnimGroup(animGroup);
}

function applyDirectTransformStyles(animGroup, element, props) {
    if (!hasDirectTransformUpdates(props)) {
        return;
    }

    const order = elementTransformOrders.get(animGroup) || DEFAULT_TRANSFORM_ORDER;
    const {
        x = 0,
        y = 0,
        z = 0,
        scaleX = 1,
        scaleY = 1,
        scaleZ = 1,
        rotateX = 0,
        rotateY = 0,
        rotateZ = 0,
        skewX = 0,
        skewY = 0
    } = props;

    element.style.transform = buildTransformString(
        x,
        y,
        z,
        scaleX,
        scaleY,
        scaleZ,
        rotateX,
        rotateY,
        rotateZ,
        skewX,
        skewY,
        order
    );
}

function applyDirectStyleUpdates(style, props) {
    Object.entries(DIRECT_STYLE_APPLIERS).forEach(([key, applyStyle]) => {
        if (props[key] !== undefined) {
            applyStyle(style, props[key]);
        }
    });

    if (props.width !== undefined && props.height !== undefined) {
        style.width = `${props.width}px`;
        style.height = `${props.height}px`;
    }
}

function applyDirectPropertyUpdate(update) {
    const animGroup = update.elementId;
    const element = findAnimTarget(animGroup);
    if (!element) {
        reportError(`Element with data-anim-target="${animGroup}" not found`, {
            source: 'animation',
            severity: 'warning',
            code: 'TARGET_NOT_FOUND',
            engine: 'WAAPI',
            elementId: animGroup
        });
        return;
    }

    clearTrackedAnimations(animGroup, element);

    const props = update.properties;
    applyDirectTransformStyles(animGroup, element, props);
    applyDirectStyleUpdates(element.style, props);
}

export function stopAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    const { affected, total } = forEachAffectedAnimation(animGroup, properties, animData => animData.animation.finish());
    if (!properties || affected === total) {
        cleanupAnimGroup(animGroup);
    }
    sendLifecycleEvent('stopped', animGroup);
}

export function resetAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    const { affected, total } = forEachAffectedAnimation(animGroup, properties, animData => animData.animation.cancel());
    if (!properties || affected === total) {
        cleanupAnimGroup(animGroup);
    }
    sendLifecycleEvent('reset', animGroup);
}

export function restartAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => {
        animData.animation.cancel();
        animData.animation.play();
    });

    const groupTracking = animationGroups.get(animGroup);
    if (groupTracking) {
        groupTracking.completedProperties = 0;
        groupTracking.started = false;
    }
    sendLifecycleEvent('restarted', animGroup);
}

export function pauseAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => animData.animation.pause());
    sendLifecycleEvent('paused', animGroup);
}

export function resumeAnimation(animGroup, properties) {
    const elementAnims = activeAnimations.get(animGroup);
    if (!elementAnims) return;
    forEachAffectedAnimation(animGroup, properties, animData => {
        animData.animation.play();
        if (animData.updateFn) {
            animData.updateFn();
        }
    });
    sendLifecycleEvent('resumed', animGroup);
}

export function setProperties(updates) {
    updates.forEach(applyDirectPropertyUpdate);
}
