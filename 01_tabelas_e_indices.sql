-- 01 - Tabelas, chaves, restricoes e indices
-- Schema novo. Ordem respeita as dependencias FK.

CREATE TABLE categoria (
    id_categoria NUMBER CONSTRAINT pk_categoria PRIMARY KEY,
    nome VARCHAR2(100) NOT NULL,
    descricao VARCHAR2(250),
    CONSTRAINT uq_categoria_nome UNIQUE (nome)
);

CREATE TABLE editora (
    id_editora NUMBER CONSTRAINT pk_editora PRIMARY KEY,
    nome VARCHAR2(100) NOT NULL,
    endereco VARCHAR2(200),
    contacto VARCHAR2(30)
);

CREATE TABLE autor (
    id_autor NUMBER CONSTRAINT pk_autor PRIMARY KEY,
    nome VARCHAR2(100) NOT NULL,
    nacionalidade VARCHAR2(50)
);

CREATE TABLE funcionario (
    id_funcionario NUMBER CONSTRAINT pk_funcionario PRIMARY KEY,
    nome VARCHAR2(100) NOT NULL,
    email VARCHAR2(100),
    telefone VARCHAR2(20),
    cargo VARCHAR2(50) NOT NULL,
    estado VARCHAR2(20) DEFAULT 'ATIVO' NOT NULL,
    CONSTRAINT uq_funcionario_email UNIQUE (email),
    CONSTRAINT ck_func_estado CHECK (estado IN ('ATIVO', 'INATIVO'))
);

CREATE TABLE utilizador (
    id_utilizador NUMBER CONSTRAINT pk_utilizador PRIMARY KEY,
    nome VARCHAR2(100) NOT NULL,
    email VARCHAR2(100),
    telefone VARCHAR2(20),
    endereco VARCHAR2(200),
    data_registo DATE DEFAULT SYSDATE NOT NULL,
    estado VARCHAR2(20) DEFAULT 'ATIVO' NOT NULL,
    CONSTRAINT uq_utilizador_email UNIQUE (email),
    CONSTRAINT ck_util_estado CHECK (estado IN ('ATIVO', 'INATIVO'))
);

CREATE TABLE livro (
    id_livro NUMBER CONSTRAINT pk_livro PRIMARY KEY,
    titulo VARCHAR2(200) NOT NULL,
    isbn VARCHAR2(20),
    ano_publicacao NUMBER(4),
    edicao VARCHAR2(30),
    id_categoria NUMBER NOT NULL,
    id_editora NUMBER,
    CONSTRAINT uq_livro_isbn UNIQUE (isbn),
    CONSTRAINT fk_livro_categoria FOREIGN KEY (id_categoria)
        REFERENCES categoria (id_categoria),
    CONSTRAINT fk_livro_editora FOREIGN KEY (id_editora)
        REFERENCES editora (id_editora),
    CONSTRAINT ck_livro_ano CHECK (ano_publicacao IS NULL OR ano_publicacao BETWEEN 1000 AND 9999)
);

CREATE TABLE livro_autor (
    id_livro NUMBER NOT NULL,
    id_autor NUMBER NOT NULL,
    CONSTRAINT pk_livro_autor PRIMARY KEY (id_livro, id_autor),
    CONSTRAINT fk_la_livro FOREIGN KEY (id_livro) REFERENCES livro (id_livro),
    CONSTRAINT fk_la_autor FOREIGN KEY (id_autor) REFERENCES autor (id_autor)
);

CREATE TABLE exemplar (
    id_exemplar NUMBER CONSTRAINT pk_exemplar PRIMARY KEY,
    id_livro NUMBER NOT NULL,
    codigo_exemplar VARCHAR2(30) NOT NULL,
    estado VARCHAR2(30) DEFAULT 'BOM' NOT NULL,
    disponibilidade VARCHAR2(20) DEFAULT 'DISPONIVEL' NOT NULL,
    data_aquisicao DATE,
    CONSTRAINT uq_exemplar_codigo UNIQUE (codigo_exemplar),
    CONSTRAINT fk_exemplar_livro FOREIGN KEY (id_livro) REFERENCES livro (id_livro),
    CONSTRAINT ck_exemplar_estado CHECK (estado IN ('BOM', 'DANIFICADO', 'INUTILIZADO')),
    CONSTRAINT ck_exemplar_disp CHECK (disponibilidade IN
        ('DISPONIVEL', 'EMPRESTADO', 'RESERVADO', 'INDISPONIVEL'))
);

