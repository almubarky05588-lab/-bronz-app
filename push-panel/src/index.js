// لوحة إشعارات برونز — صفحة + إرسال عبر OneSignal.
// لا يُحفظ أي مفتاح هنا: المفتاح يرسله جوال صاحب المتجر مع كل طلب.
import PAGE from './page.html';

const APP_ID = 'da1ab6c7-deb4-458e-bfcb-6e41e150d686';

export default {
  async fetch(req) {
    const url = new URL(req.url);
    if (req.method === 'POST' && url.pathname === '/send') return send(req);
    return new Response(PAGE, {
      headers: { 'content-type': 'text/html; charset=utf-8', 'cache-control': 'no-store' },
    });
  },
};

async function send(req) {
  try {
    const key = (req.headers.get('x-key') || '').trim().replace(/^Key\s+/i, '');
    if (!key) return json({ error: 'المفتاح مفقود' }, 401);

    const b = await req.json();
    const title = String(b.title || '').trim() || 'برونز';
    const body = String(b.body || '').trim();
    if (!body) return json({ error: 'اكتب نص الإشعار' }, 400);

    const msg = {
      app_id: APP_ID,
      target_channel: 'push',
      headings: { en: title, ar: title },
      contents: { en: body, ar: body },
    };

    const customer = String(b.customer || '').trim();
    if (customer) msg.include_aliases = { external_id: [customer] };
    else msg.included_segments = ['Total Subscriptions'];

    const v = String(b.value || '').trim();
    const data = {};
    if (b.open === 'order' && v) data.order_id = v;
    if (b.open === 'product' && v) data.product_id = v;
    if (b.open === 'category' && v) data.category_id = v;
    if (b.open === 'offers') data.offers = '1';
    if (Object.keys(data).length) msg.data = data;

    const r = await fetch('https://api.onesignal.com/notifications?c=push', {
      method: 'POST',
      headers: { Authorization: 'Key ' + key, 'Content-Type': 'application/json' },
      body: JSON.stringify(msg),
    });
    const out = await r.json().catch(() => ({}));
    return json(out, r.status);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
}

function json(o, s = 200) {
  return new Response(JSON.stringify(o), {
    status: s,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}
