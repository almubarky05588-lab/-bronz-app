// لوحة برونز — إشعارات OneSignal + ترتيب الرئيسية + البوب اب.
// مفتاح OneSignal لا يُحفظ هنا: يرسله جوال صاحب المتجر مع كل إرسال.
// إعدادات الرئيسية والبوب اب تُحفظ في KV (CONFIG) ويقرأها التطبيق من /config.
import PAGE from './page.html';

const APP_ID = 'da1ab6c7-deb4-458e-bfcb-6e41e150d686';
const STORE_HOST = 'bronz-sa.com';

// أقسام المتجر (نفس lib/core/catalog.dart في التطبيق)
const CATS = [
  [636667848, 'عطور رجالية'], [2011162313, 'عطور نسائية'], [886820816, 'للجنسين'],
  [1783479303, 'عطور الجسم'], [781738507, 'العود والبخور'], [952945814, 'مستحضرات التجميل'],
  [1935632650, 'أحمر الشفاه'], [666982592, 'كريم أساس'], [1723150419, 'الماسكرا'],
  [971641143, 'طلاء الأظافر'], [1590276103, 'أدوات المكياج'], [1860677013, 'العناية'],
  [2020370844, 'السيروم'], [111210193, 'عطور الشعر'], [138908188, 'عطور بديلة'],
  [769323888, 'العدسات'], [315372818, 'الرموش'],
].map(([id, name]) => ({ id, name }));

const catName = (id) => (CATS.find((c) => c.id === id) || {}).name || '';

const DEFAULT_CONFIG = {
  v: 0,
  circles: [
    { type: 'offers', label: 'العروض' },
    { type: 'latest', label: 'وصل حديثًا' },
    ...[636667848, 2011162313, 886820816, 781738507, 952945814, 1860677013, 111210193, 138908188, 769323888, 315372818]
      .map((id) => ({ type: 'category', id, label: catName(id) })),
  ],
  rails: [
    { type: 'latest', title: 'وصل حديثًا' },
    { type: 'offers', title: 'أقوى العروض 🔥' },
    ...[636667848, 2011162313, 781738507, 952945814, 1860677013]
      .map((id) => ({ type: 'category', id, title: catName(id) })),
  ],
  popup: { active: false, id: '', image: '', title: '', body: '', button: 'تسوّق الآن', open: 'offers', value: '', freq: 'once' },
};

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET, POST, OPTIONS',
  'access-control-allow-headers': 'content-type, x-key, x-pin',
};

export default {
  async fetch(req, env) {
    const url = new URL(req.url);
    if (req.method === 'OPTIONS') return new Response(null, { headers: CORS });
    try {
      if (url.pathname === '/config' && req.method === 'GET') return await getConfig(env);
      if (url.pathname === '/config' && req.method === 'POST') return await saveConfig(req, env);
      if (url.pathname === '/meta' && req.method === 'GET') return json({ cats: CATS });
      if (url.pathname === '/og' && req.method === 'GET') return await ogImage(url);
      if (url.pathname === '/send' && req.method === 'POST') return await send(req);
    } catch (e) {
      return json({ error: String(e) }, 500);
    }
    return new Response(PAGE, {
      headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' },
    });
  },
};

// ───────── الإعدادات ─────────

async function loadConfig(env) {
  const raw = await env.CONFIG.get('config');
  if (!raw) return DEFAULT_CONFIG;
  try {
    return { ...DEFAULT_CONFIG, ...JSON.parse(raw) };
  } catch {
    return DEFAULT_CONFIG;
  }
}

async function getConfig(env) {
  return json(await loadConfig(env), 200, { 'cache-control': 'public, max-age=30' });
}

async function sha(text) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode('bronz:' + text));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

/** أول رمز يُحفظ يصير هو رمز اللوحة. */
async function pinOk(env, pin) {
  pin = String(pin || '').trim();
  if (pin.length < 4) return false;
  const h = await sha(pin);
  const saved = await env.CONFIG.get('pin');
  if (!saved) {
    await env.CONFIG.put('pin', h);
    return true;
  }
  return saved === h;
}

const str = (v, max = 200) => String(v ?? '').trim().slice(0, max);
const num = (v) => {
  const n = Number(v);
  return Number.isFinite(n) && n > 0 ? n : undefined;
};
const kind = (t) => (['offers', 'latest', 'category'].includes(t) ? t : 'category');

