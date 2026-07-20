#!/usr/bin/env python3
"""Rend les icônes PNG de la marque Budget depuis la géométrie du logo.

Même géométrie que branding/logo.svg (le chemin ascendant du
patrimoine), dessinée en supersampling 4× pour des bords nets :
- Budget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png
- webapp/icon-512.png, webapp/icon-192.png, webapp/apple-touch-icon.png (180)
"""
from PIL import Image, ImageDraw

SS = 4  # supersampling
BASE = 1024 * SS


def lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def render():
    img = Image.new("RGB", (BASE, BASE))
    top, bottom = (0x13, 0x1B, 0x2E), (0x0B, 0x0E, 0x14)
    for y in range(BASE):
        # dégradé diagonal approché par la moyenne x+y
        row = Image.new("RGB", (BASE, 1))
        d = ImageDraw.Draw(row)
        for x in range(0, BASE, 32):
            t = (x + y) / (2 * BASE)
            d.rectangle([x, 0, x + 32, 1], fill=lerp(top, bottom, t))
        img.paste(row, (0, y))

    draw = ImageDraw.Draw(img)
    pts = [(232, 712), (436, 540), (568, 618), (792, 352)]
    pts = [(x * SS, y * SS) for x, y in pts]
    width = 78 * SS
    indigo, violet = (0x4B, 0x5C, 0xFF), (0x8B, 0x5C, 0xF6)

    # segments colorés le long du chemin + joints ronds
    seg_colors = [lerp(indigo, violet, t) for t in (0.15, 0.5, 0.85)]
    for (p1, p2), color in zip(zip(pts, pts[1:]), seg_colors):
        draw.line([p1, p2], fill=color, width=width)
    for p, color in zip(pts, [indigo] + seg_colors):
        r = width // 2
        draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)

    # socle et sommet
    def dot(p, r, color):
        r *= SS
        draw.ellipse([p[0] - r, p[1] - r, p[0] + r, p[1] + r], fill=color)

    dot(pts[0], 40, indigo)
    dot(pts[3], 62, (0x5A, 0xA7, 0xFF))
    dot(pts[3], 26, (0xF2, 0xF4, 0xF8))

    return img.resize((1024, 1024), Image.LANCZOS)


if __name__ == "__main__":
    icon = render()
    icon.save("Budget/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon1024.png", optimize=True)
    for size, name in [(512, "webapp/icon-512.png"), (192, "webapp/icon-192.png"),
                       (180, "webapp/apple-touch-icon.png")]:
        icon.resize((size, size), Image.LANCZOS).save(name, optimize=True)
    print("ICONS_RENDERED")
