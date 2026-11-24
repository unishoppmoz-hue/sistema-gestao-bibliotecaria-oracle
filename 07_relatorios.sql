-- 07 - Consultas de verificacao e relatorios

PROMPT === UTILIZADORES ===
SELECT * FROM utilizador ORDER BY id_utilizador;

PROMPT === EXEMPLARES ===
SELECT x.id_exemplar, x.codigo_exemplar, l.titulo, x.estado, x.disponibilidade
  FROM exemplar x
  JOIN livro l ON l.id_livro = x.id_livro
 ORDER BY x.id_exemplar;

PROMPT === EMPRESTIMOS ===
SELECT e.id_emprestimo, u.nome AS utilizador, x.codigo_exemplar,
       e.data_emprestimo, e.prazo_devolucao, e.data_devolucao, e.estado
  FROM emprestimo e
  JOIN utilizador u ON u.id_utilizador = e.id_utilizador
  JOIN exemplar x ON x.id_exemplar = e.id_exemplar
 ORDER BY e.id_emprestimo;

PROMPT === RESERVAS ===
SELECT r.id_reserva, u.nome AS utilizador, l.titulo,
       r.posicao_lista, r.estado, r.data_hora_reserva
  FROM reserva r
  JOIN utilizador u ON u.id_utilizador = r.id_utilizador
  JOIN livro l ON l.id_livro = r.id_livro
 ORDER BY r.id_reserva;

PROMPT === MULTAS ===
SELECT m.id_multa, m.id_emprestimo, u.nome AS utilizador,
       m.valor, m.data_multa, m.estado
  FROM multa m
  JOIN emprestimo e ON e.id_emprestimo = m.id_emprestimo
  JOIN utilizador u ON u.id_utilizador = e.id_utilizador
 ORDER BY m.id_multa;

PROMPT === NOTIFICACOES ===
SELECT * FROM notificacao ORDER BY id_notificacao;

PROMPT === LIVROS MAIS REQUISITADOS ===
SELECT l.id_livro, l.titulo, COUNT(e.id_emprestimo) AS total_emprestimos
  FROM livro l
  JOIN exemplar x ON x.id_livro = l.id_livro
  LEFT JOIN emprestimo e ON e.id_exemplar = x.id_exemplar
 GROUP BY l.id_livro, l.titulo
 ORDER BY total_emprestimos DESC, l.titulo;

PROMPT === UTILIZADORES COM MAIS EMPRESTIMOS ===
SELECT u.id_utilizador, u.nome, COUNT(e.id_emprestimo) AS total_emprestimos
  FROM utilizador u
  LEFT JOIN emprestimo e ON e.id_utilizador = u.id_utilizador
 GROUP BY u.id_utilizador, u.nome
 ORDER BY total_emprestimos DESC, u.nome;

PROMPT === EMPRESTIMOS EM ATRASO ===
SELECT e.id_emprestimo, u.nome, l.titulo, e.prazo_devolucao
  FROM emprestimo e
  JOIN utilizador u ON u.id_utilizador = e.id_utilizador
  JOIN exemplar x ON x.id_exemplar = e.id_exemplar
  JOIN livro l ON l.id_livro = x.id_livro
 WHERE e.estado = 'ATRASADO'
 ORDER BY e.prazo_devolucao;

PROMPT === OBJECTOS INVALIDOS ===
SELECT object_name, object_type, status
  FROM user_objects
 WHERE status = 'INVALID'
 ORDER BY object_type, object_name;

PROMPT === ERROS DE COMPILACAO ===
SELECT name, type, line, position, text
  FROM user_errors
 ORDER BY name, sequence;
