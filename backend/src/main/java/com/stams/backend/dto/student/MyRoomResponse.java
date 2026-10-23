package com.stams.backend.dto.student;

import com.stams.backend.dto.room.RoomResponse;
import com.stams.backend.dto.room.StudentSummary;

import java.util.List;

/** The student's home screen (S1) and "Where is it?" step (S2): their room and the property's shared spaces. */
public record MyRoomResponse(
        RoomResponse room,
        String propertyName,
        String landlordName,
        List<StudentSummary> roommates,
        List<RoomResponse> sharedSpaces
) {
}
