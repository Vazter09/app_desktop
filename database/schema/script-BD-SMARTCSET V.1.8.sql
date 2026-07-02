--
-- PostgreSQL database dump
--

\restrict i4eEGgAcgIyteo6StLYtzPUlRUw1QaAm8uaXUFNsnzyl4cbN0hPaBoKdGjHJij9

-- Dumped from database version 18.4 (Ubuntu 18.4-1.pgdg24.04+1)
-- Dumped by pg_dump version 18.4 (Ubuntu 18.4-1.pgdg24.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: extension; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.extension AS numeric(8,0)
	CONSTRAINT extension_check CHECK ((VALUE >= (0)::numeric));


--
-- Name: mail_personal; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.mail_personal AS character varying(255)
	CONSTRAINT mail_personal_check CHECK (((VALUE)::text ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'::text));


--
-- Name: telefono_fijo; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.telefono_fijo AS numeric(10,0)
	CONSTRAINT telefono_fijo_check CHECK (((VALUE >= ('6010000000'::bigint)::numeric) AND (VALUE <= ('6089999999'::bigint)::numeric)));


--
-- Name: telefono_movil; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.telefono_movil AS numeric(10,0)
	CONSTRAINT telefono_movil_check CHECK (((VALUE >= ('3000000000'::bigint)::numeric) AND (VALUE <= ('3519999999'::bigint)::numeric)));


--
-- Name: datos_personales_aprendiz; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.datos_personales_aprendiz AS (
	tel_alterno public.telefono_movil,
	tel_sede public.telefono_fijo,
	ext_sede public.extension,
	tel_padre_fijo public.telefono_fijo,
	tel_padre_movil public.telefono_movil,
	val_mail_institucional public.mail_personal,
	nom_contacto_emergencias character varying,
	tel_contacto_emergencias numeric(10,0)
);


--
-- Name: innovacion_proyectos; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.innovacion_proyectos AS (
	ind_resuelve_necesidad_sector_prod boolean,
	ind_mejora_proceso_productivo boolean,
	ind_usa_nuevas_tecnicas boolean,
	ind_prod_derechos_autor boolean,
	ind_posicion_mercado boolean
);


--
-- Name: inv_ambiente; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.inv_ambiente AS (
	equipos_computo boolean,
	num_equipos numeric(3,0),
	ind_smartboard boolean,
	ind_videobeam boolean,
	ind_impresora boolean,
	ind_aire boolean,
	val_capacidad numeric(3,0)
);


--
-- Name: mail_institucional; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.mail_institucional AS character varying(255)
	CONSTRAINT mail_institucional_check CHECK (((VALUE)::text ~* '^[a-z0-9._%-]+@[a-z0-9.-]+\.[a-z]{2,}$'::text));


--
-- Name: nombre_geografico; Type: DOMAIN; Schema: public; Owner: -
--

CREATE DOMAIN public.nombre_geografico AS character varying(50)
	CONSTRAINT nombre_geografico_check CHECK (((length((VALUE)::text) >= 3) AND ((VALUE)::text ~ '^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ .-]+$'::text)));


--
-- Name: valoracion_productiva; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.valoracion_productiva AS (
	ind_necesidad_cliente_potencial boolean,
	ind_viabilidad_plan_negocio boolean
);


--
-- Name: fn_after_asistencia_llamados(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_after_asistencia_llamados() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tiempo_gracia INT;
    v_max_llamados  INT;
    v_llamados_actual SMALLINT;
BEGIN
    -- Obtener parámetros
    SELECT val_tiempo_gracia_aprendiz, val_max_llamados_aprendiz
      INTO v_tiempo_gracia, v_max_llamados
      FROM tab_pmtros_grales
     LIMIT 1;

    -- Solo actuar si es 'Tarde' y supera la gracia
    IF NEW.ind_estado = 'Tarde' AND NEW.minutos_retraso > v_tiempo_gracia THEN
        -- Incrementar llamados
        UPDATE tab_aprendices
           SET num_llamados = num_llamados + 1
         WHERE id_aprendiz = NEW.id_aprendiz;

        -- Obtener nuevo valor y verificar límite
        SELECT num_llamados
          INTO v_llamados_actual
          FROM tab_aprendices
         WHERE id_aprendiz = NEW.id_aprendiz;

        IF v_llamados_actual >= v_max_llamados THEN
            RAISE NOTICE 'Aprendiz % (llamados acumulados: %).',
                         NEW.id_aprendiz, v_llamados_actual;
        END IF;
    END IF;

    RETURN NEW;
END;
$$;


--
-- Name: fun_act_tabla(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_act_tabla() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_usuario   TEXT;
    wid_consec  tab_borrados.id_consec%TYPE;
BEGIN
    -- Intenta leer el usuario SmartCSET seteado por PHP en esta sesión.
    -- El segundo argumento TRUE evita error si la variable no existe.
    w_usuario := NULLIF(TRIM(current_setting('app.usuario', TRUE)), '');

    -- Si no hay usuario de app (conexión directa a la BD), usa el
    -- usuario de conexión PostgreSQL como fallback.
    IF w_usuario IS NULL THEN
        w_usuario := CURRENT_USER;
    END IF;

    IF TG_OP = 'INSERT' THEN
        NEW.usr_insert = w_usuario;
        NEW.fec_insert = CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;

    IF TG_OP = 'UPDATE' THEN
        NEW.usr_update = w_usuario;
        NEW.fec_update = CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;

    IF TG_OP = 'INSERT OR UPDATE' THEN
        SELECT MAX(a.id_consec) INTO wid_consec FROM tab_borrados a;
        IF wid_consec IS NULL THEN
            wid_consec = 1;
        ELSE
            wid_consec = wid_consec + 1;
        END IF;
        INSERT INTO tab_borrados
        VALUES (wid_consec, TG_RELNAME, w_usuario, CURRENT_TIMESTAMP);
        RETURN OLD;
    END IF;
END;
$$;


--
-- Name: fun_actualizar_aprendiz(numeric, character varying, character varying, character varying, public.mail_personal, date, numeric, numeric, character varying, character varying, character varying, character varying, public.telefono_fijo, public.telefono_movil, character varying, public.telefono_movil, boolean, public.telefono_movil, public.telefono_fijo, public.extension, public.telefono_fijo, public.telefono_movil, public.mail_personal, numeric, character varying, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_actualizar_aprendiz(wid_persona numeric, wid_tipo_docum character varying, wnom_persona character varying, wape_persona character varying, wmail_persona public.mail_personal, wfec_nacimiento date, wind_genero numeric, wid_nivel_estudio numeric, wid_profesion character varying, wid_dpto_reside character varying, wid_ciudad_reside character varying, wdir_ciudad_reside character varying, wtel_persona_fijo public.telefono_fijo, wtel_persona_movil public.telefono_movil, wnom_contacto_emergencias character varying, wtel_contacto_emergencias public.telefono_movil, wind_envio_correo boolean, wtel_alterno public.telefono_movil, wtel_sede public.telefono_fijo, wext_sede public.extension, wtel_padre_fijo public.telefono_fijo, wtel_padre_movil public.telefono_movil, wval_mail_institucional public.mail_personal, wind_etdo_formacion numeric, wusr character varying, wid_ficha numeric DEFAULT NULL::numeric) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_tipo_aprendiz CONSTANT DECIMAL(2,0) := 2;
    v_nom            VARCHAR(40);
    v_ape            VARCHAR(30);
    v_dir            VARCHAR(100);
    v_contacto       VARCHAR(60);
    v_mail_norm      TEXT;
    v_datos          datos_personales_aprendiz;
    w_exc_state      TEXT;
    w_exc_msg        TEXT;
    w_exc_detail     TEXT;
    w_exc_hint       TEXT;
BEGIN
    IF wusr IS NULL OR LENGTH(TRIM(wusr)) < 3 THEN
        PERFORM smartcset_raise_validacion('El usuario de auditoría no es válido.');
    END IF;

    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    v_nom := TRIM(wnom_persona);
    v_ape := TRIM(wape_persona);
    IF LENGTH(v_nom) < 3 OR LENGTH(v_ape) < 2 THEN
        PERFORM smartcset_raise_validacion(
            'Nombres (mín. 3 caracteres) y apellidos (mín. 2) son obligatorios.'
        );
    END IF;

    v_mail_norm := LOWER(TRIM(COALESCE(wmail_persona::TEXT, '')));
    IF v_mail_norm = '' OR v_mail_norm !~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' THEN
        PERFORM smartcset_raise_validacion(
            'El correo personal no tiene un formato válido.',
            'Use una dirección como nombre@dominio.com'
        );
    END IF;

    IF wfec_nacimiento > CURRENT_DATE OR wfec_nacimiento < DATE '1900-01-01' THEN
    PERFORM smartcset_raise_validacion('La fecha de nacimiento no es válida (debe ser entre 1900-01-01 y la fecha actual).');
    END IF;

    IF wind_genero IS NULL OR wind_genero NOT IN (1, 2, 3, 4) THEN
        PERFORM smartcset_raise_validacion('Seleccione un género válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_niveles_estudio WHERE id_nivel_estudio = wid_nivel_estudio
    ) THEN
        PERFORM smartcset_raise_validacion('El nivel de estudio seleccionado no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_profesiones WHERE id_profesion = wid_profesion
    ) THEN
        PERFORM smartcset_raise_validacion('La profesión u oficio seleccionado no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_dptos WHERE id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion('El departamento de residencia no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM tab_ciudades
         WHERE id_ciudad = wid_ciudad_reside
           AND id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ciudad no corresponde al departamento seleccionado.'
        );
    END IF;

    v_dir := TRIM(wdir_ciudad_reside);
    IF LENGTH(v_dir) < 10 THEN
        PERFORM smartcset_raise_validacion(
            'La dirección de residencia debe tener al menos 10 caracteres.'
        );
    END IF;

    IF wtel_persona_fijo IS NULL
       OR (wtel_persona_fijo::TEXT ~ '^\d+$' AND (wtel_persona_fijo < 6010000000 OR wtel_persona_fijo > 6089999999)) THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono fijo debe ser un número válido de Bogotá o área metropolitana (601xxxxxxx).'
        );
    END IF;

    IF wtel_persona_movil IS NULL
       OR (wtel_persona_movil::TEXT ~ '^\d+$' AND (wtel_persona_movil < 3000000000 OR wtel_persona_movil > 3519999999)) THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono móvil debe ser un celular colombiano válido (300xxxxxxx a 351xxxxxxx).'
        );
    END IF;

    v_contacto := TRIM(wnom_contacto_emergencias);
    IF LENGTH(v_contacto) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El contacto de emergencias debe tener al menos 5 caracteres.'
        );
    END IF;

    IF wtel_contacto_emergencias IS NULL
       OR (wtel_contacto_emergencias::TEXT ~ '^\d+$' AND (wtel_contacto_emergencias < 3000000000 OR wtel_contacto_emergencias > 3519999999)) THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono de emergencias debe ser un celular colombiano válido.'
        );
    END IF;

    IF wind_etdo_formacion IS NULL
       OR wind_etdo_formacion NOT IN (1, 2, 3, 4, 5, 6, 7) THEN
        PERFORM smartcset_raise_validacion('Seleccione un estado de formación válido.');
    END IF;

    IF wid_ficha IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione la ficha de formación del aprendiz.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_fichas WHERE id_ficha = wid_ficha
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ficha de formación seleccionada no existe.',
            'id_ficha=' || wid_ficha::TEXT
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_personas WHERE id_persona = wid_persona
    ) THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se encontró una persona con ese número de documento.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_personas
        WHERE id_persona = wid_persona
          AND id_tipo_persona = v_tipo_aprendiz
    ) THEN
        PERFORM smartcset_raise_negocio(
            'La persona no está registrada como aprendiz.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    v_datos := ROW(
        wtel_alterno,
        wtel_sede,
        wext_sede,
        wtel_padre_fijo,
        wtel_padre_movil,
        wval_mail_institucional,
        v_contacto,
        wtel_contacto_emergencias
    )::datos_personales_aprendiz;

    UPDATE tab_personas
    SET id_tipo_docum          = wid_tipo_docum,
        nom_persona            = v_nom,
        ape_persona            = v_ape,
        mail_persona           = v_mail_norm::mail_personal,
        fec_nacimiento         = wfec_nacimiento,
        ind_genero             = wind_genero,
        id_nivel_estudio       = wid_nivel_estudio,
        id_profesion           = wid_profesion,
        id_dpto_reside         = wid_dpto_reside,
        id_ciudad_reside       = wid_ciudad_reside,
        dir_ciudad_reside      = v_dir,
        tel_persona_fijo       = wtel_persona_fijo,
        tel_persona_movil      = wtel_persona_movil,
        nom_contacto_emergencias = v_contacto,
        tel_contacto_emergencias = wtel_contacto_emergencias,
        ind_envio_correo       = COALESCE(wind_envio_correo, FALSE),
        usr_update             = TRIM(wusr),
        fec_update             = CURRENT_TIMESTAMP
    WHERE id_persona = wid_persona;

    IF NOT EXISTS (SELECT 1 FROM tab_aprendices WHERE id_aprendiz = wid_persona) THEN
        INSERT INTO tab_aprendices (
            id_aprendiz, datos_aprendiz,
            ind_etdo_formacion, num_llamados,
            usr_insert, fec_insert
        ) VALUES (
            wid_persona, v_datos,
            wind_etdo_formacion, 0,
            TRIM(wusr), CURRENT_TIMESTAMP
        );
    ELSE
        UPDATE tab_aprendices
        SET datos_aprendiz      = v_datos,
            ind_etdo_formacion = wind_etdo_formacion,
            usr_update         = TRIM(wusr),
            fec_update         = CURRENT_TIMESTAMP
        WHERE id_aprendiz = wid_persona;
    END IF;

    IF EXISTS (
        SELECT 1 FROM tab_aprendices_fichas
        WHERE id_aprendiz = wid_persona
          AND id_ficha = wid_ficha
    ) THEN
        UPDATE tab_aprendices_fichas
        SET usr_update = TRIM(wusr),
            fec_update = CURRENT_TIMESTAMP
        WHERE id_aprendiz = wid_persona
          AND id_ficha = wid_ficha;
    ELSE
        DELETE FROM tab_aprendices_fichas
        WHERE id_aprendiz = wid_persona;

        INSERT INTO tab_aprendices_fichas (
            id_ficha, id_aprendiz, usr_insert, fec_insert
        ) VALUES (
            wid_ficha, wid_persona, TRIM(wusr), CURRENT_TIMESTAMP
        );
    END IF;

    RETURN wid_persona::TEXT;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('Ya existe un registro con esos datos.');
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$_$;


