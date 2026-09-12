import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({this.token});

  String? token;

  Future<dynamic> get(String path, {Map<String, String>? query}) {
    return _request('GET', path, query: query);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) {
    return _request('POST', path, body: body);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) {
    return _request('PUT', path, body: body);
  }

  Future<dynamic> delete(String path, {Map<String, dynamic>? body}) {
    return _request('DELETE', path, body: body);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final base = Uri.parse(ApiConfig.baseUrl);
    final uri = base.replace(
      path: '${base.path}${path.startsWith('/') ? path : '/$path'}',
      queryParameters: query?.isEmpty == true ? null : query,
    );

    final client = HttpClient();
    client.connectionTimeout = ApiConfig.timeout;

    try {
      final request = await client.openUrl(method, uri).timeout(ApiConfig.timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json; charset=utf-8');
      if (token != null && token!.isNotEmpty) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        // Fallback para ambientes AMPPS/Apache que podem remover Authorization.
        request.headers.set('X-Auth-Token', token!);
      }
      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close().timeout(ApiConfig.timeout);
      final text = await response.transform(utf8.decoder).join();
      Map<String, dynamic> json = <String, dynamic>{};
      if (text.trim().isNotEmpty) {
        final decoded = jsonDecode(text);
        if (decoded is Map<String, dynamic>) json = decoded;
      }

      if (response.statusCode < 200 || response.statusCode >= 300 || json['success'] != true) {
        throw ApiException(
          (json['message'] ?? 'Não foi possível concluir a solicitação.').toString(),
          statusCode: response.statusCode,
        );
      }
      return json['data'];
    } on SocketException {
      throw const ApiException(
        'Não foi possível conectar ao servidor. Verifique o AMPPS, o Apache, o MySQL e o endereço da API.',
      );
    } on TimeoutException {
      throw const ApiException('O servidor demorou muito para responder.');
    } on FormatException {
      throw const ApiException('O servidor retornou uma resposta inválida.');
    } finally {
      client.close(force: true);
    }
  }
}
