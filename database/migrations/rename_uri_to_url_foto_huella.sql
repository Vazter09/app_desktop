-- Renombra uri_foto_* / uri_imagen_* → url_* (nomenclatura correcta).
-- Idempotente: no falla si ya están como url_ o si la tabla no existe.
-- Aplica a tab_log_ingresos y tab_novedades_ingreso.

DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_log_ingresos'
           AND column_name = 'uri_foto_facial'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_log_ingresos'
           AND column_name = 'url_foto_facial'
    ) THEN
        ALTER TABLE tab_log_ingresos
            RENAME COLUMN uri_foto_facial TO url_foto_facial;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_log_ingresos'
           AND column_name = 'uri_imagen_huella'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_log_ingresos'
           AND column_name = 'url_imagen_huella'
    ) THEN
        ALTER TABLE tab_log_ingresos
            RENAME COLUMN uri_imagen_huella TO url_imagen_huella;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_novedades_ingreso'
           AND column_name = 'uri_foto_facial'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_novedades_ingreso'
           AND column_name = 'url_foto_facial'
    ) THEN
        ALTER TABLE tab_novedades_ingreso
            RENAME COLUMN uri_foto_facial TO url_foto_facial;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_novedades_ingreso'
           AND column_name = 'uri_imagen_huella'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns
         WHERE table_schema = 'public'
           AND table_name = 'tab_novedades_ingreso'
           AND column_name = 'url_imagen_huella'
    ) THEN
        ALTER TABLE tab_novedades_ingreso
            RENAME COLUMN uri_imagen_huella TO url_imagen_huella;
    END IF;
END $$;
