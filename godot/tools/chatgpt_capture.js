// ChatGPT sohbetindeki görselleri tam çözünürlükte ekrana getirir (matte yakalama için).
// Kullanım: javascript_tool ile bu dosyanın içeriğini çalıştır, sonra:
//   await __ims()                -> [{i, id, w, h}]
//   await __show(i, x, y, bg)    -> görseli doğal boyutta, (x,y) kaydırmasıyla, bg zeminde gösterir
//   __hide()
window.__ims = async () => {
  const s = await (await fetch('/api/auth/session')).json();
  window.__tok = s.accessToken;
  const cid = location.pathname.split('/c/')[1];
  const c = await (await fetch('/backend-api/conversation/' + cid, {
    headers: { Authorization: 'Bearer ' + __tok } })).json();
  const out = [];
  for (const n of Object.values(c.mapping)) {
    const parts = n.message?.content?.parts || [];
    for (const p of parts) {
      if (p && p.asset_pointer && n.message.author.role !== 'user') {
        out.push({ id: p.asset_pointer.replace(/^.*:\/\//, ''), w: p.width, h: p.height,
                   t: n.message.create_time });
      }
    }
  }
  out.sort((a, b) => a.t - b.t);
  window.__list = out.map((o, i) => ({ i, ...o }));
  return __list.map(o => [o.i, o.id, o.w, o.h]);
};
window.__show = async (i, x, y, bg) => {
  const o = __list[i];
  if (!window.__blobs) window.__blobs = {};
  if (!__blobs[o.id]) {
    const r = await (await fetch('/backend-api/files/download/' + o.id + '?post_id=&inline=false', {
      headers: { Authorization: 'Bearer ' + __tok } })).json();
    const b = await (await fetch(r.download_url)).blob();
    __blobs[o.id] = URL.createObjectURL(b);
  }
  let d = document.getElementById('zzcap');
  if (!d) {
    d = document.createElement('div');
    d.id = 'zzcap';
    d.style.cssText = 'position:fixed;inset:0;z-index:2147483647;overflow:hidden';
    const im = document.createElement('img');
    im.style.cssText = 'position:absolute;image-rendering:pixelated;max-width:none';
    d.appendChild(im);
    document.body.appendChild(d);
  }
  d.style.background = bg;
  const im = d.firstChild;
  const dpr = window.devicePixelRatio || 1;
  im.src = __blobs[o.id];
  await im.decode();
  im.style.width = (im.naturalWidth / dpr) + 'px';
  im.style.left = (-x / dpr) + 'px';
  im.style.top = (-y / dpr) + 'px';
  return [im.naturalWidth, im.naturalHeight, dpr, innerWidth, innerHeight];
};
window.__hide = () => document.getElementById('zzcap')?.remove();
'ok';
