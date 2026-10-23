package com.stams.backend.dto.room;

import com.fasterxml.jackson.annotation.JsonInclude;

/**
 * One row in "Assign student" search (L10).
 * The current room is only shown when it's in one of your own properties -
 * we don't reveal other landlords' properties.
 */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record StudentSearchResult(
        Long id,
        String name,
        String email,
        Placement placement,
        Long currentRoomId,
        String currentRoomName,
        String currentPropertyName
) {
    public enum Placement {
        /** Can be assigned. */
        NOT_IN_A_ROOM,
        /** In another of your rooms - assigning moves them. */
        IN_YOUR_PROPERTY,
        /** Lives in another landlord's room - can't be assigned. */
        WITH_ANOTHER_LANDLORD
    }
}
