"""MkDocs hooks for copying example files to the site."""

import shutil
import os

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
    
    print(f"Copied example files to {config['site_dir']}/examples/")
