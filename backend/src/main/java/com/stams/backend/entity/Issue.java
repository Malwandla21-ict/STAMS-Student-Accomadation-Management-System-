package com.stams.backend.entity;

import com.stams.backend.entity.enums.IssuePriority;
import com.stams.backend.entity.enums.IssueStatus;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;
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
@ToString(exclude = {"room", "student", "notifications"})
public class Issue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "room_id", nullable = false)
    private Room room;

    // Who reported it.
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @Column(nullable = false, length = 1000)
    private String description;

    // URL/path of the photo the student attached (storage handled by the
    // service layer, not this entity).
    private String photoUrl;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private IssueStatus status = IssueStatus.REPORTED;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    @Builder.Default
    private IssuePriority priority = IssuePriority.MEDIUM;

    // How many times the student has nudged the landlord about this issue.
    @Builder.Default
    @Column(nullable = false)
    private Integer nudgeCount = 0;

    private LocalDateTime lastNudgedAt;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    private LocalDateTime resolvedAt;

    @Builder.Default
    @OneToMany(mappedBy = "issue", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Notification> notifications = new ArrayList<>();
}
