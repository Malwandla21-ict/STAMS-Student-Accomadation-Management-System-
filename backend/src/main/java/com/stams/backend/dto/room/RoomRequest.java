package com.stams.backend.dto.room;

import com.stams.backend.entity.enums.OccupancyMode;
import com.stams.backend.entity.enums.RoomType;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/**
 * Body for creating or editing a room (screen L9).
 * capacity: leave out for SINGLE (always 1) and COMMUNAL (none); required for SHARED.
 */
public record RoomRequest(
        @NotBlank @Size(max = 60) String name,
        @NotNull RoomType type,
        @NotNull OccupancyMode occupancyMode,
        @Min(1) @Max(20) Integer capacity
) {
}
