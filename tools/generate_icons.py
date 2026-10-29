#!/usr/bin/env python3
"""Regenerates every PantryPal icon asset from code (needs Pillow: pip install pillow).

  python3 tools/generate_icons.py

Writes: iOS AppIcon set + launch images, Android legacy/round/adaptive/monochrome launcher icons,
the white status-bar notification icon, the Android launch logo, and assets/branding/.
"""
import json, os, pathlib
from PIL import Image, ImageDraw, ImageFilter, ImageChops

S = 2048  # master canvas

GREEN_DARK = (27, 94, 32); GREEN = (46, 125, 50); GREEN_LIGHT = (102, 187, 106)
CREAM = (255, 248, 225); CREAM_SHADE = (240, 228, 196); LID = (141, 110, 99); LID_DARK = (109, 76, 65)
LEAF = (76, 175, 80); LEAF_DARK = (46, 125, 50)

def gradient_bg(size):
    """Diagonal green gradient (light top-left → dark bottom-right)."""
    g = Image.new('RGB', (size, size))
    px = g.load()
    for y in range(size):
        for x in range(size):
            t = (x + y) / (2 * size - 2)
            px[x, y] = tuple(round(GREEN_LIGHT[i] * (1 - t) * 0.55 + GREEN[i] * (1 - t) * 0.45 + GREEN_DARK[i] * t) for i in range(3))
    return g

