import 'package:flutter/material.dart';

import '../services/api_client.dart';

typedef AuthenticatedCallback = Future<void> Function(String token, Map<String, dynamic> user);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onAuthenticated});

  final AuthenticatedCallback onAuthenticated;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _registerMode = false;
  bool _acceptedPrivacy = false;
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_registerMode && !_acceptedPrivacy) {
      _showMessage('Aceite a política de privacidade para continuar.');
      return;
    }

    setState(() => _loading = true);
    try {
      final client = ApiClient();
      final data = await client.post(
        _registerMode ? '/auth/cadastro' : '/auth/login',
        body: _registerMode
            ? {
                'nome': _nameController.text.trim(),
                'email': _emailController.text.trim(),
                'telefone': _phoneController.text.trim(),
                'senha': _passwordController.text,
                'aceitou_privacidade': _acceptedPrivacy,
              }
            : {
                'email': _emailController.text.trim(),
                'senha': _passwordController.text,
              },
      ) as Map<String, dynamic>;
      await widget.onAuthenticated(
        data['token'].toString(),
        Map<String, dynamic>.from(data['usuario'] as Map),
      );
    } on ApiException catch (error) {
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CircleAvatar(
                          radius: 38,
                          backgroundColor: Color(0xFFE8F5EE),
                          child: Icon(Icons.pets, size: 42, color: Color(0xFF146C43)),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          _registerMode ? 'Criar conta' : 'Bem-vindo',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _registerMode
                              ? 'Cadastre-se para solicitar uma adoção responsável.'
                              : 'Entre para conhecer os animais e acompanhar suas solicitações.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        if (_registerMode) ...[
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(labelText: 'Nome completo', prefixIcon: Icon(Icons.person_outline)),
                            validator: (value) => value == null || value.trim().length < 3 ? 'Informe seu nome.' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined)),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.email_outlined)),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            return !text.contains('@') ? 'Informe um e-mail válido.' : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _hidePassword,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              onPressed: () => setState(() => _hidePassword = !_hidePassword),
                              icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            ),
                          ),
                          validator: (value) => (value?.length ?? 0) < 8 ? 'Use pelo menos 8 caracteres.' : null,
                        ),
                        if (_registerMode) ...[
                          const SizedBox(height: 10),
                          CheckboxListTile(
                            contentPadding: EdgeInsets.zero,
                            value: _acceptedPrivacy,
                            onChanged: (value) => setState(() => _acceptedPrivacy = value ?? false),
                            title: const Text('Aceito o uso dos dados para cadastro e análise de adoção.'),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ],
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _loading ? null : _submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: _loading
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                                : Text(_registerMode ? 'Cadastrar' : 'Entrar'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() {
                                    _registerMode = !_registerMode;
                                    _acceptedPrivacy = false;
                                  }),
                          child: Text(_registerMode ? 'Já possuo uma conta' : 'Ainda não tenho uma conta'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
