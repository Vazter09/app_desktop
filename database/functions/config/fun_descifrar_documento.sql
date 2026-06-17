-- Descifra un documento de identidad previamente cifrado con fun_cifrar_documento.
-- Usa la clave configurada en app.encryption_key (ALTER DATABASE ... SET).
-- Retorna NULL si wenc es NULL. Ver Fase 1 Entregable 2.
CREATE OR REPLACE FUNCTION fun_descifrar_documento(
    wenc BYTEA
) RETURNS TEXT AS $$
DECLARE
    vclave TEXT;
BEGIN
    IF wenc IS NULL THEN
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

    RETURN pgp_sym_decrypt(wenc, vclave);
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
