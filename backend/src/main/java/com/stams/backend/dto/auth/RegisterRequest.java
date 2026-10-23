package com.stams.backend.dto.auth;

import com.stams.backend.entity.enums.Role;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank @Size(max = 100) String name,
        @NotBlank @Email @Size(max = 255) String email,
        // BCrypt only uses the first 72 bytes, so cap it there.
        @NotBlank @Size(min = 8, max = 72, message = "must be 8 to 72 characters") String password,
        @NotNull(message = "must be LANDLORD or STUDENT") Role role
) {
}
