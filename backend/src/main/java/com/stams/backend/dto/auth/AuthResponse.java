package com.stams.backend.dto.auth;

import com.stams.backend.dto.user.UserResponse;

/** Returned by register and login. The app stores the token and sends it on every request. */
public record AuthResponse(
        String token,
        String tokenType,
        long expiresInSeconds,
        UserResponse user
) {
}
