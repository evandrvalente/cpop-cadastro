-- ============================================
--  SCHEMA CPOP - Sistema de Cadastramento
--  Autor: Evandro Valente
--  Banco: PostgreSQL (Neon.tech)
--  Data: 2025-10-24
-- ============================================

-- Limpeza inicial (opcional, para recriar do zero)
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS relatorio_presenca_cursinho CASCADE;
DROP TABLE IF EXISTS relatorio_atividade_bolsista CASCADE;
DROP TABLE IF EXISTS alunos CASCADE;
DROP TABLE IF EXISTS turmas CASCADE;
DROP TABLE IF EXISTS usuarios CASCADE;
DROP TABLE IF EXISTS cursinhos CASCADE;

-- ============================================
-- 1️⃣ Tabela: Cursinhos
-- ============================================
CREATE TABLE cursinhos (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    tipo VARCHAR(20) CHECK (tipo IN ('formal', 'informal')) NOT NULL,
    cnpj VARCHAR(18),
    endereco_rua TEXT NOT NULL,
    endereco_numero TEXT NOT NULL,
    endereco_bairro TEXT NOT NULL,
    endereco_cidade TEXT NOT NULL,
    endereco_uf CHAR(2) NOT NULL,
    cep VARCHAR(9) NOT NULL,
    telefone TEXT NOT NULL,
    email TEXT NOT NULL,
    coordenador_cpf VARCHAR(14) NOT NULL,
    documentos_anexos JSONB,
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_coordenador FOREIGN KEY (coordenador_cpf)
        REFERENCES usuarios(cpf) DEFERRABLE INITIALLY DEFERRED
);

COMMENT ON TABLE cursinhos IS 'Cadastro de cursinhos participantes do CPOP';
COMMENT ON COLUMN cursinhos.coordenador_cpf IS 'CPF do coordenador responsável (referência em usuarios)';

-- ============================================
-- 2️⃣ Tabela: Usuários (Coordenadores, Bolsistas, Professores, Apoio)
-- ============================================
CREATE TABLE usuarios (
    cpf VARCHAR(14) PRIMARY KEY,
    nome_completo TEXT NOT NULL,
    email TEXT NOT NULL,
    telefone TEXT NOT NULL,
    role VARCHAR(20) CHECK (role IN ('ADMIN','COORDENADOR','PROFESSOR','APOIO')) NOT NULL,
    cursinho_id INTEGER,
    documento_identidade_url TEXT NOT NULL,
    endereco_rua TEXT NOT NULL,
    endereco_numero TEXT NOT NULL,
    endereco_bairro TEXT NOT NULL,
    endereco_cidade TEXT NOT NULL,
    endereco_uf CHAR(2) NOT NULL,
    cep VARCHAR(9) NOT NULL,
    conta_bancaria_numero TEXT NOT NULL,
    conta_bancaria_tipo VARCHAR(20) CHECK (conta_bancaria_tipo IN ('corrente','poupanca','pagamento')) NOT NULL,
    banco_nome TEXT NOT NULL,
    comprovante_conta_url TEXT NOT NULL,
    status_validacao VARCHAR(20) DEFAULT 'pendente' CHECK (status_validacao IN ('pendente','aprovado','rejeitado')),
    created_at TIMESTAMP DEFAULT NOW(),

    CONSTRAINT fk_usuario_cursinho FOREIGN KEY (cursinho_id)
        REFERENCES cursinhos(id) ON DELETE SET NULL
);

COMMENT ON TABLE usuarios IS 'Tabela de usuários do sistema: coordenadores, bolsistas e equipe de apoio';

