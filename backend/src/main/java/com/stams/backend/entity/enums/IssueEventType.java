package com.stams.backend.entity.enums;

/** One entry on an issue's timeline. */
public enum IssueEventType {
    REPORTED,
    STATUS_CHANGED,
    PRIORITY_CHANGED,
    NOTE_ADDED,
    NUDGED
}
