package com.stams.backend.dto.user;

import com.stams.backend.entity.User;
import com.stams.backend.entity.enums.Role;

import java.time.Instant;

/** Public view of an account - never includes the password hash. */
public record UserResponse(
        Long id,
        String name,
        String email,
        Role role,
        String phone,
        Instant createdAt
) {
    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getEmail(), user.getRole(),
                user.getPhone(), user.getCreatedAt());
    }
}