--
-- Name: fun_actualizar_password(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_actualizar_password(wid_usuario text, wpass_nuevo text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_usuario IS NULL OR TRIM(wid_usuario) = '' THEN
        PERFORM smartcset_raise_validacion('El usuario es obligatorio.');
    END IF;

    IF wpass_nuevo IS NULL OR LENGTH(wpass_nuevo) < 12 THEN
        PERFORM smartcset_raise_validacion(
            'La contraseña debe tener al menos 12 caracteres.',
            NULL,
            'Use una contraseña más larga o un hash bcrypt válido.'
        );
    END IF;

    UPDATE tab_usuarios
    SET pass_usuario = wpass_nuevo
    WHERE id_usuario = wid_usuario;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'Usuario no encontrado.',
            'id_usuario=' || wid_usuario
        );
    END IF;

    RETURN 'OK';
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
$$;


--
-- Name: fun_actualizar_sesion_actividad(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_actualizar_sesion_actividad(p_id_sesion integer, p_ult_ruta character varying DEFAULT NULL::character varying, p_ult_menu_id character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF p_id_sesion IS NULL OR p_id_sesion < 1 THEN
        RETURN 'OK';
    END IF;

    UPDATE tab_sesiones
    SET ult_actividad = CURRENT_TIMESTAMP,
        ult_ruta = COALESCE(NULLIF(TRIM(p_ult_ruta), ''), ult_ruta),
        ult_menu_id = COALESCE(NULLIF(TRIM(p_ult_menu_id), ''), ult_menu_id)
    WHERE id_sesion = p_id_sesion
      AND fec_fin IS NULL;

    RETURN 'OK';
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
$$;


--
-- Name: fun_archivar_sesiones_antiguas(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_archivar_sesiones_antiguas(p_dias integer DEFAULT 7) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_eliminados  INTEGER;
    w_exc_state   TEXT;
    w_exc_msg     TEXT;
    w_exc_detail  TEXT;
    w_exc_hint    TEXT;
BEGIN
    IF p_dias IS NULL OR p_dias < 1 THEN
        PERFORM smartcset_raise_validacion('Los días de retención deben ser al menos 1.');
    END IF;

    INSERT INTO tab_sesiones_archivo (
        id_sesion, id_usuario, fec_inicio, fec_fin, ult_actividad,
        ult_ruta, ult_menu_id, cod_cierre, usr_cierre, ip_cliente
    )
    SELECT
        s.id_sesion, s.id_usuario, s.fec_inicio, s.fec_fin, s.ult_actividad,
        s.ult_ruta, s.ult_menu_id, s.cod_cierre, s.usr_cierre, s.ip_cliente
    FROM tab_sesiones s
    WHERE s.fec_fin IS NOT NULL
      AND s.fec_fin < (CURRENT_TIMESTAMP - (p_dias || ' days')::INTERVAL)
    ON CONFLICT (id_sesion) DO NOTHING;

    DELETE FROM tab_sesiones s
    WHERE s.fec_fin IS NOT NULL
      AND s.fec_fin < (CURRENT_TIMESTAMP - (p_dias || ' days')::INTERVAL)
      AND EXISTS (
          SELECT 1 FROM tab_sesiones_archivo a WHERE a.id_sesion = s.id_sesion
      );

    GET DIAGNOSTICS w_eliminados = ROW_COUNT;

    RETURN w_eliminados::TEXT;
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
$$;


--
-- Name: fun_buscar_ingreso_abierto(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_buscar_ingreso_abierto(wid_visitante numeric) RETURNS integer
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    wid_ingreso  INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_visitante IS NULL OR wid_visitante < 1 THEN
        RETURN NULL;
    END IF;

    SELECT l.id_ingreso
      INTO wid_ingreso
      FROM tab_log_ingresos l
     WHERE l.id_visitante = wid_visitante
       AND l.fec_salida = l.fec_ingreso
     ORDER BY l.fec_ingreso DESC
     LIMIT 1;

    RETURN wid_ingreso;
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
        RETURN NULL;
END;
$$;


--
-- Name: fun_cifrar_documento(text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_cifrar_documento(wtexto text) RETURNS bytea
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
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
$$;


--
-- Name: fun_crear_usuarios_instructores(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_crear_usuarios_instructores() RETURNS TABLE(insertados integer, actualizados integer, errores integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_insertados   INTEGER := 0;
    v_actualizados INTEGER := 0;
    v_errores      INTEGER := 0;
BEGIN
    -- 1. Insertar instructores que aún no son usuarios
    WITH nuevos AS (
        INSERT INTO tab_usuarios (id_usuario, nom_usuario, pass_usuario, mail_usuario,
                                  ind_usuario, ind_estado, usr_insert, fec_insert)
        SELECT p.id_persona::VARCHAR,
               SPLIT_PART(TRIM(p.nom_persona), ' ', 1) || ' ' || SPLIT_PART(TRIM(p.ape_persona), ' ', 1),
               crypt(p.id_persona::TEXT, gen_salt('bf')),
               COALESCE(p.mail_persona, 'sin_correo@correo.com'),
               FALSE,
               TRUE,
               'carga_automatica',
               CURRENT_TIMESTAMP
        FROM tab_personas p
        WHERE p.id_tipo_persona = 3
          AND p.nom_persona IS NOT NULL AND TRIM(p.nom_persona) != ''
          AND p.ape_persona IS NOT NULL AND TRIM(p.ape_persona) != ''
        ON CONFLICT (id_usuario) DO NOTHING
        RETURNING id_usuario
    )
    SELECT COUNT(id_usuario) INTO v_insertados FROM nuevos;

    -- 2. Actualizar ind_usuario = FALSE para instructores YA existentes que aún tengan TRUE
    UPDATE tab_usuarios u
    SET ind_usuario = FALSE,
        usr_update = 'carga_automatica',
        fec_update = CURRENT_TIMESTAMP
    FROM tab_personas p
    WHERE p.id_tipo_persona = 3
      AND p.nom_persona IS NOT NULL AND TRIM(p.nom_persona) != ''
      AND p.ape_persona IS NOT NULL AND TRIM(p.ape_persona) != ''
      AND u.id_usuario = p.id_persona::VARCHAR
      AND u.ind_usuario = TRUE;   -- Solo si es necesario cambiarlo

    GET DIAGNOSTICS v_actualizados = ROW_COUNT;  -- Cuenta los actualizados

    -- 3. Asegurar menús '03' y '0301' para todos los instructores válidos que tengan usuario
    INSERT INTO tab_menu_usuarios (id_usuario, id_menu, usr_insert, fec_insert)
    SELECT u.id_usuario, m.id_menu, 'carga_automatica', CURRENT_TIMESTAMP
    FROM tab_personas p
    JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
    CROSS JOIN (VALUES ('03'), ('0301')) AS m(id_menu)
    WHERE p.id_tipo_persona = 3
      AND p.nom_persona IS NOT NULL AND TRIM(p.nom_persona) != ''
      AND p.ape_persona IS NOT NULL AND TRIM(p.ape_persona) != ''
    ON CONFLICT (id_usuario, id_menu) DO NOTHING;

    -- 4. Contar instructores elegibles que no tienen usuario
    SELECT COUNT(p.id_persona)
    INTO v_errores
    FROM tab_personas p
    LEFT JOIN tab_usuarios u ON u.id_usuario = p.id_persona::VARCHAR
    WHERE p.id_tipo_persona = 3
      AND p.nom_persona IS NOT NULL AND TRIM(p.nom_persona) != ''
      AND p.ape_persona IS NOT NULL AND TRIM(p.ape_persona) != ''
      AND u.id_usuario IS NULL;

    -- 5. Retornar resultados
    RETURN QUERY SELECT v_insertados, v_actualizados, v_errores;
END;
$$;


--
-- Name: fun_delete_menu_usuarios_por_menu(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_delete_menu_usuarios_por_menu(wid_menu character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_exists INTEGER;
    v_deleted INTEGER;
BEGIN
    -- Validar que el menú exista (ref. integridad referencial)
    SELECT COUNT(*) INTO v_exists FROM tab_menus WHERE id_menu = wid_menu;
    IF v_exists = 0 THEN
        RAISE EXCEPTION 'El menú % no existe en tab_menus', wid_menu;
    END IF;

    -- Eliminar los accesos de usuarios asociados al menú
    DELETE FROM tab_menu_usuarios
    WHERE id_menu = wid_menu;

    GET DIAGNOSTICS v_deleted = ROW_COUNT;
    -- Opcional: RAISE NOTICE 'Se eliminaron % registros de tab_menu_usuarios para el menú %', v_deleted, wid_menu;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error eliminando accesos para menú %: %', wid_menu, SQLERRM;
END;
$$;


--
-- Name: fun_delete_perfil_usuario(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_delete_perfil_usuario(wid_usuario character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM tab_menu_usuarios WHERE id_usuario = wid_usuario;
END;
$$;


--
-- Name: fun_delete_perfil_usuarios(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_delete_perfil_usuarios(p_id_usuario character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_count INTEGER;
BEGIN
    -- Validar que el usuario existe
    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_id_usuario) THEN
        RAISE EXCEPTION 'El usuario % no existe en tab_usuarios', p_id_usuario;
    END IF;

    -- Eliminar todos los menús del usuario
    DELETE FROM tab_menu_usuarios 
    WHERE id_usuario = p_id_usuario;

    -- Obtener el número de registros eliminados
    GET DIAGNOSTICS v_count = ROW_COUNT;

    -- Registrar la acción en auditoría si es necesario
    -- RAISE NOTICE 'Se eliminaron % registros de menú para el usuario %', v_count, p_id_usuario;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error al eliminar perfil del usuario %: %', p_id_usuario, SQLERRM;
END;
$$;


--
-- Name: fun_delete_tab_entradas_centro(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_delete_tab_entradas_centro(wid_entrada_centro numeric) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_entrada_centro IS NULL OR wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
        PERFORM smartcset_raise_validacion(
            'El código de entrada no es válido.',
            'id_entrada_centro=' || COALESCE(wid_entrada_centro::TEXT, 'NULL')
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
    ) THEN
        PERFORM smartcset_raise_no_encontrado(
            'La entrada no existe.',
            'id_entrada_centro=' || wid_entrada_centro::TEXT
        );
    END IF;

    DELETE FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN foreign_key_violation THEN
        PERFORM smartcset_raise_negocio(
            'No se puede eliminar: la entrada está en uso en registros de ingreso.',
            NULL,
            'Cierre o reasigne los ingresos asociados antes de eliminar la puerta.'
        );
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_delete_tab_menus(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_delete_tab_menus(p_id_menu character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_tiene_hijos INTEGER;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = p_id_menu) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El menú no existe.',
            'id_menu=' || p_id_menu
        );
    END IF;

    SELECT COUNT(*) INTO v_tiene_hijos FROM tab_menus WHERE ind_id_padre = p_id_menu;
    IF v_tiene_hijos > 0 THEN
        PERFORM smartcset_raise_negocio(
            format(
                'El menú %s tiene %s submenú(s). Elimine primero los hijos.',
                p_id_menu, v_tiene_hijos
            ),
            NULL,
            'Borre o reasigne los submenús antes de eliminar este ítem.'
        );
    END IF;

    -- Eliminar primero asignaciones a usuarios (evita dependencia de funciones auxiliares).
    DELETE FROM tab_menu_usuarios WHERE id_menu = p_id_menu;
    DELETE FROM tab_menus WHERE id_menu = p_id_menu;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN foreign_key_violation THEN
        PERFORM smartcset_raise_negocio(
            'No se puede eliminar el menú porque está en uso.',
            NULL,
            'Revise accesos de usuarios y submenús.'
        );
    WHEN OTHERS THEN
        PERFORM smartcset_raise_negocio(
            'No se pudo completar la eliminación del menú.',
            SQLERRM,
            'Verifique que no existan referencias activas al menú e intente de nuevo.'
        );
END;
$$;


--
-- Name: fun_descifrar_documento(bytea); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_descifrar_documento(wenc bytea) RETURNS text
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
    vclave       TEXT;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
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
$$;


--
-- Name: fun_ingreso_sesion(character varying, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_ingreso_sesion(p_user character varying, p_ip_cliente character varying DEFAULT NULL::character varying, p_timeout_seg integer DEFAULT 1800) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_id_sesion  tab_sesiones.id_sesion%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF p_user IS NULL OR TRIM(p_user) = '' THEN
        PERFORM smartcset_raise_validacion('El usuario de sesión es obligatorio.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_user) THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se puede registrar sesión: usuario inexistente.',
            'id_usuario=' || p_user
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_user AND ind_estado = TRUE) THEN
        PERFORM smartcset_raise_negocio(
            'El usuario se encuentra inhabilitado.',
            'id_usuario=' || p_user
        );
    END IF;

    -- Administradores: al reingresar, cierra cualquier sesión abierta previa (sin bloqueo).
    IF EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_user AND ind_usuario = TRUE) THEN
        UPDATE tab_sesiones
        SET fec_fin = CURRENT_TIMESTAMP,
            cod_cierre = 'LOGOUT',
            usr_cierre = p_user
        WHERE id_usuario = p_user
          AND fec_fin IS NULL;
    END IF;

    -- Usuarios normales: bloqueo si aún tienen sesión activa (hasta cierre manual del admin).
    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_user AND ind_usuario = TRUE)
       AND EXISTS (
        SELECT 1 FROM tab_sesiones
        WHERE id_usuario = p_user AND fec_fin IS NULL
    ) THEN
        PERFORM smartcset_raise_negocio(
            'Ya tiene una sesión activa en el sistema. Cierre sesión en el otro equipo o contacte al administrador.'
        );
    END IF;

    INSERT INTO tab_sesiones (id_usuario, ip_cliente, ult_ruta)
    VALUES (
        p_user,
        NULLIF(TRIM(p_ip_cliente), ''),
        'index.php'
    )
    RETURNING id_sesion INTO w_id_sesion;

    RETURN w_id_sesion::TEXT;
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
$$;


--
-- Name: fun_insert_log_ingreso(numeric, numeric, numeric, jsonb, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_insert_log_ingreso(wid_visitante numeric, wid_metodo_aut numeric, wid_entrada_centro numeric, wval_datos_origen jsonb, wval_observaciones text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    wid_ingreso    INTEGER;
    wts_ingreso    TIMESTAMP WITHOUT TIME ZONE;
    wid_existente  INTEGER;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_visitante) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El visitante no está registrado.',
            'id_persona=' || wid_visitante::TEXT
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_metodos_aut WHERE id_metodo_aut = wid_metodo_aut) THEN
        PERFORM smartcset_raise_validacion(
            'El método de autenticación no es válido.',
            'id_metodo_aut=' || wid_metodo_aut::TEXT
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de ingreso no existe en el catálogo.',
            'id_entrada_centro=' || wid_entrada_centro::TEXT
        );
    END IF;

    wid_existente := fun_buscar_ingreso_abierto(wid_visitante);

    IF wid_existente IS NOT NULL THEN
        PERFORM smartcset_raise_negocio(
            format(
                'Esta persona ya tiene un ingreso activo (ingreso #%s). Registre la salida antes de un nuevo ingreso.',
                wid_existente
            ),
            'id_visitante=' || wid_visitante::TEXT,
            'Use el módulo Registro salida.'
        );
    END IF;

    wts_ingreso := CURRENT_TIMESTAMP;
    wid_ingreso := nextval('seq_log_ingresos');

    INSERT INTO tab_log_ingresos (
        id_ingreso, id_visitante, fec_ingreso, fec_salida,
        id_metodo_aut, id_entrada_centro, val_datos_origen, val_observaciones
    ) VALUES (
        wid_ingreso, wid_visitante, wts_ingreso, wts_ingreso,
        wid_metodo_aut, wid_entrada_centro, wval_datos_origen, wval_observaciones
    );

    RETURN wid_ingreso;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio(
            'Esta persona ya tiene un ingreso activo. Registre la salida antes de un nuevo ingreso.',
            NULL,
            'Use el módulo Registro salida.'
        );
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_insert_menu_usuarios(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_insert_menu_usuarios(p_id_usuario character varying, p_id_menu character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = p_id_usuario) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El usuario no existe.',
            'id_usuario=' || p_id_usuario
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = p_id_menu) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El menú no existe.',
            'id_menu=' || p_id_menu
        );
    END IF;

    INSERT INTO tab_menu_usuarios (id_usuario, id_menu)
    VALUES (p_id_usuario, p_id_menu)
    ON CONFLICT (id_usuario, id_menu) DO NOTHING;
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
$$;


--
-- Name: fun_insert_tab_menus(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_insert_tab_menus(wid_menu character varying, wnom_menu character varying, wid_padre character varying, wnom_programa character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nom_len    INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_menu IS NULL OR TRIM(wid_menu) = '' THEN
        PERFORM smartcset_raise_validacion('El ID del menú es obligatorio.');
    END IF;

    IF EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = wid_menu) THEN
        PERFORM smartcset_raise_negocio(
            format('El menú %s ya existe.', wid_menu),
            NULL,
            'Use otro código o edite el menú existente.'
        );
    END IF;

    v_nom_len := LENGTH(TRIM(wnom_menu));
    IF v_nom_len < 3 OR v_nom_len > 25 THEN
        PERFORM smartcset_raise_validacion(
            format('El nombre del menú debe tener entre 3 y 25 caracteres (actual: %s).', v_nom_len)
        );
    END IF;

    IF wid_padre IS NULL THEN
        PERFORM smartcset_raise_validacion('El menú padre es obligatorio (use 00 para raíz).');
    END IF;

    IF wid_padre NOT IN ('00', '0') AND NOT EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = wid_padre) THEN
        PERFORM smartcset_raise_validacion(
            format('El menú padre %s no existe.', wid_padre),
            NULL,
            'Cree primero el menú padre o use 00 como raíz.'
        );
    END IF;

    INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa)
    VALUES (
        wid_menu,
        TRIM(wnom_menu),
        wid_padre,
        COALESCE(NULLIF(TRIM(wnom_programa), ''), 'no_aplica')
    );

    RETURN 'OK';
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
$$;


--
-- Name: fun_insert_tab_usuarios(character varying, character varying, character varying, public.mail_personal, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_insert_tab_usuarios(wid_usuario character varying, wnom_usuario character varying, wpass_usuario character varying, wmail_usuario public.mail_personal, wind_usuario boolean, wind_estado boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_usuario IS NULL OR LENGTH(TRIM(wid_usuario)) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El ID de usuario debe tener al menos 5 caracteres.',
            'id_usuario=' || COALESCE(wid_usuario, 'NULL')
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_usuarios WHERE id_usuario = wid_usuario) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe un usuario con ese identificador.',
            'id_usuario=' || wid_usuario
        );
    END IF;

    INSERT INTO tab_usuarios (
        id_usuario, nom_usuario, pass_usuario, mail_usuario, ind_usuario, ind_estado
    ) VALUES (
        wid_usuario, wnom_usuario, wpass_usuario, wmail_usuario, wind_usuario, wind_estado
    );

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('El usuario ya está registrado.');
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_migrar_fichas_creadas(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_migrar_fichas_creadas() RETURNS TABLE(insertados integer, actualizados integer, errores integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_rec RECORD;
    v_id_persona tab_personas.id_persona%TYPE;
    v_nom_persona tab_personas.nom_persona%TYPE;
    v_ape_persona tab_personas.ape_persona%TYPE;
    v_insertados  INTEGER := 0;
    v_actualizados INTEGER := 0;
    v_errores     INTEGER := 0;
    v_rowcount    INTEGER;
BEGIN
    FOR v_rec IN
        SELECT DISTINCT
            num_documento,
            nombre_instructor,
            apellido_instructor
        FROM tab_temp_fichas_creadas
        WHERE num_documento IS NOT NULL
          AND num_documento > 0
          AND TRIM(nombre_instructor) != ''
          AND TRIM(apellido_instructor) != ''
    LOOP
        v_id_persona := v_rec.num_documento;
        v_nom_persona := INITCAP(TRIM(v_rec.nombre_instructor));
        v_ape_persona := INITCAP(TRIM(v_rec.apellido_instructor));

        -- 1. Manejo de tab_personas (UPDATE o INSERT)
        BEGIN
            -- Intentar actualizar primero
            UPDATE tab_personas
            SET nom_persona = v_nom_persona,
                ape_persona = v_ape_persona,
                usr_update = 'carga_automatica',
                fec_update = CURRENT_TIMESTAMP
            WHERE id_persona = v_id_persona;
            
            GET DIAGNOSTICS v_rowcount = ROW_COUNT;
            
            IF v_rowcount = 0 THEN
                -- No existe, insertar
                INSERT INTO tab_personas (
                    id_persona,
                    id_tipo_docum,
                    id_tipo_persona,
                    nom_persona,
                    ape_persona,
                    usr_insert,
                    fec_insert
                ) VALUES (
                    v_id_persona,
                    DEFAULT,
                    3,
                    v_nom_persona,
                    v_ape_persona,
                    'carga_automatica',
                    CURRENT_TIMESTAMP
                );
                v_insertados := v_insertados + 1;
            ELSE
                v_actualizados := v_actualizados + 1;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                v_errores := v_errores + 1;
                RAISE NOTICE 'Error en persona ID %: %', v_id_persona, SQLERRM;
                CONTINUE;
        END;

        -- 2. Manejo de tab_instructores (INSERT si no existe, UPDATE solo timestamps)
        BEGIN
            INSERT INTO tab_instructores (
                id_instructor,
                usr_insert,
                fec_insert
            ) VALUES (
                v_id_persona,
                'carga_automatica',
                CURRENT_TIMESTAMP
            )
            ON CONFLICT (id_instructor) DO UPDATE
            SET usr_update = EXCLUDED.usr_insert,
                fec_update = EXCLUDED.fec_insert;
            -- No se incrementan contadores aquí (ya se contabilizó la persona)
        EXCEPTION
            WHEN OTHERS THEN
                v_errores := v_errores + 1;
                RAISE NOTICE 'Error en instructor ID %: %', v_id_persona, SQLERRM;
        END;
    END LOOP;

    RETURN QUERY SELECT v_insertados, v_actualizados, v_errores;
END;
$$;


--
-- Name: fun_procesar_aprendices(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_procesar_aprendices() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    rec RECORD;
    v_id_persona DECIMAL(10,0);
    v_nom_persona VARCHAR(40);
    v_ape_persona VARCHAR(30);
    v_mail_persona VARCHAR;
    v_tel_movil DECIMAL(10,0);
    v_id_ficha_actual DECIMAL(10,0);
    v_estado_aprendiz VARCHAR;
    v_estado_num DECIMAL(1,0);
    v_usr_insert VARCHAR(50) := 'SISTEMA';
    v_fec_insert TIMESTAMP := CURRENT_TIMESTAMP;
    v_total INT := 0;
    v_errores INT := 0;
BEGIN
    -- Recorrer cada persona distinta (identificada por tipo y número de documento)
    FOR rec IN (
        SELECT DISTINCT ON (id_tipodoc, num_documento)
            id_tipodoc,
            num_documento,
            nom_aprendiz,
            ape_aprendiz,
            val_correo,
            nom_movil,
            ind_estado_aprendiz,
            -- Obtener la ficha actual: prioridad estado '3', luego la más reciente
            (SELECT id_ficha
             FROM tab_temp_aprendices t2
             WHERE t2.id_tipodoc = t1.id_tipodoc AND t2.num_documento = t1.num_documento
             ORDER BY CASE WHEN t2.ind_estado_ficha = '3' THEN 0 ELSE 1 END, t2.fecha_reporte DESC
             LIMIT 1) AS id_ficha_actual
        FROM tab_temp_aprendices t1
        ORDER BY id_tipodoc, num_documento, fecha_reporte DESC
    ) LOOP
        v_total := v_total + 1;
        BEGIN
            -- Asignar variables
            v_id_persona := rec.num_documento::DECIMAL(10,0);
            v_nom_persona := rec.nom_aprendiz;
            v_ape_persona := rec.ape_aprendiz;
            v_mail_persona := rec.val_correo;
            v_estado_aprendiz := rec.ind_estado_aprendiz;
            v_id_ficha_actual := rec.id_ficha_actual;

            IF v_id_ficha_actual IS NULL THEN
                RAISE EXCEPTION 'No se encontró ficha para persona %', v_id_persona;
            END IF;

            -- Procesar teléfono móvil
            BEGIN
                v_tel_movil := COALESCE(rec.nom_movil::DECIMAL(10,0), 3000000000);
                IF v_tel_movil NOT BETWEEN 3000000000 AND 3519999999 THEN
                    v_tel_movil := 3000000000;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                v_tel_movil := 3000000000;
            END;

            -- Convertir estado del aprendiz (usando unaccent para normalizar tildes)
            v_estado_num := CASE
                WHEN unaccent(lower(v_estado_aprendiz)) = 'en formacion' THEN 1
                WHEN unaccent(lower(v_estado_aprendiz)) = 'aplazado' THEN 2
                WHEN unaccent(lower(v_estado_aprendiz)) = 'retiro voluntario' THEN 3
                WHEN unaccent(lower(v_estado_aprendiz)) = 'cancelado' THEN 4
                WHEN unaccent(lower(v_estado_aprendiz)) = 'condicionado' THEN 5
                WHEN unaccent(lower(v_estado_aprendiz)) = 'suspendido' THEN 6
                WHEN unaccent(lower(v_estado_aprendiz)) = 'desertado' THEN 7
                ELSE 8
            END;

            -- 1. Insertar o actualizar tab_personas usando ON CONFLICT
            INSERT INTO tab_personas (
                id_persona, id_tipo_docum, id_tipo_persona, nom_persona, ape_persona,
                mail_persona, fec_nacimiento, ind_genero,
                val_huella_digital, val_patron_facial,
                fec_ultima_entrada, fec_ultima_salida, num_visitas,
                id_nivel_estudio, id_profesion,
                id_dpto_reside, id_ciudad_reside, dir_ciudad_reside,
                tel_persona_fijo, tel_persona_movil,
                nom_contacto_emergencias, tel_contacto_emergencias,
                ind_envio_correo, ind_estado,
                usr_insert, fec_insert, usr_update, fec_update
            ) VALUES (
                v_id_persona,
                rec.id_tipodoc,
                2,
                v_nom_persona,
                v_ape_persona,
                COALESCE(v_mail_persona, 'sin_correo@correo.com'),
                '1900-01-01'::DATE,
                99,
                NULL,
                NULL,
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP,
                0,
                99,
                '00',
                '68',
                '68001',
                'Sin Dirección',
                6010000000,
                v_tel_movil,
                'Sin Contacto',
                3000000000,
                FALSE,
                TRUE,
                v_usr_insert,
                v_fec_insert,
                NULL::VARCHAR,
                NULL::TIMESTAMP
            )
            ON CONFLICT (id_persona) DO UPDATE SET
                nom_persona = EXCLUDED.nom_persona,
                ape_persona = EXCLUDED.ape_persona,
                mail_persona = EXCLUDED.mail_persona,
                tel_persona_movil = EXCLUDED.tel_persona_movil,
                usr_update = v_usr_insert,
                fec_update = v_fec_insert;

            -- 2. Insertar o actualizar tab_aprendices usando ON CONFLICT
            INSERT INTO tab_aprendices (
                id_aprendiz, datos_aprendiz, id_ficha, num_llamados,
                ind_etdo_formacion,
                usr_insert, fec_insert, usr_update, fec_update
            ) VALUES (
                v_id_persona,
                NULL,
                v_id_ficha_actual,
                0,
                v_estado_num,
                v_usr_insert,
                v_fec_insert,
                NULL::VARCHAR,
                NULL::TIMESTAMP
            )
            ON CONFLICT (id_aprendiz) DO UPDATE SET
                id_ficha = EXCLUDED.id_ficha,
                ind_etdo_formacion = EXCLUDED.ind_etdo_formacion,
                usr_update = v_usr_insert,
                fec_update = v_fec_insert;

            -- 3. Insertar histórico de todas las fichas distintas (sin duplicados)
            INSERT INTO tab_aprendices_fichas (id_ficha, id_aprendiz, id_jornada, usr_insert, fec_insert)
            SELECT DISTINCT
                t.id_ficha,
                v_id_persona,
                f.id_jornada,
                v_usr_insert,
                v_fec_insert
            FROM tab_temp_aprendices t
            JOIN tab_fichas f ON t.id_ficha = f.id_ficha
            WHERE t.id_tipodoc = rec.id_tipodoc AND t.num_documento = rec.num_documento
            ON CONFLICT (id_ficha, id_aprendiz) DO NOTHING;

        EXCEPTION WHEN OTHERS THEN
            v_errores := v_errores + 1;
            RAISE WARNING 'Error en persona %: % (SQLSTATE %)', v_id_persona, SQLERRM, SQLSTATE;
        END;
    END LOOP;

    -- Retorno similar a fun_procesar_pe04
    RETURN format('Procesados total: %s | Errores: %s', v_total, v_errores);
END;
$$;


--
-- Name: fun_procesar_df49(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_procesar_df49() RETURNS TABLE(insertados bigint, actualizados bigint, codigo_error bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_id_ficha           tab_temp_df49.id_ficha%TYPE;
    v_id_programa        tab_temp_df49.id_programa%TYPE;
    v_nom_programa       tab_temp_df49.nom_programa%TYPE;
    v_id_version         tab_temp_df49.id_version%TYPE;
    v_ind_estado         tab_temp_df49.ind_estado%TYPE;
    v_id_prog_especial   tab_temp_df49.id_prog_especial%TYPE;
    v_nom_prog_especial  tab_temp_df49.nom_prog_especial%TYPE;
    v_num_version        tab_programas.num_version%TYPE;
    v_total_insertados   BIGINT := 0;
    v_total_actualizados BIGINT := 0;
    v_total_errores      BIGINT := 0;
    v_filas              BIGINT;
BEGIN
    -- Procesar cada ficha DISTINTA, tomando el estado más reciente
    FOR v_id_ficha, v_id_programa, v_nom_programa, v_id_version, v_ind_estado, v_id_prog_especial, v_nom_prog_especial IN
        SELECT DISTINCT ON (id_ficha) 
            id_ficha,
            id_programa,
            nom_programa,
            id_version,
            ind_estado,
            id_prog_especial,
            nom_prog_especial
        FROM tab_temp_df49
        ORDER BY id_ficha, fecha_reporte DESC
    LOOP
        BEGIN
            -- 1. Calcular versión del programa
            v_num_version := CASE WHEN v_id_version > 99 THEN 1 ELSE v_id_version END;

            -- 2. UPSERT de tab_programas
            INSERT INTO tab_programas (id_programa, nom_programa, num_version)
            VALUES (v_id_programa, v_nom_programa, v_num_version)
            ON CONFLICT (id_programa) DO NOTHING;
            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_insertados := v_total_insertados + v_filas;

            UPDATE tab_programas
            SET nom_programa = v_nom_programa,
                num_version  = v_num_version
            WHERE id_programa = v_id_programa
              AND (nom_programa IS DISTINCT FROM v_nom_programa
                   OR num_version IS DISTINCT FROM v_num_version);
            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_actualizados := v_total_actualizados + v_filas;

            -- 3. UPSERT de tab_prog_especiales (solo si id válido)
            IF v_id_prog_especial IS NOT NULL AND v_id_prog_especial > 0 THEN
                INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
                VALUES (v_id_prog_especial, v_nom_prog_especial)
                ON CONFLICT (id_prog_especial) DO NOTHING;
                GET DIAGNOSTICS v_filas = ROW_COUNT;
                v_total_insertados := v_total_insertados + v_filas;

                UPDATE tab_prog_especiales
                SET nom_prog_especial = v_nom_prog_especial
                WHERE id_prog_especial = v_id_prog_especial
                  AND nom_prog_especial IS DISTINCT FROM v_nom_prog_especial;
                GET DIAGNOSTICS v_filas = ROW_COUNT;
                v_total_actualizados := v_total_actualizados + v_filas;
            END IF;

            -- 4. Actualizar SOLO ind_estado en tab_fichas
            UPDATE tab_fichas
            SET ind_estado = 
                CASE UPPER(TRIM(v_ind_estado))
                    WHEN 'INSCRIPCION' THEN 1
                    WHEN 'MATRICULA'   THEN 2
                    WHEN 'EJECUCION'   THEN 3
                    WHEN 'TERMINADA'   THEN 7
                    WHEN 'CERRADA'     THEN 8
                    ELSE 9
                END
            WHERE id_ficha = v_id_ficha;

            GET DIAGNOSTICS v_filas = ROW_COUNT;
            v_total_actualizados := v_total_actualizados + v_filas;

            IF v_filas = 0 THEN
                v_total_errores := v_total_errores + 1;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                v_total_errores := v_total_errores + 1;
                -- Opcional: registrar el error en un log o con RAISE WARNING
                -- RAISE WARNING 'Error al procesar ficha %: %', v_id_ficha, SQLERRM;
        END;
    END LOOP;

    -- 5. Retornar totales
    RETURN QUERY SELECT v_total_insertados, v_total_actualizados, v_total_errores;
END;
$$;


--
-- Name: fun_procesar_pe04(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_procesar_pe04() RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    r RECORD;
    contador INTEGER := 0;
    v_error_count INTEGER := 0;
BEGIN
    -- Asegurar existencia del registro por defecto para programas especiales (id=0)
    INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
    VALUES (0, 'Sin programa especial')
    ON CONFLICT (id_prog_especial) DO NOTHING;

    -- 1. Carga masiva de tablas maestras (con DISTINCT ON para evitar duplicados en conflicto)

    INSERT INTO tab_niveles_estudio (id_nivel_estudio, nom_nivel_estudio)
    SELECT DISTINCT ON (id_nivel_forma) id_nivel_forma, nom_nivel_forma
    FROM tab_temp_pe04
    WHERE id_nivel_forma IS NOT NULL
    ORDER BY id_nivel_forma, nom_nivel_forma
    ON CONFLICT (id_nivel_estudio) DO UPDATE SET nom_nivel_estudio = EXCLUDED.nom_nivel_estudio;

    INSERT INTO tab_sectores (id_sector, nom_sector)
    SELECT DISTINCT ON (id_sector_prog) id_sector_prog::DECIMAL(4,0), nom_sector_prog
    FROM tab_temp_pe04
    WHERE id_sector_prog IS NOT NULL
    ORDER BY id_sector_prog, nom_sector_prog
    ON CONFLICT (id_sector) DO UPDATE SET nom_sector = EXCLUDED.nom_sector;

    INSERT INTO tab_empresas (id_empresa, id_tipo_docum, nom_empresa)
    SELECT DISTINCT ON (COALESCE(id_empresa, 999))
        COALESCE(id_empresa, 999),
        CASE WHEN id_empresa IS NULL THEN 'SN' ELSE 'NIT' END,
        COALESCE(nom_empresa, 'Sin Empresa')
    FROM tab_temp_pe04
    ORDER BY COALESCE(id_empresa, 999), nom_empresa
    ON CONFLICT (id_empresa) DO UPDATE SET
        id_tipo_docum = EXCLUDED.id_tipo_docum,
        nom_empresa = EXCLUDED.nom_empresa;

    INSERT INTO tab_prog_especiales (id_prog_especial, nom_prog_especial)
    SELECT DISTINCT ON (COALESCE(NULLIF(id_prog_especial, 0), 0))
        COALESCE(NULLIF(id_prog_especial, 0), 0),
        COALESCE(NULLIF(nom_prog_especial, ''), 'Sin programa especial')
    FROM tab_temp_pe04
    ORDER BY COALESCE(NULLIF(id_prog_especial, 0), 0), nom_prog_especial
    ON CONFLICT (id_prog_especial) DO UPDATE SET nom_prog_especial = EXCLUDED.nom_prog_especial;

    INSERT INTO tab_ocupaciones (id_ocupacion, nom_ocupacion)
    SELECT DISTINCT ON (id_ocupacion) id_ocupacion, COALESCE(nom_ocupacion, 'OCUPACION DESCONOCIDA')
    FROM tab_temp_pe04
    WHERE id_ocupacion IS NOT NULL
    ORDER BY id_ocupacion, nom_ocupacion
    ON CONFLICT (id_ocupacion) DO UPDATE SET nom_ocupacion = EXCLUDED.nom_ocupacion;

    INSERT INTO tab_programas (id_programa, nom_programa, num_version)
    SELECT DISTINCT ON (id_programa)
        id_programa,
        nom_programa,
        CASE WHEN id_version IS NULL OR id_version > 99 THEN 1 ELSE id_version END
    FROM tab_temp_pe04
    WHERE id_programa IS NOT NULL
    ORDER BY id_programa, id_version DESC NULLS LAST
    ON CONFLICT (id_programa) DO UPDATE SET
        nom_programa = EXCLUDED.nom_programa,
        num_version = EXCLUDED.num_version;

    -- 2. Bucle optimizado para tab_fichas

    FOR r IN (
        SELECT
            t.*,
            COALESCE(c.id_ciudad, '68001') AS id_ciudad_calc,
            COALESCE(s.id_sector, 0) AS id_nuevo_sector_calc,
            COALESCE(t.fec_inicio_ficha, CURRENT_DATE) AS fec_inicio_calc,
            COALESCE(t.fec_fin_ficha, CURRENT_DATE + INTERVAL '1 year') AS fec_fin_calc,
            LEAST(
                EXTRACT(MONTH FROM age(
                    COALESCE(t.fec_fin_ficha, CURRENT_DATE + INTERVAL '1 year'),
                    COALESCE(t.fec_inicio_ficha, CURRENT_DATE)
                )) + 12 * EXTRACT(YEAR FROM age(
                    COALESCE(t.fec_fin_ficha, CURRENT_DATE + INTERVAL '1 year'),
                    COALESCE(t.fec_inicio_ficha, CURRENT_DATE)
                )),
                99
            )::DECIMAL(2,0) AS diff_months_calc
        FROM tab_temp_pe04 t
        LEFT JOIN tab_ciudades c
            ON unaccent(lower(c.nom_ciudad)) = unaccent(lower(t.nom_municipio))
        LEFT JOIN tab_sectores s
            ON unaccent(lower(s.nom_sector)) = unaccent(lower(TRIM(t.nom_nuevo_sector)))
    ) LOOP
        BEGIN
            INSERT INTO tab_fichas (
                id_ficha, id_centro, id_programa, id_nivel_estudio, id_jornada,
                ind_modalidad, fec_inicio, fec_fin_productiva, val_duracion,
                id_instructor_lider, id_sector, id_empresa, id_ocupacion,
                id_ciudad, cod_convenio, nom_convenio, ind_amp_cobertura,
                id_prog_especial, ind_abierta, nom_vocero, tel_vocero,
                mail_vocero, val_cupo, id_ambiente_base, num_inscritos_opcion1,
                num_inscritos_opcion2, ind_estado, num_cursos,
                tot_aprendices_masc, tot_aprendices_fem, tot_aprendices_nobin,
                tot_aprendices_trans, tot_horas_planta, tot_horas_contratista,
                tot_horas_contrat_ext, tot_horas_monitores, tot_horas_inst_empresa,
                tot_aprendices_activos, val_duracion_programa, id_nuevo_sector
            ) VALUES (
                r.id_ficha,
                COALESCE(r.cod_centro, 0),
                r.id_programa,
                COALESCE(r.id_nivel_forma, 0),
                CASE WHEN COALESCE(r.id_jornada, 1) BETWEEN 1 AND 4 THEN r.id_jornada ELSE 1 END,
                CASE UPPER(TRIM(r.val_modalidad))
                    WHEN 'PRESENCIAL' THEN 1
                    WHEN 'VIRTUAL' THEN 2
                    WHEN 'DISTANCIA' THEN 3
                    ELSE 1
                END,
                r.fec_inicio_calc,
                r.fec_fin_calc,
                r.diff_months_calc,
                77777777,
                COALESCE(r.id_sector_prog, 0)::DECIMAL(4,0),
                COALESCE(r.id_empresa, 999),
                COALESCE(r.id_ocupacion, 0),
                r.id_ciudad_calc,
                COALESCE(r.id_convenio, 0),
                COALESCE(r.nom_convenio, 'Sin Convenio'),
                FALSE,
                COALESCE(NULLIF(r.id_prog_especial, 0), 0),
                FALSE,
                'Sin Vocero',
                '3000000000',
                'sin_correo@correo.com',
                COALESCE(r.num_tot_aprend, 30),
                'Sin Ambiente Base',
                0, 0,
                CASE UPPER(TRIM(r.ind_estado_curso))
                    WHEN 'INSCRIPCION' THEN 1
                    WHEN 'MATRICULA' THEN 2
                    WHEN 'EN EJECUCION' THEN 3
                    WHEN 'TERMINADA' THEN 7
                    WHEN 'CERRADA' THEN 8
                    ELSE 9
                END,
                COALESCE(r.num_cursos, 1),
                GREATEST(COALESCE(r.num_aprend_masc, 0), 0),
                GREATEST(COALESCE(r.num_aprend_fem, 0), 0),
                GREATEST(COALESCE(r.num_aprend_nobin, 0), 0),
                0,
                COALESCE(r.val_hrs_planta, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_contrat, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_context, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_monitor, '00:00:00'::INTERVAL),
                COALESCE(r.val_hrs_instemp, '00:00:00'::INTERVAL),
                GREATEST(COALESCE(r.val_total_apr_act, 0), 0),
                -- *** Nuevo cálculo: meses, días y horas ***
                make_interval(
                    months => (COALESCE(r.val_duracion_prog, 0)::INT / 24) / 30,
                    days => (COALESCE(r.val_duracion_prog, 0)::INT / 24) % 30,
                    hours => COALESCE(r.val_duracion_prog, 0)::INT % 24
                ),
                COALESCE(r.id_nuevo_sector_calc, 0)
            )
            ON CONFLICT (id_ficha) DO UPDATE SET
                id_centro = EXCLUDED.id_centro,
                id_programa = EXCLUDED.id_programa,
                id_nivel_estudio = EXCLUDED.id_nivel_estudio,
                id_jornada = EXCLUDED.id_jornada,
                ind_modalidad = EXCLUDED.ind_modalidad,
                fec_inicio = EXCLUDED.fec_inicio,
                fec_fin_productiva = EXCLUDED.fec_fin_productiva,
                val_duracion = EXCLUDED.val_duracion,
                id_sector = EXCLUDED.id_sector,
                id_empresa = EXCLUDED.id_empresa,
                id_ocupacion = EXCLUDED.id_ocupacion,
                id_ciudad = EXCLUDED.id_ciudad,
                cod_convenio = EXCLUDED.cod_convenio,
                nom_convenio = EXCLUDED.nom_convenio,
                ind_amp_cobertura = EXCLUDED.ind_amp_cobertura,
                id_prog_especial = EXCLUDED.id_prog_especial,
                ind_estado = EXCLUDED.ind_estado,
                num_cursos = EXCLUDED.num_cursos,
                tot_aprendices_masc = EXCLUDED.tot_aprendices_masc,
                tot_aprendices_fem = EXCLUDED.tot_aprendices_fem,
                tot_aprendices_nobin = EXCLUDED.tot_aprendices_nobin,
                tot_aprendices_trans = EXCLUDED.tot_aprendices_trans,
                tot_horas_planta = EXCLUDED.tot_horas_planta,
                tot_horas_contratista = EXCLUDED.tot_horas_contratista,
                tot_horas_contrat_ext = EXCLUDED.tot_horas_contrat_ext,
                tot_horas_monitores = EXCLUDED.tot_horas_monitores,
                tot_horas_inst_empresa = EXCLUDED.tot_horas_inst_empresa,
                tot_aprendices_activos = EXCLUDED.tot_aprendices_activos,
                val_duracion_programa = EXCLUDED.val_duracion_programa,
                id_nuevo_sector = EXCLUDED.id_nuevo_sector;

            contador := contador + 1;

        EXCEPTION
            WHEN OTHERS THEN
                v_error_count := v_error_count + 1;
                RAISE WARNING 'Error en ficha % (SQLSTATE %): %', r.id_ficha, SQLSTATE, SQLERRM;
        END;
    END LOOP;

    RETURN format('Procesados total: %s | Errores: %s', contador, v_error_count);
END;
$$;


--
-- Name: fun_registrar_aprendiz(numeric, character varying, character varying, character varying, public.mail_personal, date, numeric, numeric, character varying, character varying, character varying, character varying, public.telefono_fijo, public.telefono_movil, character varying, public.telefono_movil, boolean, public.telefono_movil, public.telefono_fijo, public.extension, public.telefono_fijo, public.telefono_movil, public.mail_personal, numeric, character varying, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_registrar_aprendiz(wid_persona numeric, wid_tipo_docum character varying, wnom_persona character varying, wape_persona character varying, wmail_persona public.mail_personal, wfec_nacimiento date, wind_genero numeric, wid_nivel_estudio numeric, wid_profesion character varying, wid_dpto_reside character varying, wid_ciudad_reside character varying, wdir_ciudad_reside character varying, wtel_persona_fijo public.telefono_fijo, wtel_persona_movil public.telefono_movil, wnom_contacto_emergencias character varying, wtel_contacto_emergencias public.telefono_movil, wind_envio_correo boolean, wtel_alterno public.telefono_movil, wtel_sede public.telefono_fijo, wext_sede public.extension, wtel_padre_fijo public.telefono_fijo, wtel_padre_movil public.telefono_movil, wval_mail_institucional public.mail_personal, wind_etdo_formacion numeric, wusr character varying, wid_ficha numeric DEFAULT NULL::numeric) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    v_tipo_aprendiz CONSTANT DECIMAL(2,0) := 2;
    v_nom            VARCHAR(40);
    v_ape            VARCHAR(30);
    v_dir            VARCHAR(100);
    v_contacto       VARCHAR(60);
    v_mail_norm      TEXT;
    v_datos          datos_personales_aprendiz;
    w_exc_state      TEXT;
    w_exc_msg        TEXT;
    w_exc_detail     TEXT;
    w_exc_hint       TEXT;
BEGIN
    IF wusr IS NULL OR LENGTH(TRIM(wusr)) < 3 THEN
        PERFORM smartcset_raise_validacion('El usuario de auditoría no es válido.');
    END IF;

    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe una persona registrada con ese número de documento.',
            'id_persona=' || wid_persona::TEXT,
            'Consulte el listado administrativo o use otro documento.'
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_aprendices WHERE id_aprendiz = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe un aprendiz registrado con ese número de documento.',
            'id_aprendiz=' || wid_persona::TEXT
        );
    END IF;

    v_nom := TRIM(wnom_persona);
    v_ape := TRIM(wape_persona);
    IF LENGTH(v_nom) < 3 OR LENGTH(v_ape) < 2 THEN
        PERFORM smartcset_raise_validacion(
            'Nombres (mín. 3 caracteres) y apellidos (mín. 2) son obligatorios.'
        );
    END IF;

    v_mail_norm := LOWER(TRIM(COALESCE(wmail_persona::TEXT, '')));
    IF v_mail_norm = '' OR v_mail_norm !~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' THEN
        PERFORM smartcset_raise_validacion(
            'El correo personal no tiene un formato válido.',
            'Use una dirección como nombre@dominio.com'
        );
    END IF;

    IF wfec_nacimiento IS NULL THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento es obligatoria.');
    END IF;

    IF wfec_nacimiento > CURRENT_DATE OR wfec_nacimiento < DATE '1900-01-01' THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento no es válida.');
    END IF;

    IF wind_genero IS NULL OR wind_genero NOT IN (1, 2, 3, 4) THEN
        PERFORM smartcset_raise_validacion('Seleccione un género válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_niveles_estudio WHERE id_nivel_estudio = wid_nivel_estudio
    ) THEN
        PERFORM smartcset_raise_validacion('El nivel de estudio seleccionado no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_profesiones WHERE id_profesion = wid_profesion
    ) THEN
        PERFORM smartcset_raise_validacion('La profesión u oficio seleccionado no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_dptos WHERE id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion('El departamento de residencia no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM tab_ciudades
         WHERE id_ciudad = wid_ciudad_reside
           AND id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ciudad no corresponde al departamento seleccionado.'
        );
    END IF;

    v_dir := TRIM(wdir_ciudad_reside);
    IF LENGTH(v_dir) < 10 THEN
        PERFORM smartcset_raise_validacion(
            'La dirección de residencia debe tener al menos 10 caracteres.'
        );
    END IF;

    IF wtel_persona_fijo IS NULL
       OR wtel_persona_fijo < 6010000000
       OR wtel_persona_fijo > 6089999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono fijo debe ser un número válido de Bogotá o área metropolitana (601xxxxxxx).'
        );
    END IF;

    IF wtel_persona_movil IS NULL
       OR wtel_persona_movil < 3000000000
       OR wtel_persona_movil > 3519999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono móvil debe ser un celular colombiano válido (300xxxxxxx a 351xxxxxxx).'
        );
    END IF;

    v_contacto := TRIM(wnom_contacto_emergencias);
    IF LENGTH(v_contacto) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El contacto de emergencias debe tener al menos 5 caracteres.'
        );
    END IF;

    IF wtel_contacto_emergencias IS NULL
       OR wtel_contacto_emergencias < 3000000000
       OR wtel_contacto_emergencias > 3519999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono de emergencias debe ser un celular colombiano válido.'
        );
    END IF;

    IF wind_etdo_formacion IS NULL
       OR wind_etdo_formacion NOT IN (1, 2, 3, 4, 5, 6, 7) THEN
        PERFORM smartcset_raise_validacion('Seleccione un estado de formación válido.');
    END IF;

    IF wid_ficha IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione la ficha de formación del aprendiz.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_fichas WHERE id_ficha = wid_ficha
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ficha de formación seleccionada no existe.',
            'id_ficha=' || wid_ficha::TEXT
        );
    END IF;

    v_datos := ROW(
        wtel_alterno,
        wtel_sede,
        wext_sede,
        wtel_padre_fijo,
        wtel_padre_movil,
        wval_mail_institucional,
        v_contacto,
        wtel_contacto_emergencias
    )::datos_personales_aprendiz;

    INSERT INTO tab_personas (
        id_persona, id_tipo_docum, id_tipo_persona,
        nom_persona, ape_persona, mail_persona,
        fec_nacimiento, ind_genero,
        fec_ultima_entrada, fec_ultima_salida,
        id_nivel_estudio, id_profesion,
        id_dpto_reside, id_ciudad_reside, dir_ciudad_reside,
        tel_persona_fijo, tel_persona_movil,
        nom_contacto_emergencias, tel_contacto_emergencias,
        ind_envio_correo, ind_estado,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, wid_tipo_docum, v_tipo_aprendiz,
        v_nom, v_ape, v_mail_norm::mail_personal,
        wfec_nacimiento, wind_genero,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        wid_nivel_estudio, wid_profesion,
        wid_dpto_reside, wid_ciudad_reside, v_dir,
        wtel_persona_fijo, wtel_persona_movil,
        v_contacto, wtel_contacto_emergencias,
        COALESCE(wind_envio_correo, FALSE), TRUE,
        TRIM(wusr), CURRENT_TIMESTAMP
    );

    INSERT INTO tab_aprendices (
        id_aprendiz, datos_aprendiz,
        ind_etdo_formacion, num_llamados,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, v_datos,
        wind_etdo_formacion, 0,
        TRIM(wusr), CURRENT_TIMESTAMP
    );

    INSERT INTO tab_aprendices_fichas (
        id_ficha, id_aprendiz, usr_insert, fec_insert
    ) VALUES (
        wid_ficha, wid_persona, TRIM(wusr), CURRENT_TIMESTAMP
    );

    RETURN wid_persona::TEXT;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('Ya existe un registro con esos datos.');
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$_$;


--
-- Name: fun_registrar_contratista(numeric, character varying, character varying, character varying, public.mail_personal, date, numeric, numeric, character varying, character varying, character varying, character varying, public.telefono_fijo, public.telefono_movil, character varying, public.telefono_movil, boolean, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_registrar_contratista(wid_persona numeric, wid_tipo_docum character varying, wnom_persona character varying, wape_persona character varying, wmail_persona public.mail_personal, wfec_nacimiento date, wind_genero numeric, wid_nivel_estudio numeric, wid_profesion character varying, wid_dpto_reside character varying, wid_ciudad_reside character varying, wdir_ciudad_reside character varying, wtel_persona_fijo public.telefono_fijo, wtel_persona_movil public.telefono_movil, wnom_contacto_emergencias character varying, wtel_contacto_emergencias public.telefono_movil, wind_envio_correo boolean, wusr character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    wtipo_contratista CONSTANT DECIMAL(2,0) := 5;
    w_exc_state       TEXT;
    w_exc_msg         TEXT;
    w_exc_detail      TEXT;
    w_exc_hint        TEXT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona WHERE id_tipo_persona = wtipo_contratista
    ) THEN
        PERFORM smartcset_raise_core(
            'El catálogo de tipos de persona no incluye Contratista (id 5). Ejecute los seeds de desarrollo.'
        );
    END IF;

    RETURN fun_registrar_persona(
        wid_persona,
        wid_tipo_docum,
        wtipo_contratista,
        wnom_persona,
        wape_persona,
        wmail_persona,
        wfec_nacimiento,
        wind_genero,
        wid_nivel_estudio,
        wid_profesion,
        wid_dpto_reside,
        wid_ciudad_reside,
        wdir_ciudad_reside,
        wtel_persona_fijo,
        wtel_persona_movil,
        wnom_contacto_emergencias,
        wtel_contacto_emergencias,
        wind_envio_correo,
        TRUE,
        wusr
    );
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
$$;


--
-- Name: fun_registrar_funcionario(numeric, character varying, character varying, character varying, public.mail_personal, date, numeric, numeric, character varying, character varying, character varying, character varying, public.telefono_fijo, public.telefono_movil, character varying, public.telefono_movil, boolean, numeric, numeric, character varying, date, numeric, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_registrar_funcionario(wid_persona numeric, wid_tipo_docum character varying, wnom_persona character varying, wape_persona character varying, wmail_persona public.mail_personal, wfec_nacimiento date, wind_genero numeric, wid_nivel_estudio numeric, wid_profesion character varying, wid_dpto_reside character varying, wid_ciudad_reside character varying, wdir_ciudad_reside character varying, wtel_persona_fijo public.telefono_fijo, wtel_persona_movil public.telefono_movil, wnom_contacto_emergencias character varying, wtel_contacto_emergencias public.telefono_movil, wind_envio_correo boolean, wid_area numeric, wid_cargo numeric, wval_grado character varying, wfec_ingreso_planta date, wid_centro numeric, wusr character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    wtipo_funcionario CONSTANT DECIMAL(2,0) := 4;
    w_exc_state       TEXT;
    w_exc_msg         TEXT;
    w_exc_detail      TEXT;
    w_exc_hint        TEXT;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona WHERE id_tipo_persona = wtipo_funcionario
    ) THEN
        PERFORM smartcset_raise_core(
            'El catálogo de tipos de persona no incluye Funcionario (id 4). Ejecute los seeds de desarrollo.'
        );
    END IF;

    IF wid_area IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione el área de trabajo.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_areas WHERE id_area = wid_area) THEN
        PERFORM smartcset_raise_validacion('El área seleccionada no está registrada en el sistema.');
    END IF;

    IF wid_centro IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM tab_areas WHERE id_area = wid_area AND id_centro = wid_centro
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El área no pertenece al centro de adscripción seleccionado.'
        );
    END IF;

    IF wid_cargo IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione el cargo.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_cargos WHERE id_cargo = wid_cargo) THEN
        PERFORM smartcset_raise_validacion('El cargo seleccionado no está registrado en el sistema.');
    END IF;

    IF wval_grado IS NULL OR LENGTH(TRIM(wval_grado)) < 1 THEN
        PERFORM smartcset_raise_validacion('Indique el grado del funcionario.');
    END IF;

    IF wfec_ingreso_planta IS NULL THEN
        PERFORM smartcset_raise_validacion('Indique la fecha de ingreso a planta.');
    END IF;

    IF wfec_ingreso_planta > CURRENT_DATE THEN
        PERFORM smartcset_raise_validacion('La fecha de ingreso a planta no puede ser futura.');
    END IF;

    PERFORM fun_registrar_persona(
        wid_persona,
        wid_tipo_docum,
        wtipo_funcionario,
        wnom_persona,
        wape_persona,
        wmail_persona,
        wfec_nacimiento,
        wind_genero,
        wid_nivel_estudio,
        wid_profesion,
        wid_dpto_reside,
        wid_ciudad_reside,
        wdir_ciudad_reside,
        wtel_persona_fijo,
        wtel_persona_movil,
        wnom_contacto_emergencias,
        wtel_contacto_emergencias,
        wind_envio_correo,
        TRUE,
        wusr
    );

    INSERT INTO tab_funcionarios (
        id_funcionario, id_area, id_cargo, val_grado, id_fec_ingreso_planta,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, wid_area, wid_cargo, TRIM(wval_grado), wfec_ingreso_planta,
        TRIM(wusr), CURRENT_TIMESTAMP
    );

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('Ya existe un funcionario registrado con ese documento.');
    WHEN foreign_key_violation THEN
        PERFORM smartcset_raise_validacion(
            'Revise los catálogos seleccionados (área o cargo).'
        );
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_registrar_ingreso_manual(numeric, character varying, numeric, character varying, character varying, numeric, text, numeric, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_registrar_ingreso_manual(wid_persona numeric, wid_tipo_docum character varying, wid_tipo_persona numeric, wnom_persona character varying, wape_persona character varying, wid_entrada_centro numeric, wval_observaciones text, wid_metodo_aut numeric DEFAULT 1, wcaptura_pdf417 boolean DEFAULT false) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    wid_ingreso    INTEGER;
    wjson_origen   JSONB;
    worigen_txt    TEXT;
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF wid_metodo_aut IS NULL OR wid_metodo_aut < 1 THEN
        wid_metodo_aut := 1;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_metodos_aut WHERE id_metodo_aut = wid_metodo_aut) THEN
        PERFORM smartcset_raise_validacion(
            'El método de autenticación no es válido.',
            'id_metodo_aut=' || wid_metodo_aut::TEXT
        );
    END IF;

    worigen_txt := CASE
        WHEN wid_metodo_aut = 3 THEN 'codigo_barras'
        WHEN wid_metodo_aut = 2 THEN 'codigo_qr'
        ELSE 'registro_manual'
    END;

    IF wid_entrada_centro IS NULL OR wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
        PERFORM smartcset_raise_validacion(
            'La puerta de ingreso debe estar entre 1 y 9.',
            'id_entrada_centro=' || COALESCE(wid_entrada_centro::TEXT, 'NULL')
        );
    END IF;

    PERFORM fun_upsert_persona_visitante(
        wid_persona, wid_tipo_docum, wid_tipo_persona, wnom_persona, wape_persona
    );

    wjson_origen := jsonb_build_object(
        'origen', worigen_txt,
        'documento', wid_persona::TEXT,
        'tipo_doc', wid_tipo_docum,
        'tipo_persona', wid_tipo_persona
    );

    IF COALESCE(wcaptura_pdf417, FALSE) THEN
        wjson_origen := wjson_origen || jsonb_build_object('captura_pdf417', TRUE);
    END IF;

    wid_ingreso := fun_insert_log_ingreso(
        wid_persona,
        wid_metodo_aut,
        wid_entrada_centro,
        wjson_origen,
        NULLIF(TRIM(wval_observaciones), '')
    );

    PERFORM fun_update_persona_tras_ingreso(wid_persona);

    IF wid_tipo_persona = 2 THEN
        PERFORM fun_verify_retardo_aprendiz(wid_persona, CURRENT_TIMESTAMP);
    END IF;

    RETURN wid_ingreso;
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
$$;


--
-- Name: fun_registrar_instructor(numeric, character varying, character varying, character varying, public.mail_personal, date, numeric, numeric, numeric, character varying, character varying, character varying, character varying, public.telefono_fijo, public.telefono_movil, character varying, public.telefono_movil, boolean, numeric, numeric, boolean, boolean, boolean, numeric, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_registrar_instructor(wid_persona numeric, wid_tipo_docum character varying, wnom_persona character varying, wape_persona character varying, wmail_persona public.mail_personal, wfec_nacimiento date, wind_genero numeric, wind_est_civil numeric, wid_nivel_estudio numeric, wid_profesion character varying, wid_dpto_reside character varying, wid_ciudad_reside character varying, wdir_ciudad_reside character varying, wtel_persona_fijo public.telefono_fijo, wtel_persona_movil public.telefono_movil, wnom_contacto_emergencias character varying, wtel_contacto_emergencias public.telefono_movil, wind_envio_correo boolean, wid_centro numeric, wid_red numeric, wind_tipo_contrato boolean, wind_contratado_actual boolean, wind_disponibilidad boolean, wind_estado numeric, wusr character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    wid_tipo_instructor CONSTANT DECIMAL(2,0) := 3;
    w_exc_state         TEXT;
    w_exc_msg           TEXT;
    w_exc_detail        TEXT;
    w_exc_hint          TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona <= 20000000 THEN
        PERFORM smartcset_raise_validacion(
            'El documento del instructor debe ser mayor a 20.000.000.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    IF LENGTH(TRIM(wnom_persona)) < 3 OR LENGTH(TRIM(wape_persona)) < 2 THEN
        PERFORM smartcset_raise_validacion(
            'Nombres (mín. 3 caracteres) y apellidos (mín. 2) son obligatorios.'
        );
    END IF;

    IF wmail_persona IS NULL OR TRIM(wmail_persona::TEXT) = '' THEN
        PERFORM smartcset_raise_validacion('El correo electrónico es obligatorio.');
    END IF;

    IF wfec_nacimiento IS NULL THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento es obligatoria.');
    END IF;

    IF wind_genero IS NULL OR wind_genero NOT IN (1, 2, 4) THEN
        PERFORM smartcset_raise_validacion(
            'Seleccione un género válido (Femenino, Masculino o Trans).',
            'ind_genero=' || COALESCE(wind_genero::TEXT, 'NULL')
        );
    END IF;

    IF wind_est_civil IS NULL OR wind_est_civil < 0 OR wind_est_civil > 9 THEN
        PERFORM smartcset_raise_validacion('Seleccione un estado civil válido.');
    END IF;

    IF wid_nivel_estudio IS NULL OR NOT EXISTS (
        SELECT 1 FROM tab_niveles_estudio WHERE id_nivel_estudio = wid_nivel_estudio
    ) THEN
        PERFORM smartcset_raise_validacion('El nivel de estudio seleccionado no es válido.');
    END IF;

    IF wid_profesion IS NULL OR TRIM(wid_profesion) = '' OR NOT EXISTS (
        SELECT 1 FROM tab_profesiones WHERE id_profesion = wid_profesion
    ) THEN
        PERFORM smartcset_raise_validacion('La profesión seleccionada no es válida.');
    END IF;

    IF wid_dpto_reside IS NULL OR TRIM(wid_dpto_reside) = '' OR NOT EXISTS (
        SELECT 1 FROM tab_dptos WHERE id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion('El departamento de residencia no es válido.');
    END IF;

    IF wid_ciudad_reside IS NULL OR TRIM(wid_ciudad_reside) = '' OR NOT EXISTS (
        SELECT 1 FROM tab_ciudades
        WHERE id_ciudad = wid_ciudad_reside AND id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ciudad no corresponde al departamento seleccionado.',
            'id_ciudad=' || COALESCE(wid_ciudad_reside, 'NULL'),
            'id_dpto=' || COALESCE(wid_dpto_reside, 'NULL')
        );
    END IF;

    IF wdir_ciudad_reside IS NULL OR LENGTH(TRIM(wdir_ciudad_reside)) < 10 THEN
        PERFORM smartcset_raise_validacion(
            'La dirección debe tener al menos 10 caracteres.'
        );
    END IF;

    IF wtel_persona_fijo IS NULL OR wtel_persona_movil IS NULL
       OR wtel_contacto_emergencias IS NULL THEN
        PERFORM smartcset_raise_validacion('Los teléfonos son obligatorios y deben ser válidos.');
    END IF;

    IF wnom_contacto_emergencias IS NULL OR LENGTH(TRIM(wnom_contacto_emergencias)) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El contacto de emergencias debe tener al menos 5 caracteres.'
        );
    END IF;

    IF wid_centro IS NULL OR NOT EXISTS (
        SELECT 1 FROM tab_centros WHERE id_centro = wid_centro
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El centro de formación seleccionado no existe.',
            'id_centro=' || COALESCE(wid_centro::TEXT, 'NULL')
        );
    END IF;

    IF wid_red IS NULL OR NOT EXISTS (
        SELECT 1 FROM tab_redes WHERE id_red = wid_red
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La red de conocimiento seleccionada no existe.',
            'id_red=' || COALESCE(wid_red::TEXT, 'NULL')
        );
    END IF;

    IF wind_estado IS NULL OR wind_estado < 0 OR wind_estado > 9 THEN
        PERFORM smartcset_raise_validacion('El estado del instructor no es válido.');
    END IF;

    IF wusr IS NULL OR LENGTH(TRIM(wusr)) < 3 THEN
        PERFORM smartcset_raise_validacion('Usuario de auditoría no válido.');
    END IF;

    IF EXISTS (SELECT 1 FROM tab_instructores WHERE id_instructor = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe un instructor registrado con ese número de documento.',
            'id_instructor=' || wid_persona::TEXT
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe una persona registrada con ese documento.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    INSERT INTO tab_personas (
        id_persona, id_tipo_docum, id_tipo_persona,
        nom_persona, ape_persona, mail_persona,
        fec_nacimiento, ind_genero,
        fec_ultima_entrada, fec_ultima_salida,
        id_nivel_estudio, id_profesion,
        id_dpto_reside, id_ciudad_reside, dir_ciudad_reside,
        tel_persona_fijo, tel_persona_movil,
        nom_contacto_emergencias, tel_contacto_emergencias,
        ind_envio_correo, ind_estado,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, wid_tipo_docum, wid_tipo_instructor,
        TRIM(wnom_persona), TRIM(wape_persona), TRIM(wmail_persona::TEXT)::mail_personal,
        wfec_nacimiento, wind_genero,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        wid_nivel_estudio, wid_profesion,
        wid_dpto_reside, wid_ciudad_reside, TRIM(wdir_ciudad_reside),
        wtel_persona_fijo, wtel_persona_movil,
        TRIM(wnom_contacto_emergencias), wtel_contacto_emergencias,
        COALESCE(wind_envio_correo, TRUE), TRUE,
        wusr, CURRENT_TIMESTAMP
    );

    INSERT INTO tab_instructores (
        id_instructor, id_centro,
        ind_tipo_contrato, ind_contratado_actual,
        ind_genero, ind_est_civil,
        id_nivel_estudio, id_profesion, id_red,
        ind_disponibilidad, ind_estado,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, wid_centro,
        COALESCE(wind_tipo_contrato, TRUE), COALESCE(wind_contratado_actual, TRUE),
        wind_genero, wind_est_civil,
        wid_nivel_estudio, wid_profesion, wid_red,
        COALESCE(wind_disponibilidad, TRUE), wind_estado,
        wusr, CURRENT_TIMESTAMP
    );

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('Ya existe un registro con esos datos.');
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_registrar_intento_login(character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_registrar_intento_login(wip_cliente character varying, wid_usuario character varying, wind_exitoso boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wip_cliente IS NULL OR LENGTH(TRIM(wip_cliente)) < 7 THEN
        PERFORM smartcset_raise_validacion(
            'IP de cliente inválida.',
            'ip_cliente=' || COALESCE(wip_cliente, 'NULL')
        );
    END IF;

    INSERT INTO tab_intentos_login (ip_cliente, id_usuario, ind_exitoso)
    VALUES (wip_cliente, wid_usuario, wind_exitoso);

    -- Limpiar registros de más de 90 días para no crecer indefinidamente
    DELETE FROM tab_intentos_login
    WHERE fec_intento < CURRENT_TIMESTAMP - INTERVAL '90 days';

    RETURN 'OK';
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
$$;


--
-- Name: fun_registrar_persona(numeric, character varying, numeric, character varying, character varying, public.mail_personal, date, numeric, numeric, character varying, character varying, character varying, character varying, public.telefono_fijo, public.telefono_movil, character varying, public.telefono_movil, boolean, boolean, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_registrar_persona(wid_persona numeric, wid_tipo_docum character varying, wid_tipo_persona numeric, wnom_persona character varying, wape_persona character varying, wmail_persona public.mail_personal, wfec_nacimiento date, wind_genero numeric, wid_nivel_estudio numeric, wid_profesion character varying, wid_dpto_reside character varying, wid_ciudad_reside character varying, wdir_ciudad_reside character varying, wtel_persona_fijo public.telefono_fijo, wtel_persona_movil public.telefono_movil, wnom_contacto_emergencias character varying, wtel_contacto_emergencias public.telefono_movil, wind_envio_correo boolean, wind_estado boolean, wusr character varying) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    wmail_norm   TEXT;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    IF wid_tipo_persona IS NULL OR wid_tipo_persona < 1 THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de persona.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona
        WHERE id_tipo_persona = wid_tipo_persona AND id_tipo_persona <> 99
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de persona no es válido.',
            'id_tipo_persona=' || COALESCE(wid_tipo_persona::TEXT, 'NULL')
        );
    END IF;

    IF LENGTH(TRIM(COALESCE(wnom_persona, ''))) < 3 THEN
        PERFORM smartcset_raise_validacion('Los nombres deben tener al menos 3 caracteres.');
    END IF;

    IF LENGTH(TRIM(COALESCE(wape_persona, ''))) < 2 THEN
        PERFORM smartcset_raise_validacion('Los apellidos deben tener al menos 2 caracteres.');
    END IF;

    wmail_norm := LOWER(TRIM(COALESCE(wmail_persona, '')));
    IF wmail_norm = '' OR wmail_norm !~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' THEN
        PERFORM smartcset_raise_validacion(
            'El correo personal no tiene un formato válido.',
            'Use una dirección como nombre@dominio.com'
        );
    END IF;

    IF wfec_nacimiento IS NULL THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento es obligatoria.');
    END IF;

    IF wfec_nacimiento > CURRENT_DATE THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento no puede ser futura.');
    END IF;

    IF wfec_nacimiento < DATE '1900-01-01' THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento no es válida.');
    END IF;

    IF wind_genero IS NULL OR wind_genero < 1 THEN
        PERFORM smartcset_raise_validacion('Seleccione el género.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_niveles_estudio WHERE id_nivel_estudio = wid_nivel_estudio
    ) THEN
        PERFORM smartcset_raise_validacion('El nivel de estudio seleccionado no es válido.');
    END IF;

    IF wid_profesion IS NULL OR TRIM(wid_profesion) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione la profesión.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_profesiones WHERE id_profesion = wid_profesion
    ) THEN
        PERFORM smartcset_raise_validacion('La profesión seleccionada no es válida.');
    END IF;

    IF wid_dpto_reside IS NULL OR TRIM(wid_dpto_reside) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el departamento de residencia.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_dptos WHERE id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion('El departamento de residencia no es válido.');
    END IF;

    IF wid_ciudad_reside IS NULL OR TRIM(wid_ciudad_reside) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione la ciudad de residencia.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_ciudades
        WHERE id_ciudad = wid_ciudad_reside AND id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ciudad no corresponde al departamento seleccionado.'
        );
    END IF;

    IF LENGTH(TRIM(COALESCE(wdir_ciudad_reside, ''))) < 10 THEN
        PERFORM smartcset_raise_validacion('La dirección debe tener al menos 10 caracteres.');
    END IF;

    IF wtel_persona_fijo IS NULL
       OR wtel_persona_fijo < 6010000000
       OR wtel_persona_fijo > 6089999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono fijo debe ser un número válido de Bogotá o área metropolitana (601xxxxxxx).'
        );
    END IF;

    IF wtel_persona_movil IS NULL
       OR wtel_persona_movil < 3000000000
       OR wtel_persona_movil > 3519999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono móvil debe ser un celular colombiano válido (300xxxxxxx a 351xxxxxxx).'
        );
    END IF;

    IF LENGTH(TRIM(COALESCE(wnom_contacto_emergencias, ''))) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El nombre del contacto de emergencias debe tener al menos 5 caracteres.'
        );
    END IF;

    IF wtel_contacto_emergencias IS NULL
       OR wtel_contacto_emergencias < 3000000000
       OR wtel_contacto_emergencias > 3519999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono de emergencias debe ser un celular colombiano válido.'
        );
    END IF;

    IF wusr IS NULL OR LENGTH(TRIM(wusr)) < 3 THEN
        PERFORM smartcset_raise_validacion('No se pudo identificar el usuario de registro.');
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe una persona registrada con ese número de documento.'
        );
    END IF;

    INSERT INTO tab_personas (
        id_persona, id_tipo_docum, id_tipo_persona,
        nom_persona, ape_persona, mail_persona,
        fec_nacimiento, ind_genero,
        fec_ultima_entrada, fec_ultima_salida,
        id_nivel_estudio, id_profesion,
        id_dpto_reside, id_ciudad_reside, dir_ciudad_reside,
        tel_persona_fijo, tel_persona_movil,
        nom_contacto_emergencias, tel_contacto_emergencias,
        ind_envio_correo, ind_estado,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, wid_tipo_docum, wid_tipo_persona,
        TRIM(wnom_persona), TRIM(wape_persona), wmail_norm::mail_personal,
        wfec_nacimiento, wind_genero,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        wid_nivel_estudio, wid_profesion,
        wid_dpto_reside, wid_ciudad_reside, TRIM(wdir_ciudad_reside),
        wtel_persona_fijo, wtel_persona_movil,
        TRIM(wnom_contacto_emergencias), wtel_contacto_emergencias,
        COALESCE(wind_envio_correo, FALSE), COALESCE(wind_estado, TRUE),
        TRIM(wusr), CURRENT_TIMESTAMP
    );

    RETURN wid_persona::TEXT;
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
$_$;


--
-- Name: fun_registrar_salida_manual(numeric, character varying, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_registrar_salida_manual(wid_persona numeric, wid_tipo_docum character varying, wval_observaciones text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    wid_ingreso  INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_personas WHERE id_persona = wid_persona
    ) THEN
        PERFORM smartcset_raise_no_encontrado(
            'No hay visitante registrado con ese documento.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;

    wid_ingreso := fun_buscar_ingreso_abierto(wid_persona);

    IF wid_ingreso IS NULL THEN
        PERFORM smartcset_raise_negocio(
            'No tiene un ingreso activo para registrar salida.',
            'id_persona=' || wid_persona::TEXT,
            'Registre primero el ingreso o verifique documento y tipo.'
        );
    END IF;

    wid_ingreso := fun_update_log_salida(
        wid_ingreso,
        NULLIF(TRIM(wval_observaciones), '')
    );

    PERFORM fun_update_persona_tras_salida(wid_persona);

    RETURN wid_ingreso;
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
$$;


--
-- Name: fun_salida_sesion(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_salida_sesion(p_id_sesion integer, p_cod_cierre character varying, p_usr_cierre character varying DEFAULT NULL::character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_cod        tab_sesiones.cod_cierre%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF p_id_sesion IS NULL OR p_id_sesion < 1 THEN
        PERFORM smartcset_raise_validacion('El identificador de sesión es obligatorio.');
    END IF;

    w_cod := UPPER(NULLIF(TRIM(p_cod_cierre), ''));
    IF w_cod IS NULL OR w_cod NOT IN ('LOGOUT', 'ADMIN', 'TIMEOUT', 'IP_MISMATCH') THEN
        PERFORM smartcset_raise_validacion('Código de cierre de sesión no válido.');
    END IF;

    UPDATE tab_sesiones
    SET fec_fin = CURRENT_TIMESTAMP,
        cod_cierre = w_cod,
        usr_cierre = NULLIF(TRIM(p_usr_cierre), '')
    WHERE id_sesion = p_id_sesion
      AND fec_fin IS NULL;

    RETURN 'OK';
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
$$;


--
-- Name: fun_siem_actividad_fisica(date, date, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_actividad_fisica(wfecha_desde date DEFAULT NULL::date, wfecha_hasta date DEFAULT NULL::date, wtipo_persona text DEFAULT NULL::text, wlimit integer DEFAULT 50, woffset integer DEFAULT 0) RETURNS TABLE(id_log numeric, nom_persona character varying, id_persona character varying, nom_tipo_persona character varying, nom_entrada character varying, fec_ingreso timestamp without time zone, fec_salida timestamp without time zone, abierto boolean, total_filas bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        l.id_ingreso::NUMERIC,
        p.nom_persona::VARCHAR,
        l.id_visitante::VARCHAR AS id_persona,
        tp.nom_tipo_persona,
        e.nom_entrada_centro AS nom_entrada,
        l.fec_ingreso,
        l.fec_salida,
        (l.fec_salida = l.fec_ingreso) AS abierto,
        COUNT(*) OVER() AS total_filas
    FROM tab_log_ingresos l
    JOIN tab_personas          p  ON p.id_persona         = l.id_visitante
    JOIN tab_tipos_persona     tp ON tp.id_tipo_persona    = p.id_tipo_persona
    JOIN tab_entradas_centro   e  ON e.id_entrada_centro   = l.id_entrada_centro
    WHERE
        (wfecha_desde IS NULL OR DATE(l.fec_ingreso) >= wfecha_desde)
        AND (wfecha_hasta IS NULL OR DATE(l.fec_ingreso) <= wfecha_hasta)
        AND (wtipo_persona IS NULL OR wtipo_persona = ''
             OR tp.nom_tipo_persona ILIKE '%' || wtipo_persona || '%')
    ORDER BY l.fec_ingreso DESC
    LIMIT wlimit OFFSET woffset;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_alertas_recientes(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_alertas_recientes() RETURNS TABLE(tipo text, descripcion text, ip_cliente character varying, fec_evento timestamp without time zone, severidad text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        CASE
            WHEN bloqueo.ip_cliente IS NOT NULL THEN 'IP_BLOQUEADA'
            ELSE 'FALLO_AUTH'
        END AS tipo,
        CASE
            WHEN bloqueo.ip_cliente IS NOT NULL
                THEN 'IP bloqueada por ' || bloqueo.total_fallos || ' intentos fallidos'
            ELSE 'Intento fallido: usuario ' || COALESCE(t.id_usuario, '(desconocido)')
        END AS descripcion,
        t.ip_cliente,
        t.fec_intento AS fec_evento,
        CASE
            WHEN bloqueo.ip_cliente IS NOT NULL THEN 'danger'
            ELSE 'warning'
        END AS severidad
    FROM tab_intentos_login t
    LEFT JOIN (
        SELECT il.ip_cliente, COUNT(*) AS total_fallos
        FROM tab_intentos_login il
        WHERE il.fec_intento >= NOW() - INTERVAL '15 minutes'
          AND il.ind_exitoso = FALSE
        GROUP BY il.ip_cliente
        HAVING COUNT(*) >= 5
    ) bloqueo ON bloqueo.ip_cliente = t.ip_cliente
    WHERE t.ind_exitoso = FALSE
    ORDER BY t.fec_intento DESC
    LIMIT 8;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_dashboard_kpis(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_dashboard_kpis() RETURNS TABLE(total_intentos_hoy bigint, fallos_hoy bigint, ips_bloqueadas bigint, sesiones_activas bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        (SELECT COUNT(*) FROM tab_intentos_login
         WHERE DATE(fec_intento) = CURRENT_DATE)::BIGINT,

        (SELECT COUNT(*) FROM tab_intentos_login
         WHERE DATE(fec_intento) = CURRENT_DATE
           AND ind_exitoso = FALSE)::BIGINT,

        (SELECT COUNT(DISTINCT ip_cliente) FROM tab_intentos_login
         WHERE fec_intento >= NOW() - INTERVAL '15 minutes'
           AND ind_exitoso = FALSE
         GROUP BY ip_cliente
         HAVING COUNT(*) >= 5)::BIGINT,

        (SELECT COUNT(*) FROM tab_sesiones
         WHERE fec_fin IS NULL)::BIGINT;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_desbloquear_ip(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_desbloquear_ip(wip_cliente text, wid_operador text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wip_cliente IS NULL OR TRIM(wip_cliente) = '' THEN
        PERFORM smartcset_raise_validacion('La IP es obligatoria.');
    END IF;

    DELETE FROM tab_intentos_login
    WHERE ip_cliente = wip_cliente
      AND ind_exitoso = FALSE
      AND fec_intento >= NOW() - INTERVAL '30 minutes';

    RETURN 'OK';

EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_eventos_por_hora(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_eventos_por_hora() RETURNS TABLE(hora integer, exitosos bigint, fallidos bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        EXTRACT(HOUR FROM fec_intento)::INT AS hora,
        COUNT(*) FILTER (WHERE ind_exitoso = TRUE)  AS exitosos,
        COUNT(*) FILTER (WHERE ind_exitoso = FALSE) AS fallidos
    FROM tab_intentos_login
    WHERE fec_intento >= NOW() - INTERVAL '24 hours'
    GROUP BY EXTRACT(HOUR FROM fec_intento)
    ORDER BY hora;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_forzar_cierre_sesion(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_forzar_cierre_sesion(wid_sesion text, wid_operador text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wid_sesion IS NULL OR TRIM(wid_sesion) = '' THEN
        PERFORM smartcset_raise_validacion('El ID de sesión es obligatorio.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_sesiones WHERE id_sesion = wid_sesion::INTEGER) THEN
        PERFORM smartcset_raise_negocio('La sesión no existe.');
    END IF;

    UPDATE tab_sesiones
    SET fec_fin    = NOW(),
        usr_cierre = wid_operador,
        cod_cierre = 'ADMIN'
    WHERE id_sesion = wid_sesion::INTEGER
      AND fec_fin IS NULL;

    RETURN 'OK';

EXCEPTION
    WHEN SQLSTATE 'P0001' THEN RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_ips_bloqueadas(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_ips_bloqueadas(wmax_intentos integer DEFAULT 5, wventana_minutos integer DEFAULT 15) RETURNS TABLE(ip_cliente character varying, total_intentos bigint, ultimo_intento timestamp without time zone, minutos_expira integer, expirada boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        t.ip_cliente,
        COUNT(*)                      AS total_intentos,
        MAX(t.fec_intento)            AS ultimo_intento,
        GREATEST(0,
            wventana_minutos - EXTRACT(EPOCH FROM (NOW() - MIN(t.fec_intento)))::INT / 60
        )                             AS minutos_expira,
        (MAX(t.fec_intento) < NOW() - (wventana_minutos || ' minutes')::INTERVAL) AS expirada
    FROM tab_intentos_login t
    WHERE t.ind_exitoso = FALSE
      AND t.fec_intento >= NOW() - (wventana_minutos * 2 || ' minutes')::INTERVAL
    GROUP BY t.ip_cliente
    HAVING COUNT(*) >= wmax_intentos
    ORDER BY MAX(t.fec_intento) DESC;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_list_eventos(text, text, date, date, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_list_eventos(wip_cliente text DEFAULT NULL::text, wid_usuario text DEFAULT NULL::text, wfecha_desde date DEFAULT NULL::date, wfecha_hasta date DEFAULT NULL::date, wind_exitoso text DEFAULT NULL::text, wlimit integer DEFAULT 50, woffset integer DEFAULT 0) RETURNS TABLE(ip_cliente character varying, id_usuario character varying, ind_exitoso boolean, fec_intento timestamp without time zone, total_filas bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        t.ip_cliente,
        t.id_usuario,
        t.ind_exitoso,
        t.fec_intento,
        COUNT(*) OVER() AS total_filas
    FROM tab_intentos_login t
    WHERE
        (wip_cliente IS NULL OR wip_cliente = ''  OR t.ip_cliente ILIKE '%' || wip_cliente || '%')
        AND (wid_usuario IS NULL OR wid_usuario = '' OR t.id_usuario ILIKE '%' || wid_usuario || '%')
        AND (wfecha_desde IS NULL OR DATE(t.fec_intento) >= wfecha_desde)
        AND (wfecha_hasta IS NULL OR DATE(t.fec_intento) <= wfecha_hasta)
        AND (wind_exitoso IS NULL OR wind_exitoso = ''
             OR (wind_exitoso = 'true'  AND t.ind_exitoso = TRUE)
             OR (wind_exitoso = 'false' AND t.ind_exitoso = FALSE))
    ORDER BY t.fec_intento DESC
    LIMIT wlimit OFFSET woffset;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_sesiones_activas(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_sesiones_activas() RETURNS TABLE(id_sesion text, id_usuario character varying, nom_usuario character varying, ip_cliente character varying, fec_ingreso timestamp without time zone, fec_actividad timestamp without time zone, minutos_activo integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        s.id_sesion::TEXT,
        s.id_usuario,
        u.nom_usuario,
        s.ip_cliente,
        s.fec_inicio      AS fec_ingreso,
        s.ult_actividad   AS fec_actividad,
        EXTRACT(EPOCH FROM (NOW() - s.fec_inicio))::INT / 60 AS minutos_activo
    FROM tab_sesiones s
    JOIN tab_usuarios u ON u.id_usuario = s.id_usuario
    WHERE s.fec_fin IS NULL
    ORDER BY s.fec_inicio DESC;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_siem_top_ips_fallidas(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_siem_top_ips_fallidas() RETURNS TABLE(ip_cliente character varying, total_fallos bigint, ultimo_fallo timestamp without time zone, bloqueada boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    RETURN QUERY
    SELECT
        t.ip_cliente,
        COUNT(*) AS total_fallos,
        MAX(t.fec_intento) AS ultimo_fallo,
        (COUNT(*) FILTER (
            WHERE t.fec_intento >= NOW() - INTERVAL '15 minutes'
        ) >= 5) AS bloqueada
    FROM tab_intentos_login t
    WHERE DATE(t.fec_intento) = CURRENT_DATE
      AND t.ind_exitoso = FALSE
    GROUP BY t.ip_cliente
    ORDER BY total_fallos DESC
    LIMIT 5;

EXCEPTION
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$;


--
-- Name: fun_trigger_desasignar_menu(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_trigger_desasignar_menu() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM fun_delete_menu_usuarios_por_menu(OLD.id_menu);
    RETURN OLD;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Error en trigger tg_desasignar_menu para menú %: %', OLD.id_menu, SQLERRM;
END;
$$;


--
-- Name: fun_trigger_menu(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_trigger_menu() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
 DECLARE wid_menu tab_menus.id_menu%TYPE;
	BEGIN
        SELECT a.id_menu INTO wid_menu FROM tab_menus a
        WHERE a.id_menu = '9';
        IF NOT FOUND THEN
            RETURN NULL;
        END IF;
        -- V.1.3: INSERT solo con 2 valores (id_usuario, id_menu)
        -- El programa 'Exit' está en tab_menus.nom_programa
        INSERT INTO tab_menu_usuarios (id_usuario, id_menu)
        VALUES (NEW.id_usuario, wid_menu);
        IF FOUND THEN
            RETURN NULL;
        END IF;
    END;
$$;


--
-- Name: fun_trigger_menu_admin(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_trigger_menu_admin() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO tab_menu_usuarios (id_usuario, id_menu)
    SELECT u.id_usuario, NEW.id_menu
    FROM tab_usuarios u
    WHERE u.ind_usuario = TRUE
    ON CONFLICT (id_usuario, id_menu) DO NOTHING;
    RETURN NEW;
END;
$$;


--
-- Name: fun_update_log_salida(integer, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_update_log_salida(wid_ingreso integer, wval_observaciones text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    wts_salida   TIMESTAMP WITHOUT TIME ZONE;
    wts_ingreso  TIMESTAMP WITHOUT TIME ZONE;
    wrows        INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    SELECT fec_ingreso
      INTO wts_ingreso
      FROM tab_log_ingresos
     WHERE id_ingreso = wid_ingreso;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No existe el registro de ingreso indicado.',
            'id_ingreso=' || wid_ingreso::TEXT
        );
    END IF;

    wts_salida := CURRENT_TIMESTAMP;
    IF wts_salida <= wts_ingreso THEN
        wts_salida := wts_ingreso + interval '1 microsecond';
    END IF;

    UPDATE tab_log_ingresos
    SET fec_salida = wts_salida,
        val_observaciones = CASE
            WHEN wval_observaciones IS NOT NULL AND TRIM(wval_observaciones) <> '' THEN
                CASE
                    WHEN val_observaciones IS NULL OR TRIM(val_observaciones) = '' THEN TRIM(wval_observaciones)
                    ELSE TRIM(val_observaciones) || ' | Salida: ' || TRIM(wval_observaciones)
                END
            ELSE val_observaciones
        END
    WHERE id_ingreso = wid_ingreso
      AND fec_salida = fec_ingreso;

    GET DIAGNOSTICS wrows = ROW_COUNT;

    IF wrows = 0 THEN
        IF EXISTS (SELECT 1 FROM tab_log_ingresos WHERE id_ingreso = wid_ingreso) THEN
            PERFORM smartcset_raise_negocio(
                format('La salida del ingreso #%s ya fue registrada.', wid_ingreso),
                NULL,
                'Verifique el listado de salidas del día.'
            );
        ELSE
            PERFORM smartcset_raise_no_encontrado(
                'No existe el registro de ingreso indicado.',
                'id_ingreso=' || wid_ingreso::TEXT
            );
        END IF;
    END IF;

    RETURN wid_ingreso;
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
$$;


--
-- Name: fun_update_persona_tras_ingreso(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_update_persona_tras_ingreso(wid_persona numeric) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    UPDATE tab_personas
    SET fec_ultima_entrada = CURRENT_TIMESTAMP,
        num_visitas        = num_visitas + 1
    WHERE id_persona = wid_persona;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se encontró el visitante para actualizar el ingreso.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;
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
$$;


--
-- Name: fun_update_persona_tras_salida(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_update_persona_tras_salida(wid_persona numeric) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    UPDATE tab_personas
    SET fec_ultima_salida = CURRENT_TIMESTAMP
    WHERE id_persona = wid_persona;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'No se encontró el visitante para actualizar la salida.',
            'id_persona=' || wid_persona::TEXT
        );
    END IF;
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
$$;


--
-- Name: fun_update_tab_config_sistema(boolean, boolean, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_update_tab_config_sistema(wind_modulo_registro boolean, wind_login_registro_standalone boolean, wnom_sistema character varying, wpath_logo character varying, wcolor_primario character varying, wcolor_secundario character varying, wtheme_bg_deep character varying, wtheme_bg_card character varying, wtheme_bg_panel character varying, wtheme_accent character varying, wtheme_accent_dim character varying, wtheme_blue character varying, wtheme_purple character varying, wtheme_orange character varying, wtheme_text_primary character varying, wtheme_text_muted character varying, wtheme_border character varying, wtheme_error character varying, wtheme_success character varying, wtheme_font_display character varying, wtheme_font_body character varying, wtheme_light_bg_deep character varying, wtheme_light_bg_card character varying, wtheme_light_accent character varying, wtheme_light_text_primary character varying, wtheme_light_text_muted character varying, wusr_registro character varying, wpass_registro_hash character varying) RETURNS text
    LANGUAGE plpgsql
    AS $_$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wcolor_primario !~ '^#[0-9A-Fa-f]{6}$' OR wcolor_secundario !~ '^#[0-9A-Fa-f]{6}$' THEN
        PERFORM smartcset_raise_validacion('Los colores primario y secundario deben ser hex de 6 dígitos (#RRGGBB).');
    END IF;

    IF LENGTH(TRIM(wnom_sistema)) < 2 THEN
        PERFORM smartcset_raise_validacion('El nombre del sistema es obligatorio.');
    END IF;

    UPDATE tab_config_sistema
    SET ind_modulo_registro           = wind_modulo_registro,
        ind_login_registro_standalone = wind_login_registro_standalone,
        nom_sistema                   = TRIM(wnom_sistema),
        path_logo                     = TRIM(wpath_logo),
        color_primario                = wcolor_primario,
        color_secundario              = wcolor_secundario,
        theme_bg_deep                 = wtheme_bg_deep,
        theme_bg_card                 = wtheme_bg_card,
        theme_bg_panel                = wtheme_bg_panel,
        theme_accent                  = wtheme_accent,
        theme_accent_dim              = wtheme_accent_dim,
        theme_blue                    = wtheme_blue,
        theme_purple                  = wtheme_purple,
        theme_orange                  = wtheme_orange,
        theme_text_primary            = wtheme_text_primary,
        theme_text_muted              = wtheme_text_muted,
        theme_border                  = wtheme_border,
        theme_error                   = wtheme_error,
        theme_success                 = wtheme_success,
        theme_font_display            = TRIM(wtheme_font_display),
        theme_font_body               = TRIM(wtheme_font_body),
        theme_light_bg_deep           = wtheme_light_bg_deep,
        theme_light_bg_card           = wtheme_light_bg_card,
        theme_light_accent            = wtheme_light_accent,
        theme_light_text_primary      = wtheme_light_text_primary,
        theme_light_text_muted        = wtheme_light_text_muted,
        usr_registro                  = NULLIF(TRIM(wusr_registro), ''),
        pass_registro_hash            = CASE
            WHEN wpass_registro_hash IS NULL OR TRIM(wpass_registro_hash) = '' THEN pass_registro_hash
            ELSE wpass_registro_hash
        END
    WHERE id_config = 1;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado('No existe configuración del sistema (id_config=1).');
    END IF;

    RETURN 'OK';
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
$_$;


--
-- Name: fun_update_tab_menus(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_update_tab_menus(wid_menu character varying, wnom_menu character varying, wid_padre character varying, wnom_programa character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nom_len    INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = wid_menu) THEN
        PERFORM smartcset_raise_no_encontrado(
            'El menú no existe.',
            'id_menu=' || wid_menu
        );
    END IF;

    v_nom_len := LENGTH(TRIM(wnom_menu));
    IF v_nom_len < 3 OR v_nom_len > 25 THEN
        PERFORM smartcset_raise_validacion(
            format('El nombre del menú debe tener entre 3 y 25 caracteres (actual: %s).', v_nom_len)
        );
    END IF;

    IF wid_padre IS NULL THEN
        PERFORM smartcset_raise_validacion('El menú padre es obligatorio (use 00 para raíz).');
    END IF;

    IF wid_padre NOT IN ('00', '0') AND NOT EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = wid_padre) THEN
        PERFORM smartcset_raise_validacion(
            format('El menú padre %s no existe.', wid_padre)
        );
    END IF;

    UPDATE tab_menus
    SET nom_menu     = TRIM(wnom_menu),
        ind_id_padre = wid_padre,
        nom_programa = COALESCE(NULLIF(TRIM(wnom_programa), ''), 'no_aplica')
    WHERE id_menu = wid_menu;

    RETURN 'OK';
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
$$;


--
-- Name: fun_update_tab_usuarios(character varying, character varying, character varying, public.mail_personal, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_update_tab_usuarios(wid_usuario character varying, wnom_usuario character varying, wpass_usuario character varying, wmail_usuario public.mail_personal, wind_usuario boolean, wind_estado boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    UPDATE tab_usuarios
    SET nom_usuario  = wnom_usuario,
        pass_usuario = wpass_usuario,
        mail_usuario = wmail_usuario,
        ind_usuario  = wind_usuario,
        ind_estado   = wind_estado
    WHERE id_usuario = wid_usuario;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado(
            'El usuario no existe.',
            'id_usuario=' || wid_usuario
        );
    END IF;

    RETURN 'OK';
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
$$;


--
-- Name: fun_upsert_persona_visitante(numeric, character varying, numeric, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_upsert_persona_visitante(wid_persona numeric, wid_tipo_docum character varying, wid_tipo_persona numeric, wnom_persona character varying, wape_persona character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state    TEXT;
    w_exc_msg      TEXT;
    w_exc_detail   TEXT;
    w_exc_hint     TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona
        WHERE id_tipo_persona = wid_tipo_persona AND id_tipo_persona <> 99
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de persona no es válido.',
            'id_tipo_persona=' || COALESCE(wid_tipo_persona::TEXT, 'NULL'),
            'Seleccione aprendiz, instructor, visitante u otro tipo habilitado.'
        );
    END IF;

    IF LENGTH(TRIM(wnom_persona)) < 2 OR LENGTH(TRIM(wape_persona)) < 2 THEN
        PERFORM smartcset_raise_validacion(
            'Nombres y apellidos son obligatorios (mínimo 2 caracteres).'
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        UPDATE tab_personas
        SET id_tipo_docum   = wid_tipo_docum,
            id_tipo_persona = wid_tipo_persona,
            nom_persona     = TRIM(wnom_persona),
            ape_persona     = TRIM(wape_persona)
        WHERE id_persona = wid_persona;
    ELSE
        INSERT INTO tab_personas (
            id_persona, id_tipo_docum, id_tipo_persona,
            nom_persona, ape_persona
        ) VALUES (
            wid_persona, wid_tipo_docum, wid_tipo_persona,
            TRIM(wnom_persona), TRIM(wape_persona)
        );
    END IF;
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
$$;


--
-- Name: fun_upsert_tab_entradas_centro(numeric, character varying, numeric, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_upsert_tab_entradas_centro(wid_entrada_centro numeric, wnom_entrada_centro character varying, wid_centro numeric, wid_sede numeric) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_nom        VARCHAR(50);
    v_len        INTEGER;
    v_id         tab_entradas_centro.id_entrada_centro%TYPE;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    v_nom := UPPER(TRIM(wnom_entrada_centro));
    v_len := LENGTH(v_nom);
    IF v_len < 5 OR v_len > 50 THEN
        PERFORM smartcset_raise_validacion(
            format('El nombre de la entrada debe tener entre 5 y 50 caracteres (actual: %s).', v_len)
        );
    END IF;

    IF wid_centro IS NULL OR wid_sede IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione la sede donde queda la entrada.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_sedes
        WHERE id_centro = wid_centro AND id_sede = wid_sede
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La sede seleccionada no existe en el sistema.',
            format('id_centro=%s id_sede=%s', wid_centro, wid_sede)
        );
    END IF;

    IF wid_entrada_centro IS NOT NULL
       AND EXISTS (
           SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
       )
    THEN
        IF wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
            PERFORM smartcset_raise_validacion('El código de entrada no es válido.');
        END IF;

        v_id := wid_entrada_centro;

        UPDATE tab_entradas_centro
        SET nom_entrada_centro = v_nom,
            id_centro          = wid_centro,
            id_sede            = wid_sede
        WHERE id_entrada_centro = v_id;
    ELSE
        IF wid_entrada_centro IS NOT NULL THEN
            IF wid_entrada_centro < 1 OR wid_entrada_centro > 9 THEN
                PERFORM smartcset_raise_validacion('El código de entrada debe ser un número entre 1 y 9.');
            END IF;
            IF EXISTS (
                SELECT 1 FROM tab_entradas_centro WHERE id_entrada_centro = wid_entrada_centro
            ) THEN
                PERFORM smartcset_raise_negocio(
                    format('El código de entrada %s ya está en uso.', wid_entrada_centro),
                    NULL,
                    'Edite la entrada existente o deje que el sistema asigne el código.'
                );
            END IF;
            v_id := wid_entrada_centro;
        ELSE
            SELECT MIN(s.codigo)::DECIMAL(1, 0)
              INTO v_id
              FROM generate_series(1, 9) AS s(codigo)
             WHERE NOT EXISTS (
                 SELECT 1
                   FROM tab_entradas_centro e
                  WHERE e.id_entrada_centro = s.codigo
             );

            IF v_id IS NULL THEN
                PERFORM smartcset_raise_negocio(
                    'Ya están registradas las 9 entradas permitidas en el sistema.',
                    NULL,
                    'Elimine una entrada existente para poder crear otra.'
                );
            END IF;
        END IF;

        INSERT INTO tab_entradas_centro (
            id_entrada_centro, nom_entrada_centro, id_centro, id_sede
        ) VALUES (
            v_id, v_nom, wid_centro, wid_sede
        );
    END IF;

    RETURN v_id::TEXT;
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
$$;


--
-- Name: fun_validar_correo(character varying, public.mail_personal); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_validar_correo(wuser character varying, wmail public.mail_personal) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_existe     INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    SELECT COUNT(*) INTO v_existe 
    FROM tab_usuarios 
    WHERE id_usuario = wuser AND mail_usuario = wmail;

    IF v_existe > 0 THEN
        RETURN 'OK';
    ELSE
        RETURN 'ERROR: Los datos no coinciden con nuestros registros.';
    END IF;
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
$$;


--
-- Name: fun_validar_login(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_validar_login(wuser character varying, wpass character varying) RETURNS TABLE(v_status text, v_mensaje text, v_id character varying, v_nombre character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
-- NOTA IMPORTANTE:
-- Esta función ya no compara la contraseña en el motor porque las claves
-- se almacenan como hashes PHP (bcrypt / password_hash).
-- El parámetro wpass se ignora. La comparación se hace en PHP con password_verify().
-- Se mantiene la firma original para no romper llamadas existentes.
BEGIN
    RETURN QUERY
    SELECT 'OK'::TEXT, 'Usuario encontrado'::TEXT, u.id_usuario, u.nom_usuario
    FROM tab_usuarios u
    WHERE u.id_usuario = wuser
      AND u.ind_estado = TRUE;
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
$$;


--
-- Name: fun_validar_sesion_activa(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_validar_sesion_activa(p_id_sesion integer, p_id_usuario character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_ult_actividad  tab_sesiones.ult_actividad%TYPE;
    w_exc_state      TEXT;
    w_exc_msg        TEXT;
    w_exc_detail     TEXT;
    w_exc_hint       TEXT;
BEGIN
    IF p_id_sesion IS NULL OR p_id_sesion < 1 THEN
        RETURN NULL;
    END IF;

    IF p_id_usuario IS NULL OR TRIM(p_id_usuario) = '' THEN
        RETURN NULL;
    END IF;

    SELECT s.ult_actividad
    INTO w_ult_actividad
    FROM tab_sesiones s
    WHERE s.id_sesion = p_id_sesion
      AND s.id_usuario = p_id_usuario
      AND s.fec_fin IS NULL;

    IF NOT FOUND OR w_ult_actividad IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN w_ult_actividad::TEXT;
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
$$;


--
-- Name: fun_validar_usuario(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_validar_usuario(_usuario character varying) RETURNS TABLE(id_usuario text, nom_usuario text)
    LANGUAGE plpgsql
    AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    -- Solo verifica que el usuario exista y esté activo.
    -- La validación de la contraseña se hace en PHP con password_verify().
    RETURN QUERY
    SELECT u.id_usuario, u.nom_usuario
    FROM tab_usuarios u
    WHERE u.id_usuario = _usuario
      AND u.ind_estado = TRUE;
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
$$;


--
-- Name: fun_verificar_bloqueo_ip(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_verificar_bloqueo_ip(wip_cliente character varying, wmax_intentos integer DEFAULT 5, wventana_minutos integer DEFAULT 15) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_intentos   INTEGER;
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wip_cliente IS NULL OR LENGTH(TRIM(wip_cliente)) < 7 THEN
        PERFORM smartcset_raise_validacion(
            'IP de cliente inválida.',
            'ip_cliente=' || COALESCE(wip_cliente, 'NULL')
        );
    END IF;

    SELECT COUNT(*)
    INTO v_intentos
    FROM tab_intentos_login
    WHERE ip_cliente    = wip_cliente
      AND ind_exitoso   = FALSE
      AND fec_intento  >= CURRENT_TIMESTAMP - (wventana_minutos || ' minutes')::INTERVAL;

    IF v_intentos >= wmax_intentos THEN
        PERFORM smartcset_raise_negocio(
            'Acceso bloqueado temporalmente por múltiples intentos fallidos. '
            || 'Intente de nuevo en ' || wventana_minutos || ' minutos.',
            'ip=' || wip_cliente || ' intentos_fallidos=' || v_intentos
        );
    END IF;

    RETURN 'OK';
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
$$;


--
-- Name: fun_verify_retardo_aprendiz(numeric, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fun_verify_retardo_aprendiz(wid_aprendiz numeric, whora_llegada timestamp with time zone) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE
    wreg_pmtros         RECORD;
    wreg_trabajo        RECORD;
    wreg_jornadas       RECORD;
    wminutos_retardo    INT := 0;
    wind_estado         VARCHAR;
    whora_limite_gracia TIME;
    wtiene_permiso      BOOLEAN := FALSE;
    whora_llegada_time  TIME;
BEGIN
    whora_llegada_time := whora_llegada::TIME;

    SELECT val_tiempo_gracia_aprendiz
      INTO wreg_pmtros
      FROM tab_pmtros_grales
     LIMIT 1;

    IF NOT FOUND THEN
        RAISE NOTICE 'No hay datos en parámetros generales. Consulte con el administrador.';
        RETURN FALSE;
    END IF;

    SELECT a.id_ficha, b.id_jornada
      INTO wreg_trabajo
      FROM tab_aprendices a
      JOIN tab_fichas b ON a.id_ficha = b.id_ficha
     WHERE a.id_aprendiz = wid_aprendiz
       AND a.ind_etdo_formacion = 1
       AND b.ind_estado = 3;

    IF NOT FOUND THEN
        RAISE NOTICE 'El aprendiz % no está activo o su ficha no está en ejecución.', wid_aprendiz;
        RETURN FALSE;
    END IF;

    SELECT hora_entrada, hora_salida
      INTO wreg_jornadas
      FROM tab_jornadas
     WHERE id_jornada = wreg_trabajo.id_jornada;

    IF NOT FOUND THEN
        RAISE NOTICE 'No se encontró la jornada asociada. Consulte con el administrador.';
        RETURN FALSE;
    END IF;

    IF whora_llegada_time > wreg_jornadas.hora_salida THEN
        RETURN FALSE;
    END IF;

    whora_limite_gracia := wreg_jornadas.hora_entrada +
                           (wreg_pmtros.val_tiempo_gracia_aprendiz || ' minutes')::INTERVAL;

    IF whora_llegada_time <= whora_limite_gracia THEN
        wind_estado      := 'Presente';
        wminutos_retardo := 0;
    ELSE
        SELECT EXISTS (
            SELECT 1
              FROM tab_permisos_aprendiz
             WHERE id_aprendiz = wid_aprendiz
               AND CURRENT_DATE BETWEEN fec_inicio_permiso AND fec_final_permiso
        ) INTO wtiene_permiso;

        IF wtiene_permiso THEN
            wind_estado      := 'Presente';
            wminutos_retardo := 0;
        ELSE
            wind_estado      := 'Tarde';
            wminutos_retardo := EXTRACT(EPOCH FROM (whora_llegada_time - wreg_jornadas.hora_entrada)) / 60;
        END IF;
    END IF;

    INSERT INTO tab_asistencia_aprendiz (
        id_aprendiz, fec_asistencia, hora_asistencia, minutos_retraso, ind_estado
    ) VALUES (
        wid_aprendiz, CURRENT_DATE, whora_llegada, wminutos_retardo, wind_estado
    )
    ON CONFLICT (id_aprendiz, fec_asistencia) DO UPDATE
    SET hora_asistencia  = EXCLUDED.hora_asistencia,
        minutos_retraso  = EXCLUDED.minutos_retraso,
        ind_estado       = EXCLUDED.ind_estado;

    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Excepción al procesar asistencia del aprendiz %. ERROR: % - ESTADO: %',
                      wid_aprendiz, SQLERRM, SQLSTATE;
        RETURN FALSE;
END;
$$;


--
-- Name: smartcset_handle_sql_error(text, text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.smartcset_handle_sql_error(p_state text DEFAULT NULL::text, p_msg text DEFAULT NULL::text, p_detail text DEFAULT NULL::text, p_hint text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_state  TEXT;
    v_msg    TEXT;
    v_detail TEXT;
    v_hint   TEXT;
BEGIN
    -- GET STACKED DIAGNOSTICS solo es válido en el bloque EXCEPTION del mismo
    -- subprograma; al llamar esta función vía PERFORM hay que pasar los valores.
    IF p_state IS NULL THEN
        PERFORM smartcset_raise_negocio(
            'No se pudo completar la operación en base de datos.',
            COALESCE(p_msg, NULL),
            'Si persiste, contacte al administrador.'
        );
        RETURN;
    END IF;

    v_state  := p_state;
    v_msg    := COALESCE(p_msg, '');
    v_detail := COALESCE(p_detail, '');
    v_hint   := COALESCE(p_hint, '');

    IF v_state = 'P0001' THEN
        RAISE EXCEPTION '%', v_msg
            USING ERRCODE = v_state,
                  DETAIL = COALESCE(v_detail, ''),
                  HINT = COALESCE(v_hint, '');
    END IF;

    CASE v_state
        WHEN '23505' THEN
            PERFORM smartcset_raise_negocio(
                'El registro ya existe o hay un conflicto con datos activos.',
                v_detail,
                'Revise duplicados o cierre visitas/ingresos abiertos.'
            );
        WHEN '23503' THEN
            PERFORM smartcset_raise_validacion(
                'No se puede completar la operación: referencia inválida o dato en uso.',
                v_detail,
                'Verifique catálogos, usuarios y menús relacionados.'
            );
        WHEN '23502' THEN
            PERFORM smartcset_raise_validacion(
                'Faltan datos obligatorios.',
                v_detail,
                'Complete todos los campos requeridos.'
            );
        WHEN '23514' THEN
            PERFORM smartcset_raise_validacion(
                'Los datos no cumplen las reglas del sistema.',
                v_detail,
                'Revise longitudes, formatos y valores permitidos.'
            );
        WHEN '22001' THEN
            PERFORM smartcset_raise_validacion(
                'Uno de los valores es demasiado largo.',
                v_detail,
                NULL
            );
        WHEN '22P02' THEN
            PERFORM smartcset_raise_validacion(
                'Formato de dato inválido.',
                v_detail,
                NULL
            );
        ELSE
            PERFORM smartcset_raise_negocio(
                'No se pudo completar la operación en base de datos.',
                v_msg,
                'Si persiste, contacte al administrador.'
            );
    END CASE;
END;
$$;


--
-- Name: smartcset_raise_core(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.smartcset_raise_core(wmensaje text, wdetalle text DEFAULT NULL::text, whint text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION '%', wmensaje
        USING ERRCODE = 'P0001',
              DETAIL = COALESCE(wdetalle, ''),
              HINT = COALESCE(whint, '');
END;
$$;


--
-- Name: smartcset_raise_negocio(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.smartcset_raise_negocio(wmensaje text, wdetalle text DEFAULT NULL::text, whint text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM smartcset_raise_core(wmensaje, wdetalle, whint);
END;
$$;


--
-- Name: smartcset_raise_no_encontrado(text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.smartcset_raise_no_encontrado(wmensaje text, wdetalle text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM smartcset_raise_core(
        wmensaje,
        wdetalle,
        'Verifique el identificador e intente de nuevo.'
    );
END;
$$;


--
-- Name: smartcset_raise_validacion(text, text, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.smartcset_raise_validacion(wmensaje text, wdetalle text DEFAULT NULL::text, whint text DEFAULT NULL::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    PERFORM smartcset_raise_core(wmensaje, wdetalle, whint);
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: log_migracion_aprendices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_migracion_aprendices (
    id_log integer NOT NULL,
    fecha timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    num_documento_original text,
    motivo text,
    datos_fila jsonb
);


--
-- Name: log_migracion_aprendices_id_log_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_migracion_aprendices_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_migracion_aprendices_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_migracion_aprendices_id_log_seq OWNED BY public.log_migracion_aprendices.id_log;


--
-- Name: seq_id_sector; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_id_sector
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_intentos_login; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_intentos_login
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tab_log_ingresos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_log_ingresos (
    id_ingreso integer NOT NULL,
    id_visitante numeric(10,0) NOT NULL,
    fec_ingreso timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fec_salida timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_metodo_aut numeric(2,0) NOT NULL,
    id_entrada_centro numeric(1,0) NOT NULL,
    val_datos_origen jsonb,
    val_observaciones text,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_log_ingresos_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_log_ingresos_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: seq_log_ingresos; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_log_ingresos
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: seq_log_ingresos; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.seq_log_ingresos OWNED BY public.tab_log_ingresos.id_ingreso;


--
-- Name: seq_sesiones; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_sesiones
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tab_activ_proyecto; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_activ_proyecto (
    id_actividad numeric(10,0) NOT NULL,
    nom_actividad text NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_activ_proyecto_nom_actividad_check CHECK ((length(nom_actividad) >= 5)),
    CONSTRAINT tab_activ_proyecto_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_activ_proyecto_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_adicion_contratos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_adicion_contratos (
    id_instructor numeric(10,0) NOT NULL,
    num_contrato character varying NOT NULL,
    num_adicion numeric(1,0) NOT NULL,
    fec_ini_adicion date NOT NULL,
    fec_fin_adicion date NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_adicion_contratos_num_adicion_check CHECK (((num_adicion >= (0)::numeric) AND (num_adicion <= (3)::numeric))),
    CONSTRAINT tab_adicion_contratos_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_adicion_contratos_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_ambientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_ambientes (
    id_ambiente character varying NOT NULL,
    nom_ambiente character varying(50) NOT NULL,
    id_centro numeric(4,0) NOT NULL,
    id_sede numeric(1,0) NOT NULL,
    ind_disponible_man boolean DEFAULT true NOT NULL,
    ind_disponible_tar boolean DEFAULT true NOT NULL,
    ind_disponible_noc boolean DEFAULT true NOT NULL,
    inventario_ambiente public.inv_ambiente,
    equipos_ambiente json,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_ambientes_nom_ambiente_check CHECK ((length((nom_ambiente)::text) >= 5)),
    CONSTRAINT tab_ambientes_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_ambientes_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_aprendices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_aprendices (
    id_aprendiz numeric(10,0) NOT NULL,
    datos_aprendiz public.datos_personales_aprendiz,
    id_ficha numeric(10,0) NOT NULL,
    num_llamados smallint DEFAULT 0 NOT NULL,
    ind_etdo_formacion numeric(1,0) DEFAULT 8 NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_aprendices_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_aprendices_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_aprendices_fichas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_aprendices_fichas (
    id_ficha numeric(10,0) DEFAULT '2999900001'::bigint NOT NULL,
    id_aprendiz numeric(10,0) NOT NULL,
    id_jornada numeric(1,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_aprendices_fichas_id_jornada_check CHECK (((id_jornada >= (1)::numeric) AND (id_jornada <= (4)::numeric))),
    CONSTRAINT tab_aprendices_fichas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_aprendices_fichas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_areas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_areas (
    id_area numeric(2,0) NOT NULL,
    nom_area character varying(80) NOT NULL,
    id_centro numeric(4,0) NOT NULL,
    nom_encargado character varying(80) NOT NULL,
    tel_area public.telefono_fijo NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_areas_nom_area_check CHECK ((length((nom_area)::text) >= 3)),
    CONSTRAINT tab_areas_nom_encargado_check CHECK ((length((nom_encargado)::text) >= 3)),
    CONSTRAINT tab_areas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_areas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_asistencia_aprendiz; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_asistencia_aprendiz (
    id_aprendiz numeric(10,0) NOT NULL,
    fec_asistencia date NOT NULL,
    hora_asistencia time without time zone NOT NULL,
    minutos_retraso integer DEFAULT 0 NOT NULL,
    ind_estado character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_asistencia_aprendiz_ind_estado_check CHECK ((((ind_estado)::text = 'Presente'::text) OR ((ind_estado)::text = 'Tarde'::text) OR ((ind_estado)::text = 'Ausente'::text) OR ((ind_estado)::text = 'Desconocido'::text))),
    CONSTRAINT tab_asistencia_aprendiz_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_asistencia_aprendiz_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_ausencias_aprendiz; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_ausencias_aprendiz (
    id_aprendiz numeric(10,0) NOT NULL,
    fec_ausencia date DEFAULT '1900-01-01'::date NOT NULL,
    val_motivo text DEFAULT 'Sin Motivo Ausencia Aprendiz'::text NOT NULL,
    ind_evidencia_excusa boolean DEFAULT true NOT NULL,
    val_ruta_excusa character varying DEFAULT 'Sin ruta evidencia Aprendiz'::character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_ausencias_aprendiz_fec_ausencia_check CHECK ((fec_ausencia <= CURRENT_DATE)),
    CONSTRAINT tab_ausencias_aprendiz_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_ausencias_aprendiz_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_bitacora; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_bitacora (
    id_consecutivo bigint NOT NULL,
    fec_bitacora timestamp without time zone NOT NULL,
    texto_evento text NOT NULL,
    nom_encargado character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    CONSTRAINT tab_bitacora_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3))
);


--
-- Name: tab_bitacora_id_consecutivo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tab_bitacora_id_consecutivo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tab_bitacora_id_consecutivo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tab_bitacora_id_consecutivo_seq OWNED BY public.tab_bitacora.id_consecutivo;


--
-- Name: tab_borrados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_borrados (
    id_consec integer NOT NULL,
    nom_tabla character varying NOT NULL,
    nom_registro jsonb NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    CONSTRAINT tab_borrados_nom_tabla_check CHECK ((length((nom_tabla)::text) >= 5)),
    CONSTRAINT tab_borrados_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3))
);


--
-- Name: tab_cargos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_cargos (
    id_cargo numeric(2,0) NOT NULL,
    nom_cargo character varying(90) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_cargos_nom_cargo_check CHECK ((length((nom_cargo)::text) >= 3)),
    CONSTRAINT tab_cargos_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_cargos_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_centros; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_centros (
    id_centro numeric(4,0) NOT NULL,
    nom_centro character varying(100) NOT NULL,
    dir_centro character varying(100) DEFAULT 'Sin dirección'::character varying NOT NULL,
    tel_centro public.telefono_fijo DEFAULT '6010000000'::bigint NOT NULL,
    num_extension_tel public.extension DEFAULT 11111 NOT NULL,
    nom_subdirector character varying(80) NOT NULL,
    id_regional numeric(2,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_centros_dir_centro_check CHECK ((length((dir_centro)::text) >= 10)),
    CONSTRAINT tab_centros_nom_centro_check CHECK ((length((nom_centro)::text) >= 3)),
    CONSTRAINT tab_centros_nom_subdirector_check CHECK ((length((nom_subdirector)::text) >= 3)),
    CONSTRAINT tab_centros_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_centros_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_certificados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_certificados (
    id_consecutivo numeric(2,0) NOT NULL,
    fec_certificado date NOT NULL,
    id_instructor numeric(10,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_certificados_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_certificados_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_ciudades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_ciudades (
    id_ciudad character varying(5) NOT NULL,
    nom_ciudad public.nombre_geografico NOT NULL,
    id_dpto character varying(2) NOT NULL,
    ind_capital boolean DEFAULT false NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_ciudades_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_ciudades_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_compet_instructor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_compet_instructor (
    id_instructor numeric(10,0) NOT NULL,
    id_competencia numeric(10,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_compet_instructor_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_compet_instructor_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_competencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_competencias (
    id_competencia numeric(10,0) NOT NULL,
    nom_competencia text NOT NULL,
    num_raps numeric(2,0) NOT NULL,
    num_horas numeric(4,0) NOT NULL,
    ind_transversal boolean DEFAULT false NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_competencias_nom_competencia_check CHECK ((length(nom_competencia) >= 5)),
    CONSTRAINT tab_competencias_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_competencias_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_competencias_ficha; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_competencias_ficha (
    id_ficha numeric(10,0) NOT NULL,
    id_competencia numeric(10,0) NOT NULL,
    ind_estado numeric(1,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_competencias_ficha_ind_estado_check CHECK (((ind_estado >= (0)::numeric) AND (ind_estado <= (3)::numeric))),
    CONSTRAINT tab_competencias_ficha_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_competencias_ficha_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_config_sistema; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_config_sistema (
    id_config smallint DEFAULT 1 NOT NULL,
    ind_modulo_registro boolean DEFAULT true NOT NULL,
    ind_login_registro_standalone boolean DEFAULT false NOT NULL,
    nom_sistema character varying(80) DEFAULT 'SmartCSET'::character varying NOT NULL,
    path_logo character varying(255) DEFAULT 'public/uploads/logos/logo.png'::character varying NOT NULL,
    color_primario character varying(7) DEFAULT '#2E4731'::character varying NOT NULL,
    color_secundario character varying(7) DEFAULT '#6B8E23'::character varying NOT NULL,
    theme_bg_deep character varying(32) DEFAULT '#020917'::character varying NOT NULL,
    theme_bg_card character varying(32) DEFAULT '#060f24'::character varying NOT NULL,
    theme_bg_panel character varying(64) DEFAULT 'rgba(6, 15, 36, 0.85)'::character varying NOT NULL,
    theme_accent character varying(32) DEFAULT '#00e5b0'::character varying NOT NULL,
    theme_accent_dim character varying(64) DEFAULT 'rgba(0, 245, 255, 0.15)'::character varying NOT NULL,
    theme_blue character varying(32) DEFAULT '#4a9eff'::character varying NOT NULL,
    theme_purple character varying(32) DEFAULT '#9b6dff'::character varying NOT NULL,
    theme_orange character varying(32) DEFAULT '#ff7b2e'::character varying NOT NULL,
    theme_text_primary character varying(32) DEFAULT '#e8f4ff'::character varying NOT NULL,
    theme_text_muted character varying(128) DEFAULT 'rgba(150,180,220,0.7)'::character varying NOT NULL,
    theme_border character varying(64) DEFAULT 'rgba(0,245,255,0.2)'::character varying NOT NULL,
    theme_error character varying(32) DEFAULT '#ff3c6e'::character varying NOT NULL,
    theme_success character varying(32) DEFAULT '#00e5b0'::character varying NOT NULL,
    theme_font_display character varying(120) DEFAULT 'Orbitron'::character varying NOT NULL,
    theme_font_body character varying(120) DEFAULT 'Rajdhani'::character varying NOT NULL,
    theme_light_bg_deep character varying(32) DEFAULT '#f5f7fb'::character varying NOT NULL,
    theme_light_bg_card character varying(32) DEFAULT '#ffffff'::character varying NOT NULL,
    theme_light_accent character varying(32) DEFAULT '#0b74c7'::character varying NOT NULL,
    theme_light_text_primary character varying(32) DEFAULT '#111827'::character varying NOT NULL,
    theme_light_text_muted character varying(128) DEFAULT 'rgba(55,65,81,0.8)'::character varying NOT NULL,
    usr_registro character varying(40),
    pass_registro_hash character varying(255),
    usr_insert character varying(50) DEFAULT 'migration'::character varying NOT NULL,
    fec_insert timestamp without time zone DEFAULT now() NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_config_sistema_id_config_check CHECK ((id_config = 1))
);


--
-- Name: tab_contratos_instructor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_contratos_instructor (
    id_instructor numeric(10,0) NOT NULL,
    num_contrato character varying NOT NULL,
    year_contrato numeric(4,0),
    fec_inicio date NOT NULL,
    fec_fin date NOT NULL,
    ind_vigente boolean DEFAULT true NOT NULL,
    ind_adicion boolean DEFAULT false NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_contratos_instructor_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_contratos_instructor_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_dispositivos_porteria; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_dispositivos_porteria (
    id_dispositivo integer NOT NULL,
    nom_dispositivo character varying(100) NOT NULL,
    token_hash text NOT NULL,
    id_usuario_audit character varying NOT NULL,
    id_entrada_default numeric,
    ind_activo boolean DEFAULT true NOT NULL,
    fec_ultimo_uso timestamp without time zone,
    usr_insert character varying(50) DEFAULT 'system'::character varying NOT NULL,
    fec_insert timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone
);


--
-- Name: tab_dispositivos_porteria_id_dispositivo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tab_dispositivos_porteria_id_dispositivo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tab_dispositivos_porteria_id_dispositivo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tab_dispositivos_porteria_id_dispositivo_seq OWNED BY public.tab_dispositivos_porteria.id_dispositivo;


--
-- Name: tab_dptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_dptos (
    id_dpto character varying(2) NOT NULL,
    nom_dpto public.nombre_geografico NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_dptos_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_dptos_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_empresas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_empresas (
    id_empresa numeric(10,0) NOT NULL,
    id_tipo_docum character varying(3) DEFAULT 'N/A'::character varying NOT NULL,
    nom_empresa character varying(100) DEFAULT 'Sin Empresa'::character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_empresas_nom_empresa_check CHECK ((length((nom_empresa)::text) >= 2)),
    CONSTRAINT tab_empresas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_empresas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_entradas_centro; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_entradas_centro (
    id_entrada_centro numeric(1,0) NOT NULL,
    nom_entrada_centro character varying(50) NOT NULL,
    id_centro numeric(4,0) NOT NULL,
    id_sede numeric(1,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_entradas_centro_nom_entrada_centro_check CHECK ((length((nom_entrada_centro)::text) >= 5)),
    CONSTRAINT tab_entradas_centro_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_entradas_centro_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_evidencias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_evidencias (
    id_evidencia character varying NOT NULL,
    nom_evidencia text NOT NULL,
    val_nota_maxima numeric(3,0) NOT NULL,
    val_nota_minima numeric(3,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_evidencias_nom_evidencia_check CHECK ((length(nom_evidencia) >= 5)),
    CONSTRAINT tab_evidencias_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_evidencias_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3)),
    CONSTRAINT tab_evidencias_val_nota_maxima_check CHECK (((val_nota_maxima >= (0)::numeric) AND (val_nota_maxima <= (100)::numeric))),
    CONSTRAINT tab_evidencias_val_nota_minima_check CHECK (((val_nota_minima >= (0)::numeric) AND (val_nota_minima <= (100)::numeric)))
);


--
-- Name: tab_evidenciasxrap; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_evidenciasxrap (
    id_rap numeric(10,0) NOT NULL,
    id_evidencia character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_evidenciasxrap_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_evidenciasxrap_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_fichas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_fichas (
    id_ficha numeric(10,0) NOT NULL,
    id_centro numeric(4,0) NOT NULL,
    id_programa numeric(8,0) NOT NULL,
    id_nivel_estudio numeric(2,0) NOT NULL,
    id_jornada numeric(1,0) NOT NULL,
    ind_modalidad numeric(1,0) NOT NULL,
    fec_inicio date NOT NULL,
    fec_fin_lectiva date DEFAULT CURRENT_DATE NOT NULL,
    fec_fin_productiva date NOT NULL,
    val_duracion numeric(2,0) DEFAULT 1 NOT NULL,
    id_instructor_lider numeric(10,0) DEFAULT 77777777 NOT NULL,
    id_sector numeric(4,0) DEFAULT 0 NOT NULL,
    id_empresa numeric(10,0) DEFAULT 999 NOT NULL,
    id_ocupacion numeric(4,0) DEFAULT 0 NOT NULL,
    id_ciudad character varying DEFAULT 68001 NOT NULL,
    cod_convenio numeric(1,0) DEFAULT 0 NOT NULL,
    nom_convenio character varying DEFAULT 'Sin Convenio'::character varying NOT NULL,
    ind_amp_cobertura boolean DEFAULT false NOT NULL,
    id_prog_especial numeric(6,0) DEFAULT 0 NOT NULL,
    ind_abierta boolean DEFAULT false NOT NULL,
    nom_vocero character varying DEFAULT 'Sin Vocero'::character varying NOT NULL,
    tel_vocero public.telefono_movil DEFAULT '3000000000'::bigint NOT NULL,
    mail_vocero public.mail_personal DEFAULT 'sin_correo@correo.com'::character varying NOT NULL,
    val_cupo numeric(3,0) DEFAULT 30 NOT NULL,
    id_ambiente_base character varying DEFAULT 'Sin Ambiente Base'::character varying NOT NULL,
    num_inscritos_opcion1 numeric(3,0) DEFAULT 0 NOT NULL,
    num_inscritos_opcion2 numeric(3,0) DEFAULT 0 NOT NULL,
    ind_estado numeric(1,0) DEFAULT 1 NOT NULL,
    num_cursos numeric(2,0) DEFAULT 1 NOT NULL,
    tot_aprendices_masc numeric(3,0) NOT NULL,
    tot_aprendices_fem numeric(3,0) NOT NULL,
    tot_aprendices_nobin numeric(2,0) NOT NULL,
    tot_aprendices_trans numeric(2,0) DEFAULT 0 NOT NULL,
    total_aprendices numeric(4,0) GENERATED ALWAYS AS ((((COALESCE(tot_aprendices_masc, (0)::numeric(3,0)) + COALESCE(tot_aprendices_fem, (0)::numeric(3,0))) + COALESCE(tot_aprendices_nobin, (0)::numeric(4,0))) + COALESCE(tot_aprendices_trans, (0)::numeric(4,0)))) STORED,
    tot_horas_planta interval DEFAULT '00:00:00'::interval NOT NULL,
    tot_horas_contratista interval DEFAULT '00:00:00'::interval NOT NULL,
    tot_horas_contrat_ext interval DEFAULT '00:00:00'::interval NOT NULL,
    tot_horas_monitores interval DEFAULT '00:00:00'::interval NOT NULL,
    tot_horas_inst_empresa interval DEFAULT '00:00:00'::interval NOT NULL,
    total_horas interval GENERATED ALWAYS AS (((((COALESCE(tot_horas_planta, '00:00:00'::interval) + COALESCE(tot_horas_contratista, '00:00:00'::interval)) + COALESCE(tot_horas_contrat_ext, '00:00:00'::interval)) + COALESCE(tot_horas_monitores, '00:00:00'::interval)) + COALESCE(tot_horas_inst_empresa, '00:00:00'::interval))) STORED,
    tot_aprendices_activos numeric(3,0) NOT NULL,
    val_duracion_programa interval NOT NULL,
    id_nuevo_sector numeric(1,0) DEFAULT 0 NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_fichas_id_jornada_check CHECK (((id_jornada >= (1)::numeric) AND (id_jornada <= (4)::numeric))),
    CONSTRAINT tab_fichas_nom_vocero_check CHECK (((length((nom_vocero)::text) >= 3) AND (length((nom_vocero)::text) <= 50))),
    CONSTRAINT tab_fichas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_fichas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_funcionarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_funcionarios (
    id_funcionario numeric(10,0) NOT NULL,
    id_area numeric(2,0) NOT NULL,
    id_cargo numeric(2,0) NOT NULL,
    val_grado character varying NOT NULL,
    id_fec_ingreso_planta date NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_funcionarios_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_funcionarios_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_horas_instructor; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_horas_instructor (
    id_instructor numeric(10,0) NOT NULL,
    id_mes numeric(2,0) NOT NULL,
    val_horas_form_mes numeric(4,0) NOT NULL,
    val_horas_apoyo_mes numeric(4,0) NOT NULL,
    val_horas_invest_mes numeric(4,0) NOT NULL,
    val_horas_acum numeric(3,0) NOT NULL,
    usr_insert character varying NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying,
    fec_update timestamp without time zone,
    CONSTRAINT tab_horas_instructor_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_horas_instructor_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_instructores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_instructores (
    id_instructor numeric(10,0) NOT NULL,
    id_centro numeric(4,0) DEFAULT 9309 NOT NULL,
    ind_tipo_contrato boolean DEFAULT true NOT NULL,
    ind_contratado_actual boolean DEFAULT true NOT NULL,
    ind_genero numeric(1,0) DEFAULT 3 NOT NULL,
    ind_est_civil numeric(1,0) DEFAULT 0 NOT NULL,
    id_nivel_estudio numeric(2,0) DEFAULT 99 NOT NULL,
    id_profesion character varying DEFAULT '00'::character varying NOT NULL,
    id_red numeric(2,0) DEFAULT 99 NOT NULL,
    ind_disponibilidad boolean DEFAULT true NOT NULL,
    ind_estado numeric(1,0) DEFAULT 0 NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_instructores_id_instructor_check CHECK ((id_instructor > (10000000)::numeric)),
    CONSTRAINT tab_instructores_ind_est_civil_check CHECK (((ind_est_civil >= (0)::numeric) AND (ind_est_civil <= (9)::numeric))),
    CONSTRAINT tab_instructores_ind_estado_check CHECK (((ind_estado >= (0)::numeric) AND (ind_estado <= (9)::numeric))),
    CONSTRAINT tab_instructores_ind_genero_check CHECK (((ind_genero = (1)::numeric) OR (ind_genero = (2)::numeric) OR (ind_genero = (3)::numeric) OR (ind_genero = (4)::numeric))),
    CONSTRAINT tab_instructores_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_instructores_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_intentos_login; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_intentos_login (
    id_intento integer DEFAULT nextval('public.seq_intentos_login'::regclass) NOT NULL,
    ip_cliente character varying(45) NOT NULL,
    id_usuario character varying(20),
    ind_exitoso boolean DEFAULT false NOT NULL,
    fec_intento timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT tab_intentos_login_ip_check CHECK ((length(TRIM(BOTH FROM ip_cliente)) >= 7))
);


--
-- Name: tab_jornadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_jornadas (
    id_jornada numeric(1,0) NOT NULL,
    nom_jornada character varying NOT NULL,
    hora_entrada time without time zone NOT NULL,
    hora_salida time without time zone NOT NULL,
    ind_noche boolean NOT NULL,
    hora_llegada_sabado time without time zone NOT NULL,
    hora_salida_sabado time without time zone NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_jornadas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_jornadas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_juicios_eval; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_juicios_eval (
    id_aprendiz numeric(10,0) NOT NULL,
    id_rap numeric(6,0) NOT NULL,
    val_juicio character varying NOT NULL,
    fec_juicio date NOT NULL,
    id_instructor numeric(10,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_juicios_eval_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_juicios_eval_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3)),
    CONSTRAINT tab_juicios_eval_val_juicio_check CHECK ((length((val_juicio)::text) >= 5))
);


--
-- Name: tab_llamados_atencion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_llamados_atencion (
    id_llamado integer NOT NULL,
    ind_tipo boolean NOT NULL,
    id_tercero numeric(10,0) NOT NULL,
    ind_tipo_tercero boolean NOT NULL,
    fec_llamado date NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_llamados_atencion_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_llamados_atencion_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_llamados_atencion_id_llamado_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tab_llamados_atencion_id_llamado_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tab_llamados_atencion_id_llamado_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tab_llamados_atencion_id_llamado_seq OWNED BY public.tab_llamados_atencion.id_llamado;


--
-- Name: tab_menu_usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_menu_usuarios (
    id_usuario character varying(20) NOT NULL,
    id_menu character varying(20) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_menu_usuarios_id_menu_check CHECK ((length((id_menu)::text) >= 2)),
    CONSTRAINT tab_menu_usuarios_id_usuario_check CHECK ((length((id_usuario)::text) >= 5)),
    CONSTRAINT tab_menu_usuarios_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_menu_usuarios_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_menus; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_menus (
    id_menu character varying(20) NOT NULL,
    nom_menu character varying(25) NOT NULL,
    ind_id_padre character varying(20) NOT NULL,
    nom_programa character varying(255) DEFAULT 'no_aplica'::character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_menus_id_menu_check CHECK ((length((id_menu)::text) >= 2)),
    CONSTRAINT tab_menus_ind_id_padre_check CHECK ((length((ind_id_padre)::text) >= 2)),
    CONSTRAINT tab_menus_nom_menu_check CHECK ((length((nom_menu)::text) >= 3)),
    CONSTRAINT tab_menus_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_menus_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_metodos_aut; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_metodos_aut (
    id_metodo_aut numeric(2,0) NOT NULL,
    nom_metodo_aut character varying(30) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_metodos_aut_nom_metodo_aut_check CHECK ((length((nom_metodo_aut)::text) >= 5)),
    CONSTRAINT tab_metodos_aut_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_metodos_aut_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_niveles_estudio; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_niveles_estudio (
    id_nivel_estudio numeric(2,0) NOT NULL,
    nom_nivel_estudio character varying(50) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_niveles_estudio_nom_nivel_estudio_check CHECK ((length((nom_nivel_estudio)::text) >= 5)),
    CONSTRAINT tab_niveles_estudio_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_niveles_estudio_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_ocupaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_ocupaciones (
    id_ocupacion numeric(4,0) NOT NULL,
    nom_ocupacion character varying(160) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_ocupaciones_nom_ocupacion_check CHECK ((length((nom_ocupacion)::text) >= 4)),
    CONSTRAINT tab_ocupaciones_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_ocupaciones_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_ofertas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_ofertas (
    id_oferta smallint NOT NULL,
    ano_oferta numeric(4,0) NOT NULL,
    trim_oferta numeric(1,0) NOT NULL,
    num_oferta numeric(1,0) NOT NULL,
    ind_tipo_oferta boolean DEFAULT true NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_ofertas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_ofertas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_permisos_aprendiz; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_permisos_aprendiz (
    id_aprendiz numeric(10,0) NOT NULL,
    id_tipo_permiso smallint NOT NULL,
    fec_inicio_permiso date NOT NULL,
    fec_final_permiso date DEFAULT '2999-12-31'::date NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_permisos_aprendiz_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_permisos_aprendiz_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_personas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_personas (
    id_persona numeric(10,0) NOT NULL,
    id_tipo_docum character varying(4) DEFAULT 'CC'::character varying NOT NULL,
    id_tipo_persona numeric(2,0) DEFAULT 1 NOT NULL,
    nom_persona character varying(40) NOT NULL,
    ape_persona character varying(30) DEFAULT 'Sin apellido'::character varying NOT NULL,
    mail_persona public.mail_personal DEFAULT 'sin_correo@correo.com'::character varying NOT NULL,
    fec_nacimiento date DEFAULT '1900-01-01'::date NOT NULL,
    ind_genero numeric(2,0) DEFAULT 99 NOT NULL,
    val_huella_digital bytea,
    val_patron_facial jsonb,
    fec_ultima_entrada timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fec_ultima_salida timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    num_visitas smallint DEFAULT 0 NOT NULL,
    id_nivel_estudio numeric(2,0) DEFAULT 99 NOT NULL,
    id_profesion character varying DEFAULT '00'::character varying NOT NULL,
    id_dpto_reside character varying(2) DEFAULT '68'::character varying NOT NULL,
    id_ciudad_reside character varying(5) DEFAULT '68001'::character varying NOT NULL,
    dir_ciudad_reside character varying(100) DEFAULT 'Sin Dirección'::character varying NOT NULL,
    tel_persona_fijo public.telefono_fijo DEFAULT '6010000000'::bigint NOT NULL,
    tel_persona_movil public.telefono_movil DEFAULT '3000000000'::bigint NOT NULL,
    nom_contacto_emergencias character varying(60) DEFAULT 'Sin Contacto'::character varying NOT NULL,
    tel_contacto_emergencias public.telefono_movil DEFAULT '3000000000'::bigint NOT NULL,
    ind_envio_correo boolean DEFAULT false NOT NULL,
    ind_estado boolean DEFAULT true NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_personas_ape_persona_check CHECK ((length((ape_persona)::text) >= 2)),
    CONSTRAINT tab_personas_dir_ciudad_reside_check CHECK ((length((dir_ciudad_reside)::text) >= 10)),
    CONSTRAINT tab_personas_nom_contacto_emergencias_check CHECK ((length((nom_contacto_emergencias)::text) >= 5)),
    CONSTRAINT tab_personas_nom_persona_check CHECK ((length((nom_persona)::text) >= 3)),
    CONSTRAINT tab_personas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_personas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_pmtros_grales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_pmtros_grales (
    id_centro numeric(8,0) NOT NULL,
    dir_centro character varying(90) NOT NULL,
    tel_centro numeric(10,0) NOT NULL,
    ano_academico numeric(4,0) NOT NULL,
    mes_academico numeric(2,0) NOT NULL,
    val_nota_minima_rap numeric(3,0) DEFAULT 71 NOT NULL,
    num_horas_instructor numeric(3,0) DEFAULT 160 NOT NULL,
    val_porcent_icfes_raps numeric(2,0) DEFAULT 75 NOT NULL,
    val_tiempo_gracia_aprendiz numeric(2,0) DEFAULT 0 NOT NULL,
    val_tiempo_gracia_instru numeric(2,0) DEFAULT 0 NOT NULL,
    val_max_llamados_aprendiz numeric(1,0) DEFAULT 3 NOT NULL,
    nom_administrador character varying(80) NOT NULL,
    tel_administrador numeric(10,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_pmtros_grales_dir_centro_check CHECK ((length((dir_centro)::text) >= 10)),
    CONSTRAINT tab_pmtros_grales_nom_administrador_check CHECK (((length((nom_administrador)::text) >= 3) AND (length((nom_administrador)::text) <= 80))),
    CONSTRAINT tab_pmtros_grales_num_horas_instructor_check CHECK (((num_horas_instructor >= (0)::numeric) AND (num_horas_instructor <= (200)::numeric))),
    CONSTRAINT tab_pmtros_grales_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_pmtros_grales_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3)),
    CONSTRAINT tab_pmtros_grales_val_nota_minima_rap_check CHECK (((val_nota_minima_rap >= (0)::numeric) AND (val_nota_minima_rap <= (100)::numeric)))
);


--
-- Name: tab_porteria_sync_client; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_porteria_sync_client (
    client_id uuid NOT NULL,
    id_dispositivo integer NOT NULL,
    tipo_operacion character varying(10) NOT NULL,
    id_ingreso numeric NOT NULL,
    fec_sync timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT chk_sync_tipo_operacion CHECK (((tipo_operacion)::text = ANY (ARRAY[('ingreso'::character varying)::text, ('salida'::character varying)::text])))
);


--
-- Name: tab_profesiones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_profesiones (
    id_profesion character varying NOT NULL,
    nom_profesion character varying(250) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_profesiones_nom_profesion_check CHECK ((length((nom_profesion)::text) >= 3)),
    CONSTRAINT tab_profesiones_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_profesiones_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_prog_competencia; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_prog_competencia (
    id_ruta numeric(8,0) NOT NULL,
    id_ficha numeric(10,0) NOT NULL,
    id_fase numeric(1,0) NOT NULL,
    id_competencia numeric(8,0) NOT NULL,
    id_instructor numeric(10,0) NOT NULL,
    id_actividad numeric(10,0) NOT NULL,
    id_rap numeric(10,0) NOT NULL,
    val_dias numeric(2,0) DEFAULT 6 NOT NULL,
    fec_inicio date NOT NULL,
    fec_final date NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_prog_competencia_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_prog_competencia_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_prog_especiales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_prog_especiales (
    id_prog_especial numeric(6,0) NOT NULL,
    nom_prog_especial character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_prog_especiales_nom_prog_especial_check CHECK ((length((nom_prog_especial)::text) >= 3)),
    CONSTRAINT tab_prog_especiales_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_prog_especiales_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_programacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_programacion (
    id_ruta numeric(8,0) NOT NULL,
    id_ficha numeric(10,0) NOT NULL,
    id_fase numeric(1,0) NOT NULL,
    id_competencia numeric(8,0) NOT NULL,
    id_instructor numeric(10,0) NOT NULL,
    id_jornada numeric(1,0) NOT NULL,
    fec_inicial date NOT NULL,
    fec_final date NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_programacion_id_jornada_check CHECK (((id_jornada >= (1)::numeric) AND (id_jornada <= (4)::numeric))),
    CONSTRAINT tab_programacion_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_programacion_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_programas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_programas (
    id_programa numeric(8,0) NOT NULL,
    nom_programa character varying(200) NOT NULL,
    num_snies character varying DEFAULT 'SNIES-00000'::character varying NOT NULL,
    num_version numeric(2,0) DEFAULT 1 NOT NULL,
    ind_tipo character varying DEFAULT '0'::character varying NOT NULL,
    val_duracion_lect_hrs numeric(4,0) DEFAULT 0 NOT NULL,
    val_duracion_prod_hrs numeric(4,0) DEFAULT 0 NOT NULL,
    val_duracion_lect_mes numeric(2,0) DEFAULT 0 NOT NULL,
    val_duracion_prod_me numeric(2,0) DEFAULT 0 NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_programas_nom_programa_check CHECK ((length((nom_programa)::text) >= 5)),
    CONSTRAINT tab_programas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_programas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_proyectos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_proyectos (
    id_proyecto numeric(8,0) NOT NULL,
    id_programa numeric(8,0) NOT NULL,
    nom_proyecto character varying(100) NOT NULL,
    num_fichas_asociadas numeric(2,0) NOT NULL,
    val_tiempo_ejecucion numeric(2,0) NOT NULL,
    num_resultados numeric(2,0) NOT NULL,
    num_rap_especificos numeric(2,0) NOT NULL,
    num_rap_transversales numeric(2,0) NOT NULL,
    num_rap_basicos numeric(2,0) NOT NULL,
    val_problema text NOT NULL,
    val_justificacion text NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_proyectos_nom_proyecto_check CHECK ((length((nom_proyecto)::text) >= 5)),
    CONSTRAINT tab_proyectos_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_proyectos_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3)),
    CONSTRAINT tab_proyectos_val_justificacion_check CHECK ((length(val_justificacion) >= 5)),
    CONSTRAINT tab_proyectos_val_problema_check CHECK ((length(val_problema) >= 5))
);


--
-- Name: tab_raps; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_raps (
    id_rap numeric(10,0) NOT NULL,
    nom_rap text NOT NULL,
    id_competencia numeric(10,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_raps_nom_rap_check CHECK ((length(nom_rap) >= 5)),
    CONSTRAINT tab_raps_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_raps_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_redes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_redes (
    id_red numeric(2,0) NOT NULL,
    nom_red text NOT NULL,
    nom_lider character varying(80) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_redes_nom_lider_check CHECK ((length((nom_lider)::text) >= 3)),
    CONSTRAINT tab_redes_nom_red_check CHECK ((length(nom_red) >= 3)),
    CONSTRAINT tab_redes_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_redes_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_regionales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_regionales (
    id_regional numeric(2,0) NOT NULL,
    nom_regional character varying(50) NOT NULL,
    dir_regional character varying(100) DEFAULT 'Sin dirección'::character varying NOT NULL,
    id_dpto character varying(2) NOT NULL,
    tel_regional public.telefono_fijo DEFAULT '6010000000'::bigint NOT NULL,
    num_extension_tel public.extension DEFAULT 11111 NOT NULL,
    nom_director character varying(80) DEFAULT 'Sin Datos'::character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_regionales_dir_regional_check CHECK ((length((dir_regional)::text) >= 10)),
    CONSTRAINT tab_regionales_nom_director_check CHECK ((length((nom_director)::text) >= 3)),
    CONSTRAINT tab_regionales_nom_regional_check CHECK ((length((nom_regional)::text) >= 10)),
    CONSTRAINT tab_regionales_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_regionales_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_rutas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_rutas (
    id_ruta numeric(8,0) NOT NULL,
    id_ficha numeric(10,0) NOT NULL,
    nom_ruta character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_rutas_nom_ruta_check CHECK ((length((nom_ruta)::text) >= 5)),
    CONSTRAINT tab_rutas_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_rutas_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_sectores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_sectores (
    id_sector numeric(4,0) NOT NULL,
    nom_sector character varying NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_sectores_nom_sector_check CHECK ((length((nom_sector)::text) >= 3)),
    CONSTRAINT tab_sectores_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_sectores_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_sedes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_sedes (
    id_centro numeric(4,0) NOT NULL,
    id_sede numeric(1,0) NOT NULL,
    nom_sede character varying(100) NOT NULL,
    dir_sede character varying(100) NOT NULL,
    nom_encargado character varying(80) NOT NULL,
    tel_sede public.telefono_fijo NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_sedes_dir_sede_check CHECK ((length((dir_sede)::text) >= 10)),
    CONSTRAINT tab_sedes_nom_encargado_check CHECK ((length((nom_encargado)::text) >= 3)),
    CONSTRAINT tab_sedes_nom_sede_check CHECK ((length((nom_sede)::text) >= 4)),
    CONSTRAINT tab_sedes_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_sedes_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_sesiones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_sesiones (
    id_sesion integer DEFAULT nextval('public.seq_sesiones'::regclass) NOT NULL,
    id_usuario character varying(20) NOT NULL,
    fec_inicio timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fec_fin timestamp without time zone,
    ult_actividad timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    ult_ruta character varying(255),
    ult_menu_id character varying(20),
    cod_cierre character varying(20),
    usr_cierre character varying(50),
    ip_cliente character varying(45)
);


--
-- Name: tab_sesiones_archivo; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_sesiones_archivo (
    id_sesion integer NOT NULL,
    id_usuario character varying(20) NOT NULL,
    fec_inicio timestamp without time zone NOT NULL,
    fec_fin timestamp without time zone NOT NULL,
    ult_actividad timestamp without time zone NOT NULL,
    ult_ruta character varying(255),
    ult_menu_id character varying(20),
    cod_cierre character varying(20),
    usr_cierre character varying(50),
    ip_cliente character varying(45)
);


--
-- Name: tab_temp_aprendices; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_temp_aprendices (
    id_ficha numeric,
    nom_ficha character varying,
    ind_estado_ficha character varying,
    fecha_reporte date,
    id_tipodoc character varying,
    num_documento character varying,
    nom_aprendiz character varying,
    ape_aprendiz character varying,
    nom_movil character varying,
    val_correo character varying,
    ind_estado_aprendiz character varying
);


--
-- Name: tab_temp_df14a; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_temp_df14a (
    fecha_reporte date,
    cod_regional numeric(2,0),
    nom_regional character varying,
    cod_centro numeric(4,0),
    nom_centro character varying,
    cod_programa numeric(8,0),
    cod_ver_programa numeric(3,0),
    nom_programa character varying,
    niv_formacion character varying,
    dur_maxima numeric(4,0),
    dur_eta_lectiva character varying,
    dur_eta_productiv character varying,
    id_ficha numeric(8,0),
    fec_ini_ficha date,
    fec_fin_ficha date,
    num_cupo numeric(4,0),
    estado_ficha character varying,
    tipo_respuesta character varying,
    programa_especial character varying,
    cod_convenio numeric(1,0),
    ind_cobertura character varying,
    nom_convenio character varying,
    tip_docum_empresa character varying,
    num_docum_empresa numeric(10,0),
    nom_empresa character varying,
    en_transito character varying,
    ind_induccion numeric(2,0),
    ind_formacion numeric(2,0),
    ind_condicionado numeric(2,0),
    ind_aplazado numeric(2,0),
    ind_retiro_volun numeric(2,0),
    ind_canc_virtual numeric(2,0),
    ind_deser_virtual numeric(2,0),
    ind_cancelado numeric(2,0),
    ind_por_certif numeric(2,0),
    ind_certificado numeric(2,0),
    ind_traslado numeric(2,0),
    ind_otros numeric(2,0)
);


--
-- Name: tab_temp_df49; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_temp_df49 (
    fecha_reporte date,
    cod_regional numeric(2,0),
    nom_regional character varying,
    cod_centro numeric(4,0),
    nom_centro character varying,
    id_ficha numeric(7,0),
    fec_inicial date,
    fec_final date,
    ind_estado character varying,
    id_programa numeric(8,0),
    id_version numeric(4,0),
    nom_programa character varying,
    ind_nivel character varying,
    num_aprend_matric numeric(3,0),
    num_aprend_certif numeric(3,0),
    num_aprend_sincer numeric(3,0),
    num_aprend_sinjui numeric(3,0),
    num_aprend_noapro numeric(3,0),
    id_convenio numeric(1,0),
    nom_convenio character varying,
    ind_cobertura character varying,
    id_prog_especial numeric(6,0),
    nom_prog_especial character varying
);


--
-- Name: tab_temp_df51; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_temp_df51 (
    fecha_reporte date,
    cod_regional numeric(2,0),
    nom_regional character varying,
    cod_centro numeric(4,0),
    nom_centro character varying,
    id_ficha numeric(8,0),
    id_version_programa smallint,
    tipo_formacion character varying,
    tipo_respuesta character varying,
    fecha_inicial date,
    fecha_final date,
    estado_ficha character varying,
    num_cupo smallint,
    aprendices_activos smallint,
    activos_con_ruta smallint,
    activos_sin_ruta smallint,
    apren_con_ruta_y_noved smallint,
    apren_sin_ruta_con_noved smallint
);


--
-- Name: tab_temp_df53; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_temp_df53 (
    fecha_reporte date,
    cod_regional numeric(2,0),
    nom_regional character varying,
    cod_centro numeric(4,0),
    nom_centro character varying,
    id_ficha numeric(8,0),
    nombre_programa character varying,
    id_version_programa smallint,
    tipo_formacion character varying,
    tipo_respuesta character varying,
    fecha_inicial date,
    fecha_final date,
    estado_ficha character varying,
    aprendices_activos numeric(2,0),
    programada character varying,
    cod_programa_especial numeric(4,0),
    nom_programa_especial character varying,
    cod_convenio character varying,
    ampliacion_cobertura character varying,
    nom_convenio character varying,
    tipo_docum_empresa character varying,
    num_docum_empresa numeric(10,0),
    nombre_empresa character varying,
    tipo_ficha character varying
);


--
-- Name: tab_temp_fichas_creadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_temp_fichas_creadas (
    cod_ficha numeric,
    nom_programa character varying,
    horas_programa character varying,
    fec_inicio date,
    fec_fin date,
    fec_ejecucion character varying,
    estado_ficha character varying,
    cantidad_aprendices numeric,
    cant_aprendices_transito numeric,
    tipo_documento character varying,
    num_documento numeric,
    nombre_instructor character varying,
    apellido_instructor character varying
);


--
-- Name: tab_temp_juicios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_temp_juicios (
    fecha_reporte date,
    id_ficha numeric(10,0),
    id_programa numeric(8,0),
    id_version numeric(2,0),
    nom_ficha character varying,
    ind_estado character varying,
    fec_inicio date,
    fec_fin date,
    id_modalidad character varying,
    cod_regional numeric(2,0),
    nom_regional character varying,
    cod_centro numeric(4,0),
    nom_centro character varying,
    id_tipodoc character varying,
    num_docume numeric(10,0),
    nom_aprendiz character varying,
    ape_aprendiz character varying,
    ind_est_aprendiz character varying,
    cod_competencia numeric(8,0),
    nom_competencia text,
    cod_rap numeric(8,0),
    val_rap numeric(4,0),
    nom_rap text,
    val_juicio character varying,
    fec_juicio character varying,
    tip_doc_instructor character varying,
    num_doc_instructor numeric(15,0),
    nom_instructor character varying
);


--
-- Name: tab_temp_pe04; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_temp_pe04 (
    fecha_reporte date,
    cod_regional numeric(2,0),
    nom_regional character varying,
    cod_centro numeric(4,0),
    nom_centro character varying,
    id_ficha numeric(7,0),
    id_unico_ficha numeric(8,0),
    ind_estado_curso character varying,
    id_nivel_forma numeric(2,0),
    nom_nivel_forma character varying,
    id_jornada numeric(1,0),
    nom_jornada character varying,
    ind_tipo_forma character varying,
    fec_inicio_ficha date,
    fec_fin_ficha date,
    val_etapa_ficha character varying,
    val_modalidad character varying,
    nom_responsable character varying,
    id_empresa numeric(10,0),
    id_tipodoc_emp character varying,
    nom_empresa character varying,
    id_sector_prog numeric(1,0),
    nom_sector_prog character varying,
    id_ocupacion numeric(4,0),
    nom_ocupacion character varying,
    id_programa numeric(8,0),
    id_version smallint,
    nom_programa character varying,
    id_pais numeric(2,0),
    nom_pais character varying,
    id_depto numeric(2,0),
    nom_depto character varying,
    id_municipio numeric(5,0),
    nom_municipio character varying,
    id_convenio numeric(1,0),
    nom_convenio character varying,
    ind_cobertura character varying,
    id_prog_especial numeric(6,0),
    nom_prog_especial character varying,
    num_cursos numeric(2,0),
    num_aprend_masc numeric(3,0),
    num_aprend_fem numeric(3,0),
    num_aprend_nobin numeric(3,0),
    num_tot_aprend numeric(4,0),
    val_hrs_planta interval,
    val_hrs_contrat interval,
    val_hrs_context interval,
    val_hrs_monitor interval,
    val_hrs_instemp interval,
    val_total_hrs interval,
    val_total_apr_act numeric(4,0),
    val_duracion_prog numeric(4,0),
    nom_nuevo_sector character varying DEFAULT 'NA'::character varying
);


--
-- Name: tab_tipos_docum; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_tipos_docum (
    id_tipo_docum character varying(4) NOT NULL,
    nom_tipo_docum character varying(40) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_tipos_docum_nom_tipo_docum_check CHECK ((length((nom_tipo_docum)::text) >= 2)),
    CONSTRAINT tab_tipos_docum_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_tipos_docum_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_tipos_permiso; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_tipos_permiso (
    id_tipo_permiso smallint NOT NULL,
    nom_tipo_permiso character varying NOT NULL,
    num_dias smallint NOT NULL,
    num_horas smallint NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_tipos_permiso_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_tipos_permiso_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_tipos_persona; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_tipos_persona (
    id_tipo_persona numeric(2,0) NOT NULL,
    nom_tipo_persona character varying(25) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_tipos_persona_nom_tipo_persona_check CHECK ((length((nom_tipo_persona)::text) >= 5)),
    CONSTRAINT tab_tipos_persona_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_tipos_persona_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_usuarios (
    id_usuario character varying(20) NOT NULL,
    nom_usuario character varying(50) NOT NULL,
    pass_usuario character varying NOT NULL,
    mail_usuario public.mail_personal NOT NULL,
    ind_usuario boolean DEFAULT false NOT NULL,
    ind_estado boolean DEFAULT true NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_usuarios_id_usuario_check CHECK ((length((id_usuario)::text) >= 3)),
    CONSTRAINT tab_usuarios_nom_usuario_check CHECK ((length(TRIM(BOTH FROM nom_usuario)) >= 3)),
    CONSTRAINT tab_usuarios_pass_usuario_check CHECK ((length((pass_usuario)::text) >= 60)),
    CONSTRAINT tab_usuarios_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_usuarios_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: tab_vehiculos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tab_vehiculos (
    id_vehiculo character varying NOT NULL,
    ind_tipovehiculo numeric(1,0) NOT NULL,
    id_propietario numeric(10,0) NOT NULL,
    usr_insert character varying(50) NOT NULL,
    fec_insert timestamp without time zone NOT NULL,
    usr_update character varying(50),
    fec_update timestamp without time zone,
    CONSTRAINT tab_vehiculos_usr_insert_check CHECK ((length(TRIM(BOTH FROM usr_insert)) >= 3)),
    CONSTRAINT tab_vehiculos_usr_update_check CHECK ((length(TRIM(BOTH FROM usr_update)) >= 3))
);


--
-- Name: log_migracion_aprendices id_log; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_migracion_aprendices ALTER COLUMN id_log SET DEFAULT nextval('public.log_migracion_aprendices_id_log_seq'::regclass);


--
-- Name: tab_bitacora id_consecutivo; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_bitacora ALTER COLUMN id_consecutivo SET DEFAULT nextval('public.tab_bitacora_id_consecutivo_seq'::regclass);


--
-- Name: tab_dispositivos_porteria id_dispositivo; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_dispositivos_porteria ALTER COLUMN id_dispositivo SET DEFAULT nextval('public.tab_dispositivos_porteria_id_dispositivo_seq'::regclass);


--
-- Name: tab_llamados_atencion id_llamado; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_llamados_atencion ALTER COLUMN id_llamado SET DEFAULT nextval('public.tab_llamados_atencion_id_llamado_seq'::regclass);


--
-- Name: tab_log_ingresos id_ingreso; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_log_ingresos ALTER COLUMN id_ingreso SET DEFAULT nextval('public.seq_log_ingresos'::regclass);


--
-- Name: log_migracion_aprendices log_migracion_aprendices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_migracion_aprendices
    ADD CONSTRAINT log_migracion_aprendices_pkey PRIMARY KEY (id_log);


--
-- Name: tab_activ_proyecto tab_activ_proyecto_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_activ_proyecto
    ADD CONSTRAINT tab_activ_proyecto_pkey PRIMARY KEY (id_actividad);


--
-- Name: tab_adicion_contratos tab_adicion_contratos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_adicion_contratos
    ADD CONSTRAINT tab_adicion_contratos_pkey PRIMARY KEY (num_contrato, num_adicion);


--
-- Name: tab_ambientes tab_ambientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ambientes
    ADD CONSTRAINT tab_ambientes_pkey PRIMARY KEY (id_ambiente);


--
-- Name: tab_aprendices_fichas tab_aprendices_fichas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_aprendices_fichas
    ADD CONSTRAINT tab_aprendices_fichas_pkey PRIMARY KEY (id_ficha, id_aprendiz);


--
-- Name: tab_aprendices tab_aprendices_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_aprendices
    ADD CONSTRAINT tab_aprendices_pkey PRIMARY KEY (id_aprendiz);


--
-- Name: tab_areas tab_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_areas
    ADD CONSTRAINT tab_areas_pkey PRIMARY KEY (id_area);


--
-- Name: tab_asistencia_aprendiz tab_asistencia_aprendiz_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_asistencia_aprendiz
    ADD CONSTRAINT tab_asistencia_aprendiz_pkey PRIMARY KEY (id_aprendiz, fec_asistencia);


--
-- Name: tab_ausencias_aprendiz tab_ausencias_aprendiz_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ausencias_aprendiz
    ADD CONSTRAINT tab_ausencias_aprendiz_pkey PRIMARY KEY (id_aprendiz, fec_ausencia);


--
-- Name: tab_bitacora tab_bitacora_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_bitacora
    ADD CONSTRAINT tab_bitacora_pkey PRIMARY KEY (id_consecutivo);


--
-- Name: tab_borrados tab_borrados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_borrados
    ADD CONSTRAINT tab_borrados_pkey PRIMARY KEY (id_consec);


--
-- Name: tab_cargos tab_cargos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_cargos
    ADD CONSTRAINT tab_cargos_pkey PRIMARY KEY (id_cargo);


--
-- Name: tab_centros tab_centros_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_centros
    ADD CONSTRAINT tab_centros_pkey PRIMARY KEY (id_centro);


--
-- Name: tab_certificados tab_certificados_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_certificados
    ADD CONSTRAINT tab_certificados_pkey PRIMARY KEY (id_consecutivo);


--
-- Name: tab_ciudades tab_ciudades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ciudades
    ADD CONSTRAINT tab_ciudades_pkey PRIMARY KEY (id_ciudad);


--
-- Name: tab_compet_instructor tab_compet_instructor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_compet_instructor
    ADD CONSTRAINT tab_compet_instructor_pkey PRIMARY KEY (id_instructor, id_competencia);


--
-- Name: tab_competencias_ficha tab_competencias_ficha_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_competencias_ficha
    ADD CONSTRAINT tab_competencias_ficha_pkey PRIMARY KEY (id_ficha, id_competencia);


--
-- Name: tab_competencias tab_competencias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_competencias
    ADD CONSTRAINT tab_competencias_pkey PRIMARY KEY (id_competencia);


--
-- Name: tab_config_sistema tab_config_sistema_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_config_sistema
    ADD CONSTRAINT tab_config_sistema_pkey PRIMARY KEY (id_config);


--
-- Name: tab_contratos_instructor tab_contratos_instructor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_contratos_instructor
    ADD CONSTRAINT tab_contratos_instructor_pkey PRIMARY KEY (id_instructor, num_contrato);


--
-- Name: tab_dispositivos_porteria tab_dispositivos_porteria_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_dispositivos_porteria
    ADD CONSTRAINT tab_dispositivos_porteria_pkey PRIMARY KEY (id_dispositivo);


--
-- Name: tab_dptos tab_dptos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_dptos
    ADD CONSTRAINT tab_dptos_pkey PRIMARY KEY (id_dpto);


--
-- Name: tab_empresas tab_empresas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_empresas
    ADD CONSTRAINT tab_empresas_pkey PRIMARY KEY (id_empresa);


--
-- Name: tab_entradas_centro tab_entradas_centro_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_entradas_centro
    ADD CONSTRAINT tab_entradas_centro_pkey PRIMARY KEY (id_entrada_centro);


--
-- Name: tab_evidencias tab_evidencias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_evidencias
    ADD CONSTRAINT tab_evidencias_pkey PRIMARY KEY (id_evidencia);


--
-- Name: tab_evidenciasxrap tab_evidenciasxrap_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_evidenciasxrap
    ADD CONSTRAINT tab_evidenciasxrap_pkey PRIMARY KEY (id_rap, id_evidencia);


--
-- Name: tab_fichas tab_fichas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_pkey PRIMARY KEY (id_ficha);


--
-- Name: tab_funcionarios tab_funcionarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_funcionarios
    ADD CONSTRAINT tab_funcionarios_pkey PRIMARY KEY (id_funcionario);


--
-- Name: tab_horas_instructor tab_horas_instructor_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_horas_instructor
    ADD CONSTRAINT tab_horas_instructor_pkey PRIMARY KEY (id_instructor, id_mes);


--
-- Name: tab_instructores tab_instructores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_instructores
    ADD CONSTRAINT tab_instructores_pkey PRIMARY KEY (id_instructor);


--
-- Name: tab_intentos_login tab_intentos_login_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_intentos_login
    ADD CONSTRAINT tab_intentos_login_pkey PRIMARY KEY (id_intento);


--
-- Name: tab_jornadas tab_jornadas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_jornadas
    ADD CONSTRAINT tab_jornadas_pkey PRIMARY KEY (id_jornada);


--
-- Name: tab_juicios_eval tab_juicios_eval_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_juicios_eval
    ADD CONSTRAINT tab_juicios_eval_pkey PRIMARY KEY (id_aprendiz);


--
-- Name: tab_llamados_atencion tab_llamados_atencion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_llamados_atencion
    ADD CONSTRAINT tab_llamados_atencion_pkey PRIMARY KEY (id_llamado);


--
-- Name: tab_log_ingresos tab_log_ingresos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_log_ingresos
    ADD CONSTRAINT tab_log_ingresos_pkey PRIMARY KEY (id_ingreso);


--
-- Name: tab_menu_usuarios tab_menu_usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_menu_usuarios
    ADD CONSTRAINT tab_menu_usuarios_pkey PRIMARY KEY (id_usuario, id_menu);


--
-- Name: tab_menus tab_menus_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_menus
    ADD CONSTRAINT tab_menus_pkey PRIMARY KEY (id_menu);


--
-- Name: tab_metodos_aut tab_metodos_aut_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_metodos_aut
    ADD CONSTRAINT tab_metodos_aut_pkey PRIMARY KEY (id_metodo_aut);


--
-- Name: tab_niveles_estudio tab_niveles_estudio_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_niveles_estudio
    ADD CONSTRAINT tab_niveles_estudio_pkey PRIMARY KEY (id_nivel_estudio);


--
-- Name: tab_ocupaciones tab_ocupaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ocupaciones
    ADD CONSTRAINT tab_ocupaciones_pkey PRIMARY KEY (id_ocupacion);


--
-- Name: tab_ofertas tab_ofertas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ofertas
    ADD CONSTRAINT tab_ofertas_pkey PRIMARY KEY (id_oferta);


--
-- Name: tab_permisos_aprendiz tab_permisos_aprendiz_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_permisos_aprendiz
    ADD CONSTRAINT tab_permisos_aprendiz_pkey PRIMARY KEY (id_aprendiz, fec_inicio_permiso);


--
-- Name: tab_personas tab_personas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_personas
    ADD CONSTRAINT tab_personas_pkey PRIMARY KEY (id_persona);


--
-- Name: tab_pmtros_grales tab_pmtros_grales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_pmtros_grales
    ADD CONSTRAINT tab_pmtros_grales_pkey PRIMARY KEY (id_centro);


--
-- Name: tab_porteria_sync_client tab_porteria_sync_client_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_porteria_sync_client
    ADD CONSTRAINT tab_porteria_sync_client_pkey PRIMARY KEY (client_id);


--
-- Name: tab_profesiones tab_profesiones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_profesiones
    ADD CONSTRAINT tab_profesiones_pkey PRIMARY KEY (id_profesion);


--
-- Name: tab_prog_competencia tab_prog_competencia_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_prog_competencia
    ADD CONSTRAINT tab_prog_competencia_pkey PRIMARY KEY (id_ruta, id_ficha, id_fase, id_competencia, id_instructor, id_actividad, id_rap);


--
-- Name: tab_prog_especiales tab_prog_especiales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_prog_especiales
    ADD CONSTRAINT tab_prog_especiales_pkey PRIMARY KEY (id_prog_especial);


--
-- Name: tab_programacion tab_programacion_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_programacion
    ADD CONSTRAINT tab_programacion_pkey PRIMARY KEY (id_ruta, id_ficha, id_competencia, id_instructor);


--
-- Name: tab_programas tab_programas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_programas
    ADD CONSTRAINT tab_programas_pkey PRIMARY KEY (id_programa);


--
-- Name: tab_proyectos tab_proyectos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_proyectos
    ADD CONSTRAINT tab_proyectos_pkey PRIMARY KEY (id_proyecto);


--
-- Name: tab_raps tab_raps_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_raps
    ADD CONSTRAINT tab_raps_pkey PRIMARY KEY (id_rap);


--
-- Name: tab_redes tab_redes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_redes
    ADD CONSTRAINT tab_redes_pkey PRIMARY KEY (id_red);


--
-- Name: tab_regionales tab_regionales_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_regionales
    ADD CONSTRAINT tab_regionales_pkey PRIMARY KEY (id_regional);


--
-- Name: tab_rutas tab_rutas_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_rutas
    ADD CONSTRAINT tab_rutas_pkey PRIMARY KEY (id_ruta);


--
-- Name: tab_sectores tab_sectores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_sectores
    ADD CONSTRAINT tab_sectores_pkey PRIMARY KEY (id_sector);


--
-- Name: tab_sedes tab_sedes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_sedes
    ADD CONSTRAINT tab_sedes_pkey PRIMARY KEY (id_centro, id_sede);


--
-- Name: tab_sesiones_archivo tab_sesiones_archivo_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_sesiones_archivo
    ADD CONSTRAINT tab_sesiones_archivo_pkey PRIMARY KEY (id_sesion);


--
-- Name: tab_sesiones tab_sesiones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_sesiones
    ADD CONSTRAINT tab_sesiones_pkey PRIMARY KEY (id_sesion);


--
-- Name: tab_tipos_docum tab_tipos_docum_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_tipos_docum
    ADD CONSTRAINT tab_tipos_docum_pkey PRIMARY KEY (id_tipo_docum);


--
-- Name: tab_tipos_permiso tab_tipos_permiso_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_tipos_permiso
    ADD CONSTRAINT tab_tipos_permiso_pkey PRIMARY KEY (id_tipo_permiso);


--
-- Name: tab_tipos_persona tab_tipos_persona_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_tipos_persona
    ADD CONSTRAINT tab_tipos_persona_pkey PRIMARY KEY (id_tipo_persona);


--
-- Name: tab_usuarios tab_usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_usuarios
    ADD CONSTRAINT tab_usuarios_pkey PRIMARY KEY (id_usuario);


--
-- Name: tab_vehiculos tab_vehiculos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_vehiculos
    ADD CONSTRAINT tab_vehiculos_pkey PRIMARY KEY (id_vehiculo);


--
-- Name: idx_aprendices_fichas_aprendiz; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_aprendices_fichas_aprendiz ON public.tab_aprendices_fichas USING btree (id_aprendiz, fec_insert DESC NULLS LAST, id_ficha DESC);


--
-- Name: INDEX idx_aprendices_fichas_aprendiz; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON INDEX public.idx_aprendices_fichas_aprendiz IS 'Ficha más reciente por aprendiz (listado admin de aprendices). Evita seq scan O(n²) en el LATERAL.';


--
-- Name: idx_disp_porteria_activo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_disp_porteria_activo ON public.tab_dispositivos_porteria USING btree (ind_activo) WHERE (ind_activo = true);


--
-- Name: idx_fec_ingresos; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_fec_ingresos ON public.tab_log_ingresos USING btree (fec_ingreso DESC);


--
-- Name: idx_log_ingreso_persona_abierto; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_log_ingreso_persona_abierto ON public.tab_log_ingresos USING btree (id_visitante) WHERE (fec_salida = fec_ingreso);


--
-- Name: INDEX idx_log_ingreso_persona_abierto; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON INDEX public.idx_log_ingreso_persona_abierto IS 'Una sola visita abierta por persona (salida pendiente).';


--
-- Name: idx_sync_client_dispositivo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sync_client_dispositivo ON public.tab_porteria_sync_client USING btree (id_dispositivo, fec_sync DESC);


--
-- Name: ix_tab_intentos_login_fec; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tab_intentos_login_fec ON public.tab_intentos_login USING btree (fec_intento DESC);


--
-- Name: ix_tab_intentos_login_ip_fec; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tab_intentos_login_ip_fec ON public.tab_intentos_login USING btree (ip_cliente, fec_intento DESC);


--
-- Name: ix_tab_sesiones_fec_fin; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX ix_tab_sesiones_fec_fin ON public.tab_sesiones USING btree (fec_fin, fec_inicio);


--
-- Name: ux_tab_sesiones_usuario_activa; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ux_tab_sesiones_usuario_activa ON public.tab_sesiones USING btree (id_usuario) WHERE (fec_fin IS NULL);


--
-- Name: tab_menus tg_desasignar_menu; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_desasignar_menu BEFORE DELETE ON public.tab_menus FOR EACH ROW EXECUTE FUNCTION public.fun_trigger_desasignar_menu();


--
-- Name: tab_menus tg_menu_dmin; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_menu_dmin AFTER INSERT ON public.tab_menus FOR EACH ROW EXECUTE FUNCTION public.fun_trigger_menu_admin();


--
-- Name: tab_usuarios tg_menu_usuarios; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tg_menu_usuarios AFTER INSERT ON public.tab_usuarios FOR EACH ROW EXECUTE FUNCTION public.fun_trigger_menu();


--
-- Name: tab_asistencia_aprendiz trg_after_asistencia_llamados; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_after_asistencia_llamados AFTER INSERT OR UPDATE ON public.tab_asistencia_aprendiz FOR EACH ROW EXECUTE FUNCTION public.fn_after_asistencia_llamados();


--
-- Name: tab_activ_proyecto tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_activ_proyecto FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_adicion_contratos tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_adicion_contratos FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_ambientes tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_ambientes FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_aprendices tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_aprendices FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_aprendices_fichas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_aprendices_fichas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_areas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_areas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_asistencia_aprendiz tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_asistencia_aprendiz FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_ausencias_aprendiz tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_ausencias_aprendiz FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_bitacora tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_bitacora FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_centros tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_centros FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_certificados tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_certificados FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_ciudades tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_ciudades FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_compet_instructor tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_compet_instructor FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_competencias tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_competencias FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_competencias_ficha tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_competencias_ficha FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_config_sistema tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_config_sistema FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_contratos_instructor tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_contratos_instructor FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_dptos tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_dptos FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_empresas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_empresas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_entradas_centro tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_entradas_centro FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_evidencias tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_evidencias FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_evidenciasxrap tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_evidenciasxrap FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_fichas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_fichas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_horas_instructor tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_horas_instructor FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_instructores tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_instructores FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_jornadas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_jornadas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_juicios_eval tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_juicios_eval FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_llamados_atencion tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_llamados_atencion FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_log_ingresos tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_log_ingresos FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_menu_usuarios tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_menu_usuarios FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_menus tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_menus FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_metodos_aut tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_metodos_aut FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_niveles_estudio tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_niveles_estudio FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_ocupaciones tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_ocupaciones FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_ofertas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_ofertas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_personas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_personas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_pmtros_grales tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_pmtros_grales FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_profesiones tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_profesiones FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_prog_competencia tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_prog_competencia FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_prog_especiales tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_prog_especiales FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_programacion tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_programacion FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_programas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_programas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_proyectos tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_proyectos FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_raps tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_raps FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_redes tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_redes FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_regionales tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_regionales FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_rutas tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_rutas FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_sectores tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_sectores FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_sedes tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_sedes FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_tipos_docum tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_tipos_docum FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_tipos_permiso tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_tipos_permiso FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_tipos_persona tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_tipos_persona FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_usuarios tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_usuarios FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_vehiculos tri_act_tabla; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON public.tab_vehiculos FOR EACH ROW EXECUTE FUNCTION public.fun_act_tabla();


--
-- Name: tab_dispositivos_porteria fk_disp_porteria_usuario; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_dispositivos_porteria
    ADD CONSTRAINT fk_disp_porteria_usuario FOREIGN KEY (id_usuario_audit) REFERENCES public.tab_usuarios(id_usuario);


--
-- Name: tab_porteria_sync_client fk_sync_client_dispositivo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_porteria_sync_client
    ADD CONSTRAINT fk_sync_client_dispositivo FOREIGN KEY (id_dispositivo) REFERENCES public.tab_dispositivos_porteria(id_dispositivo);


--
-- Name: tab_adicion_contratos tab_adicion_contratos_id_instructor_num_contrato_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_adicion_contratos
    ADD CONSTRAINT tab_adicion_contratos_id_instructor_num_contrato_fkey FOREIGN KEY (id_instructor, num_contrato) REFERENCES public.tab_contratos_instructor(id_instructor, num_contrato);


--
-- Name: tab_ambientes tab_ambientes_id_centro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ambientes
    ADD CONSTRAINT tab_ambientes_id_centro_fkey FOREIGN KEY (id_centro) REFERENCES public.tab_centros(id_centro);


--
-- Name: tab_ambientes tab_ambientes_id_centro_id_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ambientes
    ADD CONSTRAINT tab_ambientes_id_centro_id_sede_fkey FOREIGN KEY (id_centro, id_sede) REFERENCES public.tab_sedes(id_centro, id_sede);


--
-- Name: tab_aprendices_fichas tab_aprendices_fichas_id_aprendiz_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_aprendices_fichas
    ADD CONSTRAINT tab_aprendices_fichas_id_aprendiz_fkey FOREIGN KEY (id_aprendiz) REFERENCES public.tab_aprendices(id_aprendiz);


--
-- Name: tab_aprendices_fichas tab_aprendices_fichas_id_ficha_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_aprendices_fichas
    ADD CONSTRAINT tab_aprendices_fichas_id_ficha_fkey FOREIGN KEY (id_ficha) REFERENCES public.tab_fichas(id_ficha);


--
-- Name: tab_aprendices_fichas tab_aprendices_fichas_id_jornada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_aprendices_fichas
    ADD CONSTRAINT tab_aprendices_fichas_id_jornada_fkey FOREIGN KEY (id_jornada) REFERENCES public.tab_jornadas(id_jornada);


--
-- Name: tab_aprendices tab_aprendices_id_aprendiz_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_aprendices
    ADD CONSTRAINT tab_aprendices_id_aprendiz_fkey FOREIGN KEY (id_aprendiz) REFERENCES public.tab_personas(id_persona);


--
-- Name: tab_aprendices tab_aprendices_id_ficha_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_aprendices
    ADD CONSTRAINT tab_aprendices_id_ficha_fkey FOREIGN KEY (id_ficha) REFERENCES public.tab_fichas(id_ficha);


--
-- Name: tab_areas tab_areas_id_centro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_areas
    ADD CONSTRAINT tab_areas_id_centro_fkey FOREIGN KEY (id_centro) REFERENCES public.tab_centros(id_centro);


--
-- Name: tab_asistencia_aprendiz tab_asistencia_aprendiz_id_aprendiz_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_asistencia_aprendiz
    ADD CONSTRAINT tab_asistencia_aprendiz_id_aprendiz_fkey FOREIGN KEY (id_aprendiz) REFERENCES public.tab_aprendices(id_aprendiz);


--
-- Name: tab_ausencias_aprendiz tab_ausencias_aprendiz_id_aprendiz_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ausencias_aprendiz
    ADD CONSTRAINT tab_ausencias_aprendiz_id_aprendiz_fkey FOREIGN KEY (id_aprendiz) REFERENCES public.tab_aprendices(id_aprendiz);


--
-- Name: tab_centros tab_centros_id_regional_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_centros
    ADD CONSTRAINT tab_centros_id_regional_fkey FOREIGN KEY (id_regional) REFERENCES public.tab_regionales(id_regional);


--
-- Name: tab_certificados tab_certificados_id_instructor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_certificados
    ADD CONSTRAINT tab_certificados_id_instructor_fkey FOREIGN KEY (id_instructor) REFERENCES public.tab_instructores(id_instructor);


--
-- Name: tab_ciudades tab_ciudades_id_dpto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_ciudades
    ADD CONSTRAINT tab_ciudades_id_dpto_fkey FOREIGN KEY (id_dpto) REFERENCES public.tab_dptos(id_dpto);


--
-- Name: tab_compet_instructor tab_compet_instructor_id_competencia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_compet_instructor
    ADD CONSTRAINT tab_compet_instructor_id_competencia_fkey FOREIGN KEY (id_competencia) REFERENCES public.tab_competencias(id_competencia);


--
-- Name: tab_compet_instructor tab_compet_instructor_id_instructor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_compet_instructor
    ADD CONSTRAINT tab_compet_instructor_id_instructor_fkey FOREIGN KEY (id_instructor) REFERENCES public.tab_instructores(id_instructor);


--
-- Name: tab_competencias_ficha tab_competencias_ficha_id_competencia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_competencias_ficha
    ADD CONSTRAINT tab_competencias_ficha_id_competencia_fkey FOREIGN KEY (id_competencia) REFERENCES public.tab_competencias(id_competencia);


--
-- Name: tab_competencias_ficha tab_competencias_ficha_id_ficha_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_competencias_ficha
    ADD CONSTRAINT tab_competencias_ficha_id_ficha_fkey FOREIGN KEY (id_ficha) REFERENCES public.tab_fichas(id_ficha);


--
-- Name: tab_empresas tab_empresas_id_tipo_docum_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_empresas
    ADD CONSTRAINT tab_empresas_id_tipo_docum_fkey FOREIGN KEY (id_tipo_docum) REFERENCES public.tab_tipos_docum(id_tipo_docum);


--
-- Name: tab_entradas_centro tab_entradas_centro_id_centro_id_sede_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_entradas_centro
    ADD CONSTRAINT tab_entradas_centro_id_centro_id_sede_fkey FOREIGN KEY (id_centro, id_sede) REFERENCES public.tab_sedes(id_centro, id_sede);


--
-- Name: tab_evidenciasxrap tab_evidenciasxrap_id_evidencia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_evidenciasxrap
    ADD CONSTRAINT tab_evidenciasxrap_id_evidencia_fkey FOREIGN KEY (id_evidencia) REFERENCES public.tab_evidencias(id_evidencia);


--
-- Name: tab_evidenciasxrap tab_evidenciasxrap_id_rap_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_evidenciasxrap
    ADD CONSTRAINT tab_evidenciasxrap_id_rap_fkey FOREIGN KEY (id_rap) REFERENCES public.tab_raps(id_rap);


--
-- Name: tab_fichas tab_fichas_id_ambiente_base_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_ambiente_base_fkey FOREIGN KEY (id_ambiente_base) REFERENCES public.tab_ambientes(id_ambiente);


--
-- Name: tab_fichas tab_fichas_id_centro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_centro_fkey FOREIGN KEY (id_centro) REFERENCES public.tab_centros(id_centro);


--
-- Name: tab_fichas tab_fichas_id_ciudad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_ciudad_fkey FOREIGN KEY (id_ciudad) REFERENCES public.tab_ciudades(id_ciudad);


--
-- Name: tab_fichas tab_fichas_id_empresa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_empresa_fkey FOREIGN KEY (id_empresa) REFERENCES public.tab_empresas(id_empresa);


--
-- Name: tab_fichas tab_fichas_id_instructor_lider_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_instructor_lider_fkey FOREIGN KEY (id_instructor_lider) REFERENCES public.tab_instructores(id_instructor);


--
-- Name: tab_fichas tab_fichas_id_jornada_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_jornada_fkey FOREIGN KEY (id_jornada) REFERENCES public.tab_jornadas(id_jornada);


--
-- Name: tab_fichas tab_fichas_id_nivel_estudio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_nivel_estudio_fkey FOREIGN KEY (id_nivel_estudio) REFERENCES public.tab_niveles_estudio(id_nivel_estudio);


--
-- Name: tab_fichas tab_fichas_id_nuevo_sector_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_nuevo_sector_fkey FOREIGN KEY (id_nuevo_sector) REFERENCES public.tab_sectores(id_sector);


--
-- Name: tab_fichas tab_fichas_id_ocupacion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_ocupacion_fkey FOREIGN KEY (id_ocupacion) REFERENCES public.tab_ocupaciones(id_ocupacion);


--
-- Name: tab_fichas tab_fichas_id_prog_especial_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_prog_especial_fkey FOREIGN KEY (id_prog_especial) REFERENCES public.tab_prog_especiales(id_prog_especial);


--
-- Name: tab_fichas tab_fichas_id_programa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_programa_fkey FOREIGN KEY (id_programa) REFERENCES public.tab_programas(id_programa);


--
-- Name: tab_fichas tab_fichas_id_sector_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_fichas
    ADD CONSTRAINT tab_fichas_id_sector_fkey FOREIGN KEY (id_sector) REFERENCES public.tab_sectores(id_sector);


--
-- Name: tab_funcionarios tab_funcionarios_id_area_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_funcionarios
    ADD CONSTRAINT tab_funcionarios_id_area_fkey FOREIGN KEY (id_area) REFERENCES public.tab_areas(id_area);


--
-- Name: tab_funcionarios tab_funcionarios_id_cargo_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_funcionarios
    ADD CONSTRAINT tab_funcionarios_id_cargo_fkey FOREIGN KEY (id_cargo) REFERENCES public.tab_cargos(id_cargo);


--
-- Name: tab_funcionarios tab_funcionarios_id_funcionario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_funcionarios
    ADD CONSTRAINT tab_funcionarios_id_funcionario_fkey FOREIGN KEY (id_funcionario) REFERENCES public.tab_personas(id_persona);


--
-- Name: tab_horas_instructor tab_horas_instructor_id_instructor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_horas_instructor
    ADD CONSTRAINT tab_horas_instructor_id_instructor_fkey FOREIGN KEY (id_instructor) REFERENCES public.tab_instructores(id_instructor);


--
-- Name: tab_instructores tab_instructores_id_centro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_instructores
    ADD CONSTRAINT tab_instructores_id_centro_fkey FOREIGN KEY (id_centro) REFERENCES public.tab_centros(id_centro);


--
-- Name: tab_instructores tab_instructores_id_nivel_estudio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_instructores
    ADD CONSTRAINT tab_instructores_id_nivel_estudio_fkey FOREIGN KEY (id_nivel_estudio) REFERENCES public.tab_niveles_estudio(id_nivel_estudio);


--
-- Name: tab_instructores tab_instructores_id_profesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_instructores
    ADD CONSTRAINT tab_instructores_id_profesion_fkey FOREIGN KEY (id_profesion) REFERENCES public.tab_profesiones(id_profesion);


--
-- Name: tab_instructores tab_instructores_id_red_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_instructores
    ADD CONSTRAINT tab_instructores_id_red_fkey FOREIGN KEY (id_red) REFERENCES public.tab_redes(id_red);


--
-- Name: tab_juicios_eval tab_juicios_eval_id_instructor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_juicios_eval
    ADD CONSTRAINT tab_juicios_eval_id_instructor_fkey FOREIGN KEY (id_instructor) REFERENCES public.tab_instructores(id_instructor);


--
-- Name: tab_juicios_eval tab_juicios_eval_id_rap_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_juicios_eval
    ADD CONSTRAINT tab_juicios_eval_id_rap_fkey FOREIGN KEY (id_rap) REFERENCES public.tab_raps(id_rap);


--
-- Name: tab_log_ingresos tab_log_ingresos_id_entrada_centro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_log_ingresos
    ADD CONSTRAINT tab_log_ingresos_id_entrada_centro_fkey FOREIGN KEY (id_entrada_centro) REFERENCES public.tab_entradas_centro(id_entrada_centro);


--
-- Name: tab_log_ingresos tab_log_ingresos_id_metodo_aut_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_log_ingresos
    ADD CONSTRAINT tab_log_ingresos_id_metodo_aut_fkey FOREIGN KEY (id_metodo_aut) REFERENCES public.tab_metodos_aut(id_metodo_aut);


--
-- Name: tab_log_ingresos tab_log_ingresos_id_visitante_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_log_ingresos
    ADD CONSTRAINT tab_log_ingresos_id_visitante_fkey FOREIGN KEY (id_visitante) REFERENCES public.tab_personas(id_persona);


--
-- Name: tab_menu_usuarios tab_menu_usuarios_id_menu_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_menu_usuarios
    ADD CONSTRAINT tab_menu_usuarios_id_menu_fkey FOREIGN KEY (id_menu) REFERENCES public.tab_menus(id_menu);


--
-- Name: tab_menu_usuarios tab_menu_usuarios_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_menu_usuarios
    ADD CONSTRAINT tab_menu_usuarios_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.tab_usuarios(id_usuario);


--
-- Name: tab_permisos_aprendiz tab_permisos_aprendiz_id_aprendiz_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_permisos_aprendiz
    ADD CONSTRAINT tab_permisos_aprendiz_id_aprendiz_fkey FOREIGN KEY (id_aprendiz) REFERENCES public.tab_aprendices(id_aprendiz);


--
-- Name: tab_personas tab_personas_id_ciudad_reside_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_personas
    ADD CONSTRAINT tab_personas_id_ciudad_reside_fkey FOREIGN KEY (id_ciudad_reside) REFERENCES public.tab_ciudades(id_ciudad);


--
-- Name: tab_personas tab_personas_id_dpto_reside_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_personas
    ADD CONSTRAINT tab_personas_id_dpto_reside_fkey FOREIGN KEY (id_dpto_reside) REFERENCES public.tab_dptos(id_dpto);


--
-- Name: tab_personas tab_personas_id_nivel_estudio_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_personas
    ADD CONSTRAINT tab_personas_id_nivel_estudio_fkey FOREIGN KEY (id_nivel_estudio) REFERENCES public.tab_niveles_estudio(id_nivel_estudio);


--
-- Name: tab_personas tab_personas_id_profesion_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_personas
    ADD CONSTRAINT tab_personas_id_profesion_fkey FOREIGN KEY (id_profesion) REFERENCES public.tab_profesiones(id_profesion);


--
-- Name: tab_personas tab_personas_id_tipo_docum_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_personas
    ADD CONSTRAINT tab_personas_id_tipo_docum_fkey FOREIGN KEY (id_tipo_docum) REFERENCES public.tab_tipos_docum(id_tipo_docum);


--
-- Name: tab_personas tab_personas_id_tipo_persona_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_personas
    ADD CONSTRAINT tab_personas_id_tipo_persona_fkey FOREIGN KEY (id_tipo_persona) REFERENCES public.tab_tipos_persona(id_tipo_persona);


--
-- Name: tab_pmtros_grales tab_pmtros_grales_id_centro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_pmtros_grales
    ADD CONSTRAINT tab_pmtros_grales_id_centro_fkey FOREIGN KEY (id_centro) REFERENCES public.tab_centros(id_centro);


--
-- Name: tab_prog_competencia tab_prog_competencia_id_actividad_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_prog_competencia
    ADD CONSTRAINT tab_prog_competencia_id_actividad_fkey FOREIGN KEY (id_actividad) REFERENCES public.tab_activ_proyecto(id_actividad);


--
-- Name: tab_prog_competencia tab_prog_competencia_id_competencia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_prog_competencia
    ADD CONSTRAINT tab_prog_competencia_id_competencia_fkey FOREIGN KEY (id_competencia) REFERENCES public.tab_competencias(id_competencia);


--
-- Name: tab_prog_competencia tab_prog_competencia_id_ficha_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_prog_competencia
    ADD CONSTRAINT tab_prog_competencia_id_ficha_fkey FOREIGN KEY (id_ficha) REFERENCES public.tab_fichas(id_ficha);


--
-- Name: tab_prog_competencia tab_prog_competencia_id_instructor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_prog_competencia
    ADD CONSTRAINT tab_prog_competencia_id_instructor_fkey FOREIGN KEY (id_instructor) REFERENCES public.tab_instructores(id_instructor);


--
-- Name: tab_prog_competencia tab_prog_competencia_id_ruta_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_prog_competencia
    ADD CONSTRAINT tab_prog_competencia_id_ruta_fkey FOREIGN KEY (id_ruta) REFERENCES public.tab_rutas(id_ruta);


--
-- Name: tab_programacion tab_programacion_id_competencia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_programacion
    ADD CONSTRAINT tab_programacion_id_competencia_fkey FOREIGN KEY (id_competencia) REFERENCES public.tab_competencias(id_competencia);


--
-- Name: tab_programacion tab_programacion_id_ficha_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_programacion
    ADD CONSTRAINT tab_programacion_id_ficha_fkey FOREIGN KEY (id_ficha) REFERENCES public.tab_fichas(id_ficha);


--
-- Name: tab_programacion tab_programacion_id_instructor_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_programacion
    ADD CONSTRAINT tab_programacion_id_instructor_fkey FOREIGN KEY (id_instructor) REFERENCES public.tab_instructores(id_instructor);


--
-- Name: tab_proyectos tab_proyectos_id_programa_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_proyectos
    ADD CONSTRAINT tab_proyectos_id_programa_fkey FOREIGN KEY (id_programa) REFERENCES public.tab_programas(id_programa);


--
-- Name: tab_raps tab_raps_id_competencia_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_raps
    ADD CONSTRAINT tab_raps_id_competencia_fkey FOREIGN KEY (id_competencia) REFERENCES public.tab_competencias(id_competencia);


--
-- Name: tab_regionales tab_regionales_id_dpto_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_regionales
    ADD CONSTRAINT tab_regionales_id_dpto_fkey FOREIGN KEY (id_dpto) REFERENCES public.tab_dptos(id_dpto);


--
-- Name: tab_rutas tab_rutas_id_ficha_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_rutas
    ADD CONSTRAINT tab_rutas_id_ficha_fkey FOREIGN KEY (id_ficha) REFERENCES public.tab_fichas(id_ficha);


--
-- Name: tab_sedes tab_sedes_id_centro_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_sedes
    ADD CONSTRAINT tab_sedes_id_centro_fkey FOREIGN KEY (id_centro) REFERENCES public.tab_centros(id_centro);


--
-- Name: tab_sesiones tab_sesiones_id_usuario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_sesiones
    ADD CONSTRAINT tab_sesiones_id_usuario_fkey FOREIGN KEY (id_usuario) REFERENCES public.tab_usuarios(id_usuario);


--
-- Name: tab_vehiculos tab_vehiculos_id_propietario_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tab_vehiculos
    ADD CONSTRAINT tab_vehiculos_id_propietario_fkey FOREIGN KEY (id_propietario) REFERENCES public.tab_personas(id_persona);


--
-- PostgreSQL database dump complete
--

\unrestrict i4eEGgAcgIyteo6StLYtzPUlRUw1QaAm8uaXUFNsnzyl4cbN0hPaBoKdGjHJij9

