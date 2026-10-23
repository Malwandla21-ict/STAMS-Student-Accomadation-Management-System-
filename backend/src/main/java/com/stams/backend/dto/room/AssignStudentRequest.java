package com.stams.backend.dto.room;

import jakarta.validation.constraints.NotNull;

public record AssignStudentRequest(@NotNull Long studentId) {
}
