<?php
/**
 * DIAGNÓSTICO DE BD - Encuentra el error de ind_usuario
 */
require_once('src/prepare.php');

echo "<h1>🔍 DIAGNÓSTICO DE BASE DE DATOS</h1>";
echo "<hr>";

// 1. Ver estructura de tabla_usuarios
echo "<h3>1. Estructura de tab_usuarios</h3>";
$result = $pdo->query("
    SELECT column_name, data_type, column_default, is_nullable
    FROM information_schema.columns
    WHERE table_name = 'tab_usuarios'
    ORDER BY ordinal_position
");
echo "<table border='1'><tr><th>Columna</th><th>Tipo</th><th>Default</th><th>Nullable</th></tr>";
foreach ($result->fetchAll() as $row) {
    echo "<tr>";
    echo "<td>" . $row['column_name'] . "</td>";
    echo "<td>" . $row['data_type'] . "</td>";
    echo "<td>" . ($row['column_default'] ?? 'NINGUNO') . "</td>";
    echo "<td>" . ($row['is_nullable'] == 'YES' ? 'SÍ' : 'NO') . "</td>";
    echo "</tr>";
}
echo "</table>";

// 2. Ver triggers en tab_usuarios
echo "<h3>2. Triggers en tab_usuarios</h3>";
$result = $pdo->query("
    SELECT trigger_name, event_manipulation, action_statement
    FROM information_schema.triggers
    WHERE event_object_table = 'tab_usuarios'
");
$triggers = $result->fetchAll();
if (empty($triggers)) {
    echo "<p style='color:green'>✅ NO hay triggers en tab_usuarios</p>";
} else {
    echo "<table border='1'><tr><th>Nombre</th><th>Evento</th><th>Acción</th></tr>";
    foreach ($triggers as $row) {
        echo "<tr>";
        echo "<td>" . $row['trigger_name'] . "</td>";
        echo "<td>" . $row['event_manipulation'] . "</td>";
        echo "<td><pre>" . substr($row['action_statement'], 0, 200) . "...</pre></td>";
        echo "</tr>";
    }
    echo "</table>";
}

// 3. Ver estado actual de usuarios
echo "<h3>3. Estado Actual de Usuarios</h3>";
$result = $pdo->query("
    SELECT id_usuario, nom_usuario, ind_usuario, ind_estado
    FROM tab_usuarios
    ORDER BY id_usuario
");
echo "<table border='1'><tr><th>ID Usuario</th><th>Nombre</th><th>ind_usuario</th><th>ind_estado</th></tr>";
foreach ($result->fetchAll() as $row) {
    $ind_usuario_color = $row['ind_usuario'] ? 'green' : 'red';
    $ind_estado_color = $row['ind_estado'] ? 'green' : 'red';
    echo "<tr>";
    echo "<td>" . $row['id_usuario'] . "</td>";
    echo "<td>" . $row['nom_usuario'] . "</td>";
    echo "<td style='color:{$ind_usuario_color}; font-weight:bold'>" . ($row['ind_usuario'] ? 'TRUE (Admin)' : 'FALSE (Normal)') . "</td>";
    echo "<td style='color:{$ind_estado_color}; font-weight:bold'>" . ($row['ind_estado'] ? 'TRUE (Activo)' : 'FALSE (Inactivo)') . "</td>";
    echo "</tr>";
}
echo "</table>";

// 4. Ver funciones SQL
echo "<h3>4. Funciones SQL en Schema</h3>";
$result = $pdo->query("
    SELECT routine_name, routine_type
    FROM information_schema.routines
    WHERE routine_schema = 'public'
    ORDER BY routine_name
");
$routines = $result->fetchAll();
if (empty($routines)) {
    echo "<p>No hay funciones SQL</p>";
} else {
    echo "<ul>";
    foreach ($routines as $row) {
        echo "<li><strong>" . $row['routine_name'] . "</strong> (" . $row['routine_type'] . ")</li>";
    }
    echo "</ul>";
}

echo "<hr>";
echo "<p><strong>FIN DEL DIAGNÓSTICO</strong></p>";
?>
