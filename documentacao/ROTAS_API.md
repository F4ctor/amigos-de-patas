# Rotas da API

Base local no navegador:

```text
http://localhost/ong_adocao/backend_api
```

Base no emulador Android:

```text
http://10.0.2.2/ong_adocao/backend_api
```

## Autenticação

| Método | Rota | Autenticação | Finalidade |
|---|---|---:|---|
| POST | `/auth/cadastro` | Não | Criar usuário |
| POST | `/auth/login` | Não | Entrar |
| POST | `/auth/logout` | Sim | Encerrar sessão |
| GET | `/auth/perfil` | Sim | Consultar perfil |
| PUT | `/auth/perfil` | Sim | Atualizar nome, telefone ou senha |

## Área do usuário

| Método | Rota | Finalidade |
|---|---|---|
| GET | `/animais` | Listar e filtrar animais |
| GET | `/animais/{id}` | Ver detalhes do animal |
| POST | `/adocoes` | Enviar solicitação |
| GET | `/minhas-adocoes` | Acompanhar solicitações |
| GET | `/campanhas` | Listar campanhas ativas |
| GET | `/noticias` | Listar notícias publicadas |
| GET | `/videos` | Listar vídeos publicados |
| GET | `/configuracoes/publicas` | Consultar dados públicos da ONG |

## Administração

Todas exigem token de administrador.

| Método | Rota | Finalidade |
|---|---|---|
| GET | `/admin/dashboard` | Indicadores gerais |
| POST | `/admin/upload` | Enviar imagem |
| GET/POST | `/admin/animais` | Listar ou criar animais |
| PUT/DELETE | `/admin/animais/{id}` | Editar ou excluir/inativar animal |
| GET | `/admin/adocoes` | Listar solicitações |
| PUT | `/admin/adocoes/{id}/status` | Atualizar análise |
| GET | `/admin/usuarios` | Listar usuários |
| PUT | `/admin/usuarios/{id}/status` | Ativar/inativar usuário |
| GET/POST | `/admin/campanhas` | Listar ou criar campanha |
| PUT/DELETE | `/admin/campanhas/{id}` | Editar ou excluir campanha |
| GET/POST | `/admin/noticias` | Listar ou criar notícia |
| PUT/DELETE | `/admin/noticias/{id}` | Editar ou excluir notícia |
| GET/POST | `/admin/videos` | Listar ou criar vídeo |
| PUT/DELETE | `/admin/videos/{id}` | Editar ou excluir vídeo |
| GET/PUT | `/admin/configuracoes` | Consultar ou alterar dados da ONG |
