const API_BASE = '../backend_api';
const token = localStorage.getItem('ong_admin_token');
if (!token) location.href = 'login.html';

const content = document.getElementById('content');
const pageTitle = document.getElementById('pageTitle');
const modalRoot = document.getElementById('modalRoot');
const sidebar = document.getElementById('sidebar');
const user = JSON.parse(localStorage.getItem('ong_admin_user') || '{}');
document.getElementById('adminName').textContent = user.nome || 'Administrador';

const titles = {
  dashboard: 'Visão geral', animais: 'Animais', adocoes: 'Solicitações de adoção',
  campanhas: 'Campanhas', noticias: 'Notícias', videos: 'Vídeos',
  usuarios: 'Usuários', configuracoes: 'Configurações'
};

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>'"]/g, ch => ({'&':'&amp;','<':'&lt;','>':'&gt;',"'":'&#039;','"':'&quot;'}[ch]));
}
function money(value) {
  return Number(value || 0).toLocaleString('pt-BR', {style:'currency', currency:'BRL'});
}
function dateBr(value) {
  if (!value) return '-';
  const safe = String(value).replace(' ', 'T');
  const d = new Date(safe);
  return Number.isNaN(d.getTime()) ? escapeHtml(value) : d.toLocaleString('pt-BR');
}
function badge(status) {
  const positive = ['ativo','ativa','publicada','publicado','disponivel','aprovada','concluida'];
  const warning = ['pendente','em_analise','entrevista','reservado','rascunho'];
  const cls = positive.includes(status) ? 'green' : warning.includes(status) ? 'orange' : 'red';
  return `<span class="badge ${cls}">${escapeHtml(String(status || '').replaceAll('_', ' '))}</span>`;
}
async function api(path, options = {}) {
  const headers = {
    ...(options.headers || {}),
    Authorization: `Bearer ${token}`,
    'X-Auth-Token': token
  };
  if (options.body && !(options.body instanceof FormData)) headers['Content-Type'] = 'application/json';
  const response = await fetch(`${API_BASE}${path}`, {...options, headers});
  let json;
  try { json = await response.json(); } catch { json = {success:false, message:'Resposta inválida do servidor.'}; }
  if (response.status === 401) {
    localStorage.removeItem('ong_admin_token');
    localStorage.removeItem('ong_admin_user');
    location.href = 'login.html';
    return;
  }
  if (!response.ok || !json.success) throw new Error(json.message || 'Não foi possível concluir a operação.');
  return json.data;
}
function showLoading() { content.innerHTML = '<div class="loading">Carregando...</div>'; }
function showError(error) { content.innerHTML = `<div class="message error">${escapeHtml(error.message || error)}</div>`; }
function notify(message, type = 'success') {
  const el = document.createElement('div');
  el.className = `message ${type}`;
  el.style.position = 'fixed'; el.style.right = '20px'; el.style.top = '80px'; el.style.zIndex = '500';
  el.style.maxWidth = '380px'; el.textContent = message;
  document.body.appendChild(el); setTimeout(() => el.remove(), 3300);
}
function closeModal() { modalRoot.innerHTML = ''; }
function openModal(title, body, onSubmit, submitText = 'Salvar') {
  modalRoot.innerHTML = `
    <div class="modal-backdrop" id="modalBackdrop">
      <form class="modal" id="modalForm">
        <div class="modal-header"><h3>${escapeHtml(title)}</h3><button type="button" class="btn btn-secondary" id="modalClose">✕</button></div>
        <div class="modal-body">${body}<div id="modalMessage" class="message hidden"></div></div>
        <div class="modal-footer"><button type="button" class="btn btn-secondary" id="modalCancel">Cancelar</button><button class="btn btn-primary" id="modalSubmit" type="submit">${escapeHtml(submitText)}</button></div>
      </form>
    </div>`;
  document.getElementById('modalClose').onclick = closeModal;
  document.getElementById('modalCancel').onclick = closeModal;
  document.getElementById('modalBackdrop').addEventListener('click', e => { if (e.target.id === 'modalBackdrop') closeModal(); });
  document.getElementById('modalForm').addEventListener('submit', async e => {
    e.preventDefault();
    const submit = document.getElementById('modalSubmit');
    const msg = document.getElementById('modalMessage');
    submit.disabled = true; submit.textContent = 'Salvando...'; msg.className = 'message hidden';
    try { await onSubmit(new FormData(e.currentTarget)); closeModal(); }
    catch (error) { msg.textContent = error.message; msg.className = 'message error'; }
    finally { if (document.body.contains(submit)) { submit.disabled = false; submit.textContent = submitText; } }
  });
}
function formValue(fd, key) { return String(fd.get(key) ?? '').trim(); }
function checkValue(fd, key) { return fd.get(key) === 'on'; }
async function uploadSelectedFile(inputId) {
  const input = document.getElementById(inputId);
  if (!input || !input.files || !input.files[0]) return null;
  const form = new FormData(); form.append('arquivo', input.files[0]);
  return await api('/admin/upload', {method:'POST', body:form});
}

