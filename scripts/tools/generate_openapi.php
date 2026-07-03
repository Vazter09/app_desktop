<?php
declare(strict_types=1);

/**
 * Genera openapi.yaml desde openapi.base.json + docblocks @openapi en routers.
 *
 * Uso:
 *   php scripts/tools/generate_openapi.php
 *   php scripts/tools/generate_openapi.php --check
 */

$projectRoot = dirname(__DIR__, 2);
$basePath = $projectRoot . '/backend/openapi/openapi.base.json';
$routersRoot = $projectRoot . '/backend/routers';
$outputBackend = $projectRoot . '/backend/openapi/openapi.yaml';
$outputBackendJson = $projectRoot . '/backend/openapi/openapi.json';
$outputPublic = $projectRoot . '/frontend/web/public/docs/openapi.yaml';
$outputPublicJson = $projectRoot . '/frontend/web/public/docs/openapi.json';

$checkOnly = in_array('--check', $argv ?? [], true);

if (!is_file($basePath)) {
    fwrite(STDERR, "No se encontró {$basePath}\n");
    exit(1);
}

$baseJson = file_get_contents($basePath);
if ($baseJson === false) {
    fwrite(STDERR, "No se pudo leer openapi.base.json\n");
    exit(1);
}

/** @var array<string, mixed> $spec */
$spec = json_decode($baseJson, true, 512, JSON_THROW_ON_ERROR);
$spec['paths'] = [];

$routerFiles = findRouterFiles($routersRoot);
sort($routerFiles);

$missingOpenApi = [];
$errors = [];

foreach ($routerFiles as $filePath) {
    $content = file_get_contents($filePath);
    if ($content === false) {
        $errors[] = "No se pudo leer {$filePath}";
        continue;
    }

    try {
        $meta = parseOpenApiDocblock($content);
    } catch (Throwable $e) {
        $errors[] = relativeRouterPath($filePath, $routersRoot) . ': ' . $e->getMessage();
        continue;
    }

    if ($meta === null) {
        $missingOpenApi[] = relativeRouterPath($filePath, $routersRoot);
        continue;
    }

    try {
        $relative = relativeRouterPath($filePath, $routersRoot);
        $path = '/routers/' . $relative;
        $method = strtolower((string) ($meta['method'] ?? inferHttpMethod($content)));
        $operation = buildOperation($meta, $content, $relative, $method);

        if (!isset($spec['paths'][$path])) {
            $spec['paths'][$path] = [];
        }
        $spec['paths'][$path][$method] = $operation;
    } catch (Throwable $e) {
        $errors[] = relativeRouterPath($filePath, $routersRoot) . ': ' . $e->getMessage();
    }
}

ksort($spec['paths']);

if ($missingOpenApi !== []) {
    $errors[] = 'Routers sin docblock @openapi:' . PHP_EOL . '  - ' . implode(PHP_EOL . '  - ', $missingOpenApi);
}

$expectedCount = count($routerFiles);
$actualCount = countOperations($spec['paths']);
if ($actualCount !== $expectedCount) {
    $errors[] = "Cobertura: {$actualCount}/{$expectedCount} operaciones documentadas.";
}

if ($errors !== []) {
    fwrite(STDERR, implode(PHP_EOL . PHP_EOL, $errors) . PHP_EOL);
    exit(1);
}

$yaml = OpenApiYamlEncoder::encode($spec);
$json = json_encode($spec, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
if ($json === false) {
    fwrite(STDERR, "No se pudo serializar openapi.json\n");
    exit(1);
}

if ($checkOnly) {
    $existingBackend = is_file($outputBackend) ? (string) file_get_contents($outputBackend) : '';
    $existingPublic = is_file($outputPublic) ? (string) file_get_contents($outputPublic) : '';
    $existingBackendJson = is_file($outputBackendJson) ? (string) file_get_contents($outputBackendJson) : '';
    $existingPublicJson = is_file($outputPublicJson) ? (string) file_get_contents($outputPublicJson) : '';
    if (
        $existingBackend !== $yaml
        || $existingPublic !== $yaml
        || $existingBackendJson !== $json
        || $existingPublicJson !== $json
    ) {
        fwrite(STDERR, "openapi desactualizado. Ejecute: php scripts/tools/generate_openapi.php\n");
        exit(1);
    }
    fwrite(STDOUT, "OK openapi ({$actualCount} operaciones, spec sincronizado)\n");
    exit(0);
}

writeFile($outputBackend, $yaml);
writeFile($outputPublic, $yaml);
writeFile($outputBackendJson, $json);
writeFile($outputPublicJson, $json);

fwrite(STDOUT, "Generado {$outputBackend} ({$actualCount} operaciones)\n");
fwrite(STDOUT, "Generado {$outputBackendJson}\n");
fwrite(STDOUT, "Copiado a {$outputPublic} y {$outputPublicJson}\n");

/**
 * @return list<string>
 */
function findRouterFiles(string $routersRoot): array
{
    $files = [];
    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($routersRoot, FilesystemIterator::SKIP_DOTS)
    );

    foreach ($iterator as $file) {
        if (!$file->isFile() || $file->getExtension() !== 'php') {
            continue;
        }
        $pathname = $file->getPathname();
        if (!str_contains($pathname, '/v1/')) {
            continue;
        }
        if (str_contains($pathname, '/_lib/') || str_ends_with($pathname, '/prepare.php')) {
            continue;
        }
        $files[] = $pathname;
    }

    return $files;
}

