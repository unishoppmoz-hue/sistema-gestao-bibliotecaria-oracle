-- Executar como administrador autorizado, adaptando o caminho ao servidor.
-- O caminho deve existir fisicamente no SERVIDOR Oracle e ser acessivel
-- pela conta do servico Oracle.

CREATE OR REPLACE DIRECTORY DIR_BIBLIOTECA AS '/u01/backup/biblioteca';
GRANT READ, WRITE ON DIRECTORY DIR_BIBLIOTECA TO BIBLIOTECA;

-- Windows: substituir por caminho real, por exemplo:
-- CREATE OR REPLACE DIRECTORY DIR_BIBLIOTECA AS 'C:\oracle\backup\biblioteca';
