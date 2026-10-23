package com.stams.backend.dto.property;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.stams.backend.dto.room.RoomResponse;

import java.time.Instant;
import java.util.List;

/**
 * A property plus the numbers the Properties screens show (L5/L6).
 * "rooms" is only filled in on the single-property endpoint.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record PropertyResponse(
        Long id,
        String name,
        String addressLine1,
        String addressLine2,
        String city,
        String postalCode,
        long roomCount,
        long bedsFilled,
        long bedsTotal,
        long openIssueCount,
        long openIssueNudges,
        Instant createdAt,
        List<RoomResponse> rooms
) {
}
