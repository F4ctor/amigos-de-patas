class Campaign {
  const Campaign({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.meta,
    required this.valorArrecadado,
    this.imagem,
    this.chavePix,
  });

  final int id;
  final String titulo;
  final String descricao;
  final double meta;
  final double valorArrecadado;
  final String? imagem;
  final String? chavePix;

  double get progress => meta <= 0 ? 0 : (valorArrecadado / meta).clamp(0, 1).toDouble();

  factory Campaign.fromJson(Map<String, dynamic> json) {
    return Campaign(
      id: int.tryParse('${json['id']}') ?? 0,
      titulo: '${json['titulo'] ?? ''}',
      descricao: '${json['descricao'] ?? ''}',
      meta: double.tryParse('${json['meta']}') ?? 0,
      valorArrecadado: double.tryParse('${json['valor_arrecadado']}') ?? 0,
      imagem: json['imagem']?.toString(),
      chavePix: json['chave_pix']?.toString(),
    );
  }
}
