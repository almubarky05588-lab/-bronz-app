# يولّد خط أيقونات برونز (BronzIcons.ttf) من أيقونات SVG خطية — يُشغَّل وقت البناء من ios_prepare.sh
# الترتيب ثابت: أي أيقونة جديدة تُضاف في آخر القاموس حتى ما تتغير رموز الأيقونات السابقة.
# كل أيقونة ثلاث حالات متتالية ابتداءً من 0xE900: regular · bold · fill (نفس ترتيب packages/phosphor_flutter).
import re, sys, os
from picosvg.svg import SVG
import pathops
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.svgLib.path import parse_path
from fontTools.pens.recordingPen import RecordingPen

# (stroke elements, fill elements for filled variant or None)
ICONS = {
 'house': ('<path d="M4 10.5L12 4l8 6.5V20h-5.5v-5.5h-5V20H4z"/>', '<path d="M4 10.5L12 4l8 6.5V20h-5.5v-5.5h-5V20H4z" fill="#000" stroke="#000"/>'),
 'squaresFour': ('<rect x="4" y="4" width="6.5" height="6.5" rx="1.6"/><rect x="13.5" y="4" width="6.5" height="6.5" rx="1.6"/><rect x="4" y="13.5" width="6.5" height="6.5" rx="1.6"/><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="1.6"/>',
                 '<rect x="4" y="4" width="6.5" height="6.5" rx="1.6" fill="#000"/><rect x="13.5" y="4" width="6.5" height="6.5" rx="1.6" fill="#000"/><rect x="4" y="13.5" width="6.5" height="6.5" rx="1.6" fill="#000"/><rect x="13.5" y="13.5" width="6.5" height="6.5" rx="1.6" fill="#000"/>'),
 'handbag': ('<path d="M5.5 8h13l-1 12h-11z"/><path d="M9 8V7a3 3 0 016 0v1"/>', '<path d="M5.5 8h13l-1 12h-11z" fill="#000" stroke="#000"/><path d="M9 8V7a3 3 0 016 0v1"/>'),
 'user': ('<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20a7.5 7.5 0 0115 0"/>', '<circle cx="12" cy="8.5" r="3.8" fill="#000"/><path d="M4.5 20a7.5 7.5 0 0115 0z" fill="#000"/>'),
 'magnifyingGlass': ('<circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.2-4.2"/>', None),
 'bell': ('<path d="M6 16V11a6 6 0 1112 0v5l1.5 2h-15z"/><path d="M10 20.5a2 2 0 004 0"/>', '<path d="M6 16V11a6 6 0 1112 0v5l1.5 2h-15z" fill="#000" stroke="#000"/><path d="M10 20.5a2 2 0 004 0"/>'),
 'heart': ('<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0112 7.3 4.3 4.3 0 0119.5 10c0 5.4-7.5 10-7.5 10z"/>', '<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0112 7.3 4.3 4.3 0 0119.5 10c0 5.4-7.5 10-7.5 10z" fill="#000" stroke="#000"/>'),
 'caretLeft': ('<path d="M14.5 6l-6 6 6 6"/>', None),
 'caretRight': ('<path d="M9.5 6l6 6-6 6"/>', None),
 'plus': ('<path d="M12 6v12M6 12h12"/>', None),
 'minus': ('<path d="M6 12h12"/>', None),
 'check': ('<path d="M5 12.5l4.5 4.5L19 7.5"/>', None),
 'trash': ('<path d="M5 7h14M10 7V5h4v2M7 7l1 13h8l1-13"/>', None),
 'truck': ('<path d="M3 7h11v9H3zM14 10h4l3 3v3h-7"/><circle cx="7" cy="17.5" r="1.6"/><circle cx="17" cy="17.5" r="1.6"/>', None),
 'sealCheck': ('<circle cx="12" cy="12" r="8"/><path d="M8.5 12.2l2.3 2.3 4.7-4.8"/>', 'KNOCK:<circle cx="12" cy="12" r="8.8" fill="#000"/>|<path d="M8.5 12.2l2.3 2.3 4.7-4.8"/>'),
 'checkCircle': ('<circle cx="12" cy="12" r="8"/><path d="M8.5 12.2l2.3 2.3 4.7-4.8"/>', 'KNOCK:<circle cx="12" cy="12" r="8.8" fill="#000"/>|<path d="M8.5 12.2l2.3 2.3 4.7-4.8"/>'),
 'lock': ('<rect x="5" y="10.5" width="14" height="9.5" rx="2"/><path d="M8.5 10.5V8a3.5 3.5 0 017 0v2.5"/>', None),
 'percent': ('<path d="M18 6L6 18"/><circle cx="7.5" cy="7.5" r="2"/><circle cx="16.5" cy="16.5" r="2"/>', None),
 'sparkle': ('<path d="M12 3.5l1.9 5.6 5.6 1.9-5.6 1.9L12 18.5l-1.9-5.6L4.5 11l5.6-1.9z"/>', '<path d="M12 3.5l1.9 5.6 5.6 1.9-5.6 1.9L12 18.5l-1.9-5.6L4.5 11l5.6-1.9z" fill="#000" stroke="#000"/>'),
 'signOut': ('<path d="M14 5h4a1 1 0 011 1v12a1 1 0 01-1 1h-4"/><path d="M10 8l-4 4 4 4M6 12h9"/>', None),
 'image': ('<rect x="4" y="5" width="16" height="14" rx="2.5"/><path d="M4.5 16l4.5-4.5 4 4 2.5-2.5 4 4"/><circle cx="15" cy="9.5" r="1.4"/>', None),
 'imageBroken': ('<path d="M4 15V7.5A2.5 2.5 0 016.5 5H13M20 9v7.5a2.5 2.5 0 01-2.5 2.5H11"/><path d="M4 4l16 16"/>', None),
 'wifiSlash': ('<path d="M4 4l16 16"/><path d="M8.5 15.5a5 5 0 017 0M5 12a10 10 0 016-2.8M14.5 9.6A10 10 0 0119 12"/><circle cx="12" cy="19" r=".6"/>', None),
 'package': ('<path d="M4 8l8-4 8 4v8l-8 4-8-4z"/><path d="M4 8l8 4 8-4M12 12v8"/>', None),
 'share': ('<path d="M12 15V4M8 8l4-4 4 4"/><path d="M5 13v6h14v-6"/>', None),
 'star': ('<path d="M12 4l2.4 5 5.4.6-4 3.7 1.1 5.3L12 16l-4.9 2.6 1.1-5.3-4-3.7 5.4-.6z"/>', '<path d="M12 4l2.4 5 5.4.6-4 3.7 1.1 5.3L12 16l-4.9 2.6 1.1-5.3-4-3.7 5.4-.6z" fill="#000" stroke="#000"/>'),
 'sliders': ('<path d="M4 7h10M18 7h2M4 17h4M12 17h8"/><circle cx="16" cy="7" r="2"/><circle cx="10" cy="17" r="2"/>', None),
 'receipt': ('<path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9 8h6M9 12h6"/>', None),
 'chat': ('<path d="M5 18l1.2-3.4A7 7 0 1112 19a7 7 0 01-3.6-1z"/>', None),
 'shield': ('<path d="M12 3l7 3v6c0 4.4-3 7.6-7 9-4-1.4-7-4.6-7-9V6z"/>', None),
 'x': ('<path d="M6.5 6.5l11 11M17.5 6.5l-11 11"/>', None),
}

