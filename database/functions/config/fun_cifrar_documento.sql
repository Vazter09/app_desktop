-- Cifra un texto (documento de identidad) con pgcrypto (PGP simétrico).
-- Usa la clave configurada en app.encryption_key (ALTER DATABASE ... SET).
-- Retorna NULL si wtexto es NULL. Ver Fase 1 Entregable 2.
CREATE OR REPLACE FUNCTION fun_cifrar_documento(
    wtexto TEXT
) RETURNS BYTEA AS $$
DECLARE
    vclave       TEXT;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wtexto IS NULL THEN
        RETURN NULL;
    END IF;

    vclave := current_setting('app.encryption_key', true);
    IF vclave IS NULL OR LENGTH(TRIM(vclave)) = 0 THEN
        PERFORM smartcset_raise_negocio(
            'La clave de cifrado no está configurada en el servidor de base de datos.',
            NULL,
            'Configure app.encryption_key con ALTER DATABASE ... SET.'
        );
    END IF;

    RETURN pgp_sym_encrypt(wtexto, vclave);
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
