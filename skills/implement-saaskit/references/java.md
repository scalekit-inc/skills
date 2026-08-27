# Scalekit Auth in Spring Boot

Scalekit acts as an OIDC provider. Spring Security's `oauth2-client` starter handles the full
authorization code flow — no custom filters needed.

## Required dependencies

Add to `pom.xml` (Spring Boot 3.2+, Java 17+):

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-client</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
<dependency>
    <groupId>com.scalekit</groupId>
    <artifactId>scalekit-sdk-java</artifactId>
    <version>2.0.4</version>
</dependency>
```

## Configuration

`src/main/resources/application.yml`:

```yaml
scalekit:
  env-url: ${SCALEKIT_ENVIRONMENT_URL}
  client-id: ${SCALEKIT_CLIENT_ID}
  client-secret: ${SCALEKIT_CLIENT_SECRET}
  redirect-uri: ${SCALEKIT_REDIRECT_URI:http://localhost:8080/login/oauth2/code/scalekit}

spring:
  security:
    oauth2:
      client:
        registration:
          scalekit:
            client-id: ${scalekit.client-id}
            client-secret: ${scalekit.client-secret}
            authorization-grant-type: authorization_code
            redirect-uri: ${scalekit.redirect-uri}
            scope: openid,profile,email,offline_access
            client-name: Scalekit
        provider:
          scalekit:
            issuer-uri: ${scalekit.env-url}
            authorization-uri: ${scalekit.env-url}/oauth/authorize
            token-uri: ${scalekit.env-url}/oauth/token
            user-info-uri: ${scalekit.env-url}/userinfo
            jwk-set-uri: ${scalekit.env-url}/keys
            user-name-attribute: sub
```

## Scalekit SDK bean

```java
@Configuration
public class ScalekitConfig {

    @Value("${scalekit.env-url}")
    private String envUrl;

    @Value("${scalekit.client-id}")
    private String clientId;

    @Value("${scalekit.client-secret}")
    private String clientSecret;

    @Bean
    public ScalekitClient scalekitClient() {
        return new ScalekitClient(envUrl, clientId, clientSecret);
    }
}
```

## Security filter chain

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http,
            ClientRegistrationRepository clientRegistrationRepository) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/", "/login", "/error", "/css/**", "/js/**").permitAll()
                .anyRequest().authenticated()
            )
            .oauth2Login(oauth2 -> oauth2
                .loginPage("/login")
                .defaultSuccessUrl("/dashboard", true)
            )
            .logout(logout -> logout
                .logoutSuccessHandler(oidcLogoutSuccessHandler(clientRegistrationRepository))
                .invalidateHttpSession(true)
                .clearAuthentication(true)
            );
        return http.build();
    }

    private LogoutSuccessHandler oidcLogoutSuccessHandler(
            ClientRegistrationRepository clientRegistrationRepository) {
        OidcClientInitiatedLogoutSuccessHandler handler =
                new OidcClientInitiatedLogoutSuccessHandler(clientRegistrationRepository);
        handler.setPostLogoutRedirectUri("{baseUrl}");
        return handler;
    }
}
```

## Accessing user identity in controllers

```java
@GetMapping("/dashboard")
public String dashboard(@AuthenticationPrincipal OidcUser oidcUser, Model model) {
    model.addAttribute("name",    oidcUser.getFullName());
    model.addAttribute("email",   oidcUser.getEmail());
    model.addAttribute("subject", oidcUser.getSubject());
    model.addAttribute("claims",  oidcUser.getClaims());
    return "dashboard";
}
```

## Application routes

| Route | Auth? | Notes |
|---|---|---|
| `/` | No | Home page |
| `/login` | No | Custom login page |
| `/dashboard` | Yes | Protected; redirects to login |
| `/oauth2/authorization/scalekit` | No | Starts OIDC flow |
| `/auth/callback` | No | Handled by Spring Security automatically |
| `/logout` | Yes | Triggers OIDC end-session |

## Scalekit Dashboard setup checklist

```
- [ ] Get Environment URL (e.g., https://your-env.scalekit.dev)
- [ ] Get Client ID and Client Secret from Settings > API Credentials
- [ ] Add allowed redirect URI: http://localhost:8080/login/oauth2/code/scalekit
- [ ] Optionally add post-logout redirect: http://localhost:8080
```

## Workflow

```
- [ ] Step 1: Add Maven dependencies
- [ ] Step 2: Add application.yml OAuth2 provider/registration config
- [ ] Step 3: Create ScalekitConfig bean
- [ ] Step 4: Create SecurityConfig filter chain
- [ ] Step 5: Inject @AuthenticationPrincipal OidcUser in protected controllers
- [ ] Step 6: Configure redirect URIs in Scalekit dashboard
- [ ] Step 7: Run app and verify login → dashboard → logout flow
```

## Troubleshooting

**JWKS timeout / JWT verification errors**: Spring Security fetches JWKS on every token validation. Increase the decoder timeout.

**Redirect URI mismatch**: The `redirect-uri` in `application.yml` must exactly match what is registered in the Scalekit dashboard.

**Enable debug logging**:

```yaml
logging:
  level:
    org.springframework.security.oauth2: TRACE
```

## Reference

- Full working example: [scalekit-inc/scalekit-springboot-auth-example](https://github.com/scalekit-inc/scalekit-springboot-auth-example)
- Scalekit docs: https://docs.scalekit.com

## Tactics

### SameSite=Lax on the session cookie

```yaml
server:
  servlet:
    session:
      cookie:
        same-site: lax
        http-only: true
        secure: true
```

### Deep link preservation

Remove `true` from `defaultSuccessUrl("/dashboard", true)` to respect saved-request redirect.

### CORS for browser clients

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration config = new CorsConfiguration();
    config.setAllowedOrigins(List.of("http://localhost:3000"));
    config.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
    config.setAllowedHeaders(List.of("*"));
    config.setAllowCredentials(true);
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", config);
    return source;
}
```

### AJAX: 401 instead of redirect

```java
.exceptionHandling(ex -> ex
    .authenticationEntryPoint((request, response, authException) -> {
        String accept = request.getHeader("Accept");
        if (accept != null && accept.contains("application/json")) {
            response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Authentication required");
        } else {
            response.sendRedirect("/login");
        }
    }))
```

### OIDC logout vs local logout

`OidcClientInitiatedLogoutSuccessHandler` calls the Scalekit end-session endpoint. Always use the OIDC handler — a plain `logoutSuccessUrl()` only clears the local session.