async function loadView(view) {
  pageTitle.textContent = titles[view] || 'Painel';
  
document.querySelectorAll('#nav button').forEach(btn => btn.classList.toggle('active', btn.dataset.view === view));
  sidebar.classList.remove('open'); showLoading();
  try {
    if (view === 'dashboard') await renderDashboard();
    if (view === 'animais') await renderAnimais();
    if (view === 'adocoes') await renderAdocoes();
    if (view === 'campanhas') await renderCampanhas();
    if (view === 'noticias') await renderNoticias();
    if (view === 'videos') await renderVideos();
    if (view === 'usuarios') await renderUsuarios();
    if (view === 'configuracoes') await renderConfiguracoes();
  } catch (error) { showError(error); }
}

async function renderDashboard() {
  const data = await api('/admin/dashboard');
  const c = data.contadores;
  content.innerHTML = `
    <div class="grid-cards">
      <div class="stat-card"><span>Total de animais</span><strong>${c.animais}</strong></div>
      <div class="stat-card"><span>Disponíveis</span><strong>${c.disponiveis}</strong></div>
      <div class="stat-card"><span>Adoções pendentes</span><strong>${c.adocoes_pendentes}</strong></div>
      <div class="stat-card"><span>Usuários</span><strong>${c.usuarios}</strong></div>
      <div class="stat-card"><span>Campanhas ativas</span><strong>${c.campanhas_ativas}</strong></div>
    </div>
    <div class="panel"><div class="panel-header"><h3>Solicitações recentes</h3></div>
      <div class="table-wrap"><table><thead><tr><th>Data</th><th>Adotante</th><th>Animal</th><th>Status</th></tr></thead>
      <tbody>${data.ultimas_solicitacoes.length ? data.ultimas_solicitacoes.map(r => `<tr><td>${dateBr(r.data_solicitacao)}</td><td>${escapeHtml(r.usuario_nome)}</td><td>${escapeHtml(r.animal_nome)}</td><td>${badge(r.status)}</td></tr>`).join('') : '<tr><td colspan="4" class="empty">Nenhuma solicitação.</td></tr>'}</tbody></table></div>
    </div>`;
}

