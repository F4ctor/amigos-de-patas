<?php
declare(strict_types=1);

require __DIR__ . '/config/config.php';
require __DIR__ . '/src/Database.php';
require __DIR__ . '/src/Response.php';
require __DIR__ . '/src/Auth.php';
require __DIR__ . '/src/Helpers.php';

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Auth-Token');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    http_response_code(204);
    exit;
}

$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
$path = routePath();

try {
    $pdo = Database::connection();
    if ($method === 'GET' && $path === '/') {
        Response::success([
            'app' => 'API ONG Adoção',
            'version' => '1.3.0-postgresql',
            'status' => 'online',
        ], 'API disponível.');
    }

    if ($method === 'POST' && $path === '/auth/cadastro') {
        $data = requestData();
        requireFields($data, ['nome', 'email', 'senha']);

        $email = strtolower(trim((string)$data['email']));
        if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
            Response::error('E-mail inválido.', 422, ['email' => 'Informe um endereço válido.']);
        }
        if (mb_strlen((string)$data['senha']) < 8) {
            Response::error('A senha deve possuir pelo menos 8 caracteres.', 422);
        }
        if (!boolValue($data['aceitou_privacidade'] ?? false)) {
            Response::error('É necessário aceitar a política de privacidade.', 422);
        }

        $exists = $pdo->prepare('SELECT id FROM usuarios WHERE email = ? LIMIT 1');
        $exists->execute([$email]);
        if ($exists->fetch()) {
            Response::error('Já existe um usuário com este e-mail.', 409);
        }

        $stmt = $pdo->prepare(
            'INSERT INTO usuarios (nome, email, telefone, senha_hash, tipo, status, aceitou_privacidade)
             VALUES (?, ?, ?, ?, \'usuario\', \'ativo\', 1) RETURNING id'
        );
        $stmt->execute([
            trim((string)$data['nome']),
            $email,
            nullableString($data['telefone'] ?? null),
            password_hash((string)$data['senha'], PASSWORD_DEFAULT),
        ]);
        $id = (int)$stmt->fetchColumn();
        $token = Auth::createSession($id);
        Response::success([
            'token' => $token,
            'usuario' => [
                'id' => $id,
                'nome' => trim((string)$data['nome']),
                'email' => $email,
                'telefone' => nullableString($data['telefone'] ?? null),
                'tipo' => 'usuario',
            ],
        ], 'Cadastro realizado com sucesso.', 201);
    }

    if ($method === 'POST' && $path === '/auth/login') {
        $data = requestData();
        requireFields($data, ['email', 'senha']);
        $email = strtolower(trim((string)$data['email']));

        $stmt = $pdo->prepare('SELECT * FROM usuarios WHERE email = ? LIMIT 1');
        $stmt->execute([$email]);
        $user = $stmt->fetch();
        if (!$user || !password_verify((string)$data['senha'], $user['senha_hash'])) {
            Response::error('E-mail ou senha incorretos.', 401);
        }
        if ($user['status'] !== 'ativo') {
            Response::error('Usuário inativo.', 403);
        }

        $token = Auth::createSession((int)$user['id']);
        unset($user['senha_hash']);
        $user['id'] = (int)$user['id'];
        $user['aceitou_privacidade'] = (bool)$user['aceitou_privacidade'];
        Response::success(['token' => $token, 'usuario' => $user], 'Login realizado com sucesso.');
    }

    if ($method === 'POST' && $path === '/auth/logout') {
        Auth::user();
        Auth::logout();
        Response::success(null, 'Sessão encerrada.');
    }

    if ($method === 'GET' && $path === '/auth/perfil') {
        Response::success(Auth::user(), 'Perfil carregado.');
    }

    if ($method === 'PUT' && $path === '/auth/perfil') {
        $user = Auth::user();
        $data = requestData();
        requireFields($data, ['nome']);

        $fields = ['nome = ?', 'telefone = ?'];
        $params = [trim((string)$data['nome']), nullableString($data['telefone'] ?? null)];
        if (!empty($data['senha'])) {
            if (mb_strlen((string)$data['senha']) < 8) {
                Response::error('A nova senha deve possuir pelo menos 8 caracteres.', 422);
            }
            $fields[] = 'senha_hash = ?';
            $params[] = password_hash((string)$data['senha'], PASSWORD_DEFAULT);
        }
        $params[] = $user['id'];
        $stmt = $pdo->prepare('UPDATE usuarios SET ' . implode(', ', $fields) . ' WHERE id = ?');
        $stmt->execute($params);
        Response::success(null, 'Perfil atualizado.');
    }

    if ($method === 'GET' && $path === '/animais') {
        $where = ['1=1'];
        $params = [];
        foreach (['especie', 'sexo', 'porte', 'status'] as $field) {
            if (!empty($_GET[$field])) {
                $where[] = "$field = ?";
                $params[] = $_GET[$field];
            }
        }
        if (!empty($_GET['busca'])) {
            $where[] = '(nome ILIKE ? OR raca ILIKE ? OR descricao ILIKE ?)';
            $search = '%' . trim((string)$_GET['busca']) . '%';
            array_push($params, $search, $search, $search);
        }
        $stmt = $pdo->prepare('SELECT * FROM animais WHERE ' . implode(' AND ', $where) . ' ORDER BY data_cadastro DESC');
        $stmt->execute($params);
        $rows = array_map('normalizeAnimal', $stmt->fetchAll());
        Response::success($rows, 'Animais carregados.');
    }

    if ($method === 'GET' && preg_match('#^/animais/(\d+)$#', $path, $m)) {
        $stmt = $pdo->prepare('SELECT * FROM animais WHERE id = ? LIMIT 1');
        $stmt->execute([(int)$m[1]]);
        $animal = $stmt->fetch();
        if (!$animal) {
            Response::error('Animal não encontrado.', 404);
        }
        $photos = $pdo->prepare('SELECT id, arquivo, descricao, ordem FROM fotos_animais WHERE animal_id = ? ORDER BY ordem, id');
        $photos->execute([(int)$m[1]]);
        $animal = normalizeAnimal($animal);
        $animal['fotos'] = array_map(static function (array $photo): array {
            $photo['id'] = (int)$photo['id'];
            $photo['ordem'] = (int)$photo['ordem'];
            $photo['arquivo'] = normalizeMediaUrl($photo['arquivo']);
            return $photo;
        }, $photos->fetchAll());
        Response::success($animal, 'Animal carregado.');
    }

    if ($method === 'POST' && $path === '/adocoes') {
        $user = Auth::user();
        $data = requestData();
        requireFields($data, ['animal_id', 'tipo_moradia', 'motivo_adocao']);

        $animalId = (int)$data['animal_id'];
        $check = $pdo->prepare('SELECT id, status FROM animais WHERE id = ? LIMIT 1');
        $check->execute([$animalId]);
        $animal = $check->fetch();
        if (!$animal) {
            Response::error('Animal não encontrado.', 404);
        }
        if ($animal['status'] !== 'disponivel') {
            Response::error('Este animal não está disponível para novas solicitações.', 409);
        }

        $duplicate = $pdo->prepare(
            'SELECT id FROM solicitacoes_adocao
             WHERE usuario_id = ? AND animal_id = ? AND status NOT IN (\'recusada\', \'cancelada\', \'concluida\') LIMIT 1'
        );
        $duplicate->execute([$user['id'], $animalId]);
        if ($duplicate->fetch()) {
            Response::error('Você já possui uma solicitação ativa para este animal.', 409);
        }

        $stmt = $pdo->prepare(
            'INSERT INTO solicitacoes_adocao
             (usuario_id, animal_id, tipo_moradia, possui_quintal, possui_outros_animais,
              quantidade_pessoas, todos_concordam, motivo_adocao, experiencia_com_animais, observacoes)
             VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING id'
        );
        $stmt->execute([
            $user['id'],
            $animalId,
            trim((string)$data['tipo_moradia']),
            boolValue($data['possui_quintal'] ?? false),
            boolValue($data['possui_outros_animais'] ?? false),
            max(1, (int)($data['quantidade_pessoas'] ?? 1)),
            boolValue($data['todos_concordam'] ?? false),
            trim((string)$data['motivo_adocao']),
            nullableString($data['experiencia_com_animais'] ?? null),
            nullableString($data['observacoes'] ?? null),
        ]);
        Response::success(['id' => (int)$stmt->fetchColumn()], 'Solicitação enviada para análise.', 201);
    }

    if ($method === 'GET' && $path === '/minhas-adocoes') {
        $user = Auth::user();
        $stmt = $pdo->prepare(
            'SELECT s.*, a.nome AS animal_nome, a.especie, a.foto_principal
             FROM solicitacoes_adocao s
             INNER JOIN animais a ON a.id = s.animal_id
             WHERE s.usuario_id = ? ORDER BY s.data_solicitacao DESC'
        );
        $stmt->execute([$user['id']]);
        $rows = array_map(static function (array $row): array {
            $row['id'] = (int)$row['id'];
            $row['animal_id'] = (int)$row['animal_id'];
            $row['usuario_id'] = (int)$row['usuario_id'];
            $row['foto_principal'] = normalizeMediaUrl($row['foto_principal']);
            return $row;
        }, $stmt->fetchAll());
        Response::success($rows, 'Solicitações carregadas.');
    }

    if ($method === 'GET' && $path === '/campanhas') {
        $stmt = $pdo->query('SELECT * FROM campanhas WHERE status = \'ativa\' ORDER BY data_cadastro DESC');
        $rows = array_map(static function (array $row): array {
            $row['id'] = (int)$row['id'];
            $row['meta'] = (float)$row['meta'];
            $row['valor_arrecadado'] = (float)$row['valor_arrecadado'];
            $row['imagem'] = normalizeMediaUrl($row['imagem']);
            return $row;
        }, $stmt->fetchAll());
        Response::success($rows, 'Campanhas carregadas.');
    }

    if ($method === 'GET' && $path === '/noticias') {
        $stmt = $pdo->query('SELECT id, titulo, resumo, conteudo, imagem, data_publicacao FROM noticias WHERE status = \'publicada\' ORDER BY COALESCE(data_publicacao, data_cadastro) DESC');
        $rows = array_map(static function (array $row): array {
            $row['id'] = (int)$row['id'];
            $row['imagem'] = normalizeMediaUrl($row['imagem']);
            return $row;
        }, $stmt->fetchAll());
        Response::success($rows, 'Notícias carregadas.');
    }

    if ($method === 'GET' && $path === '/videos') {
        $stmt = $pdo->query('SELECT id, titulo, descricao, url, data_publicacao FROM videos WHERE status = \'publicado\' ORDER BY COALESCE(data_publicacao, data_cadastro) DESC');
        $rows = array_map(static function (array $row): array {
            $row['id'] = (int)$row['id'];
            return $row;
        }, $stmt->fetchAll());
        Response::success($rows, 'Vídeos carregados.');
    }

    if ($method === 'GET' && $path === '/configuracoes/publicas') {
        $stmt = $pdo->query('SELECT nome_ong, descricao, telefone, email, endereco, chave_pix, tipo_chave_pix, instagram, facebook, youtube, politica_privacidade FROM configuracoes WHERE id = 1');
        Response::success($stmt->fetch() ?: [], 'Configurações carregadas.');
    }

    // Rotas administrativas
    if (str_starts_with($path, '/admin')) {
        $admin = Auth::user(true, ['administrador']);

        if ($method === 'GET' && $path === '/admin/dashboard') {
            $counts = [];
            foreach ([
                'animais' => 'SELECT COUNT(*) FROM animais',
                'disponiveis' => 'SELECT COUNT(*) FROM animais WHERE status = \'disponivel\'',
                'adocoes_pendentes' => 'SELECT COUNT(*) FROM solicitacoes_adocao WHERE status IN (\'pendente\', \'em_analise\', \'entrevista\')',
                'usuarios' => 'SELECT COUNT(*) FROM usuarios WHERE tipo = \'usuario\'',
                'campanhas_ativas' => 'SELECT COUNT(*) FROM campanhas WHERE status = \'ativa\'',
            ] as $key => $sql) {
                $counts[$key] = (int)$pdo->query($sql)->fetchColumn();
            }
            $latest = $pdo->query(
                'SELECT s.id, s.status, s.data_solicitacao, a.nome AS animal_nome, u.nome AS usuario_nome
                 FROM solicitacoes_adocao s
                 INNER JOIN animais a ON a.id = s.animal_id
                 INNER JOIN usuarios u ON u.id = s.usuario_id
                 ORDER BY s.data_solicitacao DESC LIMIT 8'
            )->fetchAll();
            Response::success(['contadores' => $counts, 'ultimas_solicitacoes' => $latest], 'Painel carregado.');
        }

        if ($method === 'POST' && $path === '/admin/upload') {
            if (!isset($_FILES['arquivo']) || !is_uploaded_file($_FILES['arquivo']['tmp_name'])) {
                Response::error('Selecione uma imagem válida.', 422);
            }
            $file = $_FILES['arquivo'];
            if (($file['size'] ?? 0) > MAX_UPLOAD_BYTES) {
                Response::error('A imagem deve ter no máximo 5 MB.', 422);
            }
            $finfo = new finfo(FILEINFO_MIME_TYPE);
            $mime = $finfo->file($file['tmp_name']);
            if (!in_array($mime, ALLOWED_UPLOAD_MIME, true)) {
                Response::error('Formato não permitido. Use JPG, PNG ou WEBP.', 422);
            }
            $extension = match ($mime) {
                'image/jpeg' => 'jpg',
                'image/png' => 'png',
                'image/webp' => 'webp',
                default => 'bin',
            };
            $name = date('YmdHis') . '_' . bin2hex(random_bytes(8)) . '.' . $extension;
            $destination = UPLOAD_DIR . '/' . $name;
            if (!move_uploaded_file($file['tmp_name'], $destination)) {
                Response::error('Não foi possível salvar a imagem.', 500);
            }
            $relative = ltrim(apiBasePath(), '/') . '/uploads/' . $name;
            adminLog($admin['id'], 'upload_imagem', null, null, $name);
            Response::success(['url' => publicBaseUrl() . '/' . $relative, 'caminho' => $relative], 'Imagem enviada.', 201);
        }

        if ($method === 'GET' && $path === '/admin/animais') {
            $rows = array_map('normalizeAnimal', $pdo->query('SELECT * FROM animais ORDER BY data_cadastro DESC')->fetchAll());
            Response::success($rows, 'Animais carregados.');
        }

        if ($method === 'POST' && $path === '/admin/animais') {
            $data = requestData();
            requireFields($data, ['nome', 'especie']);
            $stmt = $pdo->prepare(
                'INSERT INTO animais
                (nome, especie, raca, sexo, idade_aproximada, porte, descricao, comportamento, estado_saude,
                 vacinado, castrado, status, foto_principal, data_resgate)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING id'
            );
            $stmt->execute([
                trim((string)$data['nome']),
                $data['especie'],
                nullableString($data['raca'] ?? null),
                $data['sexo'] ?? 'nao_informado',
                nullableString($data['idade_aproximada'] ?? null),
                $data['porte'] ?? 'nao_informado',
                nullableString($data['descricao'] ?? null),
                nullableString($data['comportamento'] ?? null),
                nullableString($data['estado_saude'] ?? null),
                boolValue($data['vacinado'] ?? false),
                boolValue($data['castrado'] ?? false),
                $data['status'] ?? 'disponivel',
                nullableString($data['foto_principal'] ?? null),
                nullableString($data['data_resgate'] ?? null),
            ]);
            $id = (int)$stmt->fetchColumn();
            adminLog($admin['id'], 'criar', 'animais', $id);
            Response::success(['id' => $id], 'Animal cadastrado.', 201);
        }

        if ($method === 'PUT' && preg_match('#^/admin/animais/(\d+)$#', $path, $m)) {
            $data = requestData();
            requireFields($data, ['nome', 'especie']);
            $stmt = $pdo->prepare(
                'UPDATE animais SET nome=?, especie=?, raca=?, sexo=?, idade_aproximada=?, porte=?, descricao=?,
                 comportamento=?, estado_saude=?, vacinado=?, castrado=?, status=?, foto_principal=?, data_resgate=?
                 WHERE id=?'
            );
            $stmt->execute([
                trim((string)$data['nome']), $data['especie'], nullableString($data['raca'] ?? null),
                $data['sexo'] ?? 'nao_informado', nullableString($data['idade_aproximada'] ?? null),
                $data['porte'] ?? 'nao_informado', nullableString($data['descricao'] ?? null),
                nullableString($data['comportamento'] ?? null), nullableString($data['estado_saude'] ?? null),
                boolValue($data['vacinado'] ?? false), boolValue($data['castrado'] ?? false),
                $data['status'] ?? 'disponivel', nullableString($data['foto_principal'] ?? null),
                nullableString($data['data_resgate'] ?? null), (int)$m[1],
            ]);
            adminLog($admin['id'], 'atualizar', 'animais', (int)$m[1]);
            Response::success(null, 'Animal atualizado.');
        }

        if ($method === 'DELETE' && preg_match('#^/admin/animais/(\d+)$#', $path, $m)) {
            $id = (int)$m[1];
            $has = $pdo->prepare('SELECT COUNT(*) FROM solicitacoes_adocao WHERE animal_id = ?');
            $has->execute([$id]);
            if ((int)$has->fetchColumn() > 0) {
                $stmt = $pdo->prepare('UPDATE animais SET status = \'indisponivel\' WHERE id = ?');
                $stmt->execute([$id]);
                adminLog($admin['id'], 'inativar', 'animais', $id);
                Response::success(null, 'O animal possui histórico e foi marcado como indisponível.');
            }
            $stmt = $pdo->prepare('DELETE FROM animais WHERE id = ?');
            $stmt->execute([$id]);
            adminLog($admin['id'], 'excluir', 'animais', $id);
            Response::success(null, 'Animal excluído.');
        }

        if ($method === 'GET' && $path === '/admin/adocoes') {
            $stmt = $pdo->query(
                'SELECT s.*, a.nome AS animal_nome, u.nome AS usuario_nome, u.email AS usuario_email, u.telefone AS usuario_telefone
                 FROM solicitacoes_adocao s
                 INNER JOIN animais a ON a.id = s.animal_id
                 INNER JOIN usuarios u ON u.id = s.usuario_id
                 ORDER BY s.data_solicitacao DESC'
            );
            Response::success($stmt->fetchAll(), 'Solicitações carregadas.');
        }

        if ($method === 'PUT' && preg_match('#^/admin/adocoes/(\d+)/status$#', $path, $m)) {
            $data = requestData();
            requireFields($data, ['status']);
            $allowed = ['pendente','em_analise','entrevista','aprovada','recusada','cancelada','concluida'];
            if (!in_array($data['status'], $allowed, true)) {
                Response::error('Status inválido.', 422);
            }
            $stmt = $pdo->prepare('UPDATE solicitacoes_adocao SET status = ?, resposta_ong = ? WHERE id = ?');
            $stmt->execute([$data['status'], nullableString($data['resposta_ong'] ?? null), (int)$m[1]]);
            if ($data['status'] === 'concluida') {
                $animal = $pdo->prepare('SELECT animal_id FROM solicitacoes_adocao WHERE id = ?');
                $animal->execute([(int)$m[1]]);
                $animalId = (int)$animal->fetchColumn();
                if ($animalId) {
                    $pdo->prepare('UPDATE animais SET status = \'adotado\' WHERE id = ?')->execute([$animalId]);
                }
            }
            adminLog($admin['id'], 'alterar_status', 'solicitacoes_adocao', (int)$m[1], (string)$data['status']);
            Response::success(null, 'Solicitação atualizada.');
        }

        if ($method === 'GET' && $path === '/admin/usuarios') {
            $rows = $pdo->query('SELECT id, nome, email, telefone, tipo, status, aceitou_privacidade, data_cadastro FROM usuarios ORDER BY data_cadastro DESC')->fetchAll();
            Response::success($rows, 'Usuários carregados.');
        }

        if ($method === 'PUT' && preg_match('#^/admin/usuarios/(\d+)/status$#', $path, $m)) {
            $data = requestData();
            requireFields($data, ['status']);
            if (!in_array($data['status'], ['ativo', 'inativo'], true)) {
                Response::error('Status inválido.', 422);
            }
            $pdo->prepare('UPDATE usuarios SET status = ? WHERE id = ? AND tipo = \'usuario\'')->execute([$data['status'], (int)$m[1]]);
            adminLog($admin['id'], 'alterar_status', 'usuarios', (int)$m[1], (string)$data['status']);
            Response::success(null, 'Usuário atualizado.');
        }

        if ($method === 'GET' && $path === '/admin/campanhas') {
            $rows = $pdo->query('SELECT * FROM campanhas ORDER BY data_cadastro DESC')->fetchAll();
            Response::success($rows, 'Campanhas carregadas.');
        }

        if ($method === 'POST' && $path === '/admin/campanhas') {
            $data = requestData();
            requireFields($data, ['titulo', 'descricao']);
            $stmt = $pdo->prepare('INSERT INTO campanhas (titulo, descricao, meta, valor_arrecadado, imagem, chave_pix, tipo_chave_pix, status, data_inicio, data_fim) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?) RETURNING id');
            $stmt->execute([
                trim((string)$data['titulo']), trim((string)$data['descricao']), (float)($data['meta'] ?? 0),
                (float)($data['valor_arrecadado'] ?? 0), nullableString($data['imagem'] ?? null),
                nullableString($data['chave_pix'] ?? null), $data['tipo_chave_pix'] ?? 'nao_informado',
                $data['status'] ?? 'ativa', nullableString($data['data_inicio'] ?? null), nullableString($data['data_fim'] ?? null),
            ]);
            $id = (int)$stmt->fetchColumn();
            adminLog($admin['id'], 'criar', 'campanhas', $id);
            Response::success(['id' => $id], 'Campanha cadastrada.', 201);
        }

        if ($method === 'PUT' && preg_match('#^/admin/campanhas/(\d+)$#', $path, $m)) {
            $data = requestData();
            requireFields($data, ['titulo', 'descricao']);
            $stmt = $pdo->prepare('UPDATE campanhas SET titulo=?, descricao=?, meta=?, valor_arrecadado=?, imagem=?, chave_pix=?, tipo_chave_pix=?, status=?, data_inicio=?, data_fim=? WHERE id=?');
            $stmt->execute([
                trim((string)$data['titulo']), trim((string)$data['descricao']), (float)($data['meta'] ?? 0),
                (float)($data['valor_arrecadado'] ?? 0), nullableString($data['imagem'] ?? null),
                nullableString($data['chave_pix'] ?? null), $data['tipo_chave_pix'] ?? 'nao_informado',
                $data['status'] ?? 'ativa', nullableString($data['data_inicio'] ?? null), nullableString($data['data_fim'] ?? null), (int)$m[1],
            ]);
            adminLog($admin['id'], 'atualizar', 'campanhas', (int)$m[1]);
            Response::success(null, 'Campanha atualizada.');
        }

        if ($method === 'DELETE' && preg_match('#^/admin/campanhas/(\d+)$#', $path, $m)) {
            $pdo->prepare('DELETE FROM campanhas WHERE id = ?')->execute([(int)$m[1]]);
            adminLog($admin['id'], 'excluir', 'campanhas', (int)$m[1]);
            Response::success(null, 'Campanha excluída.');
        }

        if ($method === 'GET' && $path === '/admin/noticias') {
            Response::success($pdo->query('SELECT * FROM noticias ORDER BY data_cadastro DESC')->fetchAll(), 'Notícias carregadas.');
        }

        if ($method === 'POST' && $path === '/admin/noticias') {
            $data = requestData();
            requireFields($data, ['titulo', 'conteudo']);
            $stmt = $pdo->prepare('INSERT INTO noticias (titulo, resumo, conteudo, imagem, status, autor_id, data_publicacao) VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id');
            $stmt->execute([
                trim((string)$data['titulo']), nullableString($data['resumo'] ?? null), trim((string)$data['conteudo']),
                nullableString($data['imagem'] ?? null), $data['status'] ?? 'publicada', $admin['id'],
                nullableString($data['data_publicacao'] ?? null) ?: date('Y-m-d H:i:s'),
            ]);
            $id = (int)$stmt->fetchColumn();
            adminLog($admin['id'], 'criar', 'noticias', $id);
            Response::success(['id' => $id], 'Notícia cadastrada.', 201);
        }

        if ($method === 'PUT' && preg_match('#^/admin/noticias/(\d+)$#', $path, $m)) {
            $data = requestData();
            requireFields($data, ['titulo', 'conteudo']);
            $stmt = $pdo->prepare('UPDATE noticias SET titulo=?, resumo=?, conteudo=?, imagem=?, status=?, data_publicacao=? WHERE id=?');
            $stmt->execute([
                trim((string)$data['titulo']), nullableString($data['resumo'] ?? null), trim((string)$data['conteudo']),
                nullableString($data['imagem'] ?? null), $data['status'] ?? 'publicada',
                nullableString($data['data_publicacao'] ?? null) ?: date('Y-m-d H:i:s'), (int)$m[1],
            ]);
            adminLog($admin['id'], 'atualizar', 'noticias', (int)$m[1]);
            Response::success(null, 'Notícia atualizada.');
        }

        if ($method === 'DELETE' && preg_match('#^/admin/noticias/(\d+)$#', $path, $m)) {
            $pdo->prepare('DELETE FROM noticias WHERE id = ?')->execute([(int)$m[1]]);
            adminLog($admin['id'], 'excluir', 'noticias', (int)$m[1]);
            Response::success(null, 'Notícia excluída.');
        }

        if ($method === 'GET' && $path === '/admin/videos') {
            Response::success($pdo->query('SELECT * FROM videos ORDER BY data_cadastro DESC')->fetchAll(), 'Vídeos carregados.');
        }

        if ($method === 'POST' && $path === '/admin/videos') {
            $data = requestData();
            requireFields($data, ['titulo', 'url']);
            $stmt = $pdo->prepare('INSERT INTO videos (titulo, descricao, url, status, data_publicacao) VALUES (?, ?, ?, ?, ?) RETURNING id');
            $stmt->execute([
                trim((string)$data['titulo']), nullableString($data['descricao'] ?? null), trim((string)$data['url']),
                $data['status'] ?? 'publicado', nullableString($data['data_publicacao'] ?? null) ?: date('Y-m-d H:i:s'),
            ]);
            $id = (int)$stmt->fetchColumn();
            adminLog($admin['id'], 'criar', 'videos', $id);
            Response::success(['id' => $id], 'Vídeo cadastrado.', 201);
        }

        if ($method === 'PUT' && preg_match('#^/admin/videos/(\d+)$#', $path, $m)) {
            $data = requestData();
            requireFields($data, ['titulo', 'url']);
            $stmt = $pdo->prepare('UPDATE videos SET titulo=?, descricao=?, url=?, status=?, data_publicacao=? WHERE id=?');
            $stmt->execute([
                trim((string)$data['titulo']), nullableString($data['descricao'] ?? null), trim((string)$data['url']),
                $data['status'] ?? 'publicado', nullableString($data['data_publicacao'] ?? null) ?: date('Y-m-d H:i:s'), (int)$m[1],
            ]);
            adminLog($admin['id'], 'atualizar', 'videos', (int)$m[1]);
            Response::success(null, 'Vídeo atualizado.');
        }

        if ($method === 'DELETE' && preg_match('#^/admin/videos/(\d+)$#', $path, $m)) {
            $pdo->prepare('DELETE FROM videos WHERE id = ?')->execute([(int)$m[1]]);
            adminLog($admin['id'], 'excluir', 'videos', (int)$m[1]);
            Response::success(null, 'Vídeo excluído.');
        }

        if ($method === 'GET' && $path === '/admin/configuracoes') {
            Response::success($pdo->query('SELECT * FROM configuracoes WHERE id = 1')->fetch() ?: [], 'Configurações carregadas.');
        }

        if ($method === 'PUT' && $path === '/admin/configuracoes') {
            $data = requestData();
            requireFields($data, ['nome_ong']);
            $stmt = $pdo->prepare(
                'UPDATE configuracoes SET nome_ong=?, descricao=?, telefone=?, email=?, endereco=?, chave_pix=?, tipo_chave_pix=?, instagram=?, facebook=?, youtube=?, politica_privacidade=? WHERE id=1'
            );
            $stmt->execute([
                trim((string)$data['nome_ong']), nullableString($data['descricao'] ?? null), nullableString($data['telefone'] ?? null),
                nullableString($data['email'] ?? null), nullableString($data['endereco'] ?? null), nullableString($data['chave_pix'] ?? null),
                $data['tipo_chave_pix'] ?? 'nao_informado', nullableString($data['instagram'] ?? null), nullableString($data['facebook'] ?? null),
                nullableString($data['youtube'] ?? null), nullableString($data['politica_privacidade'] ?? null),
            ]);
            adminLog($admin['id'], 'atualizar', 'configuracoes', 1);
            Response::success(null, 'Configurações atualizadas.');
        }
    }

    Response::error('Rota não encontrada.', 404);
} catch (PDOException $e) {
    if ($e->getCode() === '23505') {
        Response::error('Já existe um registro com estes dados únicos.', 409);
    }
    if (in_array($e->getCode(), ['23514', '23502', '22P02', '22001', '22007', '22008'], true)) {
        Response::error('Dados inválidos. Confira os campos informados.', 422);
    }
    if ($e->getCode() === '23503') {
        Response::error('O registro possui vínculo ou referência inválida.', 409);
    }
    error_log($e->getMessage());
    Response::error('Erro ao acessar o banco de dados. Verifique a configuração do servidor.', 500);
} catch (Throwable $e) {
    error_log($e->getMessage());
    Response::error('Erro interno do servidor.', 500);
}