function relativeRouterPath(string $filePath, string $routersRoot): string
{
    $relative = substr($filePath, strlen($routersRoot) + 1);
    return str_replace('\\', '/', $relative);
}

/**
 * @return array<string, mixed>|null
 */
function parseOpenApiDocblock(string $content): ?array
{
    if (!preg_match('/\/\*\*(.*?)\*\//s', $content, $docMatch)) {
        return null;
    }
    $docblock = normalizeDocblockText($docMatch[1]);
    if (!preg_match('/@openapi\s*\{/s', $docblock, $startMatch, PREG_OFFSET_CAPTURE)) {
        return null;
    }

    $startPos = (int) $startMatch[0][1] + strlen('@openapi');
    $json = extractBalancedJson($docblock, $startPos);
    if ($json === null) {
        return null;
    }

    try {
        /** @var array<string, mixed> $decoded */
        $decoded = json_decode($json, true, 512, JSON_THROW_ON_ERROR);
        return $decoded;
    } catch (JsonException $e) {
        throw new RuntimeException('JSON @openapi inválido: ' . $e->getMessage() . ' → ' . substr($json, 0, 120));
    }
}

function normalizeDocblockText(string $docblock): string
{
    $lines = preg_split('/\R/', $docblock) ?: [];
    $clean = [];
    foreach ($lines as $line) {
        $clean[] = preg_replace('/^\s*\*\s?/', '', $line) ?? $line;
    }

    return trim(implode("\n", $clean));
}

function extractBalancedJson(string $text, int $offset): ?string
{
    $len = strlen($text);
    while ($offset < $len && ctype_space($text[$offset])) {
        $offset++;
    }
    if ($offset >= $len || $text[$offset] !== '{') {
        return null;
    }

    $depth = 0;
    $inString = false;
    $escape = false;

    for ($i = $offset; $i < $len; $i++) {
        $ch = $text[$i];

        if ($inString) {
            if ($escape) {
                $escape = false;
                continue;
            }
            if ($ch === '\\') {
                $escape = true;
                continue;
            }
            if ($ch === '"') {
                $inString = false;
            }
            continue;
        }

        if ($ch === '"') {
            $inString = true;
            continue;
        }

        if ($ch === '{') {
            $depth++;
            continue;
        }

        if ($ch === '}') {
            $depth--;
            if ($depth === 0) {
                return trim(substr($text, $offset, $i - $offset + 1));
            }
        }
    }

    return null;
}

function inferHttpMethod(string $content): string
{
    if (preg_match("/\\\$_SERVER\\['REQUEST_METHOD'\\]\\s*!==\\s*'([A-Z]+)'/", $content, $m)) {
        return $m[1];
    }

    return 'GET';
}

/**
 * @return list<array<string, list<string>>>
 */
function inferSecurity(string $content): array
{
    if (str_contains($content, 'require_registro_session.php')) {
        return [['registroSession' => []]];
    }
    if (str_contains($content, 'require_session_or_device.php')) {
        return [['sessionCookie' => []], ['bearerDevice' => []]];
    }
    if (preg_match('/porteriaApiRequireDevice\s*\(/', $content)) {
        return [['bearerDevice' => []]];
    }
    if (
        str_contains($content, 'require_session.php')
        || str_contains($content, 'require_admin.php')
        || str_contains($content, 'require_instructor.php')
    ) {
        return [['sessionCookie' => []]];
    }
    if (str_contains($content, 'RouterResponse::unauthorized') && str_contains($content, 'id_sesion')) {
        return [['sessionCookie' => []]];
    }

    return [];
}

function inferTagFromPath(string $relativePath): string
{
    $module = explode('/', $relativePath)[0] ?? 'General';
    return match ($module) {
        'auth' => 'Auth',
        'sesion' => 'Sesión',
        'admin' => 'Admin',
        'usuarios' => 'Usuarios',
        'entradas' => 'Entradas',
        'menus' => 'Menús',
        'instructor' => 'Instructor',
        'porteria' => 'Portería',
        'registro' => 'Registro',
        default => ucfirst($module),
    };
}

/**
 * @param array<string, mixed> $meta
 * @return array<string, mixed>
 */