function animalForm(a = {}) {
  return `<div class="form-grid">
    <div class="field"><label>Nome *</label><input name="nome" required value="${escapeHtml(a.nome)}"></div>
    <div class="field"><label>Espécie *</label><select name="especie" required>${options(['cao','gato','outro'], a.especie)}</select></div>
    <div class="field"><label>Raça</label><input name="raca" value="${escapeHtml(a.raca)}"></div>
    <div class="field"><label>Sexo</label><select name="sexo">${options(['macho','femea','nao_informado'], a.sexo)}</select></div>
    <div class="field"><label>Idade aproximada</label><input name="idade_aproximada" value="${escapeHtml(a.idade_aproximada)}"></div>
    <div class="field"><label>Porte</label><select name="porte">${options(['pequeno','medio','grande','nao_informado'], a.porte)}</select></div>
    <div class="field"><label>Status</label><select name="status">${options(['disponivel','em_analise','reservado','adotado','indisponivel'], a.status || 'disponivel')}</select></div>
    <div class="field"><label>Data do resgate</label><input type="date" name="data_resgate" value="${escapeHtml(a.data_resgate)}"></div>
    <div class="field full"><label>Descrição</label><textarea name="descricao">${escapeHtml(a.descricao)}</textarea></div>
    <div class="field full"><label>Comportamento</label><textarea name="comportamento">${escapeHtml(a.comportamento)}</textarea></div>
    <div class="field full"><label>Estado de saúde</label><textarea name="estado_saude">${escapeHtml(a.estado_saude)}</textarea></div>
    <div class="field"><label>URL da foto</label><input id="foto_principal" name="foto_principal" value="${escapeHtml(a.foto_principal)}"></div>
    <div class="field"><label>Ou envie uma imagem</label><input id="animalFile" type="file" accept="image/jpeg,image/png,image/webp"></div>
    <label class="checkbox-row"><input type="checkbox" name="vacinado" ${a.vacinado ? 'checked' : ''}> Vacinado</label>
    <label class="checkbox-row"><input type="checkbox" name="castrado" ${a.castrado ? 'checked' : ''}> Castrado</label>
  </div>`;
}
function options(values, selected) {
  return values.map(v => `<option value="${v}" ${v === selected ? 'selected' : ''}>${v.replaceAll('_',' ')}</option>`).join('');
}
function animalPayload(fd) {
  return {
    nome: formValue(fd,'nome'), especie: formValue(fd,'especie'), raca: formValue(fd,'raca'), sexo: formValue(fd,'sexo'),
    idade_aproximada: formValue(fd,'idade_aproximada'), porte: formValue(fd,'porte'), status: formValue(fd,'status'),
    data_resgate: formValue(fd,'data_resgate'), descricao: formValue(fd,'descricao'), comportamento: formValue(fd,'comportamento'),
    estado_saude: formValue(fd,'estado_saude'), foto_principal: formValue(fd,'foto_principal'),
    vacinado: checkValue(fd,'vacinado'), castrado: checkValue(fd,'castrado')
  };
}
async function openAnimal(a = null) {
  openModal(a ? 'Editar animal' : 'Novo animal', animalForm(a || {}), async fd => {
    let payload = animalPayload(fd);
    const uploaded = await uploadSelectedFile('animalFile');
    if (uploaded) payload.foto_principal = uploaded.caminho;
    await api(a ? `/admin/animais/${a.id}` : '/admin/animais', {method:a ? 'PUT':'POST', body:JSON.stringify(payload)});
    notify(a ? 'Animal atualizado.' : 'Animal cadastrado.'); await renderAnimais();
  });
}
async function renderAnimais() {
  const rows = await api('/admin/animais');
  content.innerHTML = `<div class="panel" style="margin-top:0"><div class="panel-header"><h3>Cadastro de animais</h3><button class="btn btn-primary" id="newAnimal">+ Novo animal</button></div>
  <div class="panel-body"><div class="toolbar"><input id="animalSearch" placeholder="Buscar por nome ou raça"></div>
  <div class="table-wrap"><table><thead><tr><th>Nome</th><th>Espécie</th><th>Sexo</th><th>Porte</th><th>Saúde</th><th>Status</th><th>Ações</th></tr></thead><tbody id="animalRows"></tbody></table></div></div></div>`;
  const draw = filter => {
    const list = rows.filter(a => `${a.nome} ${a.raca || ''}`.toLowerCase().includes(filter.toLowerCase()));
    document.getElementById('animalRows').innerHTML = list.length ? list.map(a => `<tr><td><strong>${escapeHtml(a.nome)}</strong><br><small>${escapeHtml(a.raca || 'Sem raça informada')}</small></td><td>${escapeHtml(a.especie)}</td><td>${escapeHtml(a.sexo)}</td><td>${escapeHtml(a.porte)}</td><td>${a.vacinado ? 'Vacinado' : 'Não vacinado'}<br>${a.castrado ? 'Castrado' : 'Não castrado'}</td><td>${badge(a.status)}</td><td><div class="actions"><button class="btn btn-secondary" data-edit="${a.id}">Editar</button><button class="btn btn-danger" data-delete="${a.id}">Excluir</button></div></td></tr>`).join('') : '<tr><td colspan="7" class="empty">Nenhum animal encontrado.</td></tr>';
  };
  draw(''); document.getElementById('animalSearch').oninput = e => draw(e.target.value);
  document.getElementById('newAnimal').onclick = () => openAnimal();
  content.querySelectorAll('[data-edit]').forEach(btn => btn.onclick = () => openAnimal(rows.find(a => a.id == btn.dataset.edit)));
  content.querySelectorAll('[data-delete]').forEach(btn => btn.onclick = async () => {
    if (!confirm('Deseja excluir ou inativar este animal?')) return;
    await api(`/admin/animais/${btn.dataset.delete}`, {method:'DELETE'}); notify('Registro atualizado.'); await renderAnimais();
  });
}

