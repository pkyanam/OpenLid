#!/usr/bin/env python3
"""Generate OpenLid agent brand-icon assets from the trifecta Icons.tsx source.

Extracts SVG path data for each provider glyph and writes standalone .imageset
entries into OpenLid/Assets.xcassets. Run from the OpenLid repo root.
"""
import json
import os
import re
import shutil
import sys

ICONS_TSX = os.path.expanduser(
    "~/projects/trifecta/trifecta-desktop/apps/web/src/components/Icons.tsx"
)
DEVIN_PNG = os.path.expanduser(
    "~/projects/trifecta/trifecta-desktop/apps/web/public/DevinLogoSquare.png"
)
HERMES_JPG = os.path.expanduser(
    "~/projects/trifecta/trifecta-desktop/apps/web/public/hermes-logo.jpg"
)
ASSETS = "OpenLid/Assets.xcassets"


def first_path_d(src: str, component: str) -> str:
    start = src.index(f"export const {component}")
    m = re.search(r'd="([^"]+)"', src[start:])
    if not m:
        raise SystemExit(f"No path data found for {component}")
    return m.group(1)


def write_imageset(name: str, filename: str, contents: dict, file_bytes: bytes):
    d = os.path.join(ASSETS, f"{name}.imageset")
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, filename), "wb") as f:
        f.write(file_bytes)
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump(contents, f, indent=2)


def svg_contents(filename: str, template: bool) -> dict:
    return {
        "images": [{"filename": filename, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {
            "preserves-vector-representation": True,
            "template-rendering-intent": "template" if template else "original",
        },
    }


def png_contents(filename: str) -> dict:
    return {
        "images": [{"filename": filename, "idiom": "universal"}],
        "info": {"author": "xcode", "version": 1},
        "properties": {"template-rendering-intent": "original"},
    }


def svg(view_box: str, fill: str, d: str) -> bytes:
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{view_box}">'
        f'<path fill="{fill}" d="{d}"/></svg>'
    ).encode()


def main():
    if not os.path.isdir(ASSETS):
        raise SystemExit("Run from the OpenLid repo root (Assets.xcassets not found).")
    src = open(ICONS_TSX).read()

    # Single-path vector glyphs. Template glyphs tint to the label color.
    glyphs = [
        # name,            component,    viewBox,             fill,       template
        ("agent.claude",   "ClaudeAI",   "0 0 256 257",       "#d97757",  False),
        ("agent.openai",   "OpenAI",     "0 0 256 260",       "#000000",  True),
        ("agent.cursor",   "CursorIcon", "0 0 466.73 532.09", "#000000",  True),
    ]
    for name, component, vb, fill, template in glyphs:
        d = first_path_d(src, component)
        write_imageset(name, "icon.svg", svg_contents("icon.svg", template), svg(vb, fill, d))

    # OpenCode: a clean box outline with a filled lower block (template). The
    # original two-tone SVG flattens to a solid blob as a template, so we author a
    # single, unambiguous monochrome glyph instead.
    opencode = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 40">'
        '<path fill-rule="evenodd" fill="#000" d="M0 0H32V40H0Z M8 8H24V32H8Z"/>'
        '<path fill="#000" d="M8 16H24V32H8Z"/></svg>'
    ).encode()
    write_imageset("agent.opencode", "icon.svg", svg_contents("icon.svg", True), opencode)

    # Antigravity (replaces the deprecated Gemini CLI): real brand PNG decoded from
    # the embedded data URL in Icons.tsx (colored, original).
    m = re.search(r'ANTIGRAVITY_ICON_DATA_URL\s*=\s*"data:image/png;base64,([^"]+)"', src)
    if not m:
        raise SystemExit("Could not find ANTIGRAVITY_ICON_DATA_URL in Icons.tsx")
    import base64
    write_imageset("agent.antigravity", "icon.png", png_contents("icon.png"),
                   base64.b64decode(m.group(1)))

    # Custom user agents: a neutral monochrome "app" glyph (template).
    custom = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
        '<path fill="#000" d="M4 3h16a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1Zm2 4v2h12V7H6Zm0 4v2h12v-2H6Zm0 4v2h8v-2H6Z"/></svg>'
    ).encode()
    write_imageset("agent.custom", "icon.svg", svg_contents("icon.svg", True), custom)

    # Devin: real brand PNG (colored, original).
    write_imageset("agent.devin", "icon.png", png_contents("icon.png"), open(DEVIN_PNG, "rb").read())

    # Hermes (Nous Research): real brand JPG (colored, original).
    write_imageset("agent.hermes", "icon.jpg", png_contents("icon.jpg"), open(HERMES_JPG, "rb").read())

    print("Generated agent icons into", ASSETS)


if __name__ == "__main__":
    main()