function clean(c) {
  const circles = (Array.isArray(c.circles) ? c.circles : []).slice(0, 30)
    .map((x) => ({ type: kind(x.type), id: num(x.id), label: str(x.label, 30), image: str(x.image, 500), hidden: !!x.hidden }))
    .filter((x) => x.type !== 'category' || x.id);
  const rails = (Array.isArray(c.rails) ? c.rails : []).slice(0, 20)
    .map((x) => ({ type: kind(x.type), id: num(x.id), title: str(x.title, 40), hidden: !!x.hidden }))
    .filter((x) => x.type !== 'category' || x.id);
  const p = c.popup || {};
  const popup = {
    active: !!p.active,
    id: str(p.id, 40) || String(Date.now()),
    image: str(p.image, 500),
    title: str(p.title, 60),
    body: str(p.body, 240),
    button: str(p.button, 30) || 'تسوّق الآن',
    open: ['none', 'offers', 'latest', 'product', 'category', 'url'].includes(p.open) ? p.open : 'none',
    value: str(p.value, 500),
    freq: ['once', 'daily', 'always'].includes(p.freq) ? p.freq : 'once',
  };
  return { v: Date.now(), circles, rails, popup };
}

async function saveConfig(req, env) {
  const b = await req.json().catch(() => ({}));
  if (!(await pinOk(env, req.headers.get('x-pin')))) return json({ error: 'الرمز غير صحيح' }, 403);
  const c = clean(b);
  await env.CONFIG.put('config', JSON.stringify(c));
  return json({ ok: true, config: c });
}

// ───────── صورة منتج من رابطه في المتجر ─────────

async function ogImage(url) {
  let target;
  try {
    target = new URL(url.searchParams.get('url') || '');
  } catch {
    return json({ error: 'رابط غير صالح' }, 400);
  }
  if (!target.hostname.endsWith(STORE_HOST)) return json({ error: 'الرابط لازم يكون من متجر برونز' }, 400);
  const r = await fetch(target.toString(), { headers: { 'user-agent': 'Mozilla/5.0 (iPhone) BronzPanel' } });
  const html = await r.text();
  const meta = (p) => {
    const a = html.match(new RegExp('<meta[^>]+(?:property|name)=["\']' + p + '["\'][^>]*content=["\']([^"\']+)', 'i'));
    const b = html.match(new RegExp('<meta[^>]+content=["\']([^"\']+)["\'][^>]*(?:property|name)=["\']' + p + '["\']', 'i'));
    const m = a || b;
    return m ? m[1].replace(/&amp;/g, '&') : '';
  };
  return json({ image: meta('og:image'), title: meta('og:title') });
}

// ───────── الإشعارات ─────────

async function send(req) {
  const key = (req.headers.get('x-key') || '').trim().replace(/^Key\s+/i, '');
  if (!key) return json({ error: 'المفتاح مفقود' }, 401);

  const b = await req.json();
  const title = str(b.title, 60) || 'برونز';
  const body = str(b.body, 240);
  if (!body) return json({ error: 'اكتب نص الإشعار' }, 400);

  const msg = {
    app_id: APP_ID,
    target_channel: 'push',
    headings: { en: title, ar: title },
    contents: { en: body, ar: body },
  };
  const customer = str(b.customer, 40);
  if (customer) msg.include_aliases = { external_id: [customer] };
  else msg.included_segments = ['Total Subscriptions'];

  const v = str(b.value, 500);
  const data = {};
  if (b.open === 'order' && v) data.order_id = v;
  if (b.open === 'product' && v) data.product_id = v;
  if (b.open === 'category' && v) data.category_id = v;
  if (b.open === 'url' && v) data.url = v;
  if (b.open === 'offers') data.offers = '1';
  if (Object.keys(data).length) msg.data = data;

  const r = await fetch('https://api.onesignal.com/notifications?c=push', {
    method: 'POST',
    headers: { Authorization: 'Key ' + key, 'Content-Type': 'application/json' },
    body: JSON.stringify(msg),
  });
  const out = await r.json().catch(() => ({}));
  return json(out, r.status);
}

function json(o, s = 200, extra = {}) {
  return new Response(JSON.stringify(o), {
    status: s,
    headers: { 'content-type': 'application/json; charset=utf-8', ...CORS, ...extra },
  });
}
