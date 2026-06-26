#!/usr/bin/env python3
import math
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter


def rounded_rectangle(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def make_icon(size):
    scale = size / 1024
    image = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)

    for y in range(size):
        t = y / max(1, size - 1)
        top = (191, 240, 235)
        bottom = (47, 146, 129)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        draw.line([(0, y), (size, y)], fill=(*color, 255))

    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    mask_draw.rounded_rectangle([0, 0, size - 1, size - 1], radius=int(220 * scale), fill=255)
    image.putalpha(mask)
    draw = ImageDraw.Draw(image)

    shadow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.ellipse(
        [int(190 * scale), int(705 * scale), int(830 * scale), int(825 * scale)],
        fill=(0, 70, 58, 70),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(int(24 * scale)))
    image.alpha_composite(shadow)

    draw = ImageDraw.Draw(image)
    line = max(10, int(24 * scale))
    white = (250, 255, 252, 255)
    tea = (124, 200, 150, 255)
    dark = (19, 82, 70, 255)
    light = (225, 255, 247, 255)

    for x, y, w, h in [(408, 190, 62, 182), (530, 168, 58, 206), (632, 226, 54, 150)]:
        points = []
        for i in range(30):
            p = i / 29
            yy = (y + h * p) * scale
            xx = (x + math.sin(p * math.pi * 2.2) * 20) * scale
            points.append((xx, yy))
        draw.line(points, fill=(235, 255, 250, 180), width=max(7, int(12 * scale)), joint="curve")

    leaf = [
        (615 * scale, 306 * scale),
        (740 * scale, 238 * scale),
        (825 * scale, 320 * scale),
        (738 * scale, 386 * scale),
    ]
    draw.polygon(leaf, fill=(214, 255, 188, 255))
    draw.line([leaf[0], leaf[1], leaf[2], leaf[3], leaf[0]], fill=dark, width=line)
    draw.line([(630 * scale, 312 * scale), (790 * scale, 316 * scale)], fill=dark, width=max(7, int(13 * scale)))

    cup_box = [250 * scale, 404 * scale, 700 * scale, 720 * scale]
    draw.rounded_rectangle(cup_box, radius=int(70 * scale), fill=white, outline=dark, width=line)
    draw.pieslice(
        [247 * scale, 376 * scale, 703 * scale, 494 * scale],
        0,
        360,
        fill=white,
        outline=dark,
        width=line,
    )
    draw.pieslice(
        [305 * scale, 406 * scale, 645 * scale, 480 * scale],
        0,
        360,
        fill=tea,
    )

    draw.arc(
        [660 * scale, 470 * scale, 860 * scale, 650 * scale],
        start=-82,
        end=92,
        fill=dark,
        width=line,
    )
    draw.arc(
        [700 * scale, 510 * scale, 810 * scale, 615 * scale],
        start=-83,
        end=88,
        fill=light,
        width=max(8, int(18 * scale)),
    )

    draw.arc(
        [205 * scale, 670 * scale, 810 * scale, 842 * scale],
        start=8,
        end=172,
        fill=dark,
        width=line,
    )
    draw.arc(
        [275 * scale, 693 * scale, 740 * scale, 804 * scale],
        start=8,
        end=172,
        fill=light,
        width=max(8, int(18 * scale)),
    )

    highlight = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    highlight_draw = ImageDraw.Draw(highlight)
    highlight_draw.rounded_rectangle(
        [75 * scale, 70 * scale, 950 * scale, 440 * scale],
        radius=int(190 * scale),
        fill=(255, 255, 255, 42),
    )
    image.alpha_composite(highlight)
    return image


def main():
    if len(sys.argv) < 2:
        raise SystemExit("usage: generate_icon.py OUTPUT.icns [PREVIEW.png]")

    output = Path(sys.argv[1])
    preview = Path(sys.argv[2]) if len(sys.argv) > 2 else None
    output.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        iconset = Path(tmp) / "AppIcon.iconset"
        iconset.mkdir()
        specs = [
            (16, 1),
            (16, 2),
            (32, 1),
            (32, 2),
            (128, 1),
            (128, 2),
            (256, 1),
            (256, 2),
            (512, 1),
            (512, 2),
        ]
        for points, scale in specs:
            pixels = points * scale
            suffix = "" if scale == 1 else "@2x"
            make_icon(pixels).save(iconset / f"icon_{points}x{points}{suffix}.png")

        subprocess.run(["iconutil", "-c", "icns", str(iconset), "-o", str(output)], check=True)

    if preview:
        preview.parent.mkdir(parents=True, exist_ok=True)
        make_icon(512).save(preview)


if __name__ == "__main__":
    main()