CREATE TABLE emprestimo (
    id_emprestimo NUMBER CONSTRAINT pk_emprestimo PRIMARY KEY,
    id_utilizador NUMBER NOT NULL,
    id_exemplar NUMBER NOT NULL,
    data_emprestimo DATE DEFAULT SYSDATE NOT NULL,
    prazo_devolucao DATE NOT NULL,
    data_devolucao DATE,
    estado VARCHAR2(20) DEFAULT 'ATIVO' NOT NULL,
    CONSTRAINT fk_emp_util FOREIGN KEY (id_utilizador) REFERENCES utilizador (id_utilizador),
    CONSTRAINT fk_emp_exemplar FOREIGN KEY (id_exemplar) REFERENCES exemplar (id_exemplar),
    CONSTRAINT ck_emp_estado CHECK (estado IN ('ATIVO', 'ATRASADO', 'DEVOLVIDO')),
    CONSTRAINT ck_emp_prazo CHECK (prazo_devolucao >= data_emprestimo),
    CONSTRAINT ck_emp_devolucao CHECK (
        (estado = 'DEVOLVIDO' AND data_devolucao IS NOT NULL)
        OR (estado IN ('ATIVO', 'ATRASADO') AND data_devolucao IS NULL)
    )
);

CREATE TABLE reserva (
    id_reserva NUMBER CONSTRAINT pk_reserva PRIMARY KEY,
    id_utilizador NUMBER NOT NULL,
    id_livro NUMBER NOT NULL,
    data_hora_reserva TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    posicao_lista NUMBER NOT NULL,
    estado VARCHAR2(20) DEFAULT 'PENDENTE' NOT NULL,
    CONSTRAINT fk_reserva_util FOREIGN KEY (id_utilizador) REFERENCES utilizador (id_utilizador),
    CONSTRAINT fk_reserva_livro FOREIGN KEY (id_livro) REFERENCES livro (id_livro),
    CONSTRAINT ck_reserva_estado CHECK (estado IN ('PENDENTE', 'NOTIFICADA', 'CONCLUIDA', 'CANCELADA')),
    CONSTRAINT ck_reserva_pos CHECK (posicao_lista >= 1)
);

-- Em 3FN, ID_UTILIZADOR é obtido através de EMPRESTIMO.
CREATE TABLE multa (
    id_multa NUMBER CONSTRAINT pk_multa PRIMARY KEY,
    id_emprestimo NUMBER NOT NULL,
    valor NUMBER(10,2) NOT NULL,
    data_multa DATE DEFAULT SYSDATE NOT NULL,
    estado VARCHAR2(20) DEFAULT 'PENDENTE' NOT NULL,
    CONSTRAINT uq_multa_emprestimo UNIQUE (id_emprestimo),
    CONSTRAINT fk_multa_emprestimo FOREIGN KEY (id_emprestimo) REFERENCES emprestimo (id_emprestimo),
    CONSTRAINT ck_multa_valor CHECK (valor > 0),
    CONSTRAINT ck_multa_estado CHECK (estado IN ('PENDENTE', 'PAGA', 'CANCELADA'))
);

CREATE TABLE notificacao (
    id_notificacao NUMBER CONSTRAINT pk_notificacao PRIMARY KEY,
    id_utilizador NUMBER NOT NULL,
    tipo VARCHAR2(30) NOT NULL,
    data_hora_envio TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    estado VARCHAR2(20) DEFAULT 'PENDENTE' NOT NULL,
    mensagem VARCHAR2(500) NOT NULL,
    id_emprestimo NUMBER,
    id_reserva NUMBER,
    CONSTRAINT fk_notif_util FOREIGN KEY (id_utilizador) REFERENCES utilizador (id_utilizador),
    CONSTRAINT fk_notif_emp FOREIGN KEY (id_emprestimo) REFERENCES emprestimo (id_emprestimo),
    CONSTRAINT fk_notif_res FOREIGN KEY (id_reserva) REFERENCES reserva (id_reserva),
    CONSTRAINT ck_notif_tipo CHECK (tipo IN ('PRAZO', 'RESERVA', 'MULTA')),
    CONSTRAINT ck_notif_estado CHECK (estado IN ('PENDENTE', 'ENVIADA', 'LIDA')),
    CONSTRAINT ck_notif_vinculo CHECK (
        (tipo = 'RESERVA' AND id_reserva IS NOT NULL AND id_emprestimo IS NULL)
        OR (tipo IN ('PRAZO', 'MULTA') AND id_emprestimo IS NOT NULL AND id_reserva IS NULL)
    )
);

-- Apenas um empréstimo activo/atrasado por exemplar (RN07).
CREATE UNIQUE INDEX uq_emp_exemplar_aberto
ON emprestimo (CASE WHEN estado IN ('ATIVO', 'ATRASADO') THEN id_exemplar END);

CREATE INDEX ix_reserva_fila ON reserva (id_livro, estado, data_hora_reserva, id_reserva);
CREATE INDEX ix_emp_prazo ON emprestimo (estado, prazo_devolucao);
CREATE INDEX ix_notif_utilizador ON notificacao (id_utilizador, data_hora_envio);

PROMPT Tabelas e indices criados.
