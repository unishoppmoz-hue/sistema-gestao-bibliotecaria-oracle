-- 06 - Cenario funcional: emprestimo, reserva, devolucao e levantamento
-- Requer os dados iniciais do ficheiro 05 e deve ser executado uma unica vez.
SET SERVEROUTPUT ON

DECLARE
    v_emprestimo NUMBER;
    v_reserva NUMBER;
    v_emprestimo_reserva NUMBER;
BEGIN
    sp_registar_emprestimo(1, 1, TRUNC(SYSDATE) + 7, v_emprestimo);
    DBMS_OUTPUT.PUT_LINE('Emprestimo inicial: ' || v_emprestimo);

    sp_reservar_livro(2, 1, v_reserva);
    DBMS_OUTPUT.PUT_LINE('Reserva criada: ' || v_reserva);

    sp_registar_devolucao(v_emprestimo);
    DBMS_OUTPUT.PUT_LINE('Devolucao registada; reserva notificada.');

    sp_levantar_reserva(v_reserva, 1, TRUNC(SYSDATE) + 7, v_emprestimo_reserva);
    DBMS_OUTPUT.PUT_LINE('Novo emprestimo: ' || v_emprestimo_reserva);
END;
/

COMMIT;

PROMPT Verifique estados em sql/07_relatorios.sql.
