# Plano de testes para apresentação do TCC

## Preparação

- Apache e PostgreSQL iniciados;
- banco importado;
- API respondendo;
- painel acessível;
- emulador Android conectado.

## Cenário 1 — Administração de animal

1. Entrar no painel;
2. cadastrar um animal com foto;
3. confirmar que aparece na lista;
4. abrir o aplicativo;
5. confirmar que aparece no catálogo;
6. editar o status no painel;
7. atualizar o aplicativo e confirmar a alteração.

## Cenário 2 — Cadastro e login

1. No aplicativo, selecionar criar conta;
2. preencher nome, e-mail, telefone e senha;
3. aceitar a política de privacidade;
4. concluir o cadastro;
5. sair e entrar novamente.

## Cenário 3 — Adoção responsável

1. Abrir um animal disponível;
2. tocar em solicitar adoção;
3. preencher o formulário;
4. confirmar a concordância dos moradores;
5. enviar;
6. entrar no painel e abrir Solicitações;
7. mudar o status para entrevista ou aprovada;
8. voltar ao perfil no aplicativo e atualizar a lista.

## Cenário 4 — Campanha e Pix

1. Criar uma campanha no painel;
2. informar meta, valor arrecadado e chave Pix;
3. abrir Doações no aplicativo;
4. confirmar a barra de progresso;
5. copiar a chave Pix.

## Cenário 5 — Comunicação institucional

1. Publicar uma notícia;
2. cadastrar um vídeo;
3. atualizar a área Conteúdo do aplicativo;
4. confirmar a exibição dos dois conteúdos.

## Resultado esperado

Os dados cadastrados no painel devem ser persistidos no PostgreSQL e refletidos no aplicativo por meio da API PHP.
