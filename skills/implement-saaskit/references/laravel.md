# Scalekit Auth — Laravel

Reference repo: [scalekit-inc/scalekit-laravel-auth-example](https://github.com/scalekit-inc/scalekit-laravel-auth-example)

## Project structure

```
app/
├── Services/
│   └── ScalekitClient.php          # Raw HTTP OAuth client (no PHP SDK)
├── Http/
│   ├── Controllers/
│   │   └── AuthController.php
│   └── Middleware/
│       ├── ScalekitAuth.php         # Session auth gate
│       ├── ScalekitPermission.php   # Per-route permission check
│       └── ScalekitTokenRefresh.php # Auto token refresh on every request

config/
└── scalekit.php                    # Reads from env via config('scalekit.*')

routes/
└── web.php                         # Named routes + middleware groups
```

## Environment variables

```env
SCALEKIT_ENVIRONMENT_URL=https://your-env.scalekit.com
SCALEKIT_CLIENT_ID=your-client-id
SCALEKIT_CLIENT_SECRET=your-client-secret
SCALEKIT_REDIRECT_URI=http://localhost:8000/auth/callback
```

> No official Scalekit PHP SDK exists. This app uses **Laravel's `Http` facade** with raw HTTP calls.

## Key methods (ScalekitClient service)

| Method | HTTP call | Auth |
|---|---|---|
| `getAuthorizationUrl($state)` | Builds `{env_url}/oauth/authorize?response_type=code&...` | None |
| `exchangeCodeForTokens($code)` | `POST {env_url}/oauth/token` with `grant_type=authorization_code` | Basic Auth |
| `refreshAccessToken($refreshToken)` | `POST {env_url}/oauth/token` with `grant_type=refresh_token` | Basic Auth |
| `validateTokenAndGetClaims($token)` | Manual base64 JWT decode — no signature verification | — |
| `hasPermission($token, $permission)` | Decodes JWT, checks permission claim chain | — |
| `logout($accessToken)` | Builds `{env_url}/oidc/logout?post_logout_redirect_uri=...` | None |

## Session storage schema

```php
session([
    'scalekit_user' => [
        'sub', 'email', 'name', 'given_name', 'family_name',
        'preferred_username',
        'claims'  // merged array of ALL claims
    ],
    'scalekit_tokens' => [
        'access_token', 'refresh_token', 'id_token',
        'expires_at', 'expires_in',
    ],
    'scalekit_roles'       => [],
    'scalekit_permissions' => [],
]);
```

## Auth flow

### Login (`GET /login`)

```php
$state = Str::random(32);
session(['oauth_state' => $state]);
$authUrl = $this->scalekitClient->getAuthorizationUrl($state);
return view('auth.login', ['auth_url' => $authUrl]);
```

### Callback (`GET /auth/callback`)

1. Validate `state` vs `session('oauth_state')` → 400 on mismatch
2. Exchange code for tokens
3. Decode ID token + access token claims, merge
4. Write session keys
5. Redirect to dashboard

### Logout (`GET|POST /logout`)

```php
$logoutUrl = $this->scalekitClient->logout($accessToken);
session()->flush();
return redirect($logoutUrl);
```

## Middleware

### Registration in `bootstrap/app.php` (Laravel 11)

```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'scalekit.auth'       => \App\Http\Middleware\ScalekitAuth::class,
        'scalekit.permission' => \App\Http\Middleware\ScalekitPermission::class,
    ]);
    $middleware->append(\App\Http\Middleware\ScalekitTokenRefresh::class);
})
```

### `ScalekitAuth` — session gate

Redirects to `auth.login` with `->with('next', $request->path())` if `scalekit_user` session key is missing.

### `ScalekitPermission` — parameterised permission check

Validates access token claims via `ScalekitClient::hasPermission()`. On failure: 403 view.

### `ScalekitTokenRefresh` — auto refresh on every request

Skipped paths: `login`, `auth/callback`, `logout`. Buffer: 5 minutes. On `invalid_grant`: flush session.

## Routes

```php
// Public
Route::get('/', [AuthController::class, 'home'])->name('auth.home');
Route::get('/login', [AuthController::class, 'login'])->name('auth.login');
Route::get('/auth/callback', [AuthController::class, 'callback'])->name('auth.callback');

// Protected group
Route::middleware(['scalekit.auth'])->group(function () {
    Route::get('/dashboard', [AuthController::class, 'dashboard'])->name('auth.dashboard');
    Route::match(['get', 'post'], '/logout', [AuthController::class, 'logout'])->name('auth.logout');
    Route::get('/sessions', [AuthController::class, 'sessions'])->name('auth.sessions');
    Route::post('/sessions/refresh-token', [AuthController::class, 'refreshToken'])->name('auth.refresh_token');

    Route::get('/organization/settings', [AuthController::class, 'organizationSettings'])
        ->middleware('scalekit.permission:organization:settings')
        ->name('auth.organization_settings');
});
```

## Install

```bash
composer require firebase/php-jwt  # Only if using JWT signature verification
php artisan key:generate
php artisan migrate
php artisan serve
```

Copy `.env.example` to `.env` and fill in the four `SCALEKIT_*` values.

## Tactics

### SameSite=Lax — required for OAuth callbacks

In `config/session.php`:

```php
'same_site' => 'lax',
'secure'    => env('SESSION_SECURE_COOKIE', false),
'http_only' => true,
```

### CSRF exclusion for the OAuth callback

GET callbacks are not subject to CSRF. For webhook POST endpoints, exclude them in `bootstrap/app.php`.

### Deep link preservation

```php
// In login
$next = $request->query('next', route('auth.dashboard'));
if (!str_starts_with($next, '/')) { $next = route('auth.dashboard'); }
session(['next' => $next]);

// In callback
$next = session()->pull('next', route('auth.dashboard'));
return redirect($next);
```

### Cache-Control: no-store on protected responses

```php
return response()
    ->view('auth.dashboard', ['user' => session('scalekit_user', [])])
    ->header('Cache-Control', 'no-store');
```

### CORS for JavaScript clients

In `config/cors.php`:

```php
'paths'               => ['api/*', 'auth/*', 'sessions/*'],
'allowed_origins'     => ['http://localhost:3000'],
'supports_credentials' => true,
```

### Session fixation after login

```php
session()->regenerate();
return redirect($next);
```

## Reference

- Full working example: [scalekit-inc/scalekit-laravel-auth-example](https://github.com/scalekit-inc/scalekit-laravel-auth-example)
- Scalekit docs: https://docs.scalekit.com
