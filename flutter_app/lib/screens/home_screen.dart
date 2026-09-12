import 'package:flutter/material.dart';

import '../models/animal.dart';
import '../models/campaign.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.client, required this.onNavigate});

  final ApiClient client;
  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String? _error;
  List<Animal> _animals = const [];
  List<Campaign> _campaigns = const [];
  Map<String, dynamic> _config = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        widget.client.get('/animais', query: {'status': 'disponivel'}),
        widget.client.get('/campanhas'),
        widget.client.get('/configuracoes/publicas'),
      ]);
      if (!mounted) return;
      setState(() {
        _animals = (results[0] as List).map((e) => Animal.fromJson(Map<String, dynamic>.from(e as Map))).take(4).toList();
        _campaigns = (results[1] as List).map((e) => Campaign.fromJson(Map<String, dynamic>.from(e as Map))).take(2).toList();
        _config = Map<String, dynamic>.from(results[2] as Map);
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF146C43), Color(0xFF249A68)]),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _config['nome_ong']?.toString() ?? 'ONG de Proteção Animal',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Ajude a transformar resgates em novas histórias.', style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => widget.onNavigate(1),
                      icon: const Icon(Icons.pets),
                      label: const Text('Quero adotar'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70)),
                      onPressed: () => widget.onNavigate(2),
                      icon: const Icon(Icons.volunteer_activism_outlined),
                      label: const Text('Fazer uma doação'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Animais esperando por uma família', onTap: () => widget.onNavigate(1)),
          const SizedBox(height: 10),
          if (_animals.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Nenhum animal disponível no momento.')))
          else
            SizedBox(
              height: 245,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _animals.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final animal = _animals[index];
                  return SizedBox(
                    width: 190,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          networkImage(animal.fotoPrincipal, height: 135, width: double.infinity),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(animal.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                              const SizedBox(height: 4),
                              Text('${animal.especie} · ${animal.porte}'.replaceAll('_', ' ')),
                            ]),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Campanhas em andamento', onTap: () => widget.onNavigate(2)),
          const SizedBox(height: 10),
          ..._campaigns.map((campaign) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(campaign.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text(campaign.descricao, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: campaign.progress),
                    const SizedBox(height: 6),
                    Text('Arrecadado: R\$ ${campaign.valorArrecadado.toStringAsFixed(2)} de R\$ ${campaign.meta.toStringAsFixed(2)}'),
                  ]),
                ),
              )),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.info_outline)),
              title: const Text('Sobre a iniciativa'),
              subtitle: Text(_config['descricao']?.toString() ?? 'Aplicativo acadêmico de apoio à proteção animal.'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onTap});
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold))),
      TextButton(onPressed: onTap, child: const Text('Ver tudo')),
    ]);
  }
}
