package com.stams.backend.exception;

/** 401 - e.g. wrong email or password at login. */
public class UnauthorizedException extends RuntimeException {
    public UnauthorizedException(String message) {
        super(message);
    }
}
