/* global document, document$, window, localStorage, sessionStorage, requestAnimationFrame */
var navStateKey = "elmAnimateNavOpenSections";
var navScrollKey = "elmAnimateNavScrollTop";
var lastNavPersistenceInitKey = null;

function getSavedNavState() {
    try {
        var raw = localStorage.getItem(navStateKey);
        return raw ? JSON.parse(raw) : {};
    } catch (e) {
        return {};
    }
}

function saveNavState() {
    var state = {};
    document.querySelectorAll("input.md-nav__toggle[id^='__nav_']").forEach(function (toggle) {
        if (toggle.checked) {
            state[toggle.id] = true;
        }
    });

    try {
        localStorage.setItem(navStateKey, JSON.stringify(state));
    } catch (e) {
        // Ignore storage errors and keep default navigation behaviour.
    }

    // Save sidebar scroll position so it can be restored after page navigation.
    var sidebar = document.querySelector(".md-sidebar--primary .md-sidebar__scrollwrap");
    if (sidebar) {
        try {
            sessionStorage.setItem(navScrollKey, sidebar.scrollTop);
        } catch (e) {
            // Ignore storage errors.
        }
    }
}

function restoreNavState() {
    var state = getSavedNavState();
    if (!Object.keys(state).length) return;

    // Suppress CSS transitions on the nav while restoring open sections so
    // they appear open instantly rather than animating in.
    var nav = document.querySelector(".md-nav--primary");
    if (nav) nav.classList.add("md-nav--instant-restore");

    // Re-open sections that were open on the previous page.
    Object.keys(state).forEach(function (id) {
        var toggle = document.getElementById(id);
        if (toggle && toggle.matches("input.md-nav__toggle") && !toggle.checked) {
            toggle.checked = true;
        }
    });

    // Remove suppression class after two animation frames so the browser has
    // painted the open state before transitions are re-enabled.
    requestAnimationFrame(function () {
        requestAnimationFrame(function () {
            if (nav) nav.classList.remove("md-nav--instant-restore");

            // Restore sidebar scroll position after Material has run its own
            // scrollIntoView on the active item, so the sidebar stays put.
            var sidebar = document.querySelector(".md-sidebar--primary .md-sidebar__scrollwrap");
            if (sidebar) {
                try {
                    var saved = sessionStorage.getItem(navScrollKey);
                    if (saved !== null) {
                        sidebar.scrollTop = parseInt(saved, 10);
                    }
                } catch (e) {
                    // Ignore storage errors.
                }
            }
        });
    });
}

function bindNavLinkPersistence() {
    // Save the current open sections only when the user navigates to another page.
    // This keeps default section toggle behaviour untouched.
    document.querySelectorAll(".md-nav a[href]").forEach(function (link) {
        if (link.dataset.navStateLinkListener) return;
        link.dataset.navStateLinkListener = "true";
        link.addEventListener("click", saveNavState);
    });
}

function initNavSectionPersistence() {
    var initKey = window.location.pathname + window.location.search;

    // Material can emit multiple lifecycle events for the same page.
    // Skip duplicate init so we don't re-touch existing open sections.
    if (lastNavPersistenceInitKey === initKey) {
        return;
    }

    restoreNavState();
    bindNavLinkPersistence();
    lastNavPersistenceInitKey = initKey;
}

// Manual reset helper for local testing in the browser console.
window.resetElmAnimateNavState = function () {
    try {
        localStorage.removeItem(navStateKey);
    } catch (e) {
        // Ignore storage errors.
    }
};

// Run on initial load
document.addEventListener("DOMContentLoaded", initNavSectionPersistence);

if (typeof document$ !== "undefined") {
    // Re-run on MkDocs Material instant navigation.
    document$.subscribe(initNavSectionPersistence);
}