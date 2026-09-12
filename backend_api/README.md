# API PHP + PostgreSQL

Instale PHP 8.1+ com pdo_pgsql, mbstring e fileinfo. Configure as variáveis DB_HOST, DB_PORT, DB_NAME, DB_USER, DB_PASS e DB_SSLMODE no servidor ou copie `config/config.local.example.php` para `config/config.local.php` e preencha os valores.

O Compose usa PostgreSQL 16 e PHP 8.3. Na instalação manual, o AMPPS fornece Apache/PHP e o PostgreSQL é executado separadamente. Importe `database/ong_adocao.sql` pelo pgAdmin/psql e, opcionalmente, os dados de demonstração.

Consulte [o guia de execução](../README_PRIMEIROS_PASSOS.md). O arquivo .env é lido pelo Compose; não é carregado automaticamente pelo PHP fora do Docker.
