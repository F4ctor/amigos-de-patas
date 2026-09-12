import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';

class AnimalsScreen extends StatefulWidget {
  const AnimalsScreen({super.key, required this.client});

  final ApiClient client;

  @override
  State<AnimalsScreen> createState() => _AnimalsScreenState();
}

class _AnimalsScreenState extends State<AnimalsScreen> {
  bool _loading = true;
  String? _error;
  List<Animal> _animals = const [];
  String _species = '';
  String _size = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.client.get('/animais', query: {
        'status': 'disponivel',
        if (_species.isNotEmpty) 'especie': _species,
        if (_size.isNotEmpty) 'porte': _size,
      }) as List;
      if (!mounted) return;
      setState(() {
        _animals = data.map((e) => Animal.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _species,
                  decoration: const InputDecoration(labelText: 'Espécie'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todas')),
                    DropdownMenuItem(value: 'cao', child: Text('Cães')),
                    DropdownMenuItem(value: 'gato', child: Text('Gatos')),
                    DropdownMenuItem(value: 'outro', child: Text('Outros')),
                  ],
                  onChanged: (value) { _species = value ?? ''; _load(); },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _size,
                  decoration: const InputDecoration(labelText: 'Porte'),
                  items: const [
                    DropdownMenuItem(value: '', child: Text('Todos')),
                    DropdownMenuItem(value: 'pequeno', child: Text('Pequeno')),
                    DropdownMenuItem(value: 'medio', child: Text('Médio')),
                    DropdownMenuItem(value: 'grande', child: Text('Grande')),
                  ],
                  onChanged: (value) { _size = value ?? ''; _load(); },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const LoadingView()
              : _error != null
                  ? ErrorView(message: _error!, onRetry: _load)
                  : _animals.isEmpty
                      ? const EmptyView(icon: Icons.pets, message: 'Nenhum animal encontrado com esses filtros.')
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _animals.length,
                            itemBuilder: (context, index) {
                              final animal = _animals[index];
                              return Card(
                                clipBehavior: Clip.antiAlias,
                                margin: const EdgeInsets.only(bottom: 14),
                                child: InkWell(
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => AnimalDetailsScreen(client: widget.client, animal: animal),
                                  )),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 125, height: 140, child: networkImage(animal.fotoPrincipal, width: 125, height: 140)),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(animal.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                                              const SizedBox(height: 6),
                                              Text('${_label(animal.especie)} · ${_label(animal.porte)}'),
                                              const SizedBox(height: 6),
                                              Text(animal.raca?.isNotEmpty == true ? animal.raca! : 'Sem raça definida'),
                                              const SizedBox(height: 10),
                                              Wrap(spacing: 6, runSpacing: 6, children: [
                                                if (animal.vacinado) const Chip(label: Text('Vacinado'), visualDensity: VisualDensity.compact),
                                                if (animal.castrado) const Chip(label: Text('Castrado'), visualDensity: VisualDensity.compact),
                                              ]),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.chevron_right)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
        ),
      ],
    );
  }

  String _label(String value) {
    const map = {'cao':'Cão','gato':'Gato','outro':'Outro','pequeno':'Pequeno','medio':'Médio','grande':'Grande'};
    return map[value] ?? value.replaceAll('_', ' ');
  }
}

class AnimalDetailsScreen extends StatelessWidget {
  const AnimalDetailsScreen({super.key, required this.client, required this.animal});

