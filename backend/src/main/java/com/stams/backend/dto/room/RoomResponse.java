package com.stams.backend.dto.room;

import com.stams.backend.entity.enums.OccupancyMode;
import com.stams.backend.entity.enums.RoomType;

import java.util.List;

public record RoomResponse(
        Long id,
        Long propertyId,
        String propertyName,
        String name,
        RoomType type,
        OccupancyMode occupancyMode,
        Integer capacity,
        int occupied,
        long openIssueCount,
        List<StudentSummary> students
) {
}
