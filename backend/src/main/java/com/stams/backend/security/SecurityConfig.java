package com.stams.backend.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.stams.backend.exception.ApiError;
import com.stams.backend.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.io.IOException;
import java.time.Instant;
import java.util.List;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http,
                                                   JwtService jwtService,
                                                   UserRepository userRepository,
                                                   ObjectMapper objectMapper) throws Exception {
        http
                // A token-based API: no cookies, sessions, login pages or CSRF tokens.
                // Lets the Flutter web app (a different origin) call the API - see corsConfigurationSource.
                .cors(Customizer.withDefaults())
                .csrf(AbstractHttpConfigurer::disable)
                .httpBasic(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable)
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/**", "/error").permitAll()
                        // Photos are fetched by <img>/Image.network, which can't send the token. Names are random UUIDs.
                        .requestMatchers(HttpMethod.GET, "/api/uploads/*").permitAll()
                        .requestMatchers("/api/properties/**", "/api/rooms/**", "/api/students/**").hasRole("LANDLORD")
                        .requestMatchers(HttpMethod.POST, "/api/issues", "/api/issues/*/nudge", "/api/uploads").hasRole("STUDENT")
                        .requestMatchers(HttpMethod.PATCH, "/api/issues/*").hasRole("LANDLORD")
                        .anyRequest().authenticated())
                .exceptionHandling(errors -> errors
                        .authenticationEntryPoint((request, response, ex) -> writeError(objectMapper, request, response,
                                HttpStatus.UNAUTHORIZED, "Sign in to continue - send a valid token as 'Authorization: Bearer <token>'"))
                        .accessDeniedHandler((request, response, ex) -> writeError(objectMapper, request, response,
                                HttpStatus.FORBIDDEN, "Your account type can't do this")))
                .addFilterBefore(new JwtAuthenticationFilter(jwtService, userRepository),
                        UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    /**
     * Which browser origins may call the API. Defaults to any localhost port, which is what
     * `flutter run -d chrome` uses. Add real domains with app.cors.allowed-origin-patterns.
     * (Mobile apps don't send an Origin, so this only matters for the web build.)
     */
    @Bean
    public CorsConfigurationSource corsConfigurationSource(
            @Value("${app.cors.allowed-origin-patterns:http://localhost:[*],http://127.0.0.1:[*]}") List<String> origins) {
        CorsConfiguration config = new CorsConfiguration();
        config.setAllowedOriginPatterns(origins);
        config.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        config.setAllowedHeaders(List.of("Authorization", "Content-Type"));
        config.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", config);
        return source;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    private static void writeError(ObjectMapper objectMapper, HttpServletRequest request, HttpServletResponse response,
                                   HttpStatus status, String message) throws IOException {
        ApiError body = new ApiError(Instant.now(), status.value(), status.getReasonPhrase(), message,
                request.getRequestURI(), null);
        response.setStatus(status.value());
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        objectMapper.writeValue(response.getOutputStream(), body);
    }
}
