package com.stams.backend.controller;

import com.stams.backend.dto.upload.UploadResponse;
import com.stams.backend.service.PhotoStorageService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.Resource;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;

/** Issue photos. Uploading needs a signed-in student; viewing is public so images load without a token. */
@RestController
@RequestMapping("/api/uploads")
@RequiredArgsConstructor
public class UploadController {

    private final PhotoStorageService storage;

    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public UploadResponse upload(@RequestParam("file") MultipartFile file) {
        return new UploadResponse("/api/uploads/" + storage.store(file));
    }

    @GetMapping("/{name}")
    public ResponseEntity<Resource> get(@PathVariable String name) {
        Resource photo = storage.load(name);
        return ResponseEntity.ok()
                .contentType(MediaTypeFactory.getMediaType(photo).orElse(MediaType.APPLICATION_OCTET_STREAM))
                .cacheControl(CacheControl.maxAge(Duration.ofDays(30)).cachePublic())
                .body(photo);
    }
}
