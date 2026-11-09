<?php

// Origins come from env so production can be locked down (comma-separated).
// Flutter Web dev servers use random ports, so a pattern is allowed only in local dev.
return [
    'paths' => ['api/*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    'allowed_origins' => array_values(array_filter(explode(',', env('CORS_ALLOWED_ORIGINS', 'http://localhost:3000')))),
    'allowed_origins_patterns' => env('APP_ENV') === 'local' ? ['#^http://(localhost|127\.0\.0\.1):\d+$#'] : [],
    'allowed_headers' => ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    'exposed_headers' => [],
    'max_age' => 600,
    'supports_credentials' => false,
];