function buildOperation(array $meta, string $content, string $relativePath, string $method): array
{
    $operation = [];

    $operation['summary'] = (string) ($meta['summary'] ?? basename($relativePath, '.php'));
    if (!empty($meta['description'])) {
        $operation['description'] = (string) $meta['description'];
    }

    $tags = $meta['tags'] ?? [inferTagFromPath($relativePath)];
    $operation['tags'] = is_array($tags) ? array_values($tags) : [(string) $tags];

    if (!empty($meta['deprecated'])) {
        $operation['deprecated'] = (bool) $meta['deprecated'];
    }

    if (array_key_exists('security', $meta)) {
        $operation['security'] = $meta['security'];
    } else {
        $security = inferSecurity($content);
        $operation['security'] = $security;
    }

    if (!empty($meta['parameters']) && is_array($meta['parameters'])) {
        $operation['parameters'] = $meta['parameters'];
    }

    if (!empty($meta['requestBody']) && is_array($meta['requestBody'])) {
        $operation['requestBody'] = buildRequestBody($meta['requestBody']);
    }

    $responseType = (string) ($meta['responseType'] ?? 'json');
    if ($responseType === 'redirect') {
        $operation['responses'] = [
            '302' => [
                'description' => (string) ($meta['redirectDescription'] ?? 'Redirección HTTP'),
            ],
        ];
    } else {
        $operation['responses'] = buildResponses($meta);
    }

    $operation['responses']['401'] = ['$ref' => '#/components/responses/Unauthorized'];
    $operation['responses']['405'] = ['$ref' => '#/components/responses/MethodNotAllowed'];

    return $operation;
}

/**
 * @param array<string, mixed> $requestBody
 * @return array<string, mixed>
 */
function buildRequestBody(array $requestBody): array
{
    $contentType = (string) ($requestBody['contentType'] ?? 'application/json');

    if ($contentType === 'multipart/form-data') {
        $properties = $requestBody['properties'] ?? [];
        $required = $requestBody['required'] ?? [];
        $schema = [
            'type' => 'object',
            'properties' => is_array($properties) ? $properties : [],
        ];
        if (is_array($required) && $required !== []) {
            $schema['required'] = $required;
        }
        return [
            'required' => true,
            'content' => [
                'multipart/form-data' => [
                    'schema' => $schema,
                ],
            ],
        ];
    }

    if ($contentType === 'application/x-www-form-urlencoded') {
        $properties = $requestBody['properties'] ?? [];
        $required = $requestBody['required'] ?? [];
        $schema = [
            'type' => 'object',
            'properties' => is_array($properties) ? $properties : [],
        ];
        if (is_array($required) && $required !== []) {
            $schema['required'] = $required;
        }
        return [
            'required' => true,
            'content' => [
                'application/x-www-form-urlencoded' => [
                    'schema' => $schema,
                ],
            ],
        ];
    }

    if (isset($requestBody['oneOf']) && is_array($requestBody['oneOf'])) {
        return [
            'required' => (bool) ($requestBody['required'] ?? true),
            'content' => [
                'application/json' => ['schema' => ['oneOf' => $requestBody['oneOf']]],
                'application/x-www-form-urlencoded' => ['schema' => ['oneOf' => $requestBody['oneOf']]],
            ],
        ];
    }

    $schema = $requestBody['schema'] ?? [
        'type' => 'object',
        'properties' => $requestBody['properties'] ?? [],
    ];
    if (!empty($requestBody['required']) && is_array($requestBody['required'])) {
        $schema['required'] = $requestBody['required'];
    }

    return [
        'required' => (bool) ($requestBody['required'] ?? true),
        'content' => [
            $contentType => ['schema' => $schema],
        ],
    ];
}

/**
 * @param array<string, mixed> $meta
 * @return array<string, mixed>
 */
function buildResponses(array $meta): array
{
    $responses = [];
    $custom = $meta['responses'] ?? [];

    if (is_array($custom) && $custom !== []) {
        foreach ($custom as $code => $response) {
            if (!is_array($response)) {
                continue;
            }
            $description = (string) ($response['description'] ?? 'OK');
            $entry = ['description' => $description];

            if (!empty($response['schema'])) {
                $entry['content'] = [
                    'application/json' => [
                        'schema' => wrapApiSuccess($response['schema']),
                    ],
                ];
            } elseif (!empty($response['dataSchema'])) {
                $entry['content'] = [
                    'application/json' => [
                        'schema' => wrapApiSuccess($response['dataSchema']),
                    ],
                ];
            } elseif (!empty($response['ref'])) {
                $entry['content'] = [
                    'application/json' => [
                        'schema' => ['$ref' => (string) $response['ref']],
                    ],
                ];
            }

            $responses[(string) $code] = $entry;
        }
    }

    if ($responses === []) {
        $responses['200'] = [
            'description' => 'Operación exitosa',
            'content' => [
                'application/json' => [
                    'schema' => ['$ref' => '#/components/schemas/ApiSuccess'],
                ],
            ],
        ];
    }

    $responses['400'] = ['$ref' => '#/components/responses/BadRequest'];

    return $responses;
}

