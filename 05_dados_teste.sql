-- 05 - Dados ficticios de demonstracao
-- Executar apenas uma vez, depois da criacao dos objectos.

INSERT INTO categoria VALUES (seq_categoria.NEXTVAL, 'Informatica', 'Tecnologias da informacao');
INSERT INTO categoria VALUES (seq_categoria.NEXTVAL, 'Literatura', 'Obras literarias');

INSERT INTO editora VALUES (seq_editora.NEXTVAL, 'Editora Saber', 'Maputo', '840000000');

INSERT INTO autor VALUES (seq_autor.NEXTVAL, 'Ana M. Tembe', 'Mocambicana');
INSERT INTO autor VALUES (seq_autor.NEXTVAL, 'Carlos Sitoe', 'Mocambicana');

INSERT INTO funcionario VALUES
    (seq_funcionario.NEXTVAL, 'Sara Matola', 'sara@biblioteca.exemplo',
     '840000111', 'Bibliotecaria', 'ATIVO');

INSERT INTO utilizador VALUES
    (seq_utilizador.NEXTVAL, 'Joao Mucavele', 'joao@exemplo.test',
     '840000222', 'Maputo', SYSDATE, 'ATIVO');

INSERT INTO utilizador VALUES
    (seq_utilizador.NEXTVAL, 'Maria Nhantumbo', 'maria@exemplo.test',
     '840000333', 'Matola', SYSDATE, 'ATIVO');

INSERT INTO livro VALUES
    (seq_livro.NEXTVAL, 'Fundamentos de Bases de Dados', '9780000000001',
     2024, '1.a', 1, 1);

INSERT INTO livro VALUES
    (seq_livro.NEXTVAL, 'Introducao a Programacao', '9780000000002',
     2025, '1.a', 1, 1);

INSERT INTO livro_autor VALUES (1, 1);
INSERT INTO livro_autor VALUES (2, 2);

INSERT INTO exemplar VALUES
    (seq_exemplar.NEXTVAL, 1, 'EX-001', 'BOM', 'DISPONIVEL', SYSDATE);

INSERT INTO exemplar VALUES
    (seq_exemplar.NEXTVAL, 2, 'EX-002', 'BOM', 'DISPONIVEL', SYSDATE);

COMMIT;

PROMPT Dados ficticios inseridos.
