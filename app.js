(async () => {
  const app = document.getElementById("app");
  const modal = document.getElementById("modal");
  const modalBody = modal.querySelector(".modal-body");
  const q = document.getElementById("q");
  const cfg = window.MUSE_CONFIG || {};
  const ratios = ["3/4", "2/3", "4/5", "3/4", "1/1", "2/3", "4/5", "3/5"];

  // ---------- Supabase ----------
  const sb = cfg.SUPABASE_URL && window.supabase
    ? window.supabase.createClient(cfg.SUPABASE_URL, cfg.SUPABASE_ANON_KEY, { auth: { flowType: "pkce", detectSessionInUrl: true, persistSession: true } })
    : null;
  let session = null;

  // ---------- Per-viewer conveniences ----------
  const store = {
    get(k) { try { return JSON.parse(localStorage.getItem(k)) || []; } catch { return []; } },
    set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch {} }
  };
  let saved = new Set(store.get("muse.saved"));
  let following = new Set(store.get("muse.following"));
  let filter = "all";

  const esc = s => String(s ?? "").replace(/[&<>"]/g, m => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[m]));
  const hash = s => [...String(s)].reduce((a, ch) => (a * 31 + ch.charCodeAt(0)) >>> 0, 7);
  const slugify = s => String(s).toLowerCase().trim().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 40);

  // ---------- Data ----------
  let CHARS = [], PINS = [], C = {}, PRODUCTS = {}, TAGS = {};
  const money = (cents, cur = "USD") => cents == null ? "" : new Intl.NumberFormat("en-US", { style: "currency", currency: cur, maximumFractionDigits: 0 }).format(cents / 100);
  const isBrand = c => c?.kind === "brand";
  function useStatic() {
    CHARS = window.CHARACTERS.map(c => ({ ...c, kind: "character", avatar: `${window.IMG_BASE}/${c.id}-1.jpg` }));
    PINS = window.PINS.map(p => ({ ...p }));
    C = Object.fromEntries(CHARS.map(c => [c.id, c]));
  }
  async function loadPublic() {
    if (!sb) return useStatic();
    try {
      const [{ data: cs, error: e1 }, { data: ps, error: e2 }, { data: prs }, { data: tags }] = await Promise.all([
        sb.from("characters").select("*").eq("is_public", true).order("created_at"),
        sb.from("pins").select("id, character_id, image_url, caption, position, created_at").eq("status", "live").order("position"),
        sb.from("products").select("*").order("created_at"),
        sb.from("pin_products").select("pin_id, product_id, position").order("position")
      ]);
      if (e1 || e2 || !cs?.length) throw e1 || e2 || new Error("empty");
      const bySlugId = Object.fromEntries(cs.map(c => [c.id, c.slug]));
      PRODUCTS = Object.fromEntries((prs || []).filter(p => bySlugId[p.brand_id]).map(p => [p.id, {
        id: p.id, brand: bySlugId[p.brand_id], name: p.name, category: p.category,
        price: money(p.price_cents, p.currency), img: p.image_url, url: p.product_url
      }]));
      TAGS = {};
      (tags || []).forEach(t => { if (PRODUCTS[t.product_id]) (TAGS[t.pin_id] ||= []).push(t.product_id); });
      CHARS = cs.map(c => ({
        id: c.slug, dbId: c.id, kind: c.kind, name: c.name, handle: c.handle, tagline: c.tagline, bio: c.bio,
        tags: c.tags || [], avatar: c.avatar_url, creator: c.creator_name, creatorHandle: c.creator_handle,
        followers: c.followers_label, following: String(40 + (hash(c.slug) % 300))
      }));
      PINS = ps.filter(p => bySlugId[p.character_id]).map(p => ({
        id: p.id, character: bySlugId[p.character_id], src: p.image_url, caption: p.caption,
        saves: 800 + (hash(p.id) % 9000), created: p.created_at
      }));
    } catch (e) {
      console.warn("Falling back to static data", e);
      useStatic();
    }
    C = Object.fromEntries(CHARS.map(c => [c.id, c]));
  }

  // Interleave characters so the feed mixes creators.
  function feedOrder() {
    const lists = CHARS.filter(c => !isBrand(c)).map(c => PINS.filter(p => p.character === c.id));
    const out = [], max = Math.max(0, ...lists.map(l => l.length));
    for (let i = 0; i < max; i++) lists.forEach(l => l[i] && out.push(l[i]));
    return out;
  }

  // ---------- Public views ----------
  const bagIcon = `<svg viewBox="0 0 24 24" width="13" height="13" aria-hidden="true"><path d="M6 8h12l-1 12H7L6 8zM9 8V6a3 3 0 0 1 6 0v2" fill="none" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round"/></svg>`;

  function pinHTML(p, i) {
    const c = C[p.character];
    const n = (TAGS[p.id] || []).length;
    return `<article class="pin" data-pin="${p.id}" tabindex="0">
      <div class="pin-media" style="aspect-ratio:${ratios[i % ratios.length]}">
        <img src="${esc(p.src)}" alt="${esc(c.name)} — ${esc(p.caption)}" loading="lazy" onload="this.classList.add('ready')">
        ${n ? `<span class="look-badge">${bagIcon}${n}</span>` : ""}
        <div class="pin-hover">
          <button class="save ${saved.has(p.id) ? "on" : ""}" data-save="${p.id}">${saved.has(p.id) ? "Saved" : "Save"}</button>
          <span class="cap">${esc(p.caption)}</span>
        </div>
      </div>
      <a class="pin-meta" href="#/c/${c.id}">
        <img class="av" src="${esc(c.avatar)}" alt="">
        <span class="name">${esc(c.name)}</span>
        <span class="ai">${c.kind === "brand" ? "AI brand" : "AI"}</span>
      </a>
    </article>`;
  }

  function gridHTML(pins, max = 5, extra = "") {
    const w = window.innerWidth;
    const n = Math.min(max, w > 1500 ? 6 : w > 1180 ? 5 : w > 900 ? 4 : w > 760 ? 3 : 2);
    const cols = Array.from({ length: n }, () => []);
    pins.forEach((p, i) => cols[i % n].push(pinHTML(p, i)));
    return `<section class="grid ${extra}">${cols.map(c => `<div class="col">${c.join("")}</div>`).join("")}</section>`;
  }

  function matches(p) {
    const term = q.value.trim().toLowerCase();
    if (!term) return true;
    const c = C[p.character];
    return [c.name, c.handle, c.creator, c.tagline, p.caption, ...c.tags].join(" ").toLowerCase().includes(term);
  }

  function home() {
    const pins = feedOrder().filter(p => (filter === "all" || p.character === filter) && matches(p));
    app.innerHTML = `
      <section class="hero">
        <div class="eyebrow">For AI characters &amp; the humans behind them</div>
        <h1>Collect the <em>muses</em><br>of a new medium.</h1>
        <p>Follow AI characters and brands. See every frame their creators publish, all in one place.</p>
      </section>
      <div class="chips">
        <button class="chip ${filter === "all" ? "on" : ""}" data-filter="all">All</button>
        ${CHARS.filter(c => !isBrand(c)).map(c => `<button class="chip ${filter === c.id ? "on" : ""}" data-filter="${c.id}">${esc(c.name)}</button>`).join("")}
      </div>
      ${pins.length ? gridHTML(pins) : `<p class="empty">Nothing matches “${esc(q.value)}”.</p>`}
      <footer class="foot">Muse · MVP preview</footer>`;
  }

  function characters() {
    app.innerHTML = `
      <section class="page-head">
        <div class="eyebrow">Directory</div>
        <h1>Characters &amp; brands</h1>
      </section>
      <section class="cards">
        ${CHARS.map(c => {
          const ps = isBrand(c)
            ? Object.values(PRODUCTS).filter(p => p.brand === c.id).map(p => ({ src: p.img }))
            : PINS.filter(p => p.character === c.id);
          return `<a class="card" href="#/c/${c.id}">
            <div class="card-cover">${[0, 1, 2].map(i => ps[i] ? `<img src="${esc(ps[i].src)}" alt="">` : `<div class="ph"></div>`).join("")}</div>
            <div class="card-body">
              <img class="av" src="${esc(c.avatar)}" alt="">
              <div><h3>${esc(c.name)}</h3><p>${c.kind === "brand" ? "AI brand" : "AI character"} · by ${esc(c.creator)}</p></div>
              <span class="count">${esc(c.followers)}</span>
            </div>
          </a>`;
        }).join("")}
      </section>`;
  }

  function profile(id, tab = "pins") {
    const c = C[id];
    if (!c) return home();
    if (isBrand(c)) return brandProfile(c, tab);
    const all = PINS.filter(p => p.character === id);
    const pins = tab === "saved" ? PINS.filter(p => saved.has(p.id)) : all;
    const f = following.has(id);
    app.innerHTML = `
      <section class="profile">
        <img class="av-xl" src="${esc(c.avatar)}" alt="${esc(c.name)}">
        <h1>${esc(c.name)}</h1>
        <div class="handle">${esc(c.handle)}</div>
        <div class="badge">${c.kind === "brand" ? "AI brand" : "AI character"} · created by <b>${esc(c.creator)}</b> ${esc(c.creatorHandle)}</div>
        <p class="bio">${esc(c.bio)}</p>
        <div class="stats"><span><b>${esc(c.followers)}</b> followers</span><span><b>${esc(c.following)}</b> following</span><span><b>${all.length}</b> pins</span></div>
        <div class="actions">
          <button class="btn ${f ? "btn-line on" : "btn-dark"}" data-follow="${id}">${f ? "Following" : "Follow"}</button>
          <button class="btn btn-line" data-share>Share</button>
        </div>
        <div class="tags">${c.tags.map(t => `<span class="tag">${esc(t)}</span>`).join("")}</div>
      </section>
      <nav class="tabs">
        <a class="tab ${tab === "pins" ? "on" : ""}" href="#/c/${id}">Created</a>
        <a class="tab ${tab === "saved" ? "on" : ""}" href="#/c/${id}/saved">Saved</a>
      </nav>
      ${pins.length ? gridHTML(pins, 3, "profile-grid") : `<p class="empty">${tab === "saved" ? "No saved pins yet." : "No live pins yet."}</p>`}`;
  }

  function productCard(pr) {
    const b = C[pr.brand];
    return `<a class="product" href="#/c/${pr.brand}">
      <div class="product-img"><img src="${esc(pr.img)}" alt="${esc(pr.name)}" loading="lazy"></div>
      <div class="product-cat">${bagIcon}${esc(pr.category)}</div>
      <div class="product-brand">${esc(b?.name)}</div>
      <div class="product-name">${esc(pr.name)}</div>
      <div class="product-price">${esc(pr.price)}</div>
    </a>`;
  }

  function followRow(c, label) {
    const f = following.has(c.id);
    return `<div class="who-row">
      <a href="#/c/${c.id}"><img class="av" src="${esc(c.avatar)}" alt=""></a>
      <a href="#/c/${c.id}" class="grow"><div class="n">${esc(c.name)}</div><div class="h">${esc(label)}</div></a>
      <button class="btn ${f ? "btn-line on" : "btn-dark"}" data-follow="${c.id}">${f ? "Following" : "Follow"}</button>
    </div>`;
  }

  function brandProfile(c, tab) {
    const products = Object.values(PRODUCTS).filter(p => p.brand === c.id);
    const ids = new Set(products.map(p => p.id));
    const worn = PINS.filter(p => (TAGS[p.id] || []).some(x => ids.has(x)));
    const f = following.has(c.id);
    const showWorn = tab === "saved";
    app.innerHTML = `
      <section class="profile">
        <img class="av-xl" src="${esc(c.avatar)}" alt="${esc(c.name)}">
        <h1>${esc(c.name)}</h1>
        <div class="handle">${esc(c.handle)}</div>
        <div class="badge">AI brand · created by <b>${esc(c.creator)}</b> ${esc(c.creatorHandle)}</div>
        <p class="bio">${esc(c.bio)}</p>
        <div class="stats"><span><b>${esc(c.followers)}</b> followers</span><span><b>${products.length}</b> products</span><span><b>${worn.length}</b> looks</span></div>
        <div class="actions">
          <button class="btn ${f ? "btn-line on" : "btn-dark"}" data-follow="${c.id}">${f ? "Following" : "Follow"}</button>
          <button class="btn btn-line" data-share>Share</button>
        </div>
        <div class="tags">${c.tags.map(t => `<span class="tag">${esc(t)}</span>`).join("")}</div>
      </section>
      <nav class="tabs">
        <a class="tab ${!showWorn ? "on" : ""}" href="#/c/${c.id}">Products</a>
        <a class="tab ${showWorn ? "on" : ""}" href="#/c/${c.id}/saved">Worn by</a>
      </nav>
      ${showWorn
        ? (worn.length ? gridHTML(worn, 3, "profile-grid") : `<p class="empty">No looks yet.</p>`)
        : (products.length ? `<section class="product-grid wide">${products.map(productCard).join("")}</section>` : `<p class="empty">No products yet.</p>`)}`;
  }

  function openPin(id) {
    const p = PINS.find(x => x.id === id);
    if (!p) return;
    const c = C[p.character];
    const more = PINS.filter(x => x.character === c.id && x.id !== id).slice(0, 6);
    const f = following.has(c.id);
    const look = (TAGS[id] || []).map(x => PRODUCTS[x]).filter(Boolean);
    const brands = [...new Set(look.map(x => x.brand))].map(b => C[b]).filter(Boolean);
    modalBody.innerHTML = `
      <div class="modal-img"><img src="${esc(p.src)}" alt="${esc(p.caption)}"></div>
      <div class="modal-side">
        <div class="modal-top">
          <button class="save ${saved.has(id) ? "on" : ""}" data-save="${id}" style="border:1px solid var(--line)">${saved.has(id) ? "Saved" : "Save"}</button>
          <button class="icon-btn" data-close aria-label="Close"><svg viewBox="0 0 24 24" width="18" height="18"><path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg></button>
        </div>
        <h2>${esc(p.caption || c.name)}</h2>
        <p class="sub">${esc(c.tagline)} · ${p.saves.toLocaleString()} saves</p>
        ${look.length ? `
        <div class="more-label shop-label">Shop the look</div>
        <div class="product-grid">${look.map(productCard).join("")}</div>
        <div class="who-list">
          ${brands.map(b => followRow(b, "Brand")).join("")}
          ${followRow(c, `AI character · by ${c.creator}`)}
        </div>` : `
        <div class="who">
          <a href="#/c/${c.id}"><img class="av" src="${esc(c.avatar)}" alt=""></a>
          <a href="#/c/${c.id}"><div class="n">${esc(c.name)}</div><div class="h">AI · by ${esc(c.creator)}</div></a>
          <button class="btn ${f ? "btn-line on" : "btn-dark"}" data-follow="${c.id}">${f ? "Following" : "Follow"}</button>
        </div>`}
        ${more.length ? `<div class="more-label">More from ${esc(c.name)}</div>
        <div class="more">${more.map(m => `<img src="${esc(m.src)}" alt="${esc(m.caption)}" data-pin="${m.id}">`).join("")}</div>` : ""}
      </div>`;
    modal.hidden = false;
    document.body.style.overflow = "hidden";
  }
  function closePin() { modal.hidden = true; document.body.style.overflow = ""; }

  // ---------- Creator studio ----------
  const notReady = `<section class="page-head"><div class="eyebrow">Studio</div><h1>Creator studio</h1><p class="lead">The backend isn't connected yet.</p></section>`;

  function signInView(msg = "") {
    app.innerHTML = `
      <section class="auth">
        <div class="eyebrow">Creator studio</div>
        <h1>Build your <em>muses</em>.</h1>
        <p class="lead">Sign in to create AI characters and brands, upload images and choose what goes live.</p>
        <form id="signin" class="form narrow">
          <label>Email<input type="email" name="email" required placeholder="you@studio.com" autocomplete="email"></label>
          <button class="btn btn-dark" type="submit">Email me a sign-in link</button>
          <p class="note" id="signin-msg">${esc(msg)}</p>
        </form>
      </section>`;
  }

  async function myCharacters() {
    const { data, error } = await sb.from("characters").select("*").eq("creator_id", session.user.id).order("created_at", { ascending: false });
    if (error) throw error;
    return data;
  }

  async function studioHome() {
    app.innerHTML = `<p class="empty">Loading your studio…</p>`;
    let mine = [];
    try { mine = await myCharacters(); } catch (e) { app.innerHTML = `<p class="empty">Couldn't load your studio: ${esc(e.message)}</p>`; return; }
    const ids = mine.map(c => c.id);
    let counts = {};
    if (ids.length) {
      const { data } = await sb.from("pins").select("character_id, status").in("character_id", ids);
      (data || []).forEach(p => { const k = counts[p.character_id] ||= { live: 0, draft: 0 }; k[p.status]++; });
    }
    app.innerHTML = `
      <section class="studio-head">
        <div>
          <div class="eyebrow">Creator studio</div>
          <h1>Your muses</h1>
          <p class="lead">${esc(session.user.email)} · <button class="link" data-signout>Sign out</button></p>
        </div>
        <a class="btn btn-dark" href="#/studio/new">New character or brand</a>
      </section>
      ${mine.length ? `<section class="studio-list">
        ${mine.map(c => {
          const k = counts[c.id] || { live: 0, draft: 0 };
          return `<a class="studio-row" href="#/studio/${esc(c.slug)}">
            ${c.avatar_url ? `<img class="av" src="${esc(c.avatar_url)}" alt="">` : `<div class="av ph"></div>`}
            <div class="grow"><div class="n">${esc(c.name)}</div><div class="h">${c.kind === "brand" ? "Brand" : "Character"} · ${esc(c.handle)}</div></div>
            <span class="pill">${k.live} live</span><span class="pill muted">${k.draft} draft</span>
            <span class="pill ${c.is_public ? "" : "muted"}">${c.is_public ? "Public" : "Hidden"}</span>
          </a>`;
        }).join("")}
      </section>` : `<div class="empty-box"><p>You haven't created anything yet.</p><a class="btn btn-dark" href="#/studio/new">Create your first character</a></div>`}`;
  }

  function newCharacterView() {
    app.innerHTML = `
      <section class="page-head"><a class="back" href="#/studio">← Studio</a><h1>New character or brand</h1></section>
      <form id="newchar" class="form">
        <div class="seg">
          <label><input type="radio" name="kind" value="character" checked><span>Character</span></label>
          <label><input type="radio" name="kind" value="brand"><span>Brand</span></label>
        </div>
        <label>Name<input name="name" required maxlength="40" placeholder="Nila"></label>
        <label>Handle<input name="handle" maxlength="40" placeholder="@nila.noir"></label>
        <label>Tagline<input name="tagline" maxlength="80" placeholder="Black dress, long gloves, one spotlight."></label>
        <label>Bio<textarea name="bio" rows="3" maxlength="300"></textarea></label>
        <label>Tags <span class="hint">comma separated</span><input name="tags" placeholder="Studio, Noir, Couture"></label>
        <label>Your creator name<input name="creator_name" maxlength="40" placeholder="Your name"></label>
        <label>Profile image<input type="file" name="avatar" accept="image/*"></label>
        <button class="btn btn-dark" type="submit">Create</button>
        <p class="note" id="newchar-msg"></p>
      </form>`;
  }

  async function manageView(slug) {
    app.innerHTML = `<p class="empty">Loading…</p>`;
    const { data: c } = await sb.from("characters").select("*").eq("slug", slug).eq("creator_id", session.user.id).maybeSingle();
    if (!c) { app.innerHTML = `<p class="empty">Not found in your studio. <a href="#/studio">Back</a></p>`; return; }
    const { data: pins } = await sb.from("pins").select("*").eq("character_id", c.id).order("position").order("created_at");
    const live = (pins || []).filter(p => p.status === "live").length;
    app.innerHTML = `
      <section class="studio-head">
        <div>
          <a class="back" href="#/studio">← Studio</a>
          <h1>${esc(c.name)}</h1>
          <p class="lead">${c.kind === "brand" ? "Brand" : "Character"} · ${esc(c.handle)} · ${live} live of ${(pins || []).length}</p>
        </div>
        <div class="row">
          <button class="btn btn-line" data-toggle-public="${c.id}" data-val="${c.is_public ? 0 : 1}">${c.is_public ? "Hide profile" : "Make profile public"}</button>
          <a class="btn btn-line" href="#/c/${esc(c.slug)}">View public profile</a>
        </div>
      </section>
      <label class="drop" id="drop">
        <input type="file" id="files" accept="image/*" multiple hidden>
        <strong>Upload images</strong>
        <span>Drop files here or click. They start as drafts; you choose what goes live.</span>
      </label>
      <p class="note" id="up-msg"></p>
      ${(pins || []).length ? `<section class="manage-grid">
        ${pins.map(p => `<div class="mcard ${p.status}">
          <div class="mimg"><img src="${esc(p.image_url)}" alt="" loading="lazy"><span class="status">${p.status === "live" ? "Live" : "Draft"}</span></div>
          <input class="cap-in" data-cap="${p.id}" value="${esc(p.caption)}" placeholder="Caption">
          <div class="row">
            <button class="btn ${p.status === "live" ? "btn-line" : "btn-dark"} sm" data-status="${p.id}" data-val="${p.status === "live" ? "draft" : "live"}">${p.status === "live" ? "Unpublish" : "Go live"}</button>
            <button class="btn btn-line sm" data-avatar="${c.id}" data-url="${esc(p.image_url)}">Set as profile</button>
            <button class="icon-btn" data-del="${p.id}" aria-label="Delete image"><svg viewBox="0 0 24 24" width="16" height="16"><path d="M5 7h14M10 11v6M14 11v6M6 7l1 12h10l1-12M9 7V4h6v3" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg></button>
          </div>
        </div>`).join("")}
      </section>` : ""}`;
    app.dataset.char = c.id;
    app.dataset.slug = c.slug;
  }

  // Shrink big photos in the browser before upload (heavy images are the slow part).
  async function shrink(file, max = 2000) {
    if (!/^image\/(jpeg|png|webp)$/.test(file.type)) return file;
    try {
      const bmp = await createImageBitmap(file);
      const scale = Math.min(1, max / Math.max(bmp.width, bmp.height));
      if (scale === 1 && file.size < 1.5e6) return file;
      const cv = document.createElement("canvas");
      cv.width = Math.round(bmp.width * scale); cv.height = Math.round(bmp.height * scale);
      cv.getContext("2d").drawImage(bmp, 0, 0, cv.width, cv.height);
      const blob = await new Promise(r => cv.toBlob(r, "image/jpeg", 0.86));
      return blob || file;
    } catch { return file; }
  }

  async function uploadFile(file) {
    const body = await shrink(file);
    const res = await fetch(`${cfg.UPLOAD_URL}/upload`, {
      method: "POST",
      headers: { Authorization: `Bearer ${session.access_token}`, "Content-Type": body.type || file.type },
      body
    });
    const out = await res.json().catch(() => ({}));
    if (!res.ok) throw new Error(out.error || `Upload failed (${res.status})`);
    return out.url;
  }

  async function uploadPins(files) {
    const msg = document.getElementById("up-msg");
    const charId = app.dataset.char;
    let done = 0;
    for (const f of files) {
      msg.textContent = `Uploading ${done + 1} of ${files.length}…`;
      try {
        const url = await uploadFile(f);
        const { error } = await sb.from("pins").insert({ character_id: charId, creator_id: session.user.id, image_url: url, caption: "", status: "draft", position: Date.now() % 1e9 });
        if (error) throw error;
        done++;
      } catch (e) { msg.textContent = `${f.name}: ${e.message}`; return; }
    }
    await manageView(app.dataset.slug);
    document.getElementById("up-msg").textContent = `${done} image${done === 1 ? "" : "s"} uploaded as drafts.`;
  }

  async function studio(sub) {
    if (!sb || !cfg.UPLOAD_URL) { app.innerHTML = notReady; return; }
    if (!session) return signInView();
    if (sub === "new") return newCharacterView();
    if (sub) return manageView(sub);
    return studioHome();
  }

  // ---------- Router ----------
  async function route() {
    closePin();
    const [, page, id, tab] = (location.hash || "#/").split("/");
    document.querySelectorAll("[data-nav]").forEach(a => {
      const n = a.dataset.nav;
      a.classList.toggle("active", n === "studio" ? page === "studio" : n === "characters" ? (page === "characters" || page === "c") : !page || page === "");
    });
    if (page === "studio") await studio(id);
    else if (page === "c") profile(id, tab === "saved" ? "saved" : "pins");
    else if (page === "characters") characters();
    else home();
    window.scrollTo(0, 0);
  }

  // ---------- Events ----------
  document.addEventListener("click", async e => {
    const t = e.target;
    const save = t.closest("[data-save]");
    if (save) {
      e.stopPropagation();
      const id = save.dataset.save;
      saved.has(id) ? saved.delete(id) : saved.add(id);
      store.set("muse.saved", [...saved]);
      document.querySelectorAll(`[data-save="${id}"]`).forEach(b => { b.classList.toggle("on", saved.has(id)); b.textContent = saved.has(id) ? "Saved" : "Save"; });
      return;
    }
    const fol = t.closest("[data-follow]");
    if (fol) {
      const id = fol.dataset.follow;
      following.has(id) ? following.delete(id) : following.add(id);
      store.set("muse.following", [...following]);
      document.querySelectorAll(`[data-follow="${id}"]`).forEach(b => { const on = following.has(id); b.className = `btn ${on ? "btn-line on" : "btn-dark"}`; b.textContent = on ? "Following" : "Follow"; });
      return;
    }
    if (t.closest("[data-share]")) {
      navigator.clipboard?.writeText(location.href).catch(() => {});
      t.closest("[data-share]").textContent = "Link copied";
      return;
    }
    if (t.closest("[data-signout]")) { await sb.auth.signOut(); session = null; location.hash = "#/studio"; route(); return; }
    const st = t.closest("[data-status]");
    if (st) {
      st.disabled = true;
      await sb.from("pins").update({ status: st.dataset.val }).eq("id", st.dataset.status);
      await Promise.all([manageView(app.dataset.slug), loadPublic()]);
      return;
    }
    const del = t.closest("[data-del]");
    if (del) {
      if (!confirm("Delete this image?")) return;
      await sb.from("pins").delete().eq("id", del.dataset.del);
      await Promise.all([manageView(app.dataset.slug), loadPublic()]);
      return;
    }
    const av = t.closest("[data-avatar]");
    if (av) {
      await sb.from("characters").update({ avatar_url: av.dataset.url }).eq("id", av.dataset.avatar);
      av.textContent = "Profile set";
      loadPublic();
      return;
    }
    const tp = t.closest("[data-toggle-public]");
    if (tp) {
      await sb.from("characters").update({ is_public: tp.dataset.val === "1" }).eq("id", tp.dataset.togglePublic);
      await Promise.all([manageView(app.dataset.slug), loadPublic()]);
      return;
    }
    const chip = t.closest("[data-filter]");
    if (chip) { filter = chip.dataset.filter; home(); return; }
    if (t.closest("[data-close]")) { closePin(); return; }
    if (t.closest(".pin-meta")) return;
    const pin = t.closest("[data-pin]");
    if (pin) openPin(pin.dataset.pin);
  });

  document.addEventListener("change", async e => {
    if (e.target.id === "files" && e.target.files.length) uploadPins([...e.target.files]);
    const cap = e.target.closest?.("[data-cap]");
    if (cap) { await sb.from("pins").update({ caption: cap.value.slice(0, 120) }).eq("id", cap.dataset.cap); loadPublic(); }
  });

  document.addEventListener("dragover", e => { const d = e.target.closest?.("#drop"); if (d) { e.preventDefault(); d.classList.add("over"); } });
  document.addEventListener("dragleave", e => { const d = e.target.closest?.("#drop"); if (d) d.classList.remove("over"); });
  document.addEventListener("drop", e => {
    const d = e.target.closest?.("#drop");
    if (!d) return;
    e.preventDefault(); d.classList.remove("over");
    const files = [...e.dataTransfer.files].filter(f => f.type.startsWith("image/"));
    if (files.length) uploadPins(files);
  });

  document.addEventListener("submit", async e => {
    e.preventDefault();
    const f = e.target;
    if (f.id === "signin") {
      const email = f.email.value.trim();
      const msg = document.getElementById("signin-msg");
      if (!email) { msg.textContent = "Enter your email first."; return; }
      f.querySelector("button").disabled = true;
      const { error } = await sb.auth.signInWithOtp({ email, options: { emailRedirectTo: `${location.origin}${location.pathname}?next=studio` } });
      msg.textContent = error ? error.message : `Check ${email} for your sign-in link.`;
      f.querySelector("button").disabled = false;
    }
    if (f.id === "newchar") {
      const msg = document.getElementById("newchar-msg");
      const name = f.name.value.trim();
      if (!name) { msg.textContent = "Give it a name."; return; }
      f.querySelector("button[type=submit]").disabled = true;
      try {
        let avatar_url = null;
        if (f.avatar.files[0]) { msg.textContent = "Uploading profile image…"; avatar_url = await uploadFile(f.avatar.files[0]); }
        const slug = `${slugify(name) || "muse"}-${Math.random().toString(36).slice(2, 6)}`;
        const handle = f.handle.value.trim() || `@${slugify(name)}`;
        const { error } = await sb.from("characters").insert({
          slug, creator_id: session.user.id, kind: f.kind.value, name, handle: handle.startsWith("@") ? handle : `@${handle}`,
          tagline: f.tagline.value.trim(), bio: f.bio.value.trim(),
          tags: f.tags.value.split(",").map(s => s.trim()).filter(Boolean).slice(0, 6),
          avatar_url, creator_name: f.creator_name.value.trim() || session.user.email.split("@")[0],
          creator_handle: `@${slugify(f.creator_name.value || session.user.email.split("@")[0])}`, followers_label: "0"
        });
        if (error) throw error;
        await loadPublic();
        location.hash = `#/studio/${slug}`;
      } catch (err) {
        msg.textContent = err.message;
        f.querySelector("button[type=submit]").disabled = false;
      }
    }
  });

  document.addEventListener("keydown", e => {
    if (e.key === "Escape") closePin();
    if (e.key === "Enter" && e.target.matches(".pin")) openPin(e.target.dataset.pin);
  });
  q.addEventListener("input", () => { if (location.hash && location.hash !== "#/") location.hash = "#/"; else home(); });
  window.addEventListener("hashchange", route);
  let lastW = window.innerWidth, rt;
  window.addEventListener("resize", () => {
    clearTimeout(rt);
    rt = setTimeout(() => {
      if (Math.abs(window.innerWidth - lastW) < 40 || !modal.hidden || (location.hash || "").startsWith("#/studio")) return;
      lastW = window.innerWidth;
      const y = window.scrollY; route(); window.scrollTo(0, y);
    }, 150);
  });

  // ---------- Boot ----------
  if (sb) {
    const { data } = await sb.auth.getSession();
    session = data.session;
    sb.auth.onAuthStateChange((_evt, s) => {
      const was = !!session;
      session = s;
      if (!was && s && (location.hash || "").startsWith("#/studio")) route();
    });
    const params = new URLSearchParams(location.search);
    if (params.get("next") === "studio") history.replaceState(null, "", `${location.pathname}#/studio`);
  }
  await loadPublic();
  route();
})();
