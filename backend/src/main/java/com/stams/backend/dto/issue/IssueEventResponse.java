package com.stams.backend.dto.issue;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.stams.backend.entity.IssueEvent;
import com.stams.backend.entity.enums.IssueEventType;
import com.stams.backend.entity.enums.IssuePriority;
import com.stams.backend.entity.enums.IssueStatus;

import java.time.Instant;

@JsonInclude(JsonInclude.Include.NON_NULL)
public record IssueEventResponse(
        Long id,
        IssueEventType type,
        Long actorId,
        String actorName,
        IssueStatus status,
        IssuePriority priority,
        String note,
        Integer nudgeNumber,
        Instant createdAt
) {
    public static IssueEventResponse from(IssueEvent event) {
        return new IssueEventResponse(event.getId(), event.getType(), event.getActor().getId(), event.getActor().getName(),
                event.getStatus(), event.getPriority(), event.getNote(), event.getNudgeNumber(), event.getCreatedAt());
    }
}
