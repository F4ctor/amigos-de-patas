<?php
declare(strict_types=1);

// Variáveis do servidor ou arquivo local ignorado pelo Git.
$local = is_file(__DIR__ . '/config.local.php') ? require __DIR__ . '/config.local.php' : [];
if (!is_array($local)) { throw new RuntimeException('Configuração local inválida.'); }
foreach (['DB_HOST'=>'127.0.0.1', 'DB_PORT'=>'5432', 'DB_NAME'=>'ong_adocao',
          'DB_USER'=>'ong_adocao', 'DB_PASS'=>'', 'DB_SSLMODE'=>'prefer'] as $key=>$fallback) {
    $value = getenv($key);
    define($key, $value !== false ? $value : ($local[$key] ?? $fallback));
}

const TOKEN_TTL_DAYS = 30;
const MAX_UPLOAD_BYTES = 5 * 1024 * 1024;
const ALLOWED_UPLOAD_MIME = ['image/jpeg', 'image/png', 'image/webp'];

const APP_TIMEZONE = 'America/Sao_Paulo';
date_default_timezone_set(APP_TIMEZONE);

const UPLOAD_DIR = __DIR__ . '/../uploads';

if (!is_dir(UPLOAD_DIR)) {
    @mkdir(UPLOAD_DIR, 0775, true);
}
