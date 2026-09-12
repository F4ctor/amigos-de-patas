class ApiConfig {
  ApiConfig._();

  // Emulador Android. No celular físico, informe o IP do computador
  // com --dart-define=API_BASE_URL=http://IP:8080/ong_adocao/backend_api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/ong_adocao/backend_api',
  );

  static const Duration timeout = Duration(seconds: 20);
}