async function renderAdocoes() {
  const rows = await api('/admin/adocoes');
  content.innerHTML = `<div class="panel" style="margin-top:0"><div class="panel-header"><h3>Solicitações recebidas</h3></div><div class="panel-body">
  <div class="table-wrap"><table><thead><tr><th>Data</th><th>Adotante</th><th>Animal</th><th>Moradia</th><th>Status</th><th>Ações</th></tr></thead><tbody>
  ${rows.length ? rows.map(r => `<tr><td>${dateBr(r.data_solicitacao)}</td><td><strong>${escapeHtml(r.usuario_nome)}</strong><br>${escapeHtml(r.usuario_email)}<br>${escapeHtml(r.usuario_telefone || '')}</td><td>${escapeHtml(r.animal_nome)}</td><td>${escapeHtml(r.tipo_moradia)}<br><small>${r.possui_quintal == 1 ? 'Possui quintal' : 'Sem quintal'} · ${r.possui_outros_animais == 1 ? 'Possui outros animais' : 'Não possui outros animais'}</small></td><td>${badge(r.status)}</td><td><button class="btn btn-secondary" data-adoption="${r.id}">Analisar</button></td></tr>`).join('') : '<tr><td colspan="6" class="empty">Nenhuma solicitação.</td></tr>'}
  </tbody></table></div></div></div>`;
  content.querySelectorAll('[data-adoption]').forEach(btn => btn.onclick = () => {
    const r = rows.find(x => x.id == btn.dataset.adoption);
    openModal('Analisar solicitação', `<div class="field"><label>Adotante</label><input disabled value="${escapeHtml(r.usuario_nome)}"></div><div class="field"><label>Animal</label><input disabled value="${escapeHtml(r.animal_nome)}"></div><div class="field"><label>Motivo da adoção</label><textarea disabled>${escapeHtml(r.motivo_adocao)}</textarea></div><div class="field"><label>Experiência com animais</label><textarea disabled>${escapeHtml(r.experiencia_com_animais)}</textarea></div><div class="field"><label>Novo status</label><select name="status">${options(['pendente','em_analise','entrevista','aprovada','recusada','cancelada','concluida'], r.status)}</select></div><div class="field"><label>Resposta da ONG</label><textarea name="resposta_ong">${escapeHtml(r.resposta_ong)}</textarea></div>`, async fd => {
      await api(`/admin/adocoes/${r.id}/status`, {method:'PUT', body:JSON.stringify({status:formValue(fd,'status'), resposta_ong:formValue(fd,'resposta_ong')})});
      notify('Solicitação atualizada.'); await renderAdocoes();
    }, 'Atualizar');
  });
}

