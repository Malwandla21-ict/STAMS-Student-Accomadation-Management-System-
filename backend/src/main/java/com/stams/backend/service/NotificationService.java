package com.stams.backend.service;

import com.stams.backend.dto.notification.NotificationResponse;
import com.stams.backend.entity.Issue;
import com.stams.backend.entity.Notification;
import com.stams.backend.entity.Room;
import com.stams.backend.exception.NotFoundException;
import com.stams.backend.repository.NotificationRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/** Alerts (A4/A5). Everyone only ever sees notifications addressed to them. */
@Service
@RequiredArgsConstructor
@Transactional
public class NotificationService {

    private final NotificationRepository notificationRepository;

    @Transactional(readOnly = true)
    public List<NotificationResponse> listMine(Long userId) {
        return notificationRepository.findByRecipientIdOrderByCreatedAtDesc(userId).stream()
                .map(NotificationService::toResponse)
                .toList();
    }

    public void markRead(Long notificationId, Long userId) {
        notificationRepository.findByIdAndRecipientId(notificationId, userId)
                .orElseThrow(() -> new NotFoundException("Notification not found"))
                .setRead(true);
    }

    public void markAllRead(Long userId) {
        notificationRepository.markAllRead(userId);
    }

    private static NotificationResponse toResponse(Notification n) {
        Issue issue = n.getIssue();
        // Issue alerts name the issue's room; "you've been added to a room" names the recipient's room.
        Room room = issue != null ? issue.getRoom() : n.getRecipient().getRoom();
        return new NotificationResponse(
                n.getId(),
                n.getType(),
                n.getMessage(),
                n.isRead(),
                n.getCreatedAt(),
                n.getActor() == null ? null : n.getActor().getName(),
                issue == null ? null : issue.getId(),
                issue == null ? null : issue.getTitle(),
                room == null ? null : room.getName(),
                room == null ? null : room.getProperty().getName(),
                n.getIssueStatus(),
                n.getNudgeNumber());
    }
}
