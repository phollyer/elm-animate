"""MkDocs hooks for copying example files to the site."""

import shutil
import os
import re
import time

# Match an iframe `src` attribute pointing into examples/src/, optionally
# prefixed by any number of `../` segments. Captures: 1=quote, 2=path tail.
_IFRAME_SRC_RE = re.compile(
    r'(<iframe\b[^>]*?\bsrc=)(["\'])((?:\.\./)+)(examples/src/[^"\']+)\2',
    re.IGNORECASE,
)


def _rewrite_iframe_srcs_in_html(site_dir):
    """Recompute iframe relative srcs against each generated HTML file.

    Snippet inclusion (`--8<--`) embeds iframe markup verbatim, so a snippet
    written for a 4-deep page (`../../../../examples/...`) becomes wrong when
    pulled into a 3-deep host page. To eliminate the runtime race in
    iframe-reload.js, we recompute the relative path from each output HTML
    file to the iframe's target inside `examples/src/`.
    """
    rewrites = 0
    for root, _dirs, files in os.walk(site_dir):
        for fname in files:
            if not fname.endswith('.html'):
                continue
            html_path = os.path.join(root, fname)
            try:
                with open(html_path, 'r', encoding='utf-8') as fh:
                    content = fh.read()
            except (OSError, UnicodeDecodeError):
                continue

            def _fix(match, _root=root):
                attr_prefix, quote, _dotdots, tail = match.groups()
                target = os.path.join(site_dir, 'examples', 'src',
                                      tail[len('examples/src/'):])
                rel = os.path.relpath(target, start=_root)
                # Use forward slashes for URLs even on Windows.
                rel = rel.replace(os.sep, '/')
                return f'{attr_prefix}{quote}{rel}{quote}'

            new_content, n = _IFRAME_SRC_RE.subn(_fix, content)
            if n and new_content != content:
                with open(html_path, 'w', encoding='utf-8') as fh:
                    fh.write(new_content)
                rewrites += n
    if rewrites:
        print(f"Rewrote {rewrites} iframe src(s) to correct relative paths")


def on_post_build(config, **kwargs):
    """Copy example source files (html, js) to the built site."""
    src_dir = os.path.join(config['docs_dir'], 'examples', 'src')
    css_dir = os.path.join(config['docs_dir'], 'examples', 'css')
    js_dir = os.path.join(config['docs_dir'], 'examples', 'js')
    dest_src_dir = os.path.join(config['site_dir'], 'examples', 'src')
    dest_css_dir = os.path.join(config['site_dir'], 'examples', 'css')
    dest_js_dir = os.path.join(config['site_dir'], 'examples', 'js')
    
    if os.path.exists(src_dir):
        # Copy src directory (html, js files)
        if os.path.exists(dest_src_dir):
            shutil.rmtree(dest_src_dir)
        shutil.copytree(src_dir, dest_src_dir, 
                       ignore=shutil.ignore_patterns('*.elm'))
    
    if os.path.exists(css_dir):
        # Copy css directory
        if os.path.exists(dest_css_dir):
            shutil.rmtree(dest_css_dir)
        shutil.copytree(css_dir, dest_css_dir)
    
    if os.path.exists(js_dir):
        # Copy js directory (elm-animate-waapi.js companion file).
        # Fail loudly if the dir is empty so a missing dist/ can't ship
        # broken WAAPI examples to gh-pages.
        if not os.listdir(js_dir):
            raise RuntimeError(
                f"{js_dir} is empty - run 'npm run build' before mkdocs build "
                "so dist/elm-motion.js is copied into docs/examples/js/."
            )
        if os.path.exists(dest_js_dir):
            shutil.rmtree(dest_js_dir)
        shutil.copytree(js_dir, dest_js_dir)
    
    # Cache-bust: append ?v=TIMESTAMP to index.js and .css references in
    # copied HTML so browsers always fetch the latest build.
    # Source files stay unchanged.
    timestamp = int(time.time())
    for root, _dirs, files in os.walk(dest_src_dir):
        for f in files:
            if f.endswith('.html'):
                filepath = os.path.join(root, f)
                with open(filepath, 'r') as fh:
                    content = fh.read()
                updated = content.replace('src="index.js"',
                                          f'src="index.js?v={timestamp}"')
                updated = updated.replace('.css"',
                                          f'.css?v={timestamp}"')
                if updated != content:
                    with open(filepath, 'w') as fh:
                        fh.write(updated)

    # Rewrite iframe srcs in generated docs HTML so snippet-included iframes
    # use the correct relative depth for the host page (eliminates the
    # iframe-reload.js startup race).
    _rewrite_iframe_srcs_in_html(config['site_dir'])

    print(f"Copied example files to {config['site_dir']}/examples/")