function campaignForm(c = {}) {
  return `<div class="form-grid"><div class="field full"><label>Título *</label><input name="titulo" required value="${escapeHtml(c.titulo)}"></div><div class="field full"><label>Descrição *</label><textarea name="descricao" required>${escapeHtml(c.descricao)}</textarea></div><div class="field"><label>Meta</label><input type="number" step="0.01" name="meta" value="${escapeHtml(c.meta || 0)}"></div><div class="field"><label>Arrecadado</label><input type="number" step="0.01" name="valor_arrecadado" value="${escapeHtml(c.valor_arrecadado || 0)}"></div><div class="field"><label>Chave Pix</label><input name="chave_pix" value="${escapeHtml(c.chave_pix)}"></div><div class="field"><label>Tipo de chave</label><select name="tipo_chave_pix">${options(['cpf','cnpj','email','telefone','aleatoria','nao_informado'], c.tipo_chave_pix || 'nao_informado')}</select></div><div class="field"><label>Status</label><select name="status">${options(['rascunho','ativa','encerrada'], c.status || 'ativa')}</select></div><div class="field"><label>Imagem (URL)</label><input name="imagem" value="${escapeHtml(c.imagem)}"></div><div class="field"><label>Início</label><input type="date" name="data_inicio" value="${escapeHtml(c.data_inicio)}"></div><div class="field"><label>Fim</label><input type="date" name="data_fim" value="${escapeHtml(c.data_fim)}"></div><div class="field full"><label>Ou envie uma imagem</label><input id="campaignFile" type="file" accept="image/jpeg,image/png,image/webp"></div></div>`;
}
async function openCampaign(c = null) {
  openModal(c ? 'Editar campanha' : 'Nova campanha', campaignForm(c || {}), async fd => {
    const payload = {titulo:formValue(fd,'titulo'), descricao:formValue(fd,'descricao'), meta:Number(formValue(fd,'meta') || 0), valor_arrecadado:Number(formValue(fd,'valor_arrecadado') || 0), chave_pix:formValue(fd,'chave_pix'), tipo_chave_pix:formValue(fd,'tipo_chave_pix'), status:formValue(fd,'status'), imagem:formValue(fd,'imagem'), data_inicio:formValue(fd,'data_inicio'), data_fim:formValue(fd,'data_fim')};
    const uploaded = await uploadSelectedFile('campaignFile'); if (uploaded) payload.imagem = uploaded.caminho;
    await api(c ? `/admin/campanhas/${c.id}` : '/admin/campanhas', {method:c?'PUT':'POST', body:JSON.stringify(payload)});
    notify('Campanha salva.'); await renderCampanhas();
  });
}
async function renderCampanhas() {
  const rows = await api('/admin/campanhas');
  content.innerHTML = `<div class="panel" style="margin-top:0"><div class="panel-header"><h3>Campanhas e Pix</h3><button id="newCampaign" class="btn btn-primary">+ Nova campanha</button></div><div class="table-wrap"><table><thead><tr><th>Título</th><th>Meta</th><th>Arrecadado</th><th>Pix</th><th>Status</th><th>Ações</th></tr></thead><tbody>${rows.length ? rows.map(c => `<tr><td><strong>${escapeHtml(c.titulo)}</strong></td><td>${money(c.meta)}</td><td>${money(c.valor_arrecadado)}</td><td>${escapeHtml(c.chave_pix || '-')}</td><td>${badge(c.status)}</td><td><div class="actions"><button class="btn btn-secondary" data-edit-campaign="${c.id}">Editar</button><button class="btn btn-danger" data-delete-campaign="${c.id}">Excluir</button></div></td></tr>`).join('') : '<tr><td colspan="6" class="empty">Nenhuma campanha.</td></tr>'}</tbody></table></div></div>`;
  document.getElementById('newCampaign').onclick = () => openCampaign();
  content.querySelectorAll('[data-edit-campaign]').forEach(b => b.onclick = () => openCampaign(rows.find(c => c.id == b.dataset.editCampaign)));
  content.querySelectorAll('[data-delete-campaign]').forEach(b => b.onclick = async () => { if(confirm('Excluir esta campanha?')) { await api(`/admin/campanhas/${b.dataset.deleteCampaign}`,{method:'DELETE'}); notify('Campanha excluída.'); renderCampanhas(); } });
}

