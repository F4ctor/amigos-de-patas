# Aplicativo Flutter - ONG Adoção

## Abrir no Android Studio

1. Instale o Flutter SDK e os plugins Flutter/Dart no Android Studio.
2. Abra esta pasta `flutter_app` como projeto.
3. Execute `flutter pub get`.
4. Confirme o endereço da API em `lib/config/api_config.dart`.
5. Inicie um emulador Android e execute `flutter run`.

### Endereço da API

- Emulador Android: `http://10.0.2.2:8080/ong_adocao/backend_api`
- Celular físico: substitua `10.0.2.2` pelo IP local do computador.

A sessão do usuário é mantida no aparelho com o pacote oficial `shared_preferences`.


## Navegação flutuante — versão 1.2.0

A navegação inferior foi atualizada para um estilo moderno e flutuante, com margem em relação às bordas da tela, cantos arredondados, sombra suave, indicador animado da seção selecionada e suporte automático à opção **Admin** quando o usuário autenticado possui `tipo = administrador`.