  final ApiClient client;
  final Animal animal;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(animal.nome)),
      body: ListView(
        children: [
          networkImage(animal.fotoPrincipal, height: 280, width: double.infinity),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(animal.nome, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('${animal.especie} · ${animal.sexo} · ${animal.porte}'.replaceAll('_', ' ')),
                if (animal.idadeAproximada?.isNotEmpty == true) ...[
                  const SizedBox(height: 6), Text('Idade aproximada: ${animal.idadeAproximada}'),
                ],
                const SizedBox(height: 18),
                Wrap(spacing: 8, children: [
                  Chip(avatar: Icon(animal.vacinado ? Icons.check_circle : Icons.info_outline), label: Text(animal.vacinado ? 'Vacinado' : 'Vacinação não confirmada')),
                  Chip(avatar: Icon(animal.castrado ? Icons.check_circle : Icons.info_outline), label: Text(animal.castrado ? 'Castrado' : 'Não castrado')),
                ]),
                const SizedBox(height: 18),
                _InfoBlock(title: 'Sobre', text: animal.descricao),
                _InfoBlock(title: 'Comportamento', text: animal.comportamento),
                _InfoBlock(title: 'Estado de saúde', text: animal.estadoSaude),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.favorite_outline),
                    label: const Padding(padding: EdgeInsets.symmetric(vertical: 13), child: Text('Solicitar adoção')),
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AdoptionFormScreen(client: client, animal: animal),
                    )),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.title, this.text});
  final String title;
  final String? text;

  @override
  Widget build(BuildContext context) {
    if (text == null || text!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6), Text(text!),
      ]),
    );
  }
}

class AdoptionFormScreen extends StatefulWidget {
  const AdoptionFormScreen({super.key, required this.client, required this.animal});

  final ApiClient client;
  final Animal animal;

  @override
  State<AdoptionFormScreen> createState() => _AdoptionFormScreenState();
}

class _AdoptionFormScreenState extends State<AdoptionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  final _experience = TextEditingController();
  final _notes = TextEditingController();
  String _housing = 'Casa';
  bool _yard = false;
  bool _otherPets = false;
  bool _everyoneAgrees = false;
  int _people = 1;
  bool _loading = false;

  @override
  void dispose() {
    _reason.dispose(); _experience.dispose(); _notes.dispose(); super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_everyoneAgrees) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Confirme que todos da residência concordam com a adoção.')));
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.client.post('/adocoes', body: {
        'animal_id': widget.animal.id,
        'tipo_moradia': _housing,
        'possui_quintal': _yard,
        'possui_outros_animais': _otherPets,
        'quantidade_pessoas': _people,
        'todos_concordam': _everyoneAgrees,
        'motivo_adocao': _reason.text.trim(),
        'experiencia_com_animais': _experience.text.trim(),
        'observacoes': _notes.text.trim(),
      });
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (_) => AlertDialog(
        title: const Text('Solicitação enviada'),
        content: const Text('A ONG analisará as informações e entrará em contato. A adoção não é automática.'),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Entendi'))],
      ));
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Solicitação de adoção')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Card(child: ListTile(leading: const CircleAvatar(child: Icon(Icons.pets)), title: Text(widget.animal.nome), subtitle: const Text('Adoção responsável'))),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _housing,
              decoration: const InputDecoration(labelText: 'Tipo de moradia'),
              items: const [DropdownMenuItem(value:'Casa', child:Text('Casa')), DropdownMenuItem(value:'Apartamento', child:Text('Apartamento')), DropdownMenuItem(value:'Chácara', child:Text('Chácara')), DropdownMenuItem(value:'Outro', child:Text('Outro'))],
              onChanged: (value) => setState(() => _housing = value ?? 'Casa'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: '1',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade de pessoas na residência'),
              onChanged: (value) => _people = int.tryParse(value) ?? 1,
            ),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Possui quintal seguro?'), value: _yard, onChanged: (v) => setState(() => _yard = v)),
            SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Possui outros animais?'), value: _otherPets, onChanged: (v) => setState(() => _otherPets = v)),
            CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Todos da residência concordam com a adoção'), value: _everyoneAgrees, onChanged: (v) => setState(() => _everyoneAgrees = v ?? false)),
            const SizedBox(height: 8),
            TextFormField(controller: _reason, maxLines: 4, decoration: const InputDecoration(labelText: 'Por que deseja adotar? *'), validator: (value) => (value?.trim().length ?? 0) < 10 ? 'Explique sua motivação com mais detalhes.' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _experience, maxLines: 3, decoration: const InputDecoration(labelText: 'Experiência com animais')),
            const SizedBox(height: 12),
            TextFormField(controller: _notes, maxLines: 3, decoration: const InputDecoration(labelText: 'Observações')),
            const SizedBox(height: 20),
            FilledButton(onPressed: _loading ? null : _submit, child: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: _loading ? const CircularProgressIndicator() : const Text('Enviar solicitação'))),
          ],
        ),
      ),
    );
  }
}