function newsForm(n = {}) {
  const dt = n.data_publicacao ? String(n.data_publicacao).replace(' ', 'T').slice(0,16) : '';
  return `<div class="form-grid"><div class="field full"><label>Título *</label><input name="titulo" required value="${escapeHtml(n.titulo)}"></div><div class="field full"><label>Resumo</label><textarea name="resumo">${escapeHtml(n.resumo)}</textarea></div><div class="field full"><label>Conteúdo *</label><textarea name="conteudo" required style="min-height:220px">${escapeHtml(n.conteudo)}</textarea></div><div class="field"><label>Status</label><select name="status">${options(['rascunho','publicada'], n.status || 'publicada')}</select></div><div class="field"><label>Publicação</label><input type="datetime-local" name="data_publicacao" value="${escapeHtml(dt)}"></div><div class="field"><label>Imagem (URL)</label><input name="imagem" value="${escapeHtml(n.imagem)}"></div><div class="field"><label>Ou envie uma imagem</label><input id="newsFile" type="file" accept="image/jpeg,image/png,image/webp"></div></div>`;
}
async function openNews(n = null) {
  openModal(n ? 'Editar notícia' : 'Nova notícia', newsForm(n || {}), async fd => {
    const payload = {titulo:formValue(fd,'titulo'), resumo:formValue(fd,'resumo'), conteudo:formValue(fd,'conteudo'), status:formValue(fd,'status'), data_publicacao:formValue(fd,'data_publicacao').replace('T',' '), imagem:formValue(fd,'imagem')};
    const uploaded = await uploadSelectedFile('newsFile'); if (uploaded) payload.imagem = uploaded.caminho;
    await api(n ? `/admin/noticias/${n.id}` : '/admin/noticias', {method:n?'PUT':'POST', body:JSON.stringify(payload)}); notify('Notícia salva.'); renderNoticias();
  });
}
async function renderNoticias() {
  const rows = await api('/admin/noticias');
  content.innerHTML = `<div class="panel" style="margin-top:0"><div class="panel-header"><h3>Notícias</h3><button id="newNews" class="btn btn-primary">+ Nova notícia</button></div><div class="table-wrap"><table><thead><tr><th>Título</th><th>Resumo</th><th>Publicação</th><th>Status</th><th>Ações</th></tr></thead><tbody>${rows.length ? rows.map(n => `<tr><td><strong>${escapeHtml(n.titulo)}</strong></td><td>${escapeHtml(n.resumo || '')}</td><td>${dateBr(n.data_publicacao)}</td><td>${badge(n.status)}</td><td><div class="actions"><button class="btn btn-secondary" data-edit-news="${n.id}">Editar</button><button class="btn btn-danger" data-delete-news="${n.id}">Excluir</button></div></td></tr>`).join('') : '<tr><td colspan="5" class="empty">Nenhuma notícia.</td></tr>'}</tbody></table></div></div>`;
  document.getElementById('newNews').onclick = () => openNews();
  content.querySelectorAll('[data-edit-news]').forEach(b => b.onclick = () => openNews(rows.find(n => n.id == b.dataset.editNews)));
  content.querySelectorAll('[data-delete-news]').forEach(b => b.onclick = async () => { if(confirm('Excluir esta notícia?')) { await api(`/admin/noticias/${b.dataset.deleteNews}`,{method:'DELETE'}); notify('Notícia excluída.'); renderNoticias(); } });
}

