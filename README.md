# Amigos de Patas

Aplicativo Android para consulta de animais, campanhas e notícias, cadastro de usuários e envio de pedidos de adoção.

## Tecnologias

- Kotlin e Jetpack Compose no aplicativo Android.
- Retrofit para comunicação HTTP com a API PHP.
- PostgreSQL para persistência dos dados.
- Docker Compose para executar a API e o banco localmente.

## Abrir no Android Studio

Clone ou baixe este repositório e abra sua pasta principal, que contém `settings.gradle.kts`. A pasta `app` é um módulo e não deve ser aberta isoladamente como projeto.

## Executar API e banco

1. Copie `.env.example` para `.env` e configure uma senha própria em `DB_PASSWORD`.
2. Na raiz do projeto, execute `docker compose up --build -d`.
3. Consulte `http://localhost:8080/amigosdepatas_server/api/public/home.php`.
4. Execute o aplicativo no emulador Android e crie uma conta.

O emulador usa `http://10.0.2.2:8080/amigosdepatas_server/`. Para um celular físico, ajuste `ApiConfig.kt` para o IP do computador na mesma rede.

## Estrutura

| Caminho | Conteúdo |
| --- | --- |
| `app/` | Aplicativo Android |
| `amigosdepatas_server/api/` | Rotas PHP |
| `amigosdepatas_server/src/` | Conexão PostgreSQL e validações |
| `amigosdepatas_server/database/schema.sql` | Estrutura do banco |
| `compose.yaml` | Serviços locais |
| `testes/test_api.py` | Roteiro de teste de integração |

Leia [as instruções completas de PostgreSQL](README_POSTGRESQL.md) para configuração manual, testes e limitações.

## Estado do projeto

A API PostgreSQL foi criada a partir dos contratos do aplicativo; o servidor e o banco anteriores não estavam no material fornecido. Não foram migrados dados antigos. O banco começa vazio, exceto pelo nome da organização.

Foi realizada conferência estática das nove rotas. A compilação Android e a integração com PHP/PostgreSQL ainda precisam ser executadas em um ambiente com essas ferramentas. A configuração HTTP é destinada ao desenvolvimento local. O login segue o contrato original, sem token de sessão, e as rotas públicas não exigem autenticação.
