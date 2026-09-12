# Modo Administrador no aplicativo Flutter

## Funcionamento

O aplicativo usa o mesmo endpoint de login para usuários comuns e administradores.
A API devolve o objeto `usuario`, incluindo o campo `tipo`.

- `tipo = usuario`: o aplicativo mostra apenas as funções normais.
- `tipo = administrador`: o aplicativo adiciona a opção **Admin** na barra de navegação.

A segurança não depende apenas da interface. Todas as rotas `/admin/...` continuam protegidas no backend PHP com `Auth::user(true, ['administrador'])`.

## Área Admin adicionada ao Flutter

A tela `lib/screens/admin_screen.dart` possui oito seções:

1. Painel / dashboard
2. Animais
3. Solicitações de adoção
4. Usuários
5. Campanhas
6. Notícias
7. Vídeos
8. Configurações da ONG

### Dashboard

Mostra contadores de animais, animais disponíveis, adoções pendentes, usuários e campanhas ativas, além das últimas solicitações.

### Animais

Permite cadastrar, editar e excluir/inativar animais utilizando `/admin/animais`.

### Adoções

Permite visualizar os dados da solicitação, alterar o status e registrar a resposta da ONG.

### Usuários

Permite ativar e inativar usuários comuns. O administrador não pode ser desativado por essa tela.

### Campanhas, notícias e vídeos

Permitem criar, editar e excluir registros usando as rotas administrativas já existentes.

### Configurações

Permite alterar os dados institucionais da ONG, chave Pix, redes sociais e política de privacidade.

## Autenticação no AMPPS

O `ApiClient` envia o token por dois cabeçalhos:

- `Authorization: Bearer TOKEN`
- `X-Auth-Token: TOKEN`

O segundo cabeçalho funciona como fallback para instalações Apache/AMPPS que não repassam `Authorization` corretamente ao PHP.

## Endereço atual da API

O arquivo `lib/config/api_config.dart` está configurado para:

`http://192.168.1.15/ong_adocao/backend_api`

Se o IPv4 do computador mudar, altere somente essa linha.

## Administrador inicial do SQL

- E-mail: `admin@ong.local`
- Senha: `Admin@123`

O SQL armazena somente o hash da senha.
