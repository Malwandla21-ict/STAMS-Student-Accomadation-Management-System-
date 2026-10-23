package com.stams.backend.entity.enums;

public enum OccupancyMode {
    /** One student, capacity is always 1. */
    SINGLE,
    /** Several students share it, capacity 2 or more. */
    SHARED,
    /** Kitchens, bathrooms, lounges: nobody is assigned, every student in the property can use it. */
    COMMUNAL
}
