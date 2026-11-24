-- 04 - Procedures de negocio

CREATE OR REPLACE PROCEDURE sp_registar_emprestimo (
    p_id_utilizador IN NUMBER,
    p_id_exemplar IN NUMBER,
    p_prazo IN DATE,
    p_id_emprestimo OUT NUMBER
) AS
    v_estado utilizador.estado%TYPE;
    v_disp exemplar.disponibilidade%TYPE;
BEGIN
    SELECT estado
      INTO v_estado
      FROM utilizador
     WHERE id_utilizador = p_id_utilizador;

    IF v_estado <> 'ATIVO' THEN
        RAISE_APPLICATION_ERROR(-20012, 'Utilizador inactivo.');
    END IF;

    SELECT disponibilidade
      INTO v_disp
      FROM exemplar
     WHERE id_exemplar = p_id_exemplar
       FOR UPDATE;

    IF v_disp <> 'DISPONIVEL' THEN
        RAISE_APPLICATION_ERROR(-20013, 'Exemplar nao disponivel.');
    END IF;

    IF p_prazo IS NULL OR TRUNC(p_prazo) <= TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20014, 'O prazo de devolucao deve ser uma data futura.');
    END IF;

    p_id_emprestimo := seq_emprestimo.NEXTVAL;

    INSERT INTO emprestimo
        (id_emprestimo, id_utilizador, id_exemplar, data_emprestimo, prazo_devolucao, estado)
    VALUES
        (p_id_emprestimo, p_id_utilizador, p_id_exemplar,
         TRUNC(SYSDATE), TRUNC(p_prazo), 'ATIVO');
END;
/

CREATE OR REPLACE PROCEDURE sp_reservar_livro (
    p_id_utilizador IN NUMBER,
    p_id_livro IN NUMBER,
    p_id_reserva OUT NUMBER
) AS
    v_estado utilizador.estado%TYPE;
    v_disponiveis NUMBER;
    v_posicao NUMBER;
BEGIN
    SELECT estado
      INTO v_estado
      FROM utilizador
     WHERE id_utilizador = p_id_utilizador;

    IF v_estado <> 'ATIVO' THEN
        RAISE_APPLICATION_ERROR(-20015, 'Utilizador inactivo.');
    END IF;

    SELECT COUNT(*)
      INTO v_disponiveis
      FROM exemplar
     WHERE id_livro = p_id_livro
       AND disponibilidade = 'DISPONIVEL';

    IF v_disponiveis > 0 THEN
        RAISE_APPLICATION_ERROR(-20016, 'Existem exemplares disponiveis; nao e necessario reservar.');
    END IF;

    SELECT NVL(MAX(posicao_lista), 0) + 1
      INTO v_posicao
      FROM reserva
     WHERE id_livro = p_id_livro
       AND estado IN ('PENDENTE', 'NOTIFICADA');

    p_id_reserva := seq_reserva.NEXTVAL;

    INSERT INTO reserva
        (id_reserva, id_utilizador, id_livro, posicao_lista, estado)
    VALUES
        (p_id_reserva, p_id_utilizador, p_id_livro, v_posicao, 'PENDENTE');
END;
/

CREATE OR REPLACE PROCEDURE sp_registar_devolucao (
    p_id_emprestimo IN NUMBER,
    p_multa_por_dia IN NUMBER DEFAULT 25
) AS
    v_exemplar NUMBER;
    v_livro NUMBER;
    v_prazo DATE;
    v_reserva NUMBER;
    v_utilizador NUMBER;
    v_dias NUMBER;
