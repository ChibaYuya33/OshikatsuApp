"""推し活アプリのアイコン/スプラッシュ素材を生成する。
ピンクのグラデ背景に白いハートときらきら(★)を配置した可愛い系デザイン。
出力: assets/icon/icon.png, icon_foreground.png, splash.png
"""
import math
import os

from PIL import Image, ImageDraw

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
os.makedirs(OUT, exist_ok=True)

SIZE = 1024
# 大人可愛い・くすみローズのグラデ。
PINK_TOP = (231, 183, 190)    # #E7B7BE 淡いくすみピンク
PINK_BOTTOM = (201, 133, 148)  # #C98594 くすみローズ
WHITE = (255, 248, 244)        # 生成りホワイト


def gradient_bg(size, top, bottom):
    img = Image.new("RGB", (size, size), top)
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / size
        r = int(top[0] + (bottom[0] - top[0]) * t)
        g = int(top[1] + (bottom[1] - top[1]) * t)
        b = int(top[2] + (bottom[2] - top[2]) * t)
        d.line([(0, y), (size, y)], fill=(r, g, b))
    return img


def heart_points(cx, cy, scale):
    pts = []
    for deg in range(0, 360, 3):
        t = math.radians(deg)
        x = 16 * math.sin(t) ** 3
        y = -(13 * math.cos(t) - 5 * math.cos(2 * t)
              - 2 * math.cos(3 * t) - math.cos(4 * t))
        pts.append((cx + x * scale, cy + y * scale))
    return pts


def star(draw, cx, cy, r, fill):
    pts = []
    for i in range(10):
        ang = math.radians(i * 36 - 90)
        rad = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    draw.polygon(pts, fill=fill)


def draw_decor(img, heart_fill, with_sparkle=True):
    d = ImageDraw.Draw(img, "RGBA")
    # 中央のハート(きらきらが見えるよう控えめサイズ)
    d.polygon(heart_points(SIZE / 2, SIZE / 2 - 24, SIZE / 60), fill=heart_fill)
    if with_sparkle:
        star(d, SIZE * 0.84, SIZE * 0.20, SIZE * 0.055, (255, 255, 255, 245))
        star(d, SIZE * 0.16, SIZE * 0.26, SIZE * 0.038, (255, 255, 255, 220))
        star(d, SIZE * 0.82, SIZE * 0.80, SIZE * 0.030, (255, 255, 255, 200))
        star(d, SIZE * 0.18, SIZE * 0.78, SIZE * 0.026, (255, 255, 255, 190))
    return img


# 1) フルアイコン(背景つき)
icon = gradient_bg(SIZE, PINK_TOP, PINK_BOTTOM)
draw_decor(icon, WHITE)
icon.save(os.path.join(OUT, "icon.png"))

# 2) Android adaptive 用の前景(透過・セーフゾーン考慮で少し小さめ)
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
d = ImageDraw.Draw(fg, "RGBA")
d.polygon(heart_points(SIZE / 2, SIZE / 2 - 16, SIZE / 70), fill=WHITE + (255,))
star(d, SIZE * 0.72, SIZE * 0.30, SIZE * 0.045, (255, 255, 255, 240))
star(d, SIZE * 0.30, SIZE * 0.66, SIZE * 0.032, (255, 255, 255, 210))
fg.save(os.path.join(OUT, "icon_foreground.png"))

# 3) スプラッシュ用ロゴ(透過・ハートのみ)
splash = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
ds = ImageDraw.Draw(splash, "RGBA")
ds.polygon(heart_points(SIZE / 2, SIZE / 2 - 20, SIZE / 40), fill=WHITE + (255,))
splash.save(os.path.join(OUT, "splash.png"))

print("generated:", os.listdir(OUT))
