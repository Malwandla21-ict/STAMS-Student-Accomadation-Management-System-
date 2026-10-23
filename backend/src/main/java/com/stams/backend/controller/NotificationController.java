package com.stams.backend.controller;

import com.stams.backend.dto.notification.NotificationResponse;
import com.stams.backend.security.AuthUser;
import com.stams.backend.service.NotificationService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** A4 / A5 Alerts - always the signed-in user's own. */
@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;

    @GetMapping
    public List<NotificationResponse> list(@AuthenticationPrincipal AuthUser me) {
        return notificationService.listMine(me.id());
    }

    @PostMapping("/{notificationId}/read")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markRead(@PathVariable Long notificationId, @AuthenticationPrincipal AuthUser me) {
        notificationService.markRead(notificationId, me.id());
    }

    @PostMapping("/read-all")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void markAllRead(@AuthenticationPrincipal AuthUser me) {
        notificationService.markAllRead(me.id());
    }
}