BEGIN
    IF p_multa_por_dia IS NULL OR p_multa_por_dia < 0 THEN
        RAISE_APPLICATION_ERROR(-20017, 'Valor diario da multa invalido.');
    END IF;

    SELECT id_exemplar, prazo_devolucao
      INTO v_exemplar, v_prazo
      FROM emprestimo
     WHERE id_emprestimo = p_id_emprestimo
       AND estado IN ('ATIVO', 'ATRASADO')
       FOR UPDATE;

    UPDATE emprestimo
       SET estado = 'DEVOLVIDO',
           data_devolucao = TRUNC(SYSDATE)
     WHERE id_emprestimo = p_id_emprestimo;

    -- O trigger liberta o exemplar. Se existir fila, o primeiro da fila recebe a reserva.
    SELECT id_livro
      INTO v_livro
      FROM exemplar
     WHERE id_exemplar = v_exemplar;

    BEGIN
        SELECT id_reserva, id_utilizador
          INTO v_reserva, v_utilizador
          FROM (
                SELECT id_reserva, id_utilizador
                  FROM reserva
                 WHERE id_livro = v_livro
                   AND estado = 'PENDENTE'
                 ORDER BY data_hora_reserva, id_reserva
               )
         WHERE ROWNUM = 1;

        UPDATE reserva
           SET estado = 'NOTIFICADA'
         WHERE id_reserva = v_reserva;

        UPDATE exemplar
           SET disponibilidade = 'RESERVADO'
         WHERE id_exemplar = v_exemplar;

        INSERT INTO notificacao
            (id_notificacao, id_utilizador, tipo, mensagem, id_reserva)
        VALUES
            (seq_notificacao.NEXTVAL, v_utilizador, 'RESERVA',
             'O livro reservado ja esta disponivel para levantamento.',
             v_reserva);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    v_dias := GREATEST(TRUNC(SYSDATE) - TRUNC(v_prazo), 0);

    IF v_dias > 0 AND p_multa_por_dia > 0 THEN
        INSERT INTO multa (id_multa, id_emprestimo, valor, estado)
        VALUES (seq_multa.NEXTVAL, p_id_emprestimo,
                v_dias * p_multa_por_dia, 'PENDENTE');
        -- trg_notificar_multa cria a notificacao correspondente.
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20018, 'Emprestimo inexistente ou ja devolvido.');
END;
/

CREATE OR REPLACE PROCEDURE sp_levantar_reserva (
    p_id_reserva IN NUMBER,
    p_id_exemplar IN NUMBER,
    p_prazo IN DATE,
    p_id_emprestimo OUT NUMBER
) AS
    v_id_utilizador NUMBER;
    v_id_livro NUMBER;
    v_livro_exemplar NUMBER;
    v_disp VARCHAR2(20);
BEGIN
    SELECT id_utilizador, id_livro
      INTO v_id_utilizador, v_id_livro
      FROM reserva
     WHERE id_reserva = p_id_reserva
       AND estado = 'NOTIFICADA'
       FOR UPDATE;

    SELECT id_livro, disponibilidade
      INTO v_livro_exemplar, v_disp
      FROM exemplar
     WHERE id_exemplar = p_id_exemplar
       FOR UPDATE;

    IF v_id_livro <> v_livro_exemplar OR v_disp <> 'RESERVADO' THEN
        RAISE_APPLICATION_ERROR(-20019, 'Exemplar nao corresponde a reserva notificada.');
    END IF;

    UPDATE exemplar
       SET disponibilidade = 'DISPONIVEL'
     WHERE id_exemplar = p_id_exemplar;

    sp_registar_emprestimo(v_id_utilizador, p_id_exemplar, p_prazo, p_id_emprestimo);

    UPDATE reserva
       SET estado = 'CONCLUIDA'
     WHERE id_reserva = p_id_reserva;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20020, 'Reserva ou exemplar inexistente/indisponivel.');
END;
/

CREATE OR REPLACE PROCEDURE sp_actualizar_atrasos AS
BEGIN
    UPDATE emprestimo
       SET estado = 'ATRASADO'
     WHERE estado = 'ATIVO'
       AND prazo_devolucao < TRUNC(SYSDATE);

    INSERT INTO notificacao
        (id_notificacao, id_utilizador, tipo, mensagem, id_emprestimo)
    SELECT seq_notificacao.NEXTVAL,
           e.id_utilizador,
           'PRAZO',
           'O prazo de devolucao do seu emprestimo expirou.',
           e.id_emprestimo
      FROM emprestimo e
     WHERE e.estado = 'ATRASADO'
       AND NOT EXISTS (
            SELECT 1
              FROM notificacao n
             WHERE n.tipo = 'PRAZO'
               AND n.id_emprestimo = e.id_emprestimo
       );
END;
/

PROMPT Procedures criadas. Confirme USER_ERRORS no final.
