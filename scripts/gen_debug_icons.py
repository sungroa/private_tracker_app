#!/usr/bin/env python3
"""
One-time script to generate debug-variant launcher icon assets.

Reads production icons from android/app/src/main/res/ and overlays a
bright orange "DEBUG" ribbon badge in the bottom-left corner.
Output files are written to android/app/src/debug/res/ for Gradle to pick
up automatically when building the debug variant.

Run from the repository root:
    python3 scripts/gen_debug_icons.py
"""

import os
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).parent.parent
MAIN_RES  = REPO_ROOT / "android/app/src/main/res"
DEBUG_RES = REPO_ROOT / "android/app/src/debug/res"

FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# Badge colour: vivid orange — unmistakable against the dark app icon
BADGE_BG    = (255, 140, 0, 255)   # orange
BADGE_FG    = (255, 255, 255, 255) # white text
BADGE_RING  = (255, 255, 255, 200) # semi-white border

def add_debug_badge(src: Path, dst: Path) -> None:
    """Composite a circular 'D' badge onto the bottom-right corner of src."""
    img = Image.open(src).convert("RGBA")
    W, H = img.size

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    # Badge sits at ~75% from centre (safe zone edge) toward bottom-right
    r = max(int(W * 0.13), 8)          # badge radius = 13% of image width
    margin = int(W * 0.05)             # padding from edge
    cx = W - margin - r
    cy = H - margin - r

    # Outer white ring for contrast against any background
    ring_w = max(int(r * 0.12), 2)
    draw.ellipse([cx - r, cy - r, cx + r, cy + r],
                 fill=BADGE_RING)

    # Inner orange circle
    inner_r = r - ring_w
    draw.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
                 fill=BADGE_BG)

    # 'D' label centred in badge
    font_size = max(int(inner_r * 1.3), 6)
    try:
        font = ImageFont.truetype(FONT_PATH, font_size)
    except IOError:
        font = ImageFont.load_default()

    label = "D"
    bbox = draw.textbbox((0, 0), label, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = cx - tw / 2 - bbox[0]
    ty = cy - th / 2 - bbox[1]
    draw.text((tx, ty), label, font=font, fill=BADGE_FG)

    # Composite badge over original image
    result = Image.alpha_composite(img, overlay)
    dst.parent.mkdir(parents=True, exist_ok=True)
    result.save(dst, format="PNG")
    print(f"  wrote {dst.relative_to(REPO_ROOT)}")


def process_directory(rel_dir: str, filename: str) -> None:
    src = MAIN_RES / rel_dir / filename
    dst = DEBUG_RES / rel_dir / filename
    if not src.exists():
        print(f"  [SKIP] {src.relative_to(REPO_ROOT)} not found")
        return
    add_debug_badge(src, dst)


def main() -> None:
    print("Generating debug launcher icon assets…\n")

    # Adaptive foreground layers (drawable-*)
    for dpi in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"):
        process_directory(f"drawable-{dpi}", "ic_launcher_foreground.png")

    # Legacy launcher icons (mipmap-*)
    for dpi in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"):
        process_directory(f"mipmap-{dpi}", "ic_launcher.png")

    print("\nDone. Commit the files under android/app/src/debug/res/")


if __name__ == "__main__":
    main()