function videoForm(v = {}) {
  const dt = v.data_publicacao ? String(v.data_publicacao).replace(' ', 'T').slice(0,16) : '';
  return `<div class="form-grid"><div class="field full"><label>Título *</label><input name="titulo" required value="${escapeHtml(v.titulo)}"></div><div class="field full"><label>Descrição</label><textarea name="descricao">${escapeHtml(v.descricao)}</textarea></div><div class="field full"><label>URL do vídeo *</label><input type="url" name="url" required value="${escapeHtml(v.url)}"></div><div class="field"><label>Status</label><select name="status">${options(['rascunho','publicado'], v.status || 'publicado')}</select></div><div class="field"><label>Publicação</label><input type="datetime-local" name="data_publicacao" value="${escapeHtml(dt)}"></div></div>`;
}
async function openVideo(v = null) {
  openModal(v ? 'Editar vídeo' : 'Novo vídeo', videoForm(v || {}), async fd => {
    const payload = {titulo:formValue(fd,'titulo'), descricao:formValue(fd,'descricao'), url:formValue(fd,'url'), status:formValue(fd,'status'), data_publicacao:formValue(fd,'data_publicacao').replace('T',' ')};
    await api(v ? `/admin/videos/${v.id}` : '/admin/videos', {method:v?'PUT':'POST', body:JSON.stringify(payload)}); notify('Vídeo salvo.'); renderVideos();
  });
}
async function renderVideos() {
  const rows = await api('/admin/videos');
  content.innerHTML = `<div class="panel" style="margin-top:0"><div class="panel-header"><h3>Vídeos</h3><button id="newVideo" class="btn btn-primary">+ Novo vídeo</button></div><div class="table-wrap"><table><thead><tr><th>Título</th><th>URL</th><th>Publicação</th><th>Status</th><th>Ações</th></tr></thead><tbody>${rows.length ? rows.map(v => `<tr><td><strong>${escapeHtml(v.titulo)}</strong></td><td><a href="${escapeHtml(v.url)}" target="_blank" rel="noopener">Abrir vídeo</a></td><td>${dateBr(v.data_publicacao)}</td><td>${badge(v.status)}</td><td><div class="actions"><button class="btn btn-secondary" data-edit-video="${v.id}">Editar</button><button class="btn btn-danger" data-delete-video="${v.id}">Excluir</button></div></td></tr>`).join('') : '<tr><td colspan="5" class="empty">Nenhum vídeo.</td></tr>'}</tbody></table></div></div>`;
  document.getElementById('newVideo').onclick = () => openVideo();
  content.querySelectorAll('[data-edit-video]').forEach(b => b.onclick = () => openVideo(rows.find(v => v.id == b.dataset.editVideo)));
  content.querySelectorAll('[data-delete-video]').forEach(b => b.onclick = async () => { if(confirm('Excluir este vídeo?')) { await api(`/admin/videos/${b.dataset.deleteVideo}`,{method:'DELETE'}); notify('Vídeo excluído.'); renderVideos(); } });
}

async function renderUsuarios() {
  const rows = await api('/admin/usuarios');
  content.innerHTML = `<div class="panel" style="margin-top:0"><div class="panel-header"><h3>Usuários cadastrados</h3></div><div class="table-wrap"><table><thead><tr><th>Nome</th><th>Contato</th><th>Tipo</th><th>Cadastro</th><th>Status</th><th>Ações</th></tr></thead><tbody>${rows.length ? rows.map(u => `<tr><td><strong>${escapeHtml(u.nome)}</strong></td><td>${escapeHtml(u.email)}<br>${escapeHtml(u.telefone || '')}</td><td>${escapeHtml(u.tipo)}</td><td>${dateBr(u.data_cadastro)}</td><td>${badge(u.status)}</td><td>${u.tipo === 'usuario' ? `<button class="btn ${u.status === 'ativo' ? 'btn-danger':'btn-primary'}" data-user-status="${u.id}" data-current="${u.status}">${u.status === 'ativo' ? 'Inativar':'Ativar'}</button>` : '-'}</td></tr>`).join('') : '<tr><td colspan="6" class="empty">Nenhum usuário.</td></tr>'}</tbody></table></div></div>`;
  content.querySelectorAll('[data-user-status]').forEach(b => b.onclick = async () => {
    const next = b.dataset.current === 'ativo' ? 'inativo' : 'ativo';
    await api(`/admin/usuarios/${b.dataset.userStatus}/status`, {method:'PUT', body:JSON.stringify({status:next})}); notify('Usuário atualizado.'); renderUsuarios();
  });
}

