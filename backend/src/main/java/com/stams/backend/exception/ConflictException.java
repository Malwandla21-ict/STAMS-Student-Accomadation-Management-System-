package com.stams.backend.exception;

/** 409 - the request is valid but breaks a rule given the current state (e.g. room is full). */
public class ConflictException extends RuntimeException {
    public ConflictException(String message) {
        super(message);
    }
}
