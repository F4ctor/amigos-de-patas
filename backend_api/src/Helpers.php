<?php
declare(strict_types=1);

function requestData(): array
{
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    if (str_contains(strtolower($contentType), 'application/json')) {
        $raw = file_get_contents('php://input') ?: '';
        if ($raw === '') {
            return [];
        }
        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            Response::error('JSON inválido.', 400);
        }
        return $decoded;
    }

    return $_POST;
}

function routePath(): string
{
    $route = $_GET['route'] ?? null;
    if (is_string($route) && $route !== '') {
        return '/' . trim($route, '/');
    }

    $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    $script = str_replace('\\', '/', dirname($_SERVER['SCRIPT_NAME'] ?? ''));
    if ($script !== '/' && str_starts_with($uri, $script)) {
        $uri = substr($uri, strlen($script));
    }
    $uri = preg_replace('#^/index\.php#', '', $uri) ?: '/';
    return '/' . trim($uri, '/');
}

function requireFields(array $data, array $fields): void
{
    $missing = [];
    foreach ($fields as $field) {
        $value = $data[$field] ?? null;
        if ($value === null || (is_string($value) && trim($value) === '')) {
            $missing[$field] = 'Campo obrigatório.';
        }
    }
    if ($missing) {
        Response::error('Preencha os campos obrigatórios.', 422, $missing);
    }
}

function boolValue(mixed $value): int
{
    return filter_var($value, FILTER_VALIDATE_BOOL) ? 1 : 0;
}

function nullableString(mixed $value): ?string
{
    if ($value === null) {
        return null;
    }
    $value = trim((string)$value);
    return $value === '' ? null : $value;
}

function apiBasePath(): string
{
    $scriptName = str_replace('\\', '/', $_SERVER['SCRIPT_NAME'] ?? '/backend_api/index.php');
    $directory = str_replace('\\', '/', dirname($scriptName));
    return '/' . trim($directory, '/');
}

function publicBaseUrl(): string
{
    $scheme = (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') ? 'https' : 'http';
    $host = $_SERVER['HTTP_HOST'] ?? 'localhost';
    return $scheme . '://' . $host;
}

function normalizeMediaUrl(?string $url): ?string
{
    if (!$url) {
        return null;
    }
    if (preg_match('#^https?://#i', $url)) {
        return $url;
    }

    $clean = ltrim($url, '/');
    if (str_starts_with($clean, 'uploads/')) {
        return publicBaseUrl() . apiBasePath() . '/' . $clean;
    }
    if (str_starts_with($clean, 'backend_api/')) {
        $projectBase = str_replace('\\', '/', dirname(apiBasePath()));
        return publicBaseUrl() . '/' . trim($projectBase . '/' . $clean, '/');
    }

    return publicBaseUrl() . '/' . $clean;
}

function normalizeAnimal(array $row): array
{
    foreach (['id'] as $key) {
        if (isset($row[$key])) {
            $row[$key] = (int)$row[$key];
        }
    }
    foreach (['vacinado', 'castrado'] as $key) {
        if (array_key_exists($key, $row)) {
            $row[$key] = (bool)$row[$key];
        }
    }
    if (array_key_exists('foto_principal', $row)) {
        $row['foto_principal'] = normalizeMediaUrl($row['foto_principal']);
    }
    return $row;
}

function adminLog(int $adminId, string $action, ?string $table = null, ?int $recordId = null, ?string $details = null): void
{
    $stmt = Database::connection()->prepare(
        'INSERT INTO logs_administrativos (administrador_id, acao, tabela_afetada, registro_id, detalhes, endereco_ip)
         VALUES (?, ?, ?, ?, ?, ?)'
    );
    $stmt->execute([
        $adminId,
        $action,
        $table,
        $recordId,
        $details,
        $_SERVER['REMOTE_ADDR'] ?? null,
    ]);
}