async function renderConfiguracoes() {
  const c = await api('/admin/configuracoes');
  content.innerHTML = `<div class="panel" style="margin-top:0"><div class="panel-header"><h3>Dados institucionais</h3></div><div class="panel-body"><form id="configForm"><div class="form-grid"><div class="field full"><label>Nome da ONG *</label><input name="nome_ong" required value="${escapeHtml(c.nome_ong)}"></div><div class="field full"><label>Descrição</label><textarea name="descricao">${escapeHtml(c.descricao)}</textarea></div><div class="field"><label>Telefone</label><input name="telefone" value="${escapeHtml(c.telefone)}"></div><div class="field"><label>E-mail</label><input type="email" name="email" value="${escapeHtml(c.email)}"></div><div class="field full"><label>Endereço</label><input name="endereco" value="${escapeHtml(c.endereco)}"></div><div class="field"><label>Chave Pix</label><input name="chave_pix" value="${escapeHtml(c.chave_pix)}"></div><div class="field"><label>Tipo de chave</label><select name="tipo_chave_pix">${options(['cpf','cnpj','email','telefone','aleatoria','nao_informado'], c.tipo_chave_pix)}</select></div><div class="field"><label>Instagram</label><input name="instagram" value="${escapeHtml(c.instagram)}"></div><div class="field"><label>Facebook</label><input name="facebook" value="${escapeHtml(c.facebook)}"></div><div class="field"><label>YouTube</label><input name="youtube" value="${escapeHtml(c.youtube)}"></div><div class="field full"><label>Política de privacidade</label><textarea name="politica_privacidade" style="min-height:180px">${escapeHtml(c.politica_privacidade)}</textarea></div></div><button class="btn btn-primary" type="submit">Salvar configurações</button></form></div></div>`;
  document.getElementById('configForm').onsubmit = async e => {
    e.preventDefault(); const fd = new FormData(e.currentTarget); const payload = Object.fromEntries(fd.entries());
    await api('/admin/configuracoes', {method:'PUT', body:JSON.stringify(payload)}); notify('Configurações salvas.');
  };
}


document.getElementById('changePasswordBtn').onclick = () => {
  openModal('Alterar senha', `
    <div class="field"><label>Nova senha</label><input type="password" name="senha" minlength="8" required autocomplete="new-password"></div>
    <div class="field"><label>Confirmar nova senha</label><input type="password" name="confirmar" minlength="8" required autocomplete="new-password"></div>
  `, async fd => {
    const senha = formValue(fd, 'senha');
    const confirmar = formValue(fd, 'confirmar');
    if (senha.length < 8) throw new Error('A senha deve possuir pelo menos 8 caracteres.');
    if (senha !== confirmar) throw new Error('As senhas não coincidem.');
    await api('/auth/perfil', {
      method: 'PUT',
      body: JSON.stringify({
        nome: user.nome || 'Administrador',
        telefone: user.telefone || '',
        senha
      })
    });
    notify('Senha atualizada com sucesso.');
  }, 'Alterar senha');
};

document.querySelectorAll('#nav button').forEach(btn => btn.addEventListener('click', () => loadView(btn.dataset.view)));
document.getElementById('menuBtn').onclick = () => sidebar.classList.toggle('open');
document.getElementById('logoutBtn').onclick = async () => {
  try { await api('/auth/logout', {method:'POST'}); } catch (_) {}
  localStorage.removeItem('ong_admin_token'); localStorage.removeItem('ong_admin_user'); location.href = 'login.html';
};
loadView('dashboard');
