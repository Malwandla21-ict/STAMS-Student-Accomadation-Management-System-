package com.stams.backend.dto.issue;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.util.List;

/**
 * Student reports an issue (S2/S3). roomId is their own room or one of their property's communal rooms.
 * photoUrls come from POST /api/uploads.
 */
public record CreateIssueRequest(
        @NotNull Long roomId,
        @NotBlank @Size(max = 120) String title,
        @NotBlank @Size(min = 10, max = 500, message = "must be 10 to 500 characters") String description,
        @Size(max = 3, message = "can have at most 3 photos") List<@NotBlank @Size(max = 500) String> photoUrls
) {
}
