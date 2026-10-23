package com.stams.backend.entity;

import com.stams.backend.entity.enums.IssuePriority;
import com.stams.backend.entity.enums.IssueStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "issues")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(onlyExplicitlyIncluded = true)
public class Issue {

    public static final int MAX_PHOTOS = 3;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    @ToString.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    /** The student who reported it. */
    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "reporter_id", nullable = false)
    private User reporter;

    @Column(nullable = false, length = 120)
    @ToString.Include
    private String title;

    @Column(nullable = false, length = 500)
    private String description;

    /** Up to {@link #MAX_PHOTOS} photo URLs, in the order the student added them. */
    @Builder.Default
    @ElementCollection
    @CollectionTable(name = "issue_photos", joinColumns = @JoinColumn(name = "issue_id"))
    @OrderColumn(name = "position")
    @Column(name = "url", nullable = false, length = 500)
    private List<String> photoUrls = new ArrayList<>();

    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    @ToString.Include
    private IssueStatus status = IssueStatus.REPORTED;

    /** The landlord sets this; new reports start at MEDIUM. */
    @Builder.Default
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private IssuePriority priority = IssuePriority.MEDIUM;

    /** Kept on the issue (not just counted from events) so lists can sort by it cheaply. */
    @Builder.Default
    @Column(nullable = false)
    private int nudgeCount = 0;

    private Instant lastNudgedAt;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(nullable = false)
    private Instant updatedAt;

    private Instant resolvedAt;

    /** The timeline: report, status changes, notes and nudges, oldest first. */
    @Builder.Default
    @OneToMany(mappedBy = "issue", cascade = CascadeType.ALL, orphanRemoval = true)
    @OrderBy("createdAt ASC, id ASC")
    private List<IssueEvent> events = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "issue", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Notification> notifications = new ArrayList<>();
}
