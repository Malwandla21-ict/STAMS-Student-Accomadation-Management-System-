package com.stams.backend.dto.issue;

import com.stams.backend.entity.enums.IssuePriority;
import com.stams.backend.entity.enums.IssueStatus;
import com.stams.backend.entity.enums.RoomType;

import java.time.Instant;
import java.util.List;

/** One issue as both apps show it: the card fields plus the full timeline (oldest first). */
public record IssueResponse(
        Long id,
        String title,
        String description,
        IssueStatus status,
        IssuePriority priority,
        Long roomId,
        String roomName,
        RoomType roomType,
        Long propertyId,
        String propertyName,
        Long reporterId,
        String reporterName,
        String landlordName,
        List<String> photoUrls,
        int nudgeCount,
        Instant lastNudgedAt,
        Instant createdAt,
        Instant resolvedAt,
        List<IssueEventResponse> events
) {
}