-- ============================================
-- 3️⃣ Tabela: Turmas
-- ============================================
CREATE TABLE turmas (
    id SERIAL PRIMARY KEY,
    cursinho_id INTEGER NOT NULL REFERENCES cursinhos(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    periodo VARCHAR(50),
    dia_horario TEXT,
    capacidade INTEGER DEFAULT 40 CHECK (capacidade <= 40),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE turmas IS 'Turmas vinculadas a cada cursinho';

-- ============================================
-- 4️⃣ Tabela: Alunos
-- ============================================
CREATE TABLE alunos (
    cpf VARCHAR(14) PRIMARY KEY,
    nome_completo TEXT NOT NULL,
    data_nascimento DATE NOT NULL,
    telefone TEXT NOT NULL,
    endereco_rua TEXT NOT NULL,
    endereco_numero TEXT NOT NULL,
    endereco_bairro TEXT NOT NULL,
    endereco_cidade TEXT NOT NULL,
    endereco_uf CHAR(2) NOT NULL,
    cep VARCHAR(9) NOT NULL,
    documento_identidade_url TEXT NOT NULL,
    conta_bancaria_numero TEXT NOT NULL,
    banco_nome TEXT NOT NULL,
    comprovante_conta_url TEXT NOT NULL,
    declaracao_renda_url TEXT NOT NULL,
    declaracao_social_url TEXT NOT NULL,
    autorizacao_responsavel_url TEXT,
    turma_id INTEGER NOT NULL REFERENCES turmas(id) ON DELETE CASCADE,
    cursinho_id INTEGER NOT NULL REFERENCES cursinhos(id) ON DELETE CASCADE,
    status_validacao VARCHAR(20) DEFAULT 'pendente' CHECK (status_validacao IN ('pendente','aprovado','rejeitado')),
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE alunos IS 'Cadastro de alunos de cada cursinho, com documentação obrigatória';
COMMENT ON COLUMN alunos.autorizacao_responsavel_url IS 'Obrigatória apenas para alunos menores de 18 anos';

-- ============================================
-- 5️⃣ Tabela: Relatórios de Atividade dos Bolsistas
-- ============================================
CREATE TABLE relatorio_atividade_bolsista (
    id SERIAL PRIMARY KEY,
    usuario_cpf VARCHAR(14) NOT NULL REFERENCES usuarios(cpf) ON DELETE CASCADE,
    mes_referencia VARCHAR(7) NOT NULL,
    arquivo_url TEXT NOT NULL,
    status_validacao VARCHAR(20) DEFAULT 'pendente' CHECK (status_validacao IN ('pendente','aprovado','rejeitado')),
    data_envio TIMESTAMP DEFAULT NOW(),
    observacoes TEXT
);

COMMENT ON TABLE relatorio_atividade_bolsista IS 'Relatórios mensais de atividades dos bolsistas';

-- ============================================
-- 6️⃣ Tabela: Relatórios de Presença dos Alunos (por cursinho)
-- ============================================
CREATE TABLE relatorio_presenca_cursinho (
    id SERIAL PRIMARY KEY,
    cursinho_id INTEGER NOT NULL REFERENCES cursinhos(id) ON DELETE CASCADE,
    mes_referencia VARCHAR(7) NOT NULL,
    arquivo_url TEXT NOT NULL,
    gerado_por VARCHAR(14) NOT NULL REFERENCES usuarios(cpf),
    data_upload TIMESTAMP DEFAULT NOW(),
    status_validacao VARCHAR(20) DEFAULT 'pendente' CHECK (status_validacao IN ('pendente','aprovado','rejeitado')),
    observacoes TEXT
);

COMMENT ON TABLE relatorio_presenca_cursinho IS 'Relatórios mensais de presença de alunos enviados por cada cursinho';

-- ============================================
-- 7️⃣ Tabela: Log de Auditoria
-- ============================================
CREATE TABLE audit_log (
    id SERIAL PRIMARY KEY,
    actor_cpf VARCHAR(14) REFERENCES usuarios(cpf),
    action TEXT NOT NULL,
    target_type TEXT NOT NULL,
    target_id TEXT,
    details JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

COMMENT ON TABLE audit_log IS 'Registra todas as ações relevantes do sistema (aprovações, cadastros, etc.)';

-- ============================================
-- Índices e Otimizações
-- ============================================
CREATE INDEX idx_usuarios_cursinho ON usuarios(cursinho_id);
CREATE INDEX idx_alunos_cursinho ON alunos(cursinho_id);
CREATE INDEX idx_alunos_turma ON alunos(turma_id);
CREATE INDEX idx_relatorio_bolsista_mes ON relatorio_atividade_bolsista(mes_referencia);
CREATE INDEX idx_relatorio_presenca_mes ON relatorio_presenca_cursinho(mes_referencia);

-- ============================================
-- Fim do schema.sql
-- ============================================
