package com.stams.backend.dto.property;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Body for creating or editing a property (screen L7). */
public record PropertyRequest(
        @NotBlank @Size(max = 100) String name,
        @NotBlank @Size(max = 150) String addressLine1,
        @Size(max = 150) String addressLine2,
        @NotBlank @Size(max = 100) String city,
        @NotBlank @Size(max = 20) String postalCode
) {
}