/**
 * @param array<string, mixed>|string $dataSchema
 * @return array<string, mixed>
 */
function wrapApiSuccess(array|string $dataSchema): array
{
    if (is_string($dataSchema) && str_starts_with($dataSchema, '#/')) {
        return [
            'allOf' => [
                ['$ref' => '#/components/schemas/ApiSuccess'],
                [
                    'type' => 'object',
                    'properties' => [
                        'data' => ['$ref' => $dataSchema],
                    ],
                ],
            ],
        ];
    }

    if (!is_array($dataSchema)) {
        return ['$ref' => '#/components/schemas/ApiSuccess'];
    }

    $schema = $dataSchema;
    if (($schema['type'] ?? '') !== 'object' && !isset($schema['$ref'])) {
        $schema = ['type' => 'object', 'properties' => $dataSchema];
    }

    return [
        'allOf' => [
            ['$ref' => '#/components/schemas/ApiSuccess'],
            [
                'type' => 'object',
                'properties' => [
                    'data' => $schema,
                ],
            ],
        ],
    ];
}

/**
 * @param array<string, mixed> $paths
 */
function countOperations(array $paths): int
{
    $count = 0;
    foreach ($paths as $methods) {
        if (!is_array($methods)) {
            continue;
        }
        $count += count($methods);
    }

    return $count;
}

function writeFile(string $path, string $contents): void
{
    $dir = dirname($path);
    if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
        throw new RuntimeException("No se pudo crear directorio {$dir}");
    }
    if (file_put_contents($path, $contents) === false) {
        throw new RuntimeException("No se pudo escribir {$path}");
    }
}

final class OpenApiYamlEncoder
{
    /**
     * @param array<string, mixed> $data
     */
    public static function encode(array $data): string
    {
        return self::dump($data, 0);
    }

    /**
     * @param mixed $value
     */
    private static function dump(mixed $value, int $indent): string
    {
        if (is_array($value)) {
            if ($value === []) {
                return "[]\n";
            }

            if (array_is_list($value)) {
                $out = '';
                foreach ($value as $item) {
                    if (!is_array($item)) {
                        $out .= str_repeat('  ', $indent) . '- ' . self::scalarInline($item) . "\n";
                        continue;
                    }

                    if (array_is_list($item)) {
                        $out .= str_repeat('  ', $indent) . "-\n";
                        $out .= self::dump($item, $indent + 1);
                        continue;
                    }

                    // Objetos en listas: estilo bloque (evita "name: X, description: Y" inválido en YAML).
                    if (count($item) === 1) {
                        $onlyKey = array_key_first($item);
                        $onlyVal = $item[$onlyKey];
                        if (!is_array($onlyVal)) {
                            $out .= str_repeat('  ', $indent) . '- ' . $onlyKey . ': ' . self::scalarInline($onlyVal) . "\n";
                            continue;
                        }
                    }

                    $out .= str_repeat('  ', $indent) . "-\n";
                    $out .= self::dumpMap($item, $indent + 1, false);
                }
                return $out;
            }

            return self::dumpMap($value, $indent, false);
        }

        return self::scalarInline($value) . "\n";
    }

    /**
     * @param array<string, mixed> $map
     */
    private static function dumpMap(array $map, int $indent, bool $nestedUnderDash): string
    {
        $out = '';
        foreach ($map as $key => $val) {
            $prefix = str_repeat('  ', $indent);
            if (is_array($val)) {
                if ($val === []) {
                    $out .= "{$prefix}{$key}: " . (array_is_list($val) ? "[]\n" : "{}\n");
                } elseif (array_is_list($val)) {
                    $out .= "{$prefix}{$key}:\n" . self::dump($val, $indent + 1);
                } else {
                    $out .= "{$prefix}{$key}:\n" . self::dumpMap($val, $indent + 1, false);
                }
            } else {
                $out .= "{$prefix}{$key}: " . self::scalarInline($val) . "\n";
            }
        }

        return $out;
    }

    private static function scalarInline(mixed $value): string
    {
        if ($value === null) {
            return 'null';
        }
        if (is_bool($value)) {
            return $value ? 'true' : 'false';
        }
        if (is_int($value) || is_float($value)) {
            return (string) $value;
        }

        $str = (string) $value;
        if ($str === '' || preg_match('/[:#\\[\\]{},"\'&*!|>%@`\n]/', $str)) {
            return '"' . str_replace(['\\', '"'], ['\\\\', '\\"'], $str) . '"';
        }

        return $str;
    }
}
