package com.stams.backend.service;

import com.stams.backend.dto.auth.AuthResponse;
import com.stams.backend.dto.auth.LoginRequest;
import com.stams.backend.dto.auth.RegisterRequest;
import com.stams.backend.dto.user.UserResponse;
import com.stams.backend.entity.User;
import com.stams.backend.exception.ConflictException;
import com.stams.backend.exception.UnauthorizedException;
import com.stams.backend.repository.UserRepository;
import com.stams.backend.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new ConflictException("An account with this email already exists");
        }
        User user = User.builder()
                .name(request.name().trim())
                .email(email)
                .passwordHash(passwordEncoder.encode(request.password()))
                .role(request.role())
                .build();
        return toAuthResponse(userRepository.save(user));
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest request) {
        // Same message whether the email or the password is wrong, so the API doesn't reveal which emails exist.
        User user = userRepository.findByEmailIgnoreCase(normalizeEmail(request.email()))
                .filter(found -> passwordEncoder.matches(request.password(), found.getPasswordHash()))
                .orElseThrow(() -> new UnauthorizedException("Incorrect email or password"));
        return toAuthResponse(user);
    }

    private AuthResponse toAuthResponse(User user) {
        return new AuthResponse(jwtService.generateToken(user), "Bearer",
                jwtService.getExpirationMs() / 1000, UserResponse.from(user));
    }

    static String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
