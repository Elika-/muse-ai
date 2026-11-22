(() => {
  const app = document.getElementById("app");
  const modal = document.getElementById("modal");
  const modalBody = modal.querySelector(".modal-body");
  const q = document.getElementById("q");
  const C = Object.fromEntries(window.CHARACTERS.map(c => [c.id, c]));
  const ratios = ["3/4", "2/3", "4/5", "3/4", "1/1", "2/3", "4/5", "3/5"];

  // Per-viewer saves/follows (convenience only).
  const store = {
    get(k) { try { return JSON.parse(localStorage.getItem(k)) || []; } catch { return []; } },
    set(k, v) { try { localStorage.setItem(k, JSON.stringify(v)); } catch {} }
  };
  let saved = new Set(store.get("muse.saved"));
  let following = new Set(store.get("muse.following"));
  let filter = "all";

  const esc = s => String(s).replace(/[&<>"]/g, m => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[m]));
  const avatar = c => `${window.IMG_BASE}/${c.id}-1.jpg`;

  // Stable interleaved order so characters mix on the home feed.
  const feedOrder = (() => {
    const out = [], byC = window.CHARACTERS.map(c => window.PINS.filter(p => p.character === c.id));
    for (let i = 0; i < 6; i++) byC.forEach(list => list[i] && out.push(list[i]));
    return out;
  })();

  function pinHTML(p, i) {
    const c = C[p.character];
    return `<article class="pin" data-pin="${p.id}" tabindex="0">
      <div class="pin-media" style="aspect-ratio:${ratios[i % ratios.length]}">
        <img src="${p.src}" alt="${esc(c.name)} — ${esc(p.caption)}" loading="lazy" onload="this.classList.add('ready')">
        <div class="pin-hover">
          <button class="save ${saved.has(p.id) ? "on" : ""}" data-save="${p.id}">${saved.has(p.id) ? "Saved" : "Save"}</button>
          <span class="cap">${esc(p.caption)}</span>
        </div>
      </div>
      <a class="pin-meta" href="#/c/${c.id}">
        <img class="av" src="${avatar(c)}" alt="">
        <span class="name">${esc(c.name)}</span>
        <span class="ai">AI</span>
      </a>
    </article>`;
  }

  // Round-robin masonry: left-to-right reading order, like a pinboard.
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
    const pins = feedOrder.filter(p => (filter === "all" || p.character === filter) && matches(p));
    app.innerHTML = `
      <section class="hero">
        <div class="eyebrow">For AI characters &amp; the humans behind them</div>
        <h1>Collect the <em>muses</em><br>of a new medium.</h1>
        <p>Follow AI characters and brands. See every frame their creators publish, all in one place.</p>
      </section>
      <div class="chips">
        <button class="chip ${filter === "all" ? "on" : ""}" data-filter="all">All</button>
        ${window.CHARACTERS.map(c => `<button class="chip ${filter === c.id ? "on" : ""}" data-filter="${c.id}">${esc(c.name)}</button>`).join("")}
      </div>
      ${pins.length ? gridHTML(pins) : `<p class="empty">Nothing matches “${esc(q.value)}”.</p>`}
      <footer class="foot">Muse · MVP preview</footer>`;
  }

  function characters() {
    app.innerHTML = `
      <section class="page-head">
        <div class="eyebrow">Directory</div>
        <h1>Characters</h1>
      </section>
      <section class="cards">
        ${window.CHARACTERS.map(c => `
          <a class="card" href="#/c/${c.id}">
            <div class="card-cover">
              <img src="${window.IMG_BASE}/${c.id}-1.jpg" alt="">
              <img src="${window.IMG_BASE}/${c.id}-2.jpg" alt="">
              <img src="${window.IMG_BASE}/${c.id}-3.jpg" alt="">
            </div>
            <div class="card-body">
              <img class="av" src="${avatar(c)}" alt="">
              <div><h3>${esc(c.name)}</h3><p>by ${esc(c.creator)}</p></div>
              <span class="count">${c.followers}</span>
            </div>
          </a>`).join("")}
      </section>`;
  }

  function profile(id, tab = "pins") {
    const c = C[id];
    if (!c) return home();
    const all = window.PINS.filter(p => p.character === id);
    const pins = tab === "saved" ? window.PINS.filter(p => saved.has(p.id)) : all;
    const f = following.has(id);
    app.innerHTML = `
      <section class="profile">
        <img class="av-xl" src="${avatar(c)}" alt="${esc(c.name)}">
        <h1>${esc(c.name)}</h1>
        <div class="handle">${esc(c.handle)}</div>
        <div class="badge">AI character · created by <b>${esc(c.creator)}</b> ${esc(c.creatorHandle)}</div>
        <p class="bio">${esc(c.bio)}</p>
        <div class="stats"><span><b>${c.followers}</b> followers</span><span><b>${c.following}</b> following</span><span><b>${all.length}</b> pins</span></div>
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
      ${pins.length ? gridHTML(pins, 3, "profile-grid") : `<p class="empty">No saved pins yet.</p>`}`;
  }

  function openPin(id) {
    const p = window.PINS.find(x => x.id === id);
    if (!p) return;
    const c = C[p.character];
    const more = window.PINS.filter(x => x.character === c.id && x.id !== id).slice(0, 6);
    const f = following.has(c.id);
    modalBody.innerHTML = `
      <div class="modal-img"><img src="${p.src}" alt="${esc(p.caption)}"></div>
      <div class="modal-side">
        <div class="modal-top">
          <button class="save ${saved.has(id) ? "on" : ""}" data-save="${id}" style="border:1px solid var(--line)">${saved.has(id) ? "Saved" : "Save"}</button>
          <button class="icon-btn" data-close aria-label="Close"><svg viewBox="0 0 24 24" width="18" height="18"><path d="M6 6l12 12M18 6L6 18" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg></button>
        </div>
        <h2>${esc(p.caption)}</h2>
        <p class="sub">${esc(c.tagline)} · ${p.saves.toLocaleString()} saves</p>
        <div class="who">
          <a href="#/c/${c.id}"><img class="av" src="${avatar(c)}" alt=""></a>
          <a href="#/c/${c.id}"><div class="n">${esc(c.name)}</div><div class="h">AI · by ${esc(c.creator)}</div></a>
          <button class="btn ${f ? "btn-line on" : "btn-dark"}" data-follow="${c.id}">${f ? "Following" : "Follow"}</button>
        </div>
        <div class="more-label">More from ${esc(c.name)}</div>
        <div class="more">${more.map(m => `<img src="${m.src}" alt="${esc(m.caption)}" data-pin="${m.id}">`).join("")}</div>
      </div>`;
    modal.hidden = false;
    document.body.style.overflow = "hidden";
  }
  function closePin() { modal.hidden = true; document.body.style.overflow = ""; }

  function route() {
    closePin();
    const [, page, id, tab] = (location.hash || "#/").split("/");
    document.querySelectorAll("[data-nav]").forEach(a => a.classList.toggle("active", (a.dataset.nav === "characters") === (page === "characters" || page === "c")));
    if (page === "c") profile(id, tab === "saved" ? "saved" : "pins");
    else if (page === "characters") characters();
    else home();
    window.scrollTo(0, 0);
  }

  document.addEventListener("click", e => {
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
    const chip = t.closest("[data-filter]");
    if (chip) { filter = chip.dataset.filter; home(); return; }
    if (t.closest("[data-close]")) { closePin(); return; }
    if (t.closest(".pin-meta")) return;
    const pin = t.closest("[data-pin]");
    if (pin) openPin(pin.dataset.pin);
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
      if (Math.abs(window.innerWidth - lastW) < 40 || !modal.hidden) return;
      lastW = window.innerWidth;
      const y = window.scrollY; route(); window.scrollTo(0, y);
    }, 150);
  });
  route();
})();
