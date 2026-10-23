package com.stams.backend.entity;

import com.stams.backend.entity.enums.OccupancyMode;
import com.stams.backend.entity.enums.RoomType;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;

import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "rooms")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
@EqualsAndHashCode(onlyExplicitlyIncluded = true)
@ToString(onlyExplicitlyIncluded = true)
public class Room {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    @ToString.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "property_id", nullable = false)
    private Property property;

    /** "Room 2", "Bathroom A", "Kitchen"... */
    @Column(nullable = false, length = 60)
    @ToString.Include
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private RoomType type;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private OccupancyMode occupancyMode;

    /** Number of beds. 1 for SINGLE, 2+ for SHARED, null for COMMUNAL. */
    private Integer capacity;

    @CreationTimestamp
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    /** Students living in this room (users whose room points here). */
    @Builder.Default
    @OneToMany(mappedBy = "room")
    @OrderBy("name ASC")
    private List<User> residents = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "room", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Issue> issues = new ArrayList<>();

    public boolean isCommunal() {
        return occupancyMode == OccupancyMode.COMMUNAL;
    }
}
