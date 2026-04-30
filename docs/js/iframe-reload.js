// Add reload buttons to all example iframes in the documentation.
// Defer loading of iframes in hidden tabs until the tab is shown,
// so onload animations play when the user actually sees them.

function initExampleIframes() {
    document.querySelectorAll("iframe[src*='/examples/']").forEach(function (iframe) {
        // Skip if already processed
        if (iframe.dataset.processed) return;
        iframe.dataset.processed = "true";

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
    });

    // Listen for tab switches to load deferred iframes
    document.querySelectorAll(".tabbed-set > input").forEach(function (input) {
        if (input.dataset.iframeListener) return;
        input.dataset.iframeListener = "true";
        input.addEventListener("change", onTabChange);
    });
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
