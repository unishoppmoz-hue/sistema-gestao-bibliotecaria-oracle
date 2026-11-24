-- 03 - Triggers de automatizacao

-- Sincroniza a disponibilidade do exemplar com o estado do emprestimo.
CREATE OR REPLACE TRIGGER trg_estado_exemplar
AFTER INSERT OR UPDATE OF estado ON emprestimo
FOR EACH ROW
BEGIN
    IF INSERTING AND :NEW.estado IN ('ATIVO', 'ATRASADO') THEN
        UPDATE exemplar
           SET disponibilidade = 'EMPRESTADO'
         WHERE id_exemplar = :NEW.id_exemplar
           AND disponibilidade = 'DISPONIVEL';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Exemplar indisponivel para emprestimo.');
        END IF;
    ELSIF UPDATING
       AND :NEW.estado = 'DEVOLVIDO'
       AND :OLD.estado IN ('ATIVO', 'ATRASADO') THEN
        UPDATE exemplar
           SET disponibilidade = 'DISPONIVEL'
         WHERE id_exemplar = :NEW.id_exemplar
           AND disponibilidade = 'EMPRESTADO';
    END IF;
END;
/

-- Preserva o historico de emprestimos (RN31).
CREATE OR REPLACE TRIGGER trg_preservar_historico
BEFORE DELETE ON emprestimo
BEGIN
    RAISE_APPLICATION_ERROR(-20011, 'Nao e permitido eliminar o historico de emprestimos.');
END;
/

-- Gera notificacao automaticamente quando uma multa e registada.
CREATE OR REPLACE TRIGGER trg_notificar_multa
AFTER INSERT ON multa
FOR EACH ROW
DECLARE
    v_id_utilizador emprestimo.id_utilizador%TYPE;
BEGIN
    SELECT id_utilizador
      INTO v_id_utilizador
      FROM emprestimo
     WHERE id_emprestimo = :NEW.id_emprestimo;

    INSERT INTO notificacao
        (id_notificacao, id_utilizador, tipo, mensagem, id_emprestimo)
    VALUES
        (seq_notificacao.NEXTVAL, v_id_utilizador, 'MULTA',
         'Foi registada uma multa por atraso de devolucao.',
         :NEW.id_emprestimo);
END;
/

PROMPT Triggers criados. Confirme USER_ERRORS no final.
