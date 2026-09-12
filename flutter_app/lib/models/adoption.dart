class Adoption {
  const Adoption({
    required this.id,
    required this.animalNome,
    required this.status,
    this.respostaOng,
    this.dataSolicitacao,
  });

  final int id;
  final String animalNome;
  final String status;
  final String? respostaOng;
  final String? dataSolicitacao;

  factory Adoption.fromJson(Map<String, dynamic> json) {
    return Adoption(
      id: int.tryParse('${json['id']}') ?? 0,
      animalNome: '${json['animal_nome'] ?? ''}',
      status: '${json['status'] ?? ''}',
      respostaOng: json['resposta_ong']?.toString(),
      dataSolicitacao: json['data_solicitacao']?.toString(),
    );
  }
}
