# فحص جودة لقطات المتجر قبل الرفع: لو أي لقطة طلعت صورها فاضية (ما تحمّلت)
# يوقف البناء بخطأ — فما يوصل لآبل شي ناقص أبدًا.
# المقياس: عدد الألوان المختلفة في نسخة مصغّرة (الشاشة الفاضية ~30 لون، المحمّلة 100+).
import sys, os, io, base64
from PIL import Image

MIN = {'1_home': 120, '2_categories': 150, '3_category': 120, '4_product': 60}
folder = sys.argv[1]
bad = []
for name, need in MIN.items():
    path = os.path.join(folder, name + '.png')
    if not os.path.exists(path):
        bad.append(f'{name}: غير موجودة')
        continue
    im = Image.open(path).convert('RGB').resize((132, 287))
    colors = len({(r // 16, g // 16, b // 16) for r, g, b in im.getdata()})
    print(f'{name}: {colors} لون (الحد الأدنى {need})')
    if colors < need:
        bad.append(f'{name}: الصور ما تحمّلت ({colors} لون)')
        # نسخة مصغّرة من اللقطة داخل السجل — حتى نشوف وش اللي ظهر بالضبط
        thumb = Image.open(path).convert('RGB')
        thumb.thumbnail((300, 650))
        buf = io.BytesIO()
        thumb.save(buf, 'JPEG', quality=70)
        print(f'IMG64:{name}:' + base64.b64encode(buf.getvalue()).decode())
if bad:
    print('❌ لقطات ناقصة — أوقفت الرفع:\n' + '\n'.join(bad))
    sys.exit(1)
print('✅ كل اللقطات مكتملة')
