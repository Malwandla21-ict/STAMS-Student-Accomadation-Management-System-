package com.stams.backend.entity.enums;

public enum NotificationType {
    /** Student -> landlord: a new issue was reported in one of your properties. */
    NEW_ISSUE,
    /** Student -> landlord: "please look at this issue". */
    NUDGE,
    /** Landlord -> student: the issue moved to a new status. */
    STATUS_CHANGE,
    /** Landlord -> student: you've been placed in a room. */
    ROOM_ASSIGNED
}
