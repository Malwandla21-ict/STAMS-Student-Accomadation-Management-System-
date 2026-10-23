package com.stams.backend.exception;

/** 404 - also used when something exists but belongs to someone else, so we don't reveal it. */
public class NotFoundException extends RuntimeException {
    public NotFoundException(String message) {
        super(message);
    }
}
