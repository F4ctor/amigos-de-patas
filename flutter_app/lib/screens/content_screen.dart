import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/news_item.dart';
import '../services/api_client.dart';
import '../widgets/common.dart';

class ContentScreen extends StatefulWidget {
  const ContentScreen({super.key, required this.client});
  final ApiClient client;

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  String? _error;
  List<NewsItem> _news = const [];
  List<Map<String, dynamic>> _videos = const [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([widget.client.get('/noticias'), widget.client.get('/videos')]);
      if (!mounted) return;
      setState(() {
        _news = (results[0] as List).map((e) => NewsItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        _videos = (results[1] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

    return Column(children: [
      TabBar(controller: _tabs, tabs: const [Tab(text: 'Notícias'), Tab(text: 'Vídeos')]),
      Expanded(
        child: TabBarView(controller: _tabs, children: [
          _news.isEmpty
              ? const EmptyView(icon: Icons.article_outlined, message: 'Nenhuma notícia publicada.')
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _news.length,
                    itemBuilder: (context, index) {
                      final item = _news[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        margin: const EdgeInsets.only(bottom: 14),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewsDetailsScreen(item: item))),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            if (item.imagem?.isNotEmpty == true) networkImage(item.imagem, height: 170, width: double.infinity),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                const SizedBox(height: 7),
                                Text(item.resumo?.isNotEmpty == true ? item.resumo! : item.conteudo, maxLines: 3, overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
          _videos.isEmpty
              ? const EmptyView(icon: Icons.video_library_outlined, message: 'Nenhum vídeo publicado.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    final rawUrl = video['url']?.toString() ?? '';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.play_arrow)),
                        title: Text(video['titulo']?.toString() ?? ''),
                        subtitle: Text('${video['descricao'] ?? ''}\n$rawUrl'),
                        trailing: const Icon(Icons.open_in_new),
                        isThreeLine: true,
                        onTap: rawUrl.isEmpty
                            ? null
                            : () async {
                                final uri = Uri.tryParse(rawUrl);
                                try {
                                  if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                    throw Exception('URL inválida');
                                  }
                                } catch (_) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Não foi possível abrir este vídeo.')),
                                    );
                                  }
                                }
                              },
                      ),
                    );
                  },
                ),
        ]),
      ),
    ]);
  }
}

class NewsDetailsScreen extends StatelessWidget {
  const NewsDetailsScreen({super.key, required this.item});
  final NewsItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notícia')),
      body: ListView(children: [
        if (item.imagem?.isNotEmpty == true) networkImage(item.imagem, height: 250, width: double.infinity),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.titulo, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(item.conteudo, style: const TextStyle(fontSize: 16, height: 1.5)),
          ]),
        ),
      ]),
    );
  }
}
