import 'package:flutter/material.dart';

import '../models/adoption.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.client, required this.user, required this.onLogout});

  final ApiClient client;
  final Map<String, dynamic> user;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String? _error;
  List<Adoption> _adoptions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.client.get('/minhas-adocoes') as List;
      if (!mounted) return;
      setState(() {
        _adoptions = data.map((e) => Adoption.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() { _error = error.message; _loading = false; });
    }
  }

  Future<void> _logout() async {
    try { await widget.client.post('/auth/logout'); } catch (_) {}
    await widget.onLogout();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(children: [
                const CircleAvatar(radius: 34, child: Icon(Icons.person, size: 34)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.user['nome']?.toString() ?? 'Usuário', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19)),
                  const SizedBox(height: 4),
                  Text(widget.user['email']?.toString() ?? ''),
                  if (widget.user['telefone']?.toString().isNotEmpty == true) Text(widget.user['telefone'].toString()),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Text('Minhas solicitações', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_loading)
            const SizedBox(height: 180, child: LoadingView())
          else if (_error != null)
            SizedBox(height: 200, child: ErrorView(message: _error!, onRetry: _load))
          else if (_adoptions.isEmpty)
            const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Você ainda não enviou solicitações de adoção.')))
          else
            ..._adoptions.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.pets)),
                    title: Text(item.animalNome),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Status: ${item.status.replaceAll('_', ' ')}'),
                      if (item.respostaOng?.isNotEmpty == true) Text('Resposta da ONG: ${item.respostaOng}'),
                    ]),
                  ),
                )),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: _logout, icon: const Icon(Icons.logout), label: const Text('Sair da conta')),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
