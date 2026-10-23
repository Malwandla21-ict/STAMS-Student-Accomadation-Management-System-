package com.stams.backend.security;

import com.stams.backend.entity.enums.Role;

/**
 * The signed-in user for the current request. Controllers get it with
 * {@code @AuthenticationPrincipal AuthUser me}.
 */
public record AuthUser(Long id, String email, Role role) {
}
