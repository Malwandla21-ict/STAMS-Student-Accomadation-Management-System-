package com.stams.backend.dto.issue;

import com.stams.backend.entity.enums.IssuePriority;
import com.stams.backend.entity.enums.IssueStatus;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** Landlord's "Update issue" sheet (L4). Status can only move forward; the note goes to the student. */
public record UpdateIssueRequest(
        @NotNull IssueStatus status,
        @NotNull IssuePriority priority,
        @Size(max = 500) String note
) {
}
