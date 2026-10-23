package com.stams.backend.entity;

import com.stams.backend.entity.enums.IssueEventType;
import com.stams.backend.entity.enums.IssuePriority;
import com.stams.backend.entity.enums.IssueStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;

/**
 * One step on an issue's timeline: who did what, when, with an optional note.
 * Which of status / priority / nudgeNumber is filled depends on the type.
 */
@Entity
@Table(name = "issue_events")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(onlyExplicitlyIncluded = true)
public class IssueEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    @ToString.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "issue_id", nullable = false)
    private Issue issue;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @ToString.Include
    private IssueEventType type;

    /** Who did it: the student for REPORTED/NUDGED, the landlord for everything else. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "actor_id", nullable = false)
    private User actor;

    /** The status the issue moved to (REPORTED and STATUS_CHANGED). */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private IssueStatus status;

    /** The priority the issue moved to (PRIORITY_CHANGED). */
    @Enumerated(EnumType.STRING)
    @Column(length = 20)
    private IssuePriority priority;

    /** Optional message from the landlord to the student. */
    @Column(length = 500)
    private String note;

    /** 1 for the first nudge, 2 for the second... (NUDGED only). */
    private Integer nudgeNumber;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private Instant createdAt;
}
