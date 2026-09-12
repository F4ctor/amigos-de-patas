-- OPCIONAL: dados fictícios do pacote original. Apenas para demonstração local.
-- Admin: admin@ong.local / Admin@123. Altere a senha no perfil após entrar.
-- Execute uma única vez após ong_adocao.sql em um banco novo.
BEGIN;
SET LOCAL TIME ZONE 'America/Sao_Paulo';
INSERT INTO usuarios (nome, email, telefone, senha_hash, tipo, status, aceitou_privacidade)
VALUES ('Administrador', 'admin@ong.local', NULL, '$2y$12$KOWZ3jBquWyBE.29VZXguePJE9J7JNH1WoVpLH0FOiqtHdyOpwFbi', 'administrador', 'ativo', 1);

INSERT INTO configuracoes (
  id, nome_ong, descricao, telefone, email, endereco, chave_pix, tipo_chave_pix,
  instagram, facebook, youtube, politica_privacidade
) VALUES (
  1,
  'ONG de Proteção Animal',
  'Projeto acadêmico para apoiar a adoção responsável de animais resgatados em Parauapebas-PA.',
  '(94) 00000-0000',
  'contato@ong.local',
  'Parauapebas - PA',
  'contato@ong.local',
  'email',
  '', '', '',
  'Os dados informados serão utilizados apenas para cadastro, contato e análise de solicitações de adoção, conforme os princípios da LGPD.'
);

INSERT INTO animais (nome, especie, raca, sexo, idade_aproximada, porte, descricao, comportamento, estado_saude, vacinado, castrado, status, foto_principal)
VALUES
('Luna', 'cao', 'Sem raça definida', 'femea', '2 anos', 'medio', 'Resgatada e pronta para encontrar uma família responsável.', 'Dócil, carinhosa e sociável.', 'Saudável e acompanhada pela ONG.', 1, 1, 'disponivel', 'backend_api/uploads/demo_luna.png'),
('Thor', 'cao', 'Sem raça definida', 'macho', '1 ano', 'grande', 'Animal ativo, ideal para família com espaço e rotina de passeios.', 'Brincalhão e protetor.', 'Vacinado e em boas condições.', 1, 0, 'disponivel', 'backend_api/uploads/demo_thor.png'),
('Mia', 'gato', 'Sem raça definida', 'femea', '8 meses', 'pequeno', 'Gatinha tranquila e acostumada com ambiente interno.', 'Calma e afetuosa.', 'Saudável.', 1, 1, 'disponivel', 'backend_api/uploads/demo_mia.png');

INSERT INTO campanhas (titulo, descricao, meta, valor_arrecadado, imagem, chave_pix, tipo_chave_pix, status, data_inicio)
VALUES ('Campanha de ração', 'Ajude a manter a alimentação dos animais acolhidos durante este mês.', 3000.00, 450.00, 'backend_api/uploads/demo_campanha.png', 'contato@ong.local', 'email', 'ativa', CURRENT_DATE);

INSERT INTO noticias (titulo, resumo, conteudo, imagem, status, autor_id, data_publicacao)
VALUES ('Bem-vindo ao aplicativo', 'Conheça o novo canal digital da ONG.', 'Este aplicativo reúne animais disponíveis para adoção, campanhas solidárias e informações institucionais.', 'backend_api/uploads/demo_noticia.png', 'publicada', 1, NOW());



COMMIT;
