# Amigos de Patas — ONG Adoção

Projeto acadêmico em **Flutter/Dart**, com painel administrativo HTML/CSS/JavaScript, API REST PHP e banco **PostgreSQL**.

Esta é a base correta `ONG_Adocao_TCC_FLOAT_DOCK_v1.3.0`. A interface com navegação inferior flutuante e o modo administrador foram preservados.

| Pasta | Finalidade |
| --- | --- |
| `flutter_app/` | Aplicativo Flutter; abra esta pasta no Android Studio |
| `painel_admin/` | Painel administrativo web |
| `backend_api/` | API PHP, autenticação, sessões e uploads |
| `database/` | Esquema PostgreSQL e dados opcionais de demonstração |
| `documentacao/` | Requisitos, rotas e plano de testes |

## Iniciar

Copie `.env.example` para `.env`, defina `DB_PASS` e execute `docker compose up --build -d`.

Painel local: `http://localhost:8080/ong_adocao/painel_admin/login.html`.

No Android Studio, abra **`flutter_app`**, que contém **`pubspec.yaml`**, e execute `flutter pub get` e `flutter run`.

Consulte [o guia completo](README_PRIMEIROS_PASSOS.md) para instalação pelo pgAdmin/AMPPS, conta de demonstração, configuração do celular e testes.

A versão Android nativa/Kotlin enviada anteriormente permanece no histórico Git. Este commit corrige a base do projeto. A execução PHP/PostgreSQL e a compilação Flutter precisam ser verificadas no ambiente local conforme o relatório de validação.
