package com.stams.backend.service;

import com.stams.backend.exception.BadRequestException;
import com.stams.backend.exception.NotFoundException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;
import java.util.regex.Pattern;

/**
 * Issue photos, saved to a folder on disk (app.uploads.dir). Files get random names, so a URL
 * can't be guessed from another one. Swap this for S3/Cloudinary when the app is deployed.
 */
@Service
public class PhotoStorageService {

    private static final Map<String, String> EXTENSIONS = Map.of(
            "image/jpeg", ".jpg",
            "image/png", ".png",
            "image/webp", ".webp",
            "image/heic", ".heic");
    private static final Pattern SAFE_NAME = Pattern.compile("^[0-9a-f-]{36}\\.(jpg|png|webp|heic)$");
    private static final long MAX_BYTES = 5 * 1024 * 1024;

    private final Path root;

    public PhotoStorageService(@Value("${app.uploads.dir:uploads}") String dir) {
        this.root = Path.of(dir).toAbsolutePath().normalize();
    }

    /** Returns the stored file name. */
    public String store(MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BadRequestException("Choose a photo to upload");
        }
        if (file.getSize() > MAX_BYTES) {
            throw new BadRequestException("Photos can be up to 5 MB");
        }
        String extension = EXTENSIONS.get(file.getContentType());
        if (extension == null) {
            throw new BadRequestException("Photos must be JPEG, PNG, WebP or HEIC");
        }
        String name = UUID.randomUUID() + extension;
        try (InputStream in = file.getInputStream()) {
            Files.createDirectories(root);
            Files.copy(in, root.resolve(name), StandardCopyOption.REPLACE_EXISTING);
        } catch (IOException e) {
            throw new UncheckedIOException("Couldn't save the photo", e);
        }
        return name;
    }

    public Resource load(String name) {
        if (!SAFE_NAME.matcher(name).matches()) {
            throw new NotFoundException("Photo not found");
        }
        Path path = root.resolve(name);
        if (!Files.isRegularFile(path)) {
            throw new NotFoundException("Photo not found");
        }
        return new FileSystemResource(path);
    }
}
