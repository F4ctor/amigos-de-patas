<?php
declare(strict_types=1);
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store');
function respond(array $data, int $status = 200): never {
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_THROW_ON_ERROR);
    exit;
}
set_exception_handler(function (Throwable $e): void {
    error_log('API error: ' . get_class($e) . ' code=' . $e->getCode());
    respond(['success' => false, 'message' => 'Erro no servidor. Verifique a configuração do banco.'], 500);
});
function db(): PDO {
    static $pdo = null;
    if ($pdo === null) {
        $password = getenv('DB_PASSWORD');
        if ($password === false || $password === '') throw new RuntimeException('DB_PASSWORD required');
        $host = getenv('DB_HOST') ?: '127.0.0.1';
        $port = getenv('DB_PORT') ?: '5432';
        $name = getenv('DB_NAME') ?: 'amigosdepatas';
        $ssl = getenv('DB_SSLMODE') ?: 'prefer';
        foreach ([$host, $port, $name, $ssl] as $v) {
            if (strpbrk($v, ";\r\n") !== false) throw new RuntimeException('Invalid DB configuration');
        }
        $pdo = new PDO("pgsql:host=$host;port=$port;dbname=$name;sslmode=$ssl;connect_timeout=5",
            getenv('DB_USER') ?: 'amigosdepatas', $password,
            [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
             PDO::ATTR_EMULATE_PREPARES => false]);
    }
    return $pdo;
}
function method(string $expected): void {
    if ($_SERVER['REQUEST_METHOD'] !== $expected) {
        header('Allow: ' . $expected);
        respond(['success' => false, 'message' => 'Método não permitido.'], 405);
    }
}
function body(): array {
    $raw = file_get_contents('php://input', false, null, 0, 16385);
    if (strlen($raw) > 16384) respond(['success'=>false,'message'=>'Corpo muito grande.'], 413);
    try { $data = json_decode($raw, true, 32, JSON_THROW_ON_ERROR); }
    catch (JsonException $e) { respond(['success'=>false,'message'=>'JSON inválido.'], 400); }
    if (!is_array($data)) respond(['success'=>false,'message'=>'Objeto JSON obrigatório.'], 400);
    return $data;
}
function field(array $data, string $key, int $max, bool $required = true): string {
    $v = $data[$key] ?? '';
    if (!is_string($v)) respond(['success'=>false,'message'=>"Campo inválido: $key."], 400);
    $v = $key === 'password' ? $v : trim($v);
    if (($required && $v === '') || strlen($v) > $max)
        respond(['success'=>false,'message'=>"Preencha corretamente: $key."], 400);
    return $v;
}
function emailField(array $data): string {
    $email = strtolower(field($data, 'email', 254));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) respond(['success'=>false,'message'=>'E-mail inválido.'], 400);
    return $email;
}
function rows(string $sql): array { return db()->query($sql)->fetchAll(); }
