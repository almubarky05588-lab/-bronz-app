# يولّد أيقونة التطبيق بلمسة «BLACK FRIDAY»: شريط أصفر مائل في الزاوية السفلية.
# الاستخدام: python make_bf_icon.py <الأيقونة الأصلية> <الخط> <المخرج>
import sys
from PIL import Image, ImageDraw, ImageFont

src, font_path, dst = sys.argv[1], sys.argv[2], sys.argv[3]
base = Image.open(src).convert('RGBA')
W = base.width
yellow, ink = (255, 214, 0, 255), (11, 11, 11, 255)
rw, rh = int(W * 2.0), int(W * 0.15)
ribbon = Image.new('RGBA', (rw, rh), yellow)
d = ImageDraw.Draw(ribbon)
font = ImageFont.truetype(font_path, int(rh * 0.44))
try:
    font.set_variation_by_name('Bold')
except Exception:
    pass
text = 'BLACK FRIDAY'
bb = d.textbbox((0, 0), text, font=font)
tw, th = bb[2] - bb[0], bb[3] - bb[1]
d.text((rw / 2 - tw / 2 - bb[0], (rh - th) / 2 - bb[1]), text, font=font, fill=ink)
ribbon = ribbon.rotate(45, expand=True, resample=Image.BICUBIC)
out = base.copy()
c = int(W * 0.72)
out.alpha_composite(ribbon, (c - ribbon.width // 2, c - ribbon.height // 2))
out.convert('RGB').save(dst, optimize=True)
print('✓', dst)
