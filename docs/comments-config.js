// Configuração pública da área de comentários do site.
// A chave abaixo é pública/anon do Supabase e pode ficar no frontend.
window.GPH_COMMENTS = {
  submitUrl: "https://vzhkuewuedfwjvwdwpob.supabase.co/functions/v1/gph-comments",
  listUrl: "https://vzhkuewuedfwjvwdwpob.supabase.co/functions/v1/gph-comments",
  publicHeaders: {
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ6aGt1ZXd1ZWRmd2p2d2R3cG9iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk2NDU5MzcsImV4cCI6MjEwNTIyMTkzN30.OEetOl-J2v5tJu7gd4fVz5T5F9Rn1Ae648vFCwFhH4w",
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ6aGt1ZXd1ZWRmd2p2d2R3cG9iIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk2NDU5MzcsImV4cCI6MjEwNTIyMTkzN30.OEetOl-J2v5tJu7gd4fVz5T5F9Rn1Ae648vFCwFhH4w"
  }
};

// Administração dos comentários no próprio site.
// A chave do administrador nunca fica neste arquivo: é digitada pelo responsável
// e mantida somente na sessão atual do navegador.
document.addEventListener("DOMContentLoaded", () => {
  const cfg = window.GPH_COMMENTS || {};
  const section = document.getElementById("comentarios");
  const list = document.getElementById("comments-list");
  if (!section || !list || !cfg.submitUrl || !cfg.listUrl) return;

  const style = document.createElement("style");
  style.textContent = `
    .gph-admin-bar{display:flex;align-items:center;gap:10px;flex-wrap:wrap;margin:-8px 0 18px}
    .gph-admin-btn{border:1px solid #2a3d59;background:#0b1523;color:#cfe0fb;border-radius:10px;padding:9px 13px;font:inherit;font-size:.88rem;font-weight:800;cursor:pointer}
    .gph-admin-btn:hover{border-color:#4f86cf}
    .gph-admin-state{font-size:.84rem;color:#7f94ad}
    .gph-admin-state.on{color:#86efac}
    .gph-admin-reply{margin-top:14px;padding-top:13px;border-top:1px solid #1c2b41}
    .gph-admin-reply label{display:block;margin-bottom:7px;font-size:.85rem;font-weight:800;color:#93c5fd}
    .gph-admin-reply textarea{width:100%;min-height:82px;resize:vertical;border:1px solid #2a3d59;background:#08121f;color:#eef4ff;border-radius:10px;padding:10px 11px;font:inherit;outline:none}
    .gph-admin-reply textarea:focus{border-color:#4f86cf;box-shadow:0 0 0 3px rgba(59,130,246,.12)}
    .gph-admin-actions{display:flex;align-items:center;gap:10px;margin-top:9px;flex-wrap:wrap}
    .gph-admin-save{border:0;background:linear-gradient(180deg,#60a5fa,#3b82f6);color:#fff;border-radius:9px;padding:9px 12px;font:inherit;font-weight:800;cursor:pointer}
    .gph-admin-msg{font-size:.84rem;color:#9fb0c5}
    .gph-admin-msg.ok{color:#86efac}.gph-admin-msg.error{color:#fca5a5}
  `;
  document.head.appendChild(style);

  const subtitle = section.querySelector(".section-sub");
  const bar = document.createElement("div");
  bar.className = "gph-admin-bar";
  bar.innerHTML = '<button type="button" class="gph-admin-btn" id="gph-admin-toggle">Responder comentários</button><span class="gph-admin-state" id="gph-admin-state">Somente o responsável pelo GP-H</span>';
  (subtitle || section.querySelector("h2"))?.insertAdjacentElement("afterend", bar);

  const toggle = document.getElementById("gph-admin-toggle");
  const state = document.getElementById("gph-admin-state");
  let adminKey = sessionStorage.getItem("gph_admin_key") || "";

  const esc = (s) => String(s ?? "").replace(/[&<>"']/g, c => ({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;","'":"&#39;"}[c]));
  const fmt = (v) => { try { return new Intl.DateTimeFormat("pt-BR", {dateStyle:"short", timeStyle:"short"}).format(new Date(v)); } catch { return ""; } };

  async function postAdmin(payload) {
    const r = await fetch(cfg.submitUrl, {
      method: "POST",
      headers: {"Content-Type":"application/json", ...(cfg.publicHeaders || {})},
      body: JSON.stringify(payload)
    });
    const data = await r.json().catch(() => ({}));
    if (!r.ok) throw new Error(data.error || "Não foi possível concluir a operação.");
    return data;
  }

  async function verify(key) {
    await postAdmin({action:"admin_check", admin_key:key});
  }

  async function renderAdminComments() {
    list.innerHTML = '<div class="empty">Carregando comentários para resposta...</div>';
    try {
      const r = await fetch(cfg.listUrl, {headers: cfg.publicHeaders || {}});
      if (!r.ok) throw new Error("Não foi possível carregar os comentários.");
      const data = await r.json();
      const rows = Array.isArray(data) ? data : (data.comments || []);
      if (!rows.length) {
        list.innerHTML = '<div class="empty">Ainda não há comentários para responder.</div>';
        return;
      }

      list.innerHTML = rows.map(x => {
        const publishedReply = x.admin_reply
          ? `<div class="comment-reply"><div class="comment-reply-label">Resposta do GP-H</div><div class="comment-reply-body">${esc(x.admin_reply)}</div></div>`
          : "";
        const buttonText = x.admin_reply ? "Atualizar resposta" : "Publicar resposta";
        return `<article class="comment" data-comment-id="${Number(x.id)}">
          <div class="comment-head"><span class="comment-name">${esc(x.name)}</span><span class="comment-date">${esc(fmt(x.created_at))}</span></div>
          <div class="comment-body">${esc(x.message)}</div>
          ${publishedReply}
          <div class="gph-admin-reply">
            <label>Responder como GP-H</label>
            <textarea maxlength="1500" placeholder="Escreva sua resposta...">${esc(x.admin_reply || "")}</textarea>
            <div class="gph-admin-actions">
              <button type="button" class="gph-admin-save">${buttonText}</button>
              <span class="gph-admin-msg"></span>
            </div>
          </div>
        </article>`;
      }).join("");

      list.querySelectorAll(".comment").forEach(card => {
        const button = card.querySelector(".gph-admin-save");
        const textarea = card.querySelector("textarea");
        const msg = card.querySelector(".gph-admin-msg");
        button.addEventListener("click", async () => {
          const reply = textarea.value.trim();
          if (reply.length < 2) {
            msg.className = "gph-admin-msg error";
            msg.textContent = "Escreva uma resposta.";
            return;
          }
          button.disabled = true;
          msg.className = "gph-admin-msg";
          msg.textContent = "Salvando...";
          try {
            await postAdmin({
              action:"admin_reply",
              admin_key:adminKey,
              comment_id:Number(card.dataset.commentId),
              reply
            });
            msg.className = "gph-admin-msg ok";
            msg.textContent = "Resposta publicada.";
            setTimeout(renderAdminComments, 450);
          } catch (e) {
            msg.className = "gph-admin-msg error";
            msg.textContent = e.message || "Não foi possível salvar.";
            if (/chave/i.test(msg.textContent)) {
              sessionStorage.removeItem("gph_admin_key");
              adminKey = "";
              state.className = "gph-admin-state";
              state.textContent = "Somente o responsável pelo GP-H";
              toggle.textContent = "Responder comentários";
            }
          } finally {
            button.disabled = false;
          }
        });
      });
    } catch (e) {
      list.innerHTML = `<div class="empty">${esc(e.message || "Não foi possível carregar os comentários agora.")}</div>`;
    }
  }

  async function activateAdmin() {
    let key = adminKey;
    if (!key) {
      key = prompt("Digite a chave de administrador do GP-H:") || "";
      if (!key) return;
    }
    state.className = "gph-admin-state";
    state.textContent = "Verificando...";
    toggle.disabled = true;
    try {
      await verify(key);
      adminKey = key;
      sessionStorage.setItem("gph_admin_key", key);
      state.className = "gph-admin-state on";
      state.textContent = "Modo administrador ativo";
      toggle.textContent = "Sair do modo administrador";
      await renderAdminComments();
    } catch (e) {
      adminKey = "";
      sessionStorage.removeItem("gph_admin_key");
      state.className = "gph-admin-state";
      state.textContent = e.message || "Chave inválida.";
      toggle.textContent = "Responder comentários";
    } finally {
      toggle.disabled = false;
    }
  }

  toggle.addEventListener("click", async () => {
    if (adminKey) {
      adminKey = "";
      sessionStorage.removeItem("gph_admin_key");
      state.className = "gph-admin-state";
      state.textContent = "Somente o responsável pelo GP-H";
      toggle.textContent = "Responder comentários";
      location.reload();
      return;
    }
    await activateAdmin();
  });

  // Se a chave já foi validada nesta aba, reabre o modo automaticamente.
  if (adminKey) activateAdmin();
});
