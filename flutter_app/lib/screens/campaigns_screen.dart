import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/campaign.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';

class CampaignsScreen extends StatefulWidget {
  const CampaignsScreen({super.key, required this.client});
  final ApiClient client;

  @override
  State<CampaignsScreen> createState() => _CampaignsScreenState();
}

class _CampaignsScreenState extends State<CampaignsScreen> {
  bool _loading = true;
  String? _error;
  List<Campaign> _campaigns = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await widget.client.get('/campanhas') as List;
      if (!mounted) return;
      setState(() {
        _campaigns = data.map((e) => Campaign.fromJson(Map<String, dynamic>.from(e as Map))).toList();
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
    if (_campaigns.isEmpty) return const EmptyView(icon: Icons.volunteer_activism_outlined, message: 'Nenhuma campanha ativa no momento.');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _campaigns.length,
        itemBuilder: (context, index) {
          final campaign = _campaigns[index];
          return Card(
            clipBehavior: Clip.antiAlias,
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (campaign.imagem?.isNotEmpty == true)
                  networkImage(campaign.imagem, height: 190, width: double.infinity),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(campaign.titulo, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(campaign.descricao),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(value: campaign.progress, minHeight: 9, borderRadius: BorderRadius.circular(20)),
                    const SizedBox(height: 8),
                    Text('R\$ ${campaign.valorArrecadado.toStringAsFixed(2)} arrecadados de R\$ ${campaign.meta.toStringAsFixed(2)}'),
                    if (campaign.chavePix?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: const Color(0xFFE8F5EE), borderRadius: BorderRadius.circular(14)),
                        child: Row(children: [
                          const Icon(Icons.pix, color: Color(0xFF146C43)),
                          const SizedBox(width: 10),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Chave Pix', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(campaign.chavePix!),
                          ])),
                          IconButton(
                            tooltip: 'Copiar chave Pix',
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: campaign.chavePix!));
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chave Pix copiada.')));
                            },
                            icon: const Icon(Icons.copy_outlined),
                          ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text('A confirmação e a prestação de contas da doação são realizadas pela ONG.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
