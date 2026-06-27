"""推し活アプリのアイコン/スプラッシュ素材を生成する。
ネイビー背景に「推」の漢字ロゴ(明るい差し色)を配した男女共通デザイン。
出力: assets/icon/icon.png, icon_foreground.png, splash.png
"""
import math
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "icon")
FONT_PATH = os.path.join(ROOT, "assets", "fonts", "ZenMaruGothic-Medium.ttf")
os.makedirs(OUT, exist_ok=True)

SIZE = 1024
# ネイビーのグラデ。
NAVY_TOP = (37, 49, 79)      # #25314F
NAVY_BOTTOM = (26, 35, 60)   # #1A233C
ACCENT = (246, 194, 75)      # #F6C24B 明るいゴールド/アンバーの差し色
ACCENT_SOFT = (246, 194, 75, 210)


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


def star(draw, cx, cy, r, fill):
    pts = []
    for i in range(10):
        ang = math.radians(i * 36 - 90)
        rad = r if i % 2 == 0 else r * 0.45
        pts.append((cx + rad * math.cos(ang), cy + rad * math.sin(ang)))
    draw.polygon(pts, fill=fill)


def draw_kanji(img, cx, cy, font_size, fill):
    """「推」を中央(cx,cy)に描画する。"""
    d = ImageDraw.Draw(img, "RGBA")
    font = ImageFont.truetype(FONT_PATH, font_size)
    # 実際の字面の bbox を取得して正確に中央寄せ。
    l, t, r, b = d.textbbox((0, 0), "推", font=font)
    w, h = r - l, b - t
    x = cx - w / 2 - l
    y = cy - h / 2 - t
    d.text((x, y), "推", font=font, fill=fill)


# 1) フルアイコン(背景つき)
icon = gradient_bg(SIZE, NAVY_TOP, NAVY_BOTTOM)
draw_kanji(icon, SIZE / 2, SIZE / 2, int(SIZE * 0.66), ACCENT + (255,))
# 控えめなきらめき
ds = ImageDraw.Draw(icon, "RGBA")
star(ds, SIZE * 0.80, SIZE * 0.20, SIZE * 0.040, ACCENT_SOFT)
star(ds, SIZE * 0.18, SIZE * 0.82, SIZE * 0.028, (255, 255, 255, 150))
icon.save(os.path.join(OUT, "icon.png"))

# 2) Android adaptive 用の前景(透過・セーフゾーン考慮で少し小さめ)
fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_kanji(fg, SIZE / 2, SIZE / 2, int(SIZE * 0.50), ACCENT + (255,))
fg.save(os.path.join(OUT, "icon_foreground.png"))

# 3) スプラッシュ用ロゴ(透過・「推」のみ)
splash = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
draw_kanji(splash, SIZE / 2, SIZE / 2, int(SIZE * 0.58), ACCENT + (255,))
splash.save(os.path.join(OUT, "splash.png"))

print("generated:", os.listdir(OUT))
