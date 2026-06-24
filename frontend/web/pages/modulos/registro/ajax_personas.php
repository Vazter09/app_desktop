<?php
declare(strict_types=1);

require_once dirname(__DIR__, 4) . '/init.php';

$query = $_SERVER['QUERY_STRING'] ?? '';
$path = '/routers/registro/v1/personas/listar.php' . ($query !== '' ? '?' . $query : '');
header('Location: ' . smartcsetUrl($path), true, 307);
exit;
