# هل اللقطة جاهزة؟ (للتصوير التلقائي) — تُستدعى بلقطتين متتاليتين بينهما ثوانٍ:
# جاهزة لو الشاشة ثبتت (ما تغيّرت بينهما) وفيها ألوان كفاية (الصور تحمّلت).
# ولازم تكون شاشة جديدة فعلًا (تختلف عن اللقطة المعتمدة اللي قبلها) — حتى لو المحاكي متأخر.
# الاستخدام: python shot_ready.py <قبل> <بعد> <أقل عدد ألوان> [اللقطة السابقة]  → خروج 0 = جاهزة
import sys
from PIL import Image, ImageChops

a = Image.open(sys.argv[1]).convert('RGB').resize((132, 287))
b = Image.open(sys.argv[2]).convert('RGB').resize((132, 287))
need = int(sys.argv[3])
def change(x, y):
    d = ImageChops.difference(x, y).convert('L')
    return sum(1 for v in d.getdata() if v > 24) / (132 * 287)

changed = change(a, b)
colors = len({(r // 16, g // 16, b_ // 16) for r, g, b_ in b.getdata()})
new = 1.0
if len(sys.argv) > 4:
    new = change(Image.open(sys.argv[4]).convert('RGB').resize((132, 287)), b)
print(f'   ثبات {100 - changed * 100:.1f}% · {colors} لون · اختلاف عن السابقة {new * 100:.0f}%')
sys.exit(0 if changed < 0.05 and colors >= need and new > 0.06 else 1)
