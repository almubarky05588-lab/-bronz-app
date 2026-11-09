# شاشة افتتاحية «الجمعة البيضاء»: الرسم الأصلي معكوس على خلفية سوداء + شريطان أصفران + عنوان ذهبي.
import sys
from PIL import Image, ImageDraw, ImageFont, ImageOps, ImageFilter, features

# الكتابة العربية تحتاج raqm/fribidi وإلا تطلع مربعات — نوقف بدل ما نطلع شاشة مكسورة
if not features.check('raqm'):
    sys.exit('❌ مكتبة تشكيل العربية (raqm/fribidi) غير متوفرة')

src, font_path, dst = sys.argv[1], sys.argv[2], sys.argv[3]
# 'notape' = بدون الشريطين (التطبيق يرسمهم متحركين فوق الخلفية)
with_tapes = len(sys.argv) < 5 or sys.argv[4] != 'notape'
base = Image.open(src).convert('RGB')
W, H = base.size

# ─── الخلفية: الرسم بخطوط فضية خافتة على أسود
inv = ImageOps.invert(base).convert('L')
sketch = inv.point(lambda v: int(v * 0.34))  # خفوت الرسم
bg = Image.new('RGB', (W, H), (10, 10, 10))
silver = Image.new('RGB', (W, H), (205, 200, 190))
bg = Image.composite(silver, bg, sketch)

# تدرّج دائري يغمّق الأطراف ويبرز الوسط
vig = Image.new('L', (W, H), 0)
ImageDraw.Draw(vig).ellipse((-W * 0.25, H * 0.18, W * 1.25, H * 0.82), fill=255)
vig = vig.filter(ImageFilter.GaussianBlur(220))
dark = Image.new('RGB', (W, H), (6, 6, 6))
bg = Image.composite(bg, Image.blend(bg, dark, 0.55), vig)

# ─── الشعار: من الصورة الأصلية (أسود على أبيض) → أبيض ناصع مع توهّج ذهبي ناعم
logo_box = (int(W * 0.22), int(H * 0.438), int(W * 0.78), int(H * 0.548))
crop = base.crop(logo_box).convert('L')
m = ImageOps.invert(crop).point(lambda v: 255 if v > 205 else (0 if v < 150 else int((v - 150) * 255 / 55)))
full = Image.new('L', (W, H), 0)
full.paste(m, logo_box[:2])
# نمسح الرسم خلف الشعار حتى يبقى نظيفًا
clear = Image.new('L', (W, H), 0)
ImageDraw.Draw(clear).rounded_rectangle((logo_box[0] - 40, logo_box[1] - 60, logo_box[2] + 40, logo_box[3] + 90), 80, fill=255)
clear = clear.filter(ImageFilter.GaussianBlur(45))
bg = Image.composite(Image.new('RGB', (W, H), (10, 10, 10)), bg, clear)
glow = full.filter(ImageFilter.GaussianBlur(40)).point(lambda v: int(min(255, v * 0.9)))
bg = Image.composite(Image.new('RGB', (W, H), (214, 176, 82)), bg, glow.point(lambda v: int(v * 0.45)))
bg.paste((255, 255, 255), (0, 0), full)

d = ImageDraw.Draw(bg)

def font(size, weight='Bold'):
    f = ImageFont.truetype(font_path, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f

def centered(y, text, f, fill):
    w = d.textlength(text, font=f, direction='rtl')
    d.text(((W - w) / 2, y), text, font=f, fill=fill, direction='rtl')

# ─── العنوان الذهبي تحت الشعار
title_f = font(150, 'Black')
title = 'الجمعة البيضاء'
tw = d.textlength(title, font=title_f, direction='rtl')
ty = int(H * 0.565)
tl = Image.new('L', (W, H), 0)
ImageDraw.Draw(tl).text(((W - tw) / 2, ty), title, font=title_f, fill=255, direction='rtl')
grad = Image.new('RGB', (W, H))
gd = ImageDraw.Draw(grad)
for yy in range(H):
    t = min(1, max(0, (yy - ty) / 200))
    c = tuple(int(a + (b - a) * t) for a, b in zip((250, 226, 150), (196, 150, 52)))
    gd.line([(0, yy), (W, yy)], fill=c)
bg.paste(grad, (0, 0), tl)

# خط ذهبي رفيع + سطر صغير
ly = ty + 230
d.line([(W / 2 - 150, ly), (W / 2 + 150, ly)], fill=(214, 176, 82), width=3)
centered(ly + 34, 'عروض لفترة محدودة', font(54, 'SemiBold'), (225, 222, 214))

# ─── شريط التحذير الأصفر
def tape(text, angle, cy):
    tw_, th_ = int(W * 1.9), 150
    t = Image.new('RGBA', (tw_, th_), (255, 214, 0, 255))
    td = ImageDraw.Draw(t)
    # حواف داكنة رفيعة
    td.rectangle((0, 0, tw_, 8), fill=(20, 20, 20, 255))
    td.rectangle((0, th_ - 8, tw_, th_), fill=(20, 20, 20, 255))
    f = font(70, 'Black')
    x = 0
    while x < tw_:
        seg = text
        sw = td.textlength(seg, font=f)
        td.text((x, th_ / 2 - 50), seg, font=f, fill=(12, 12, 12, 255))
        x += sw + 70
    t = t.rotate(angle, expand=True, resample=Image.BICUBIC)
    sh = Image.new('RGBA', t.size, (0, 0, 0, 0))
    sh.putalpha(t.split()[3].point(lambda v: int(v * 0.55)))
    sh = sh.filter(ImageFilter.GaussianBlur(18))
    px, py = (W - t.width) // 2, cy - t.height // 2
    bg.paste((0, 0, 0), (px + 10, py + 22), sh.split()[3])
    bg.paste(t, (px, py), t)

if with_tapes:
    tape('BLACK FRIDAY  •  ', -11, int(H * 0.17))
    tape('WHITE FRIDAY  •  ', 9, int(H * 0.86))

bg.save(dst, optimize=True)
print('✓', dst)
