package com.stams.backend.dto.upload;

/** Where an uploaded photo can be fetched from, e.g. "/api/uploads/3f2a...c1.jpg". */
public record UploadResponse(String url) {
}
