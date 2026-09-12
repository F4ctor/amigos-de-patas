import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key, required this.client, required this.user});

  final ApiClient client;
  final Map<String, dynamic> user;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic> _dashboard = <String, dynamic>{};
  List<Map<String, dynamic>> _animals = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _adoptions = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _users = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _campaigns = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _news = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _videos = <Map<String, dynamic>>[];
  Map<String, dynamic> _settings = <String, dynamic>{};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([
        widget.client.get('/admin/dashboard'),
        widget.client.get('/admin/animais'),
        widget.client.get('/admin/adocoes'),
        widget.client.get('/admin/usuarios'),
        widget.client.get('/admin/campanhas'),
        widget.client.get('/admin/noticias'),
        widget.client.get('/admin/videos'),
        widget.client.get('/admin/configuracoes'),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboard = _map(results[0]);
        _animals = _listOfMaps(results[1]);
        _adoptions = _listOfMaps(results[2]);
        _users = _listOfMaps(results[3]);
        _campaigns = _listOfMaps(results[4]);
        _news = _listOfMaps(results[5]);
        _videos = _listOfMaps(results[6]);
        _settings = _map(results[7]);
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) return <Map<String, dynamic>>[];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alteração salva com sucesso.')),
        );
      }
      await _loadAll();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<bool> _confirm(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _loadAll);

    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.dashboard_outlined), text: 'Painel'),
                Tab(icon: Icon(Icons.pets_outlined), text: 'Animais'),
                Tab(icon: Icon(Icons.assignment_outlined), text: 'Adoções'),
                Tab(icon: Icon(Icons.people_outline), text: 'Usuários'),
                Tab(icon: Icon(Icons.volunteer_activism_outlined), text: 'Campanhas'),
                Tab(icon: Icon(Icons.article_outlined), text: 'Notícias'),
                Tab(icon: Icon(Icons.video_library_outlined), text: 'Vídeos'),
                Tab(icon: Icon(Icons.settings_outlined), text: 'Configurações'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _dashboardTab(),
                _animalsTab(),
                _adoptionsTab(),
                _usersTab(),
                _campaignsTab(),
                _newsTab(),
                _videosTab(),
                _settingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashboardTab() {
    final counters = _map(_dashboard['contadores']);
    final latest = _listOfMaps(_dashboard['ultimas_solicitacoes']);

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modo Administrador',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(widget.user['nome']?.toString() ?? 'Administrador'),
                        Text(
                          widget.user['email']?.toString() ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Atualizar',
                    onPressed: _loadAll,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: [
              _counterCard('Animais', counters['animais'], Icons.pets),
              _counterCard('Disponíveis', counters['disponiveis'], Icons.favorite_outline),
              _counterCard('Adoções pendentes', counters['adocoes_pendentes'], Icons.assignment_late_outlined),
              _counterCard('Usuários', counters['usuarios'], Icons.people_outline),
              _counterCard('Campanhas ativas', counters['campanhas_ativas'], Icons.volunteer_activism_outlined),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Solicitações recentes',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (latest.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Nenhuma solicitação cadastrada.'),
              ),
            )
          else
            ...latest.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.pets)),
                  title: Text('${item['animal_nome'] ?? 'Animal'}'),
                  subtitle: Text('${item['usuario_nome'] ?? 'Usuário'} • ${_statusLabel(item['status'])}'),
                  trailing: Text('#${item['id'] ?? ''}'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _counterCard(String title, dynamic value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const Spacer(),
            Text(
              '${value ?? 0}',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(title, maxLines: 2),
          ],
        ),
      ),
    );
  }

  Widget _animalsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            'Animais',
            '${_animals.length} cadastro(s)',
            onAdd: () => _showAnimalDialog(),
          ),
          const SizedBox(height: 10),
          if (_animals.isEmpty)
            _emptyCard('Nenhum animal cadastrado.')
          else
            ..._animals.map(
              (animal) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(
                      (animal['nome']?.toString().isNotEmpty == true)
                          ? animal['nome'].toString().substring(0, 1).toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(animal['nome']?.toString() ?? 'Animal'),
                  subtitle: Text(
                    '${_pretty(animal['especie'])} • ${_pretty(animal['sexo'])} • ${_pretty(animal['porte'])}\nStatus: ${_statusLabel(animal['status'])}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _showAnimalDialog(animal);
                      } else if (value == 'delete') {
                        final ok = await _confirm(
                          'Excluir animal',
                          'Deseja excluir ${animal['nome'] ?? 'este animal'}? Se houver histórico de adoção, o backend poderá apenas torná-lo indisponível.',
                        );
                        if (ok) {
                          await _runAction(() async {
                            await widget.client.delete('/admin/animais/${animal['id']}');
                          });
                        }
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Editar')),
                      PopupMenuItem(value: 'delete', child: Text('Excluir / inativar')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _adoptionsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Solicitações de adoção', '${_adoptions.length} solicitação(ões)'),
          const SizedBox(height: 10),
          if (_adoptions.isEmpty)
            _emptyCard('Nenhuma solicitação de adoção.')
          else
            ..._adoptions.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ExpansionTile(
                  leading: const CircleAvatar(child: Icon(Icons.assignment_ind_outlined)),
                  title: Text('${item['animal_nome'] ?? 'Animal'} — ${item['usuario_nome'] ?? 'Usuário'}'),
                  subtitle: Text('Status: ${_statusLabel(item['status'])}'),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _detailRow('E-mail', item['usuario_email']),
                    _detailRow('Telefone', item['usuario_telefone']),
                    _detailRow('Moradia', item['tipo_moradia']),
                    _detailRow('Motivo', item['motivo_adocao']),
                    _detailRow('Experiência', item['experiencia_com_animais']),
                    _detailRow('Observações', item['observacoes']),
                    _detailRow('Resposta da ONG', item['resposta_ong']),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _showAdoptionStatusDialog(item),
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Alterar status / responder'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _usersTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Usuários', '${_users.length} usuário(s)'),
          const SizedBox(height: 10),
          ..._users.map((user) {
            final isAdmin = user['tipo']?.toString() == 'administrador';
            final active = user['status']?.toString() == 'ativo';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  child: Icon(isAdmin ? Icons.admin_panel_settings : Icons.person_outline),
                ),
                title: Text(user['nome']?.toString() ?? 'Usuário'),
                subtitle: Text(
                  '${user['email'] ?? ''}\n${isAdmin ? 'Administrador' : 'Usuário'} • ${active ? 'Ativo' : 'Inativo'}',
                ),
                isThreeLine: true,
                trailing: isAdmin
                    ? const Chip(label: Text('ADMIN'))
                    : Switch(
                        value: active,
                        onChanged: (value) => _runAction(() async {
                          await widget.client.put(
                            '/admin/usuarios/${user['id']}/status',
                            body: {'status': value ? 'ativo' : 'inativo'},
                          );
                        }),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _campaignsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            'Campanhas',
            '${_campaigns.length} campanha(s)',
            onAdd: () => _showCampaignDialog(),
          ),
          const SizedBox(height: 10),
          if (_campaigns.isEmpty)
            _emptyCard('Nenhuma campanha cadastrada.')
          else
            ..._campaigns.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.volunteer_activism_outlined)),
                  title: Text(item['titulo']?.toString() ?? 'Campanha'),
                  subtitle: Text(
                    'Meta: R\$ ${item['meta'] ?? 0} • Arrecadado: R\$ ${item['valor_arrecadado'] ?? 0}\nStatus: ${_statusLabel(item['status'])}',
                  ),
                  isThreeLine: true,
                  trailing: _crudMenu(
                    onEdit: () => _showCampaignDialog(item),
                    onDelete: () => _deleteSimple('/admin/campanhas/${item['id']}', 'Excluir campanha?'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _newsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            'Notícias',
            '${_news.length} notícia(s)',
            onAdd: () => _showNewsDialog(),
          ),
          const SizedBox(height: 10),
          if (_news.isEmpty)
            _emptyCard('Nenhuma notícia cadastrada.')
          else
            ..._news.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.article_outlined)),
                  title: Text(item['titulo']?.toString() ?? 'Notícia'),
                  subtitle: Text(
                    '${item['resumo'] ?? ''}\nStatus: ${_statusLabel(item['status'])}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: _crudMenu(
                    onEdit: () => _showNewsDialog(item),
                    onDelete: () => _deleteSimple('/admin/noticias/${item['id']}', 'Excluir notícia?'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _videosTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader(
            'Vídeos',
            '${_videos.length} vídeo(s)',
            onAdd: () => _showVideoDialog(),
          ),
          const SizedBox(height: 10),
          if (_videos.isEmpty)
            _emptyCard('Nenhum vídeo cadastrado.')
          else
            ..._videos.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.play_circle_outline)),
                  title: Text(item['titulo']?.toString() ?? 'Vídeo'),
                  subtitle: Text(
                    '${item['url'] ?? ''}\nStatus: ${_statusLabel(item['status'])}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: _crudMenu(
                    onEdit: () => _showVideoDialog(item),
                    onDelete: () => _deleteSimple('/admin/videos/${item['id']}', 'Excluir vídeo?'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _settingsTab() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Configurações da ONG', 'Dados institucionais'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow('Nome', _settings['nome_ong']),
                  _detailRow('Descrição', _settings['descricao']),
                  _detailRow('Telefone', _settings['telefone']),
                  _detailRow('E-mail', _settings['email']),
                  _detailRow('Endereço', _settings['endereco']),
                  _detailRow('Chave Pix', _settings['chave_pix']),
                  _detailRow('Instagram', _settings['instagram']),
                  _detailRow('Facebook', _settings['facebook']),
                  _detailRow('YouTube', _settings['youtube']),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _showSettingsDialog,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Editar configurações'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle, {VoidCallback? onAdd}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        if (onAdd != null)
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Novo'),
          ),
      ],
    );
  }

  Widget _emptyCard(String text) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text),
      ),
    );
  }

  Widget _detailRow(String label, dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _crudMenu({required VoidCallback onEdit, required VoidCallback onDelete}) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else {
          onDelete();
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Editar')),
        PopupMenuItem(value: 'delete', child: Text('Excluir')),
      ],
    );
  }

  Future<void> _deleteSimple(String path, String message) async {
    final ok = await _confirm('Confirmar exclusão', message);
    if (!ok) return;
    await _runAction(() async {
      await widget.client.delete(path);
    });
  }

  Future<void> _showAnimalDialog([Map<String, dynamic>? animal]) async {
    final isEditing = animal != null;
    final nome = TextEditingController(text: animal?['nome']?.toString() ?? '');
    final raca = TextEditingController(text: animal?['raca']?.toString() ?? '');
    final idade = TextEditingController(text: animal?['idade_aproximada']?.toString() ?? '');
    final descricao = TextEditingController(text: animal?['descricao']?.toString() ?? '');
    final comportamento = TextEditingController(text: animal?['comportamento']?.toString() ?? '');
    final saude = TextEditingController(text: animal?['estado_saude']?.toString() ?? '');
    final foto = TextEditingController(text: animal?['foto_principal']?.toString() ?? '');
    final resgate = TextEditingController(text: animal?['data_resgate']?.toString() ?? '');
    String especie = animal?['especie']?.toString() ?? 'cao';
    String sexo = animal?['sexo']?.toString() ?? 'nao_informado';
    String porte = animal?['porte']?.toString() ?? 'nao_informado';
    String status = animal?['status']?.toString() ?? 'disponivel';
    bool vacinado = _bool(animal?['vacinado']);
    bool castrado = _bool(animal?['castrado']);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(isEditing ? 'Editar animal' : 'Novo animal'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome *')),
                  const SizedBox(height: 10),
                  _dropdown(
                    label: 'Espécie',
                    value: especie,
                    values: const ['cao', 'gato', 'outro'],
                    onChanged: (value) => setLocalState(() => especie = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: raca, decoration: const InputDecoration(labelText: 'Raça')),
                  const SizedBox(height: 10),
                  _dropdown(
                    label: 'Sexo',
                    value: sexo,
                    values: const ['macho', 'femea', 'nao_informado'],
                    onChanged: (value) => setLocalState(() => sexo = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: idade, decoration: const InputDecoration(labelText: 'Idade aproximada')),
                  const SizedBox(height: 10),
                  _dropdown(
                    label: 'Porte',
                    value: porte,
                    values: const ['pequeno', 'medio', 'grande', 'nao_informado'],
                    onChanged: (value) => setLocalState(() => porte = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: descricao, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
                  const SizedBox(height: 10),
                  TextField(controller: comportamento, maxLines: 2, decoration: const InputDecoration(labelText: 'Comportamento')),
                  const SizedBox(height: 10),
                  TextField(controller: saude, maxLines: 2, decoration: const InputDecoration(labelText: 'Estado de saúde')),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: vacinado,
                    onChanged: (value) => setLocalState(() => vacinado = value),
                    title: const Text('Vacinado'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: castrado,
                    onChanged: (value) => setLocalState(() => castrado = value),
                    title: const Text('Castrado'),
                  ),
                  _dropdown(
                    label: 'Status',
                    value: status,
                    values: const ['disponivel', 'em_analise', 'reservado', 'adotado', 'indisponivel'],
                    onChanged: (value) => setLocalState(() => status = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: foto, decoration: const InputDecoration(labelText: 'URL/caminho da foto principal')),
                  const SizedBox(height: 10),
                  TextField(controller: resgate, decoration: const InputDecoration(labelText: 'Data do resgate (AAAA-MM-DD)')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (nome.text.trim().isEmpty) return;
                Navigator.pop(context, {
                  'nome': nome.text.trim(),
                  'especie': especie,
                  'raca': raca.text.trim(),
                  'sexo': sexo,
                  'idade_aproximada': idade.text.trim(),
                  'porte': porte,
                  'descricao': descricao.text.trim(),
                  'comportamento': comportamento.text.trim(),
                  'estado_saude': saude.text.trim(),
                  'vacinado': vacinado,
                  'castrado': castrado,
                  'status': status,
                  'foto_principal': foto.text.trim(),
                  'data_resgate': resgate.text.trim(),
                });
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    await _runAction(() async {
      if (isEditing) {
        await widget.client.put('/admin/animais/${animal['id']}', body: result);
      } else {
        await widget.client.post('/admin/animais', body: result);
      }
    });
  }

  Future<void> _showAdoptionStatusDialog(Map<String, dynamic> item) async {
    const allowed = [
      'pendente',
      'em_analise',
      'entrevista',
      'aprovada',
      'recusada',
      'cancelada',
      'concluida',
    ];
    String status = item['status']?.toString() ?? 'pendente';
    if (!allowed.contains(status)) status = 'pendente';
    final resposta = TextEditingController(text: item['resposta_ong']?.toString() ?? '');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text('Atualizar solicitação'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dropdown(
                  label: 'Status',
                  value: status,
                  values: allowed,
                  onChanged: (value) => setLocalState(() => status = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: resposta,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Resposta da ONG'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                'status': status,
                'resposta_ong': resposta.text.trim(),
              }),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;
    await _runAction(() async {
      await widget.client.put('/admin/adocoes/${item['id']}/status', body: result);
    });
  }

  Future<void> _showCampaignDialog([Map<String, dynamic>? item]) async {
    final isEditing = item != null;
    final titulo = TextEditingController(text: item?['titulo']?.toString() ?? '');
    final descricao = TextEditingController(text: item?['descricao']?.toString() ?? '');
    final meta = TextEditingController(text: item?['meta']?.toString() ?? '0');
    final arrecadado = TextEditingController(text: item?['valor_arrecadado']?.toString() ?? '0');
    final imagem = TextEditingController(text: item?['imagem']?.toString() ?? '');
    final pix = TextEditingController(text: item?['chave_pix']?.toString() ?? '');
    final inicio = TextEditingController(text: item?['data_inicio']?.toString() ?? '');
    final fim = TextEditingController(text: item?['data_fim']?.toString() ?? '');
    String tipoPix = item?['tipo_chave_pix']?.toString() ?? 'nao_informado';
    String status = item?['status']?.toString() ?? 'ativa';

    final result = await _genericFormDialog(
      title: isEditing ? 'Editar campanha' : 'Nova campanha',
      buildFields: (setLocalState) => [
        TextField(controller: titulo, decoration: const InputDecoration(labelText: 'Título *')),
        const SizedBox(height: 10),
        TextField(controller: descricao, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição *')),
        const SizedBox(height: 10),
        TextField(controller: meta, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Meta')),
        const SizedBox(height: 10),
        TextField(controller: arrecadado, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor arrecadado')),
        const SizedBox(height: 10),
        TextField(controller: imagem, decoration: const InputDecoration(labelText: 'Imagem (URL/caminho)')),
        const SizedBox(height: 10),
        TextField(controller: pix, decoration: const InputDecoration(labelText: 'Chave Pix')),
        const SizedBox(height: 10),
        _dropdown(
          label: 'Tipo da chave Pix',
          value: tipoPix,
          values: const ['cpf', 'cnpj', 'email', 'telefone', 'aleatoria', 'nao_informado'],
          onChanged: (value) => setLocalState(() => tipoPix = value),
        ),
        const SizedBox(height: 10),
        _dropdown(
          label: 'Status',
          value: status,
          values: const ['rascunho', 'ativa', 'encerrada'],
          onChanged: (value) => setLocalState(() => status = value),
        ),
        const SizedBox(height: 10),
        TextField(controller: inicio, decoration: const InputDecoration(labelText: 'Início (AAAA-MM-DD)')),
        const SizedBox(height: 10),
        TextField(controller: fim, decoration: const InputDecoration(labelText: 'Fim (AAAA-MM-DD)')),
      ],
      onSave: () {
        if (titulo.text.trim().isEmpty || descricao.text.trim().isEmpty) return null;
        return {
          'titulo': titulo.text.trim(),
          'descricao': descricao.text.trim(),
          'meta': _number(meta.text),
          'valor_arrecadado': _number(arrecadado.text),
          'imagem': imagem.text.trim(),
          'chave_pix': pix.text.trim(),
          'tipo_chave_pix': tipoPix,
          'status': status,
          'data_inicio': inicio.text.trim(),
          'data_fim': fim.text.trim(),
        };
      },
    );

    if (result == null) return;
    await _runAction(() async {
      if (isEditing) {
        await widget.client.put('/admin/campanhas/${item['id']}', body: result);
      } else {
        await widget.client.post('/admin/campanhas', body: result);
      }
    });
  }

  Future<void> _showNewsDialog([Map<String, dynamic>? item]) async {
    final isEditing = item != null;
    final titulo = TextEditingController(text: item?['titulo']?.toString() ?? '');
    final resumo = TextEditingController(text: item?['resumo']?.toString() ?? '');
    final conteudo = TextEditingController(text: item?['conteudo']?.toString() ?? '');
    final imagem = TextEditingController(text: item?['imagem']?.toString() ?? '');
    final data = TextEditingController(text: item?['data_publicacao']?.toString() ?? '');
    String status = item?['status']?.toString() ?? 'publicada';

    final result = await _genericFormDialog(
      title: isEditing ? 'Editar notícia' : 'Nova notícia',
      buildFields: (setLocalState) => [
        TextField(controller: titulo, decoration: const InputDecoration(labelText: 'Título *')),
        const SizedBox(height: 10),
        TextField(controller: resumo, maxLines: 2, decoration: const InputDecoration(labelText: 'Resumo')),
        const SizedBox(height: 10),
        TextField(controller: conteudo, maxLines: 6, decoration: const InputDecoration(labelText: 'Conteúdo *')),
        const SizedBox(height: 10),
        TextField(controller: imagem, decoration: const InputDecoration(labelText: 'Imagem (URL/caminho)')),
        const SizedBox(height: 10),
        _dropdown(
          label: 'Status',
          value: status,
          values: const ['rascunho', 'publicada'],
          onChanged: (value) => setLocalState(() => status = value),
        ),
        const SizedBox(height: 10),
        TextField(controller: data, decoration: const InputDecoration(labelText: 'Data de publicação')),
      ],
      onSave: () {
        if (titulo.text.trim().isEmpty || conteudo.text.trim().isEmpty) return null;
        return {
          'titulo': titulo.text.trim(),
          'resumo': resumo.text.trim(),
          'conteudo': conteudo.text.trim(),
          'imagem': imagem.text.trim(),
          'status': status,
          'data_publicacao': data.text.trim(),
        };
      },
    );

    if (result == null) return;
    await _runAction(() async {
      if (isEditing) {
        await widget.client.put('/admin/noticias/${item['id']}', body: result);
      } else {
        await widget.client.post('/admin/noticias', body: result);
      }
    });
  }

  Future<void> _showVideoDialog([Map<String, dynamic>? item]) async {
    final isEditing = item != null;
    final titulo = TextEditingController(text: item?['titulo']?.toString() ?? '');
    final descricao = TextEditingController(text: item?['descricao']?.toString() ?? '');
    final url = TextEditingController(text: item?['url']?.toString() ?? '');
    final data = TextEditingController(text: item?['data_publicacao']?.toString() ?? '');
    String status = item?['status']?.toString() ?? 'publicado';

    final result = await _genericFormDialog(
      title: isEditing ? 'Editar vídeo' : 'Novo vídeo',
      buildFields: (setLocalState) => [
        TextField(controller: titulo, decoration: const InputDecoration(labelText: 'Título *')),
        const SizedBox(height: 10),
        TextField(controller: descricao, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
        const SizedBox(height: 10),
        TextField(controller: url, decoration: const InputDecoration(labelText: 'URL *')),
        const SizedBox(height: 10),
        _dropdown(
          label: 'Status',
          value: status,
          values: const ['rascunho', 'publicado'],
          onChanged: (value) => setLocalState(() => status = value),
        ),
        const SizedBox(height: 10),
        TextField(controller: data, decoration: const InputDecoration(labelText: 'Data de publicação')),
      ],
      onSave: () {
        if (titulo.text.trim().isEmpty || url.text.trim().isEmpty) return null;
        return {
          'titulo': titulo.text.trim(),
          'descricao': descricao.text.trim(),
          'url': url.text.trim(),
          'status': status,
          'data_publicacao': data.text.trim(),
        };
      },
    );

    if (result == null) return;
    await _runAction(() async {
      if (isEditing) {
        await widget.client.put('/admin/videos/${item['id']}', body: result);
      } else {
        await widget.client.post('/admin/videos', body: result);
      }
    });
  }

  Future<void> _showSettingsDialog() async {
    final nome = TextEditingController(text: _settings['nome_ong']?.toString() ?? '');
    final descricao = TextEditingController(text: _settings['descricao']?.toString() ?? '');
    final telefone = TextEditingController(text: _settings['telefone']?.toString() ?? '');
    final email = TextEditingController(text: _settings['email']?.toString() ?? '');
    final endereco = TextEditingController(text: _settings['endereco']?.toString() ?? '');
    final pix = TextEditingController(text: _settings['chave_pix']?.toString() ?? '');
    final instagram = TextEditingController(text: _settings['instagram']?.toString() ?? '');
    final facebook = TextEditingController(text: _settings['facebook']?.toString() ?? '');
    final youtube = TextEditingController(text: _settings['youtube']?.toString() ?? '');
    final privacidade = TextEditingController(text: _settings['politica_privacidade']?.toString() ?? '');
    String tipoPix = _settings['tipo_chave_pix']?.toString() ?? 'nao_informado';

    final result = await _genericFormDialog(
      title: 'Editar configurações',
      buildFields: (setLocalState) => [
        TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome da ONG *')),
        const SizedBox(height: 10),
        TextField(controller: descricao, maxLines: 3, decoration: const InputDecoration(labelText: 'Descrição')),
        const SizedBox(height: 10),
        TextField(controller: telefone, decoration: const InputDecoration(labelText: 'Telefone')),
        const SizedBox(height: 10),
        TextField(controller: email, decoration: const InputDecoration(labelText: 'E-mail')),
        const SizedBox(height: 10),
        TextField(controller: endereco, decoration: const InputDecoration(labelText: 'Endereço')),
        const SizedBox(height: 10),
        TextField(controller: pix, decoration: const InputDecoration(labelText: 'Chave Pix')),
        const SizedBox(height: 10),
        _dropdown(
          label: 'Tipo da chave Pix',
          value: tipoPix,
          values: const ['cpf', 'cnpj', 'email', 'telefone', 'aleatoria', 'nao_informado'],
          onChanged: (value) => setLocalState(() => tipoPix = value),
        ),
        const SizedBox(height: 10),
        TextField(controller: instagram, decoration: const InputDecoration(labelText: 'Instagram')),
        const SizedBox(height: 10),
        TextField(controller: facebook, decoration: const InputDecoration(labelText: 'Facebook')),
        const SizedBox(height: 10),
        TextField(controller: youtube, decoration: const InputDecoration(labelText: 'YouTube')),
        const SizedBox(height: 10),
        TextField(controller: privacidade, maxLines: 5, decoration: const InputDecoration(labelText: 'Política de privacidade')),
      ],
      onSave: () {
        if (nome.text.trim().isEmpty) return null;
        return {
          'nome_ong': nome.text.trim(),
          'descricao': descricao.text.trim(),
          'telefone': telefone.text.trim(),
          'email': email.text.trim(),
          'endereco': endereco.text.trim(),
          'chave_pix': pix.text.trim(),
          'tipo_chave_pix': tipoPix,
          'instagram': instagram.text.trim(),
          'facebook': facebook.text.trim(),
          'youtube': youtube.text.trim(),
          'politica_privacidade': privacidade.text.trim(),
        };
      },
    );

    if (result == null) return;
    await _runAction(() async {
      await widget.client.put('/admin/configuracoes', body: result);
    });
  }

  Future<Map<String, dynamic>?> _genericFormDialog({
    required String title,
    required List<Widget> Function(StateSetter setLocalState) buildFields,
    required Map<String, dynamic>? Function() onSave,
  }) {
    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: buildFields(setLocalState),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                final result = onSave();
                if (result != null) Navigator.pop(context, result);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String> onChanged,
  }) {
    var effectiveValue = value;
    if (!values.contains(effectiveValue)) effectiveValue = values.first;
    return DropdownButtonFormField<String>(
      value: effectiveValue,
      decoration: InputDecoration(labelText: label),
      items: values
          .map((item) => DropdownMenuItem(value: item, child: Text(_pretty(item))))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  bool _bool(dynamic value) {
    return value == true || value == 1 || value?.toString() == '1';
  }

  double _number(String value) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }

  String _pretty(dynamic value) {
    final text = value?.toString() ?? '';
    if (text.isEmpty) return 'Não informado';
    final normalized = text.replaceAll('_', ' ');
    return normalized.substring(0, 1).toUpperCase() + normalized.substring(1);
  }

  String _statusLabel(dynamic value) => _pretty(value);
}
