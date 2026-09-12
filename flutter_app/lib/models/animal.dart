class Animal {
  const Animal({
    required this.id,
    required this.nome,
    required this.especie,
    required this.sexo,
    required this.porte,
    required this.status,
    this.raca,
    this.idadeAproximada,
    this.descricao,
    this.comportamento,
    this.estadoSaude,
    this.fotoPrincipal,
    this.vacinado = false,
    this.castrado = false,
  });

  final int id;
  final String nome;
  final String especie;
  final String sexo;
  final String porte;
  final String status;
  final String? raca;
  final String? idadeAproximada;
  final String? descricao;
  final String? comportamento;
  final String? estadoSaude;
  final String? fotoPrincipal;
  final bool vacinado;
  final bool castrado;

  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: int.tryParse('${json['id']}') ?? 0,
      nome: '${json['nome'] ?? ''}',
      especie: '${json['especie'] ?? ''}',
      sexo: '${json['sexo'] ?? ''}',
      porte: '${json['porte'] ?? ''}',
      status: '${json['status'] ?? ''}',
      raca: json['raca']?.toString(),
      idadeAproximada: json['idade_aproximada']?.toString(),
      descricao: json['descricao']?.toString(),
      comportamento: json['comportamento']?.toString(),
      estadoSaude: json['estado_saude']?.toString(),
      fotoPrincipal: json['foto_principal']?.toString(),
      vacinado: json['vacinado'] == true || json['vacinado'] == 1,
      castrado: json['castrado'] == true || json['castrado'] == 1,
    );
  }
}
