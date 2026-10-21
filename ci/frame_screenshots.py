# يحوّل لقطات المحاكي الخام إلى صور تسويقية لـ App Store (1320×2868):
# خلفية سوداء · شعار برونز الأبيض · عنوان عربي كبير · اللقطة بإطار وزوايا ناعمة.
# الاستخدام: python frame_screenshots.py <مجلد اللقطات> <خط Cairo> <أيقونة التطبيق 4096>
import sys, os, glob
from PIL import Image, ImageDraw, ImageFont, ImageOps, features

SHOTS, FONT, ICON = sys.argv[1], sys.argv[2], sys.argv[3]
W, H = 1320, 2868
BG = (11, 11, 11)

# العنوان والوصف لكل لقطة (حسب اسم الملف)
COPY = {
    '1_home': ('عطور أصلية 100%', 'أشهر الماركات العالمية في مكان واحد'),
    '2_categories': ('كل الأقسام بين يديك', 'عطور، عود، مكياج وعناية'),
    '3_category': ('تصفّح بلا حدود', 'آلاف المنتجات بتمرير واحد'),
    '4_product': ('تفاصيل كل عطر', 'صور واضحة وعروض حصرية'),
    '5_account': ('طلباتك تحت عينك', 'تتبّع طلبك وتواصل معنا بسهولة'),
}

RAQM = features.check('raqm')  # تشكيل الحروف العربية الصحيح (موجود في Pillow الرسمي)

def ar(text):
    if RAQM:
        return text
    import arabic_reshaper
    from bidi.algorithm import get_display
    return get_display(arabic_reshaper.reshape(text))

def font(size, weight):
    f = ImageFont.truetype(FONT, size)
    try:
        f.set_variation_by_name(weight)
    except Exception:
        pass
    return f

def logo(width):
    """شعار برونز الأبيض — مقصوص من أيقونة التطبيق (أسود على أبيض) ومقلوب."""
    im = Image.open(ICON).convert('L').crop((833, 1559, 3361, 2440))
    mask = ImageOps.invert(im)
    h = round(width * mask.height / mask.width)
    mask = mask.resize((width, h), Image.LANCZOS)
    white = Image.new('RGB', mask.size, (255, 255, 255))
    return white, mask

def rounded(img, r):
    m = Image.new('L', img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, img.width, img.height), r, fill=255)
    return m

def centered(draw, y, text, f, fill):
    t = ar(text)
    kw = {'direction': 'rtl'} if RAQM else {}
    w = draw.textlength(t, font=f, **kw)
    draw.text(((W - w) / 2, y), t, font=f, fill=fill, **kw)

title_f, sub_f = font(104, 'Bold'), font(46, 'Regular')
lg, lg_mask = logo(300)

for path in sorted(glob.glob(os.path.join(SHOTS, '*.png'))):
    name = os.path.splitext(os.path.basename(path))[0]
    if name not in COPY:
        continue
    title, sub = COPY[name]
    shot = Image.open(path).convert('RGB')
    canvas = Image.new('RGB', (W, H), BG)
    d = ImageDraw.Draw(canvas)

    canvas.paste(lg, ((W - lg.width) // 2, 130), lg_mask)
    centered(d, 300, title, title_f, (255, 255, 255))
    centered(d, 468, sub, sub_f, (189, 189, 184))

    # اللقطة: عرض 1040 — تبدأ من 620 وتنقص من الأسفل بشكل أنيق
    sw = 1040
    sh = round(sw * shot.height / shot.width)
    shot = shot.resize((sw, sh), Image.LANCZOS)
    x, y = (W - sw) // 2, 620
    frame = Image.new('RGB', (sw + 16, sh + 16), (48, 48, 46))
    canvas.paste(frame, (x - 8, y - 8), rounded(frame, 86))
    canvas.paste(shot, (x, y), rounded(shot, 78))

    canvas.save(path)
    print('🖼️', name)
