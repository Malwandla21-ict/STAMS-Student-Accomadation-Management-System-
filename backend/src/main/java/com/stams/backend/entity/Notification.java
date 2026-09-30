package com.stams.backend.entity;

import com.stams.backend.entity.enums.NotificationType;
import com.stams.backend.entity.enums.RecipientType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.LocalDateTime;

@Entity
@Table(name = "notifications")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(exclude = "issue")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "issue_id", nullable = false)
    private Issue issue;

    // Who this notification is for. Kept as a type + id pair rather than two
    // separate nullable foreign keys, since the recipient is either a
    // Landlord or a Student depending on recipientType.
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RecipientType recipientType;

    @Column(nullable = false)
    private Long recipientId;

    // NUDGE (student escalating to landlord) or STATUS_CHANGE (landlord
    // updating the student).
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private NotificationType type;

    @Column(nullable = false, length = 500)
    private String message;

    @Builder.Default
    @Column(nullable = false)
    private boolean isRead = false;

    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;
}
