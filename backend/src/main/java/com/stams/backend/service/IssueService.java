package com.stams.backend.service;

import com.stams.backend.dto.issue.CreateIssueRequest;
import com.stams.backend.dto.issue.IssueEventResponse;
import com.stams.backend.dto.issue.IssueResponse;
import com.stams.backend.dto.issue.UpdateIssueRequest;
import com.stams.backend.entity.Issue;
import com.stams.backend.entity.IssueEvent;
import com.stams.backend.entity.Notification;
import com.stams.backend.entity.Room;
import com.stams.backend.entity.User;
import com.stams.backend.entity.enums.IssueEventType;
import com.stams.backend.entity.enums.IssueStatus;
import com.stams.backend.entity.enums.NotificationType;
import com.stams.backend.entity.enums.Role;
import com.stams.backend.exception.BadRequestException;
import com.stams.backend.exception.ConflictException;
import com.stams.backend.exception.NotFoundException;
import com.stams.backend.repository.IssueRepository;
import com.stams.backend.repository.NotificationRepository;
import com.stams.backend.repository.RoomRepository;
import com.stams.backend.repository.UserRepository;
import com.stams.backend.security.AuthUser;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class IssueService {

    /** A student can nudge the landlord about an issue once per day. */
    static final Duration NUDGE_COOLDOWN = Duration.ofHours(24);

    private final IssueRepository issueRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;

    /** Landlords get every issue in their properties; students get the issues they reported. */
    @Transactional(readOnly = true)
    public List<IssueResponse> listMine(AuthUser me) {
        List<Issue> issues = me.role() == Role.LANDLORD
                ? issueRepository.findByRoomPropertyLandlordIdOrderByCreatedAtDesc(me.id())
                : issueRepository.findByReporterIdOrderByCreatedAtDesc(me.id());
        return issues.stream().map(IssueService::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public List<IssueResponse> listForRoom(Long roomId, Long landlordId) {
        roomRepository.findByIdAndPropertyLandlordId(roomId, landlordId)
                .orElseThrow(() -> new NotFoundException("Room not found"));
        return issueRepository.findByRoomIdOrderByCreatedAtDesc(roomId).stream().map(IssueService::toResponse).toList();
    }

    @Transactional(readOnly = true)
    public IssueResponse get(Long issueId, AuthUser me) {
        return toResponse(findVisible(issueId, me));
    }

    /** S3 submit. Students can report in their own room or any communal room of the property they live in. */
    public IssueResponse create(CreateIssueRequest request, Long studentId) {
        User student = userRepository.findById(studentId).orElseThrow(() -> new NotFoundException("Account not found"));
        Room home = student.getRoom();
        if (home == null) {
            throw new ConflictException("You can report issues once your landlord adds you to a room");
        }
        Room room = roomRepository.findById(request.roomId()).orElseThrow(() -> new NotFoundException("Room not found"));
        boolean ownRoom = room.getId().equals(home.getId());
        boolean sharedSpace = room.isCommunal() && room.getProperty().getId().equals(home.getProperty().getId());
        if (!ownRoom && !sharedSpace) {
            throw new BadRequestException("You can only report issues in your own room or your property's shared spaces");
        }

        Issue issue = Issue.builder()
                .room(room)
                .reporter(student)
                .title(request.title().trim())
                .description(request.description().trim())
                .photoUrls(request.photoUrls() == null ? new ArrayList<>() : new ArrayList<>(request.photoUrls()))
                .build();
        issue.getEvents().add(event(issue, IssueEventType.REPORTED, student).status(IssueStatus.REPORTED).build());
        issue = issueRepository.saveAndFlush(issue);

        notify(room.getProperty().getLandlord(), student, issue, NotificationType.NEW_ISSUE,
                student.getName() + " reported “" + issue.getTitle() + "”", null, null);
        return toResponse(issue);
    }

    /** L4 save: move the status forward, set the priority, optionally leave the student a note. */
    public IssueResponse update(Long issueId, UpdateIssueRequest request, Long landlordId) {
        Issue issue = issueRepository.findById(issueId)
                .filter(found -> isLandlordOf(found, landlordId))
                .orElseThrow(() -> new NotFoundException("Issue not found"));
        if (request.status().ordinal() < issue.getStatus().ordinal()) {
            throw new BadRequestException("An issue's status can only move forward");
        }
        User landlord = userRepository.getReferenceById(landlordId);
        String note = request.note() == null || request.note().isBlank() ? null : request.note().trim();
        boolean statusChanged = request.status() != issue.getStatus();

        if (request.priority() != issue.getPriority()) {
            issue.getEvents().add(event(issue, IssueEventType.PRIORITY_CHANGED, landlord).priority(request.priority()).build());
            issue.setPriority(request.priority());
        }
        if (statusChanged) {
            issue.getEvents().add(event(issue, IssueEventType.STATUS_CHANGED, landlord).status(request.status()).note(note).build());
            issue.setStatus(request.status());
            if (request.status() == IssueStatus.RESOLVED) {
                issue.setResolvedAt(Instant.now());
            }
        } else if (note != null) {
            issue.getEvents().add(event(issue, IssueEventType.NOTE_ADDED, landlord).note(note).build());
        }
        issue = issueRepository.saveAndFlush(issue);

        if (statusChanged) {
            notify(issue.getReporter(), landlord, issue, NotificationType.STATUS_CHANGE,
                    landlord.getName() + " moved “" + issue.getTitle() + "” to " + label(request.status()),
                    request.status(), null);
        }
        return toResponse(issue);
    }

    /** S6a: "Nudge Tom". Only the reporter, only while open, once per 24h. */
    public IssueResponse nudge(Long issueId, Long studentId) {
        Issue issue = issueRepository.findById(issueId)
                .filter(found -> found.getReporter().getId().equals(studentId))
                .orElseThrow(() -> new NotFoundException("Issue not found"));
        if (issue.getStatus() == IssueStatus.RESOLVED) {
            throw new ConflictException("Resolved issues can't be nudged");
        }
        Instant now = Instant.now();
        if (issue.getLastNudgedAt() != null && issue.getLastNudgedAt().plus(NUDGE_COOLDOWN).isAfter(now)) {
            throw new ConflictException("You can nudge once every 24 hours");
        }
        int number = issue.getNudgeCount() + 1;
        issue.setNudgeCount(number);
        issue.setLastNudgedAt(now);
        issue.getEvents().add(event(issue, IssueEventType.NUDGED, issue.getReporter()).nudgeNumber(number).build());
        issue = issueRepository.saveAndFlush(issue);

        notify(issue.getRoom().getProperty().getLandlord(), issue.getReporter(), issue, NotificationType.NUDGE,
                issue.getReporter().getName() + " nudged you about “" + issue.getTitle() + "”", null, number);
        return toResponse(issue);
    }

    // ---------------------------------------------------------------------

    /** The landlord who owns it or the student who reported it. Anyone else gets "not found". */
    private Issue findVisible(Long issueId, AuthUser me) {
        return issueRepository.findById(issueId)
                .filter(issue -> me.role() == Role.LANDLORD
                        ? isLandlordOf(issue, me.id())
                        : issue.getReporter().getId().equals(me.id()))
                .orElseThrow(() -> new NotFoundException("Issue not found"));
    }

    private static boolean isLandlordOf(Issue issue, Long landlordId) {
        return issue.getRoom().getProperty().getLandlord().getId().equals(landlordId);
    }

    private static IssueEvent.IssueEventBuilder event(Issue issue, IssueEventType type, User actor) {
        return IssueEvent.builder().issue(issue).type(type).actor(actor);
    }

    private void notify(User recipient, User actor, Issue issue, NotificationType type, String message,
                        IssueStatus status, Integer nudgeNumber) {
        notificationRepository.save(Notification.builder()
                .recipient(recipient)
                .actor(actor)
                .issue(issue)
                .type(type)
                .message(message)
                .issueStatus(status)
                .nudgeNumber(nudgeNumber)
                .build());
    }

    private static String label(IssueStatus status) {
        return switch (status) {
            case REPORTED -> "Reported";
            case ACKNOWLEDGED -> "Acknowledged";
            case IN_PROGRESS -> "In progress";
            case RESOLVED -> "Resolved";
        };
    }

    static IssueResponse toResponse(Issue issue) {
        Room room = issue.getRoom();
        return new IssueResponse(
                issue.getId(),
                issue.getTitle(),
                issue.getDescription(),
                issue.getStatus(),
                issue.getPriority(),
                room.getId(),
                room.getName(),
                room.getType(),
                room.getProperty().getId(),
                room.getProperty().getName(),
                issue.getReporter().getId(),
                issue.getReporter().getName(),
                room.getProperty().getLandlord().getName(),
                List.copyOf(issue.getPhotoUrls()),
                issue.getNudgeCount(),
                issue.getLastNudgedAt(),
                issue.getCreatedAt(),
                issue.getResolvedAt(),
                issue.getEvents().stream().map(IssueEventResponse::from).toList());
    }
}
