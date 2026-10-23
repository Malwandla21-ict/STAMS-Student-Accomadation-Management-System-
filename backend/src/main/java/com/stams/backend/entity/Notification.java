package com.stams.backend.entity;

import com.stams.backend.entity.enums.IssueStatus;
import com.stams.backend.entity.enums.NotificationType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(onlyExplicitlyIncluded = true)
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    @ToString.Include
    private Long id;

    /** Who sees this notification. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;

    /** Who caused it ("Aisha Bello nudged you"). */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "actor_id")
    private User actor;

    /** The issue it's about. Null for notifications that aren't about an issue, e.g. ROOM_ASSIGNED. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "issue_id")
    private Issue issue;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @ToString.Include
    private NotificationType type;

    @Column(nullable = false)
    private String message;

    /** STATUS_CHANGE only: the status the issue moved to. */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private IssueStatus issueStatus;

    /** NUDGE only: 1 for the first nudge on the issue, 2 for the second... */
    private Integer nudgeNumber;

    @Builder.Default
    @Column(name = "is_read", nullable = false)
    private boolean read = false;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private Instant createdAt;
}
