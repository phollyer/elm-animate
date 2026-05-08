/* eslint-env browser */
/* global document, CSS */

/**
 * Find the single DOM element with a matching data-anim-target attribute (or id).
 */
export function findAnimTarget(targetId) {
    return document.querySelector('[data-anim-target="' + CSS.escape(targetId) + '"]')
        || document.getElementById(targetId)
        || null;
}

/**
 * Find all DOM elements with a matching data-anim-target attribute (or id).
 */
export function findAllAnimTargets(targetId) {
    const byAttr = Array.from(document.querySelectorAll('[data-anim-target="' + CSS.escape(targetId) + '"]'));
    if (byAttr.length > 0) return byAttr;
    const byId = document.getElementById(targetId);
    return byId ? [byId] : [];
}
