"""MkDocs hooks for copying example files to the site."""

import shutil
import os
import time

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
        # Copy js directory (elm-animate-waapi.js companion file)
        if os.path.exists(dest_js_dir):
            shutil.rmtree(dest_js_dir)
        shutil.copytree(js_dir, dest_js_dir)
    
    # Cache-bust: append ?v=TIMESTAMP to index.js and .css references in
    # copied HTML so browsers always fetch the latest build.
    # Source files stay unchanged.
    timestamp = int(time.time())
    for root, dirs, files in os.walk(dest_src_dir):
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

    print(f"Copied example files to {config['site_dir']}/examples/")
