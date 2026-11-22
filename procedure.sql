CREATE OR REPLACE PROCEDURE alterar_aeronave_dispositivo(
    id_dispositivo_troca INT, 
    id_nova_aeronave INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    dono_aeronave INT;
BEGIN
    SELECT usuario_id INTO dono_aeronave
    FROM aeronave
    WHERE id = id_nova_aeronave;

    IF dono_aeronave IS NULL THEN
        RAISE EXCEPTION 'Aeronave ID % não encontrada.', id_nova_aeronave;
    END IF;

    UPDATE dispositivo 
    SET aeronave_id = id_nova_aeronave, usuario_id = dono_aeronave
    WHERE id = id_dispositivo_troca;

    IF FOUND THEN
        COMMIT;
    ELSE
        RAISE EXCEPTION 'Dispositivo ID % não encontrado.', id_dispositivo_troca;
    END IF;
END;
$$;

--==============================================================================

CREATE OR REPLACE PROCEDURE alterar_dono_aeronave(
    id_aeronave_alteracao INT,
    id_novo_dono INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    atual_dono_aeronave INT;
    novo_dono_aeronave INT;
BEGIN

    SELECT id INTO novo_dono_aeronave
    FROM usuario
    WHERE id = id_novo_dono;

    IF novo_dono_aeronave IS NULL THEN
        RAISE EXCEPTION 'Usuário ID % não encontrado.', id_novo_dono;
    END IF;

    SELECT usuario_id INTO atual_dono_aeronave
    FROM aeronave
    WHERE id = id_aeronave_alteracao;

    IF atual_dono_aeronave IS NULL THEN
        RAISE EXCEPTION 'Aeronave ID % não encontrada.', id_aeronave_alteracao;
    END IF;

    UPDATE aeronave 
    SET usuario_id = id_novo_dono
    WHERE id = id_aeronave_alteracao;

    IF FOUND THEN
        UPDATE dispositivo 
        SET usuario_id = id_novo_dono
        WHERE aeronave_id = id_aeronave_alteracao;

        IF NOT FOUND THEN
            RAISE NOTICE  'Não há dispositivos alocados na aeronave %.', id_aeronave_alteracao;
        END IF;

        COMMIT;
    ELSE
        RAISE EXCEPTION 'Operação falhou.';
    END IF;
END;
$$;







