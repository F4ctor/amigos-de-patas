# Arquitetura e requisitos do sistema

## Arquitetura

```text
Aplicativo Flutter (Android)
          |
          | HTTP/JSON
          v
API REST PHP ---------------- Painel administrativo HTML/CSS/JS
          |
          | PDO
          v
       PostgreSQL
```

O aplicativo e o painel não acessam o banco diretamente. As regras de negócio, autenticação, validação e persistência ficam na API PHP.

## Perfis

### Usuário

- criar conta e entrar;
- visualizar animais;
- filtrar por espécie e porte;
- consultar detalhes;
- enviar solicitação de adoção;
- acompanhar o status da solicitação;
- visualizar campanhas, Pix, notícias e vídeos;
- encerrar a sessão.

### Administrador

- acessar indicadores;
- gerenciar animais;
- analisar adoções;
- administrar campanhas;
- publicar notícias e vídeos;
- gerenciar usuários;
- alterar dados institucionais e Pix;
- alterar sua senha.

## Status de animais

- `disponivel`;
- `em_analise`;
- `reservado`;
- `adotado`;
- `indisponivel`.

## Status de adoções

- `pendente`;
- `em_analise`;
- `entrevista`;
- `aprovada`;
- `recusada`;
- `cancelada`;
- `concluida`.

## Requisitos não funcionais principais

- interface responsiva e legível;
- comunicação em JSON;
- banco em UTF-8;
- senhas não armazenadas em texto simples;
- separação de permissões por perfil;
- imagens limitadas por formato e tamanho;
- estrutura modular para manutenção;
- uso local por AMPPS para apresentação acadêmica.
