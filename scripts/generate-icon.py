#!/usr/bin/env python3
"""Generate mdview's macOS .icns asset from a high-resolution Pillow drawing."""

from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
ICONSET = ROOT / ".build" / "AppIcon.iconset"
OUTPUT = ROOT / "Sources" / "MDView" / "Resources" / "AppIcon.icns"
SIZE = 1024


def font(size: int) -> ImageFont.FreeTypeFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Bold.ttf",
        "/System/Library/Fonts/Supplemental/Helvetica Neue Bold.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def rounded_mask(size: int, radius: int) -> Image.Image:
    mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size, size), radius=radius, fill=255)
    return mask


def draw_icon() -> Image.Image:
    image = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    background = Image.new("RGBA", (SIZE, SIZE))
    pixels = background.load()
    for y in range(SIZE):
        for x in range(SIZE):
            diagonal = (x + y) / (2 * SIZE)
            glow = max(0, 1 - (((x - 760) ** 2 + (y - 180) ** 2) ** 0.5) / 900)
            pixels[x, y] = (
                int(42 + 36 * diagonal + 28 * glow),
                int(46 + 34 * diagonal + 25 * glow),
                int(122 + 65 * diagonal + 35 * glow),
                255,
            )
    image.alpha_composite(background, (0, 0))
    image.putalpha(rounded_mask(SIZE, 224))

    drawing = ImageDraw.Draw(image)
    # Decorative reading-light rings.
    drawing.ellipse((610, 68, 1120, 578), outline=(157, 178, 255, 40), width=28)
    drawing.ellipse((682, 140, 1048, 506), outline=(194, 210, 255, 30), width=18)

    # Soft page shadow.
    shadow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle((246, 166, 798, 866), radius=72, fill=(3, 8, 39, 145))
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    image.alpha_composite(shadow)

    page = (222, 134, 776, 840)
    drawing.rounded_rectangle(page, radius=70, fill=(250, 251, 255, 255))
    drawing.rounded_rectangle(page, radius=70, outline=(221, 227, 255, 255), width=10)

    # Folded corner.
    drawing.polygon([(634, 134), (776, 134), (776, 276)], fill=(205, 216, 255, 255))
    drawing.line([(634, 134), (634, 246), (776, 276)], fill=(175, 192, 246, 255), width=10)

    # Markdown M mark.
    mark_font = font(270)
    mark_box = drawing.textbbox((0, 0), "M", font=mark_font)
    mark_width = mark_box[2] - mark_box[0]
    drawing.text(((SIZE - mark_width) / 2, 254), "M", font=mark_font, fill=(78, 83, 206, 255))

    # Eye / viewer motif.
    drawing.ellipse((340, 552, 660, 704), fill=(95, 100, 218, 255))
    drawing.ellipse((364, 574, 636, 682), fill=(250, 251, 255, 255))
    drawing.ellipse((451, 585, 549, 673), fill=(41, 48, 146, 255))
    drawing.ellipse((482, 603, 510, 629), fill=(255, 255, 255, 220))

    # Three lightweight text lines.
    for y, width, alpha in [(752, 232, 190), (782, 170, 145), (812, 204, 105)]:
        left = (SIZE - width) / 2
        drawing.rounded_rectangle(
            (left, y, left + width, y + 11),
            radius=6,
            fill=(88, 96, 195, alpha),
        )

    return image


def main() -> None:
    icon = draw_icon()
    ICONSET.mkdir(parents=True, exist_ok=True)
    outputs = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    for name, size in outputs.items():
        icon.resize((size, size), Image.Resampling.LANCZOS).save(ICONSET / name)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    import subprocess
    subprocess.run(
        ["iconutil", "-c", "icns", str(ICONSET), "-o", str(OUTPUT)],
        check=True,
    )
    print(f"Wrote {OUTPUT.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
