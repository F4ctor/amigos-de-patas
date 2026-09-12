<?php
declare(strict_types=1);

final class Database
{
    private static ?PDO $connection = null;

    public static function connection(): PDO
    {
        if (self::$connection instanceof PDO) {
            return self::$connection;
        }

        if (DB_PASS === '') {
            throw new RuntimeException('Configure DB_PASS no servidor ou config.local.php.');
        }
        foreach ([DB_HOST, DB_PORT, DB_NAME, DB_SSLMODE] as $value) {
            if (strpbrk((string)$value, ";\r\n") !== false) {
                throw new RuntimeException('Parâmetro de conexão inválido.');
            }
        }
        $dsn = sprintf('pgsql:host=%s;port=%d;dbname=%s;sslmode=%s;connect_timeout=5',
            DB_HOST, (int)DB_PORT, DB_NAME, DB_SSLMODE);

        self::$connection = new PDO($dsn, DB_USER, DB_PASS, [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
        ]);

        self::$connection->exec("SET TIME ZONE 'America/Sao_Paulo'");
        self::$connection->exec("SET client_encoding TO 'UTF8'");
        return self::$connection;
    }
}
