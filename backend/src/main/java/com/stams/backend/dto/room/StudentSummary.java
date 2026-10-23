package com.stams.backend.dto.room;

import com.stams.backend.entity.User;

public record StudentSummary(Long id, String name, String email) {
    public static StudentSummary from(User user) {
        return new StudentSummary(user.getId(), user.getName(), user.getEmail());
    }
}
