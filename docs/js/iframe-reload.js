/* global document, document$, window, setTimeout, URL */
// Add reload buttons to all example iframes in the documentation.
// Defer loading of iframes in hidden tabs until the tab is shown,
// so onload animations play when the user actually sees them.

function initExampleIframes() {
    document.querySelectorAll("iframe[src*='/examples/']").forEach(function (iframe) {
        // Skip if already processed
        if (iframe.dataset.processed) return;
        iframe.dataset.processed = "true";

        // Normalize relative example paths so embeds resolve correctly on
        // GitHub Pages regardless of current docs page depth.
        var originalSrc = iframe.getAttribute("src") || "";
        var normalized = normalizeExampleSrc(originalSrc);
        if (normalized !== originalSrc) {
            iframe.setAttribute("src", normalized);
        }

        // Store the original URL so tab-switch reload can find every iframe
        var tabContent = iframe.closest(".tabbed-block");
        if (tabContent) {
            iframe.dataset.src = iframe.src;
            // Defer hidden iframes: remove src so they load on first visit
            if (!isTabVisible(tabContent)) {
                iframe.removeAttribute("src");
            }
        }

        // Wrap in container with reload button
        var container = document.createElement("div");
        container.className = "iframe-container";

        var btn = document.createElement("button");
        btn.className = "iframe-reload-btn";
        btn.title = "Reload example";
        btn.setAttribute("aria-label", "Reload example");
        btn.innerHTML = "&#x21bb;";
        btn.addEventListener("click", function () {
            if (iframe.src && iframe.contentWindow) {
                iframe.contentWindow.location.reload();
            } else if (iframe.dataset.src) {
                iframe.src = iframe.dataset.src;
            }
        });

        iframe.parentNode.insertBefore(container, iframe);
        container.appendChild(iframe);
        container.appendChild(btn);

        attachAutoResize(iframe);
    });

    // Listen for tab switches to load deferred iframes
    document.querySelectorAll(".tabbed-set > input").forEach(function (input) {
        if (input.dataset.iframeListener) return;
        input.dataset.iframeListener = "true";
        input.addEventListener("change", onTabChange);
    });
}

// Size the iframe to its actual content height so it never has scrollbars
// and never wastes space on wide viewports. Same-origin only; silently
// no-ops if the browser blocks access (the CSS clamp() height stays in
// effect as a safe fallback).
function attachAutoResize(iframe) {
    if (iframe.dataset.autoresize) return;
    iframe.dataset.autoresize = "true";

    var lastApplied = 0;
    var pending = false;

    function measureAndResize() {
        if (pending) return;
        pending = true;
        window.requestAnimationFrame(function () {
            pending = false;
            try {
                var doc = iframe.contentDocument;
                if (!doc || !doc.body) return;
                // Use body.scrollHeight only — documentElement.scrollHeight
                // would always at least equal the iframe viewport height
                // (html stretches to fill by default), preventing shrink.
                var contentHeight = doc.body.scrollHeight;
                if (contentHeight < 1) return;
                if (Math.abs(contentHeight - lastApplied) < 2) return;
                lastApplied = contentHeight;
                iframe.style.height = contentHeight + "px";
            } catch (_) {
                // Cross-origin or detached document; nothing to do.
            }
        });
    }

    function observeContent() {
        try {
            var win = iframe.contentWindow;
            var doc = iframe.contentDocument;
            if (!win || !doc || !doc.body) return;
            // Mark the embedded body so the example CSS can drop the
            // `min-height: 100dvh` floor it uses for standalone viewing.
            doc.body.classList.add("in-iframe");
            measureAndResize();
            if (typeof win.ResizeObserver === "function") {
                var ro = new win.ResizeObserver(measureAndResize);
                ro.observe(doc.body);
            }
            win.addEventListener("resize", measureAndResize);
        } catch (_) {
            // Cross-origin; bail out.
        }
    }

    iframe.addEventListener("load", observeContent);
    if (iframe.contentDocument && iframe.contentDocument.readyState === "complete") {
        observeContent();
    }
    // Re-measure when the parent viewport changes (the embedded page may
    // re-flow at the new width).
    window.addEventListener("resize", measureAndResize);
}

function normalizeExampleSrc(src) {
    if (!src || src.indexOf("examples/src/") === -1) {
        return src;
    }

    var parts = window.location.pathname.split("/").filter(Boolean);
    var repoBase = parts.length > 0 ? "/" + parts[0] : "";

    // Fix absolute GitHub Pages URLs that accidentally dropped the repo base,
    // e.g. https://user.github.io/examples/... -> /repo/examples/...
    if (/^https?:\/\//.test(src)) {
        if (window.location.hostname.endsWith("github.io") && repoBase) {
            try {
                var url = new URL(src);
                if (url.hostname === window.location.hostname && url.pathname.startsWith("/examples/")) {
                    return window.location.origin + repoBase + url.pathname;
                }
            } catch (_) {
                // Fall through to return original src.
            }
        }
        return src;
    }

    var normalizedPath = src.replace(/^(\.\.\/)+/, "");
    if (normalizedPath.charAt(0) === "/") {
        return normalizedPath;
    }

    if (window.location.hostname.endsWith("github.io")) {
        return repoBase + "/" + normalizedPath;
    }

    return "/" + normalizedPath;
}

function isTabVisible(tabBlock) {
    // A tabbed-block is visible when its corresponding radio input is checked.
    // The tabbed-block elements are siblings following the tabbed-labels,
    // and their visibility is controlled via CSS :checked.
    // Simplest check: is the element currently visible?
    return tabBlock.offsetParent !== null || tabBlock.offsetHeight > 0;
}

function onTabChange() {
    // Small delay to let the CSS transition show the new tab content
    setTimeout(function () {
        document.querySelectorAll("iframe[data-src]").forEach(function (iframe) {
            var tabContent = iframe.closest(".tabbed-block");
            if (tabContent && isTabVisible(tabContent)) {
                iframe.src = iframe.dataset.src;
            }
        });
    }, 50);
}

function initDocsUiEnhancements() {
    initExampleIframes();
}

// Run on initial load
document.addEventListener("DOMContentLoaded", initDocsUiEnhancements);

// Re-run on MkDocs Material instant navigation
document.addEventListener("contentUpdated", initDocsUiEnhancements);

if (typeof document$ !== "undefined") {
    document$.subscribe(initDocsUiEnhancements);
}