def pico_paths(inner, sw):
    svg = f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" stroke-width="{sw}" stroke-linecap="round" stroke-linejoin="round">{inner}</svg>'
    pico = SVG.fromstring(svg).topicosvg()
    ds = [el.get('d') for el in pico.svg_root.iter() if el.tag.endswith('path') and el.get('d')]
    return ds

def to_skpath(ds):
    p = pathops.Path()
    for d in ds:
        rp = RecordingPen(); parse_path(d, rp)
        q = pathops.Path(); pen = q.getPen()
        rp.replay(pen)
        p = pathops.op(p, q, pathops.PathOp.UNION)
    return p

def glyph_path(spec, sw):
    if spec.startswith('KNOCK:'):
        a, b = spec[6:].split('|')
        A = to_skpath(pico_paths(a, sw)); B = to_skpath(pico_paths(b, sw + 0.4))
        return pathops.op(A, B, pathops.PathOp.DIFFERENCE)
    return to_skpath(pico_paths(spec, sw))

UPM = 1024; S = UPM / 24
names = list(ICONS)
glyphs = {'.notdef': None}
cmap = {}
order = ['.notdef']
codes = {}
cp = 0xE900
for n in names:
    stroke, filled = ICONS[n]
    for style, spec, sw in (('regular', stroke, 1.6), ('bold', stroke, 2.1), ('fill', filled or stroke, 1.6 if filled else 2.1)):
        gname = f'{n}_{style}'
        path = glyph_path(spec, sw)
        pen = TTGlyphPen(None)
        tp = TransformPen(Cu2QuPen(pen, 1.0, reverse_direction=True), (S, 0, 0, -S, 0, UPM * 0.875))
        path.draw(tp)
        glyphs[gname] = pen.glyph()
        order.append(gname); cmap[cp] = gname; codes[gname] = cp; cp += 1

fb = FontBuilder(UPM, isTTF=True)
fb.setupGlyphOrder(order)
fb.setupCharacterMap(cmap)
empty = TTGlyphPen(None).glyph()
fb.setupGlyf({k: (v if v is not None else empty) for k, v in glyphs.items()})
fb.setupHorizontalMetrics({g: (UPM, 0) for g in order})
fb.setupHorizontalHeader(ascent=int(UPM*0.875), descent=-int(UPM*0.125))
fb.setupNameTable({'familyName': 'BronzIcons', 'styleName': 'Regular'})
fb.setupOS2(sTypoAscender=int(UPM*0.875), sTypoDescender=-int(UPM*0.125), usWinAscent=int(UPM*0.875), usWinDescent=int(UPM*0.125))
fb.setupPost()
out = sys.argv[1] if len(sys.argv) > 1 else 'BronzIcons.ttf'
os.makedirs(os.path.dirname(out) or '.', exist_ok=True)
fb.save(out)
print('BronzIcons:', len(order), 'glyphs ->', out)
