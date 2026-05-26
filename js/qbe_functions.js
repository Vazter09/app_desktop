/**
 * FUNCIONES QBE (QUERY BY EXAMPLE) - SistNomina V.1.4
 * Funciones específicas de edición CRUD por módulo
 */

// ===== BANCOS =====
function qbe_bancos(id, nom) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true;
    document.getElementById('f_nom').value = nom;
}

// ===== CARGOS =====
function qbe_cargos(id, nom) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true;
    document.getElementById('f_nom').value = nom;
}

// ===== CIUDADES =====
function qbe_ciudades(id_dpto, id_ciu, nom_ciu) {
    let cbxDpto = document.getElementById('f_id_dpto');
    let txtCiu = document.getElementById('f_id_ciu');

    cbxDpto.value = id_dpto;
    txtCiu.value = id_ciu;
    document.getElementById('f_nom_ciu').value = nom_ciu;

    // Bloquear Llaves Primarias en Edición
    cbxDpto.setAttribute('readonly', 'true');
    cbxDpto.style.pointerEvents = 'none';
    cbxDpto.style.backgroundColor = '#e9ecef';
    txtCiu.readOnly = true;

    // Mostrar advertencia de edición restringida
    const warning = document.getElementById('f_dpto_warning');
    if (warning) warning.classList.remove('d-none');

    document.getElementById('f_is_edit').value = '1';
}

// ===== CONCEPTOS =====
function qbe_conceptos(id, nom, dev, obl, tot, val) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true;
    document.getElementById('f_nom').value = nom;
    document.getElementById('f_devengado').checked = Boolean(dev);
    document.getElementById('f_obligatorio').checked = Boolean(obl);
    document.getElementById('f_totales').checked = Boolean(tot);
    document.getElementById('f_val').value = val;
}

// ===== DEPARTAMENTOS =====
function qbe_dptos(id, nom) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true;
    document.getElementById('f_nom').value = nom;
}

// ===== EMPLEADOS =====
function qbe_empleados(id, nom, dpto, ciudad, cargo, profesion, dir, tel, conyuge, hijos, salario, ingreso, banco, cuenta) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true; // No permitir cambio de ID
    document.getElementById('f_nom').value = nom;
    document.getElementById('f_dpto').value = dpto;

    // Cargar ciudades primero antes de setear el valor
    if (typeof filtrarCiudades === 'function') {
        filtrarCiudades(ciudad);
    } else {
        document.getElementById('f_ciudad').value = ciudad;
    }

    document.getElementById('f_cargo').value = cargo;
    document.getElementById('f_profesion').value = profesion;
    document.getElementById('f_dir').value = dir;
    document.getElementById('f_tel').value = tel;
    document.getElementById('f_conyuge').value = conyuge;
    document.getElementById('f_hijos').value = hijos;
    document.getElementById('f_salario').value = salario;
    document.getElementById('f_ingreso').value = ingreso;
    document.getElementById('f_banco').value = banco;
    document.getElementById('f_cuenta').value = cuenta;

    window.scrollTo({ top: 0, behavior: 'smooth' });
}

// ===== EMPRESAS =====
function qbe_empresas(id, nom, contacto, digichequeo, afp, eps, arl, sena, caja) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true;
    document.getElementById('f_nom').value = nom;
    document.getElementById('f_contacto').value = contacto;
    document.getElementById('f_digi').value = digichequeo;
    document.getElementById('f_afp').checked = afp;
    document.getElementById('f_eps').checked = eps;
    document.getElementById('f_arl').checked = arl;
    document.getElementById('f_sena').checked = sena;
    document.getElementById('f_caja').checked = caja;
}

// ===== MENÚS =====
function qbe_menus(id, nom, padre, programa) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true;
    document.getElementById('f_nom').value = nom;
    document.getElementById('f_padre').value = padre;
    document.getElementById('f_programa').value = programa;
}

// ===== PROFESIONES =====
function qbe_profesiones(id, nom) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true;
    document.getElementById('f_nom').value = nom;
}

// ===== USUARIOS =====
function qbe_usuarios(id, nom, mail, adm, est) {
    document.getElementById('f_id').value = id;
    document.getElementById('f_id').readOnly = true;
    document.getElementById('f_nom').value = nom;
    document.getElementById('f_mail').value = mail;
    document.getElementById('f_adm').checked = adm;
    document.getElementById('f_est').checked = est;
}