def leaf_layer(size, cx, cy, length, width, angle, color, vein):
    """A pointed leaf: rounded near the stem, tapering to a tip; rotated by angle (degrees)."""
    import math
    L = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    pad = 4
    leaf = Image.new('RGBA', (length + 2 * pad, width + 2 * pad), (0, 0, 0, 0))
    d = ImageDraw.Draw(leaf)
    n = 90
    def half(t):  # half-width profile: fullest a third of the way out, pointed at both ends
        return (width / 2) * (math.sin(math.pi * t) ** 0.85) * (1.0 - 0.25 * t)
    top = [(pad + t * length, pad + width / 2 - half(t)) for t in (i / n for i in range(n + 1))]
    bottom = [(pad + t * length, pad + width / 2 + half(t)) for t in (i / n for i in range(n, -1, -1))]
    d.polygon(top + bottom, fill=color + (255,))
    d.line([(pad + length * 0.06, pad + width / 2), (pad + length * 0.88, pad + width / 2 - width * 0.04)],
           fill=vein + (255,), width=max(2, width // 14))
    leaf = leaf.rotate(angle, resample=Image.BICUBIC, expand=True)
    L.alpha_composite(leaf, (int(cx - leaf.width / 2), int(cy - leaf.height / 2)))
    return L

def jar_layer(size, scale=1.0, mono=None):
    """The jar + leaf, centred, as RGBA. mono=(r,g,b) draws a one-colour silhouette with cut-outs."""
    L = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(L)
    u = size / 1024 * scale            # design units: jar is ~620×700 at scale 1 on a 1024 canvas
    cx, cy = size / 2, size / 2 + 40 * u
    c = (lambda col: (mono or col) + (255,))
    # body
    bw, bh, by = 560 * u, 560 * u, cy - 170 * u
    d.rounded_rectangle([cx - bw / 2, by, cx + bw / 2, by + bh], radius=110 * u, fill=c(CREAM))
    if not mono:  # soft shade on the right side of the glass
        d.rounded_rectangle([cx + bw / 2 - 120 * u, by + 40 * u, cx + bw / 2 - 40 * u, by + bh - 60 * u], radius=40 * u, fill=CREAM_SHADE + (255,))
    # neck + lid
    nw = 470 * u
    d.rounded_rectangle([cx - nw / 2, by - 60 * u, cx + nw / 2, by + 20 * u], radius=24 * u, fill=c(CREAM_SHADE))
    lw, lh, ly = 520 * u, 120 * u, by - 175 * u
    d.rounded_rectangle([cx - lw / 2, ly, cx + lw / 2, ly + lh], radius=34 * u, fill=c(LID))
    if not mono:
        for i in range(1, 5):  # lid grip lines
            x = cx - lw / 2 + i * lw / 5
            d.line([(x, ly + 28 * u), (x, ly + lh - 28 * u)], fill=LID_DARK + (255,), width=max(1, int(10 * u)))
    # label: green band with a white check, cut out in the mono version
    lbw, lbh, lby = 400 * u, 210 * u, by + 170 * u
    if mono:
        d.rounded_rectangle([cx - lbw / 2, lby, cx + lbw / 2, lby + lbh], radius=48 * u, fill=(0, 0, 0, 0))
        d.line([(cx - 95 * u, lby + 110 * u), (cx - 25 * u, lby + 165 * u), (cx + 110 * u, lby + 45 * u)],
               fill=c(CREAM), width=int(46 * u), joint='curve')
    else:
        d.rounded_rectangle([cx - lbw / 2, lby, cx + lbw / 2, lby + lbh], radius=48 * u, fill=GREEN + (255,))
        d.line([(cx - 95 * u, lby + 110 * u), (cx - 25 * u, lby + 165 * u), (cx + 110 * u, lby + 45 * u)],
               fill=CREAM + (255,), width=int(46 * u), joint='curve')
    # sprouting leaves on the lid
    stem_x, stem_top = cx + 40 * u, ly - 120 * u
    d.line([(stem_x, ly + 6 * u), (stem_x, stem_top + 40 * u)], fill=c(LEAF_DARK), width=int(22 * u))
    L.alpha_composite(leaf_layer(size, stem_x + 105 * u, stem_top - 10 * u, int(250 * u), int(120 * u), 32, mono or LEAF, mono or LEAF_DARK))
    L.alpha_composite(leaf_layer(size, stem_x - 95 * u, stem_top + 35 * u, int(200 * u), int(98 * u), 152, mono or GREEN_LIGHT, mono or LEAF_DARK))
    return L

def shadow(layer, offset, blur, opacity):
    a = layer.split()[3].point(lambda v: int(v * opacity))
    sh = Image.new('RGBA', layer.size, (0, 0, 0, 0)); sh.putalpha(a)
    sh = sh.filter(ImageFilter.GaussianBlur(blur))
    out = Image.new('RGBA', layer.size, (0, 0, 0, 0)); out.alpha_composite(sh, (0, int(offset)))
    return out

def full_icon(size=S, scale=0.86):
    """Square, opaque: iOS and the 1024 master."""
    img = gradient_bg(size).convert('RGBA')
    jar = jar_layer(size, scale)
    img.alpha_composite(shadow(jar, size * 0.018, size * 0.02, 0.35))
    img.alpha_composite(jar)
    return img.convert('RGB')

def adaptive_foreground(size=S):
    """Android adaptive foreground: art inside the 66/108 safe zone, transparent elsewhere."""
    jar = jar_layer(size, 0.52)  # inside the 66dp safe circle (measured: 30.9dp of 33dp)
    out = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    out.alpha_composite(shadow(jar, size * 0.012, size * 0.014, 0.30)); out.alpha_composite(jar)
    return out

def monochrome(size=S, scale=0.52):
    return jar_layer(size, scale, mono=(255, 255, 255))


def write_all(root):
    from PIL import ImageDraw
    master = full_icon(2048); fg = adaptive_foreground(2048); bg = gradient_bg(2048)
    mono = monochrome(2048); stat = monochrome(1024, scale=0.95); art = jar_layer(1024, 0.95)
    rs = lambda img, px: img.resize((px, px), Image.LANCZOS)
    ios_set = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    for e in json.load(open(ios_set / 'Contents.json'))['images']:   # iOS: opaque, exact sizes
        rs(master, round(float(e['size'].split('x')[0]) * int(e['scale'][0]))).convert('RGB').save(ios_set / e['filename'])
    launch = root / 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    for name, px in [('LaunchImage.png', 128), ('LaunchImage@2x.png', 256), ('LaunchImage@3x.png', 384)]:
        rs(art, px).save(launch / name)
    res = root / 'android/app/src/main/res'
    def legacy(px, round_=False):
        canvas = Image.new('RGBA', (px, px), (0, 0, 0, 0)); inner = px - 2 * round(px * 2 / 48)
        m = Image.new('L', (inner, inner), 0); md = ImageDraw.Draw(m)
        (md.ellipse([0, 0, inner - 1, inner - 1], fill=255) if round_ else
         md.rounded_rectangle([0, 0, inner - 1, inner - 1], radius=inner * 0.2, fill=255))
        canvas.paste(rs(master, inner), ((px - inner) // 2,) * 2, m); return canvas
    for d, f in {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}.items():
        os.makedirs(res / f'mipmap-{d}', exist_ok=True); os.makedirs(res / f'drawable-{d}', exist_ok=True)
        legacy(round(48 * f)).save(res / f'mipmap-{d}/ic_launcher.png')
        legacy(round(48 * f), True).save(res / f'mipmap-{d}/ic_launcher_round.png')
        rs(fg, round(108 * f)).save(res / f'mipmap-{d}/ic_launcher_foreground.png')
        rs(bg, round(108 * f)).save(res / f'mipmap-{d}/ic_launcher_background.png')
        rs(mono, round(108 * f)).save(res / f'mipmap-{d}/ic_launcher_monochrome.png')
        rs(stat, round(24 * f)).save(res / f'drawable-{d}/ic_stat_pantrypal.png')
        rs(art, round(96 * f)).save(res / f'drawable-{d}/launch_logo.png')
    os.makedirs(root / 'assets/branding', exist_ok=True)
    rs(master, 1024).convert('RGB').save(root / 'assets/branding/pantrypal_icon_1024.png')
    print('icons written')

if __name__ == '__main__':
    write_all(pathlib.Path(__file__).resolve().parent.parent)
