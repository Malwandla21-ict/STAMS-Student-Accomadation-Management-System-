package com.stams.backend.exception;

/** 400 - the request itself is wrong in a way bean validation can't express. */
public class BadRequestException extends RuntimeException {
    public BadRequestException(String message) {
        super(message);
    }
}
