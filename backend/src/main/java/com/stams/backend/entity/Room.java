package com.stams.backend.entity;

import com.stams.backend.entity.enums.OccupancyMode;
import com.stams.backend.entity.enums.RoomType;
import jakarta.persistence.*;
import lombok.*;

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
@ToString(exclude = {"property", "students", "issues"})
public class Room {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @EqualsAndHashCode.Include
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "property_id", nullable = false)
    private Property property;

    @Column(nullable = false)
    private String roomNumber;

    // BEDROOM, KITCHEN, BATHROOM, COMMON_AREA - what kind of space this is.
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RoomType type;

    // SINGLE, SHARED, COMMUNAL - how many students can occupy it, rather than
    // assuming one student per room.
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private OccupancyMode occupancyMode;

    // How many students this room can hold at once (relevant for SHARED/COMMUNAL).
    private Integer capacity;

    @Builder.Default
    @OneToMany(mappedBy = "room")
    private List<Student> students = new ArrayList<>();

    @Builder.Default
    @OneToMany(mappedBy = "room", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<Issue> issues = new ArrayList<>();
}
