<?php
declare(strict_types=1);

class ApiResponse
{
    public static function json(bool $ok, ?array $data = null, ?string $error = null, int $httpCode = 200): never
    {
        http_response_code($httpCode);
        header('Content-Type: application/json; charset=utf-8');
        $payload = ['ok' => $ok];
        if ($data !== null) {
            $payload['data'] = $data;
        }
        if ($error !== null) {
            $payload['error'] = $error;
        }
        echo json_encode($payload, JSON_UNESCAPED_UNICODE);
        exit;
    }

    public static function ok(array $data = [], int $httpCode = 200): never
    {
        self::json(true, $data, null, $httpCode);
    }

    public static function fail(string $error, int $httpCode = 400): never
    {
        self::json(false, null, $error, $httpCode);
    }

    public static function unauthorized(string $error = 'Token de dispositivo inválido o inactivo.'): never
    {
        self::fail($error, 401);
    }

    public static function disabled(): never
    {
        self::fail('API de portería deshabilitada.', 503);
    }
}
