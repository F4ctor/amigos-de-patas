<?php
declare(strict_types=1);

final class Auth
{
    /**
     * Localiza o token de autenticação em ambientes Apache/PHP diferentes.
     * Alguns pacotes locais, incluindo certas configurações do AMPPS,
     * não repassam o cabeçalho Authorization para HTTP_AUTHORIZATION.
     */
    public static function bearerToken(): ?string
    {
        $headers = [];

        // Variáveis mais comuns no Apache, CGI e FastCGI.
        foreach ([
            $_SERVER['HTTP_AUTHORIZATION'] ?? null,
            $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? null,
            $_SERVER['Authorization'] ?? null,
            $_SERVER['HTTP_X_AUTH_TOKEN'] ?? null,
            getenv('HTTP_AUTHORIZATION') ?: null,
            getenv('REDIRECT_HTTP_AUTHORIZATION') ?: null,
        ] as $value) {
            if (is_string($value) && trim($value) !== '') {
                $headers[] = trim($value);
            }
        }

        // Recupera o cabeçalho diretamente do Apache quando disponível.
        foreach (['getallheaders', 'apache_request_headers'] as $function) {
            if (!function_exists($function)) {
                continue;
            }

            $requestHeaders = $function();
            if (!is_array($requestHeaders)) {
                continue;
            }

            foreach ($requestHeaders as $name => $value) {
                $normalizedName = strtolower((string)$name);
                if (in_array($normalizedName, ['authorization', 'x-auth-token'], true)
                    && is_string($value)
                    && trim($value) !== '') {
                    $headers[] = trim($value);
                }
            }
        }

        foreach (array_unique($headers) as $header) {
            // Authorization: Bearer TOKEN
            if (preg_match('/^Bearer\s+(.+)$/i', $header, $matches)) {
                $token = trim($matches[1]);
                return $token !== '' ? $token : null;
            }

            // X-Auth-Token: TOKEN (fallback específico para ambientes que removem Authorization)
            if (preg_match('/^[a-f0-9]{64}$/i', $header)) {
                return $header;
            }
        }

        return null;
    }

    public static function createSession(int $userId): string
    {
        $pdo = Database::connection();
        $plainToken = bin2hex(random_bytes(32));
        $hash = hash('sha256', $plainToken);
        $expires = (new DateTimeImmutable('+' . TOKEN_TTL_DAYS . ' days'))->format('Y-m-d H:i:s');

        $stmt = $pdo->prepare('INSERT INTO sessoes (usuario_id, token_hash, expira_em) VALUES (?, ?, ?)');
        $stmt->execute([$userId, $hash, $expires]);

        return $plainToken;
    }

    public static function user(bool $required = true, array $roles = []): ?array
    {
        $token = self::bearerToken();
        if (!$token) {
            if ($required) {
                Response::error('Autenticação necessária.', 401);
            }
            return null;
        }

        $pdo = Database::connection();
        $stmt = $pdo->prepare(
            'SELECT u.id, u.nome, u.email, u.telefone, u.tipo, u.status, u.aceitou_privacidade
             FROM sessoes s
             INNER JOIN usuarios u ON u.id = s.usuario_id
             WHERE s.token_hash = ? AND s.expira_em > NOW() AND u.status = \'ativo\'
             LIMIT 1'
        );
        $stmt->execute([hash('sha256', $token)]);
        $user = $stmt->fetch();

        if (!$user) {
            if ($required) {
                Response::error('Sessão inválida ou expirada.', 401);
            }
            return null;
        }

        if ($roles && !in_array($user['tipo'], $roles, true)) {
            Response::error('Acesso não autorizado.', 403);
        }

        $touch = $pdo->prepare('UPDATE sessoes SET ultimo_uso_em = NOW() WHERE token_hash = ?');
        $touch->execute([hash('sha256', $token)]);

        $user['id'] = (int)$user['id'];
        $user['aceitou_privacidade'] = (bool)$user['aceitou_privacidade'];
        return $user;
    }

    public static function logout(): void
    {
        $token = self::bearerToken();
        if (!$token) {
            return;
        }
        $stmt = Database::connection()->prepare('DELETE FROM sessoes WHERE token_hash = ?');
        $stmt->execute([hash('sha256', $token)]);
    }
}
