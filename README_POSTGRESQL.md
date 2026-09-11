# Amigos de Patas — PostgreSQL

## O que foi alterado

O anexo continha o aplicativo Android/Kotlin, que chama uma API PHP com Retrofit. Não continha o servidor PHP, esquema SQL ou exportação de dados. Esta entrega adiciona uma implementação da API compatível com os modelos e rotas do aplicativo, usando PostgreSQL. Não é uma migração dos registros do banco anterior.

Arquitetura: aplicativo Android → API PHP → PostgreSQL. As credenciais do banco ficam apenas no servidor. O aplicativo não precisa de um driver PostgreSQL.

- `amigosdepatas_server/database/schema.sql`: tabelas users, animals, campaigns, news, settings e adoption_requests, com chaves, restrições e índice.
- `amigosdepatas_server/api/`: nove rotas usadas pelo aplicativo.
- `amigosdepatas_server/src/bootstrap.php`: conexão PDO PostgreSQL por variáveis de ambiente e validação de entradas.
- `compose.yaml`: banco PostgreSQL 16 e servidor PHP 8.3 com pdo_pgsql.
- `ApiConfig.kt`: endereço do emulador atualizado para a porta 8080.
- `ApiService.kt`: log de conteúdo desativado para não registrar senhas e dados pessoais.

As telas e os modelos originais foram preservados. Arquivos gerados de compilação e caches da IDE não foram incluídos; o Android Studio os recria.

## Executar com Docker Compose

1. Instale e inicie o Docker com suporte ao Compose.
2. Na pasta onde está `compose.yaml`, copie `.env.example` para `.env`.
   - Windows PowerShell: `Copy-Item .env.example .env`
   - Linux: `cp .env.example .env`
3. Edite `.env` e substitua o valor de `DB_PASSWORD` por uma senha própria.
4. Execute:

```sh
docker compose up --build -d
```

5. Abra `http://localhost:8080/amigosdepatas_server/api/public/home.php`. A resposta deve ter `success: true` e contadores inicialmente zerados.
6. Abra o projeto no Android Studio, sincronize o Gradle e execute no emulador. Faça um cadastro com senha entre 8 e 72 bytes e entre com a conta criada.

O esquema é criado automaticamente na primeira inicialização de um volume vazio. Para reaplicar o esquema de forma não destrutiva:

```sh
docker compose exec -T db psql -U amigosdepatas -d amigosdepatas -v ON_ERROR_STOP=1 < amigosdepatas_server/database/schema.sql
```

Esse comando usa redirecionamento de shell; execute em Bash ou CMD. `CREATE TABLE IF NOT EXISTS` não atualiza tabelas antigas com outra estrutura: um banco preexistente exige uma migração específica.

Para consultar os dados:

```sh
docker compose exec db psql -U amigosdepatas -d amigosdepatas
```

No psql: `SELECT id, name, email FROM users;`. Para sair, use `\q`.

Para parar sem excluir os dados: `docker compose down`. Os dados ficam no volume `postgres_data`.

## Celular físico

Em `app/src/main/java/com/acj/amigosdepatas/data/ApiConfig.kt`, troque `10.0.2.2` pelo IP do computador na rede, mantendo a porta 8080 e o caminho. Celular e computador devem estar na mesma rede, com acesso à porta 8080. `10.0.2.2` é o endereço usado pelo emulador para alcançar o computador.

## Usar PostgreSQL e PHP já instalados

Crie um usuário `amigosdepatas` com senha própria e um banco `amigosdepatas` pertencente a ele. Execute `schema.sql` conectado a esse banco com esse usuário. Habilite `pdo_pgsql` no PHP 8.1 ou superior e configure no processo do servidor:

```text
DB_HOST=127.0.0.1
DB_PORT=5432
DB_NAME=amigosdepatas
DB_USER=amigosdepatas
DB_PASSWORD=sua_senha
DB_SSLMODE=prefer
```

Sirva a pasta `amigosdepatas_server` por Apache/PHP e ajuste a porta em `ApiConfig.kt` caso o servidor use outra porta. O arquivo `.env` é lido pelo Docker Compose; PHP fora do Docker precisa receber essas variáveis pelo ambiente do servidor. Não publique `.env` ou os scripts SQL no diretório público.

## Dados e escopo

O banco começa vazio, exceto pelo nome da organização em settings. Não foram inventados animais, notícias, chaves Pix ou usuários. Cadastre os conteúdos pelo SQL/pgAdmin. A entrega não inclui painel administrativo, pois ele não estava no anexo. `image_path` pode receber uma URL HTTPS completa; para arquivos relativos, é necessário disponibilizá-los no servidor no caminho correspondente.

Login valida a senha e devolve o usuário, seguindo o contrato original. O app original não possui token de sessão; as rotas públicas continuam públicas e o pedido de adoção não é associado a um usuário autenticado. Antes de exposição pública, implemente autenticação de operações privadas, limitação de requisições e HTTPS. HTTP está mantido para desenvolvimento local.

Para transferir os registros antigos, é necessário fornecer a exportação SQL e o servidor original. Os nomes de tabelas nesta entrega foram definidos a partir dos modelos Android, sem evidência do esquema anterior.

## Verificação

Foi feita conferência estática das nove rotas e dos campos usados pelos modelos Kotlin. O ambiente de edição não tem PHP, PostgreSQL, Docker nem Android SDK disponíveis para executar a integração ou compilar o APK. Portanto, não foi confirmado um teste ponta a ponta. O roteiro automatizado abaixo deve ser executado contra o servidor local após subir o Compose; ele cria uma conta de teste e verifica cadastro, duplicidade, login válido/inválido e consultas públicas:

```sh
python3 testes/test_api.py
```

Referências técnicas: https://www.php.net/manual/en/ref.pdo-pgsql.php e https://www.postgresql.org/docs/16/ddl-identity-columns.html.
