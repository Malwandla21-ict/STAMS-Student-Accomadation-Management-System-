package com.stams.backend.dto.notification;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.stams.backend.entity.enums.IssueStatus;
import com.stams.backend.entity.enums.NotificationType;

import java.time.Instant;

/** One row on the Alerts screen (A4/A5). */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record NotificationResponse(
        Long id,
        NotificationType type,
        String message,
        boolean read,
        Instant createdAt,
        String actorName,
        Long issueId,
        String issueTitle,
        String roomName,
        String propertyName,
        IssueStatus status,
        Integer nudgeNumber
) {
}
