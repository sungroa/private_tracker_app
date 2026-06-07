#!/usr/bin/env python3
"""
One-time script to generate debug-variant launcher icon assets.

Reads production icons from android/app/src/main/res/ and overlays a
bright orange "D" badge that is correctly positioned within the adaptive
icon safe zone (72dp guaranteed visible out of 108dp total).

Adaptive icon spec:
  - Total foreground canvas:  108dp × 108dp
  - Safe zone (always visible): centre 72dp × 72dp (66.7% of each axis)
  - Inscribed safe-zone radius: 36/108 × W/2 = W/3

Run from the repository root:
    python3 scripts/gen_debug_icons.py
"""

import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).parent.parent
MAIN_RES  = REPO_ROOT / "android/app/src/main/res"
DEBUG_RES = REPO_ROOT / "android/app/src/debug/res"

FONT_PATH = "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"

# Adaptive icon safe-zone: the centre 72dp out of 108dp total
# guarantees visibility regardless of the launcher's mask shape.
SAFE_ZONE_RATIO = 72.0 / 108.0  # ≈ 0.6667

BADGE_BG   = (255, 140, 0, 255)   # vivid orange fill
BADGE_FG   = (255, 255, 255, 255) # white 'D'
BADGE_RING = (255, 255, 255, 220) # white border for contrast


def add_debug_badge(src: Path, dst: Path, *, is_foreground: bool) -> None:
    """Composite an orange 'D' badge onto the bottom-right of src.

    For adaptive foreground layers the badge is constrained to the safe zone.
    For legacy mipmap icons it is constrained to the inscribed circle.
    """
    img = Image.open(src).convert("RGBA")
    W, H = img.size
    cx_img, cy_img = W / 2.0, H / 2.0

    if is_foreground:
        # Guaranteed-visible radius from the image centre.
        # safe_zone_r = (W/2) × (72/108) = W/3
        visible_r = (min(W, H) / 2.0) * SAFE_ZONE_RATIO
    else:
        # Legacy icons are masked by an inscribed circle (radius = W/2).
        # Use a slightly smaller radius so the badge doesn't kiss the edge.
        visible_r = min(W, H) / 2.0 * 0.90

    # Badge radius = 28% of the visible radius (large enough to read).
    badge_r = max(int(visible_r * 0.28), 4)

    # Badge centre: push toward bottom-right corner along the diagonal,
    # stopping just inside the safe boundary (visible_r − badge_r − 2px gap).
    reach = visible_r - badge_r - 2
    diag  = reach / math.sqrt(2)
    cx = cx_img + diag
    cy = cy_img + diag

    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    draw    = ImageDraw.Draw(overlay)

    # Outer white ring (contrast halo).
    ring_w = max(int(badge_r * 0.15), 1)
    draw.ellipse(
        [cx - badge_r, cy - badge_r, cx + badge_r, cy + badge_r],
        fill=BADGE_RING,
    )

    # Orange fill.
    inner_r = badge_r - ring_w
    draw.ellipse(
        [cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
        fill=BADGE_BG,
    )

    # 'D' centred inside the badge.
    font_size = max(int(inner_r * 1.4), 4)
    try:
        font = ImageFont.truetype(FONT_PATH, font_size)
    except IOError:
        font = ImageFont.load_default()

    label = "D"
    bbox  = draw.textbbox((0, 0), label, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    draw.text(
        (cx - tw / 2 - bbox[0], cy - th / 2 - bbox[1]),
        label,
        font=font,
        fill=BADGE_FG,
    )

    result = Image.alpha_composite(img, overlay)
    dst.parent.mkdir(parents=True, exist_ok=True)
    result.save(dst, format="PNG")

    safe_r_str = f"safe_r={visible_r:.0f}" if is_foreground else f"inscr_r={visible_r:.0f}"
    print(f"  {dst.relative_to(REPO_ROOT)}  [{W}×{H}, {safe_r_str}, badge_r={badge_r}]")


def process(rel_dir: str, filename: str, *, is_foreground: bool) -> None:
    src = MAIN_RES / rel_dir / filename
    dst = DEBUG_RES / rel_dir / filename
    if not src.exists():
        print(f"  [SKIP] {src.relative_to(REPO_ROOT)} not found")
        return
    add_debug_badge(src, dst, is_foreground=is_foreground)


def main() -> None:
    print("Generating debug launcher icon assets…\n")

    print("Adaptive foreground layers (must respect safe zone):")
    for dpi in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"):
        process(f"drawable-{dpi}", "ic_launcher_foreground.png", is_foreground=True)

    print("\nLegacy mipmap icons (inscribed-circle constraint):")
    for dpi in ("mdpi", "hdpi", "xhdpi", "xxhdpi", "xxxhdpi"):
        process(f"mipmap-{dpi}", "ic_launcher.png", is_foreground=False)

    print("\nDone. Commit the files under android/app/src/debug/res/")


if __name__ == "__main__":
    main()
