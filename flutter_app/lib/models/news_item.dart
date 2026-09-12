class NewsItem {
  const NewsItem({
    required this.id,
    required this.titulo,
    required this.conteudo,
    this.resumo,
    this.imagem,
    this.dataPublicacao,
  });

  final int id;
  final String titulo;
  final String conteudo;
  final String? resumo;
  final String? imagem;
  final String? dataPublicacao;

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: int.tryParse('${json['id']}') ?? 0,
      titulo: '${json['titulo'] ?? ''}',
      conteudo: '${json['conteudo'] ?? ''}',
      resumo: json['resumo']?.toString(),
      imagem: json['imagem']?.toString(),
      dataPublicacao: json['data_publicacao']?.toString(),
    );
  }
}
