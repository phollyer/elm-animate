#!/usr/bin/env python3
"""One-shot conversion script for the responsive-examples rollout.

Run from the repository root. Idempotent: safe to run multiple times.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
EXAMPLES = ROOT / "docs" / "examples" / "src"
DOCS_ANIMATION = ROOT / "docs" / "animation"
DOCS_SCROLL = ROOT / "docs" / "scroll"


# ---------------------------------------------------------------------------
# 1) index.html: add responsive.css link if missing.
# ---------------------------------------------------------------------------

CSS_LINK_PATTERN = re.compile(
    r'(<link rel="stylesheet" href="((?:\.\./)+)css/base\.css">)'
)


def patch_index_html(path: Path) -> bool:
    text = path.read_text()
    if "responsive.css" in text:
        return False
    new_text, n = CSS_LINK_PATTERN.subn(
        r'\1\n    <link rel="stylesheet" href="\2css/responsive.css">',
        text,
        count=1,
    )
    if n == 0:
        print(f"  WARN no base.css link in {path.relative_to(ROOT)}")
        return False
    path.write_text(new_text)
    return True


# ---------------------------------------------------------------------------
# 2) Markdown iframes: convert inline style="…" to class="example-iframe …".
# ---------------------------------------------------------------------------

# Anything with height <= 270 -> sm; <= 380 -> md; otherwise lg.
IFRAME_RE = re.compile(
    r'<iframe\s+src="([^"]+/examples/src/[^"]+)"\s+'
    r'style="width:\s*100%;\s*height:\s*(\d+)px;[^"]*"\s*loading="lazy">'
    r"</iframe>"
)


def iframe_class_for(height_px: int) -> str:
    if height_px <= 270:
        return "example-iframe example-iframe--sm"
    if height_px <= 400:
        return "example-iframe example-iframe--md"
    return "example-iframe example-iframe--lg"


def patch_markdown(path: Path) -> int:
    text = path.read_text()

    def repl(m: re.Match[str]) -> str:
        src = m.group(1)
        height = int(m.group(2))
        klass = iframe_class_for(height)
        return f'<iframe src="{src}" class="{klass}" loading="lazy"></iframe>'

    new_text, n = IFRAME_RE.subn(repl, text)
    if n:
        path.write_text(new_text)
    return n


# ---------------------------------------------------------------------------
# 3) Main.elm: layout transforms.
# ---------------------------------------------------------------------------

# Outer view container — the canonical "box demo" wrapper.
OUTER_BOX_DEMO = re.compile(
    r"""    div
        \[ style "text-align" "center"
        , style "height" "90vh"
        , style "width" "100%"
        , style "padding-top" "10px"
        \]"""
)

OUTER_BOX_DEMO_REPLACEMENT = '''    div
        [ class "example-stage"
        , style "text-align" "center"
        ]'''

# Inner flex wrapper found in the box demos — collapses 80vh constraint.
INNER_FLEX_WRAPPER = re.compile(
    r"""        , div
            \[ style "height" "80vh"
            , style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            \]"""
)

INNER_FLEX_WRAPPER_REPLACEMENT = '''        , div
            [ style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]'''

# 200x200 decorative box -> .example-box class. Two orderings appear in the
# corpus (height first or width first).
BOX_200_HEIGHT_FIRST = re.compile(
    r"""                    \+\+ \[ style "height" "200px"
                       , style "width" "200px"
"""
)
BOX_200_WIDTH_FIRST = re.compile(
    r"""                    \+\+ \[ style "width" "200px"
                       , style "height" "200px"
"""
)
BOX_200_REPLACEMENT = '''                    ++ [ class "example-box"
'''

# DiscreteProperties has its 220px parent flex wrapper inline.
DISCRETE_PARENT = re.compile(
    r"""        , div
            \[ style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "height" "220px"
            \]"""
)
DISCRETE_PARENT_REPLACEMENT = '''        , div
            [ style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "min-height" "220px"
            ]'''

# Some inner box variant uses width-first with extra spacing
DISCRETE_BOX_WIDTH_FIRST = re.compile(
    r"""                    \+\+ \[ style "width" "200px"
                       , style "height" "200px"
"""
)

# HelloText pattern: 100vh / 100vw -> stage class.
HELLO_OUTER = re.compile(
    r"""    div
        \[ style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "font-size" "48px"
        , style "font-weight" "bold"
        , style "height" "100vh"
        , style "width" "100vw"
        \]"""
)
HELLO_OUTER_REPLACEMENT = '''    div
        [ class "example-stage"
        , style "font-size" "48px"
        , style "font-weight" "bold"
        ]'''

# ControllingAnimations / TransformOrder canvas: 350px box -> .example-canvas.
CANVAS_350 = re.compile(
    r"""    div
        \[ style "width" "100%"
        , style "max-width" "500px"
        , style "height" "350px"
        , style "background" "white"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba\(0, 0, 0, 0\.1\)"
        \]"""
)
CANVAS_350_REPLACEMENT = '''    div
        [ class "example-canvas"
        , style "background" "white"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        ]'''


# FadeInOut-family variant: outer wrapper has extra align rules.
FADEINOUT_OUTER = re.compile(
    r"""    div
        \[ style "text-align" "center"
        , style "height" "90vh"
        , style "width" "100%"
        , style "align" "center"
        , style "align-items" "center"
        , style "justify-content" "center"
        , style "padding-top" "10px"
        \]"""
)
FADEINOUT_OUTER_REPLACEMENT = '''    div
        [ class "example-stage"
        , style "text-align" "center"
        ]'''

FADEINOUT_INNER_FLEX = re.compile(
    r"""        , div
            \[ style "height" "80vh"
            , style "width" "100%"
            , style "display" "flex"
            , style "align" "center"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            \]"""
)
FADEINOUT_INNER_FLEX_REPLACEMENT = '''        , div
            [ style "width" "100%"
            , style "display" "flex"
            , style "align-items" "center"
            , style "justify-content" "center"
            , style "padding-top" "10px"
            ]'''

# FadeInOut box: 80vh/80vw red square -> .example-square (drops vh/vw).
FADEINOUT_BOX = re.compile(
    r"""                    \+\+ \[ style "height" "80vh"
                       , style "width" "80vw"
                       , style "margin" "0 auto"
"""
)
FADEINOUT_BOX_REPLACEMENT = '''                    ++ [ class "example-square"
'''

# TransformOrder canvas: 350px playing field with extra position/overflow.
TRANSFORM_CANVAS = re.compile(
    r"""    div
        \[ style "position" "relative"
        , style "width" "100%"
        , style "max-width" "500px"
        , style "height" "350px"
        , style "background-color" "#ffffff"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba\(0, 0, 0, 0\.1\)"
        , style "overflow" "hidden"
        \]"""
)
TRANSFORM_CANVAS_REPLACEMENT = '''    div
        [ class "example-canvas"
        , style "position" "relative"
        , style "background-color" "#ffffff"
        , style "border-radius" "12px"
        , style "box-shadow" "0 4px 8px rgba(0, 0, 0, 0.1)"
        , style "overflow" "hidden"
        ]'''


# Patterns to apply, in order. Each is (regex, replacement) tuples.
MAIN_ELM_TRANSFORMS = [
    (OUTER_BOX_DEMO, OUTER_BOX_DEMO_REPLACEMENT),
    (FADEINOUT_OUTER, FADEINOUT_OUTER_REPLACEMENT),
    (INNER_FLEX_WRAPPER, INNER_FLEX_WRAPPER_REPLACEMENT),
    (FADEINOUT_INNER_FLEX, FADEINOUT_INNER_FLEX_REPLACEMENT),
    (DISCRETE_PARENT, DISCRETE_PARENT_REPLACEMENT),
    (BOX_200_HEIGHT_FIRST, BOX_200_REPLACEMENT),
    (BOX_200_WIDTH_FIRST, BOX_200_REPLACEMENT),
    (FADEINOUT_BOX, FADEINOUT_BOX_REPLACEMENT),
    (HELLO_OUTER, HELLO_OUTER_REPLACEMENT),
    (CANVAS_350, CANVAS_350_REPLACEMENT),
    (TRANSFORM_CANVAS, TRANSFORM_CANVAS_REPLACEMENT),
]

CLASS_IMPORT_RE = re.compile(
    r"^import Html\.Attributes exposing \(([^)]*)\)$", re.MULTILINE
)


def ensure_class_import(text: str) -> str:
    """Make sure `class` is in Html.Attributes' exposing list when used."""
    if "class " not in text and 'class "example' not in text:
        return text
    m = CLASS_IMPORT_RE.search(text)
    if not m:
        return text
    exposed = [s.strip() for s in m.group(1).split(",")]
    if "class" in exposed:
        return text
    exposed.append("class")
    exposed = sorted(set(exposed))
    new_line = f"import Html.Attributes exposing ({', '.join(exposed)})"
    return text[: m.start()] + new_line + text[m.end() :]


def patch_main_elm(path: Path) -> int:
    text = path.read_text()
    original = text
    n_total = 0
    for pattern, replacement in MAIN_ELM_TRANSFORMS:
        new_text, n = pattern.subn(replacement, text)
        text = new_text
        n_total += n
    if n_total == 0 and original == text:
        return 0
    text = ensure_class_import(text)
    if text != original:
        path.write_text(text)
    return n_total


# ---------------------------------------------------------------------------
# Driver
# ---------------------------------------------------------------------------


def main() -> int:
    print("== Patching index.html files ==")
    n_html = 0
    for p in sorted(EXAMPLES.rglob("index.html")):
        if patch_index_html(p):
            n_html += 1
            print(f"  + {p.relative_to(ROOT)}")
    print(f"  ({n_html} updated)")

    print("== Patching markdown iframe embeds ==")
    n_md_files = 0
    n_md_iframes = 0
    for root in (DOCS_ANIMATION, DOCS_SCROLL):
        for p in sorted(root.rglob("*.md")):
            n = patch_markdown(p)
            if n:
                n_md_files += 1
                n_md_iframes += n
                print(f"  + {p.relative_to(ROOT)} ({n})")
    print(f"  ({n_md_iframes} iframes across {n_md_files} files)")

    print("== Patching Main.elm files ==")
    n_main = 0
    for p in sorted(EXAMPLES.rglob("Main.elm")):
        n = patch_main_elm(p)
        if n:
            n_main += 1
            print(f"  + {p.relative_to(ROOT)} ({n} hits)")
    print(f"  ({n_main} files updated)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
