package com.stams.backend.service;

import com.stams.backend.dto.room.RoomRequest;
import com.stams.backend.dto.room.RoomResponse;
import com.stams.backend.dto.room.StudentSummary;
import com.stams.backend.entity.Notification;
import com.stams.backend.entity.Property;
import com.stams.backend.entity.Room;
import com.stams.backend.entity.User;
import com.stams.backend.entity.enums.IssueStatus;
import com.stams.backend.entity.enums.NotificationType;
import com.stams.backend.entity.enums.OccupancyMode;
import com.stams.backend.entity.enums.Role;
import com.stams.backend.exception.BadRequestException;
import com.stams.backend.exception.ConflictException;
import com.stams.backend.exception.NotFoundException;
import com.stams.backend.repository.IssueRepository;
import com.stams.backend.repository.NotificationRepository;
import com.stams.backend.repository.PropertyRepository;
import com.stams.backend.repository.RoomRepository;
import com.stams.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class RoomService {

    private final RoomRepository roomRepository;
    private final PropertyRepository propertyRepository;
    private final UserRepository userRepository;
    private final IssueRepository issueRepository;
    private final NotificationRepository notificationRepository;

    @Transactional(readOnly = true)
    public List<RoomResponse> listForProperty(Long propertyId, Long landlordId) {
        findOwnedProperty(propertyId, landlordId);
        return roomRepository.findByPropertyIdOrderByNameAsc(propertyId).stream()
                .map(this::toResponse)
                .toList();
    }

    @Transactional(readOnly = true)
    public RoomResponse get(Long roomId, Long landlordId) {
        return toResponse(findOwned(roomId, landlordId));
    }

    public RoomResponse create(Long propertyId, RoomRequest request, Long landlordId) {
        Property property = findOwnedProperty(propertyId, landlordId);
        Room room = Room.builder()
                .property(property)
                .name(request.name().trim())
                .type(request.type())
                .occupancyMode(request.occupancyMode())
                .capacity(resolveCapacity(request))
                .build();
        return toResponse(roomRepository.save(room));
    }

    public RoomResponse update(Long roomId, RoomRequest request, Long landlordId) {
        Room room = findOwned(roomId, landlordId);
        Integer newCapacity = resolveCapacity(request);
        int occupied = room.getResidents().size();

        if (request.occupancyMode() == OccupancyMode.COMMUNAL && occupied > 0) {
            throw new ConflictException("Remove the " + occupied + " student(s) in this room before making it communal");
        }
        if (newCapacity != null && occupied > newCapacity) {
            throw new ConflictException("This room has " + occupied + " students - remove some before lowering the capacity to " + newCapacity);
        }

        room.setName(request.name().trim());
        room.setType(request.type());
        room.setOccupancyMode(request.occupancyMode());
        room.setCapacity(newCapacity);
        return toResponse(room);
    }

    public void delete(Long roomId, Long landlordId) {
        Room room = findOwned(roomId, landlordId);
        if (!room.getResidents().isEmpty()) {
            throw new ConflictException("Remove the students in this room before deleting it");
        }
        if (issueRepository.countByRoomIdAndStatusNot(roomId, IssueStatus.RESOLVED) > 0) {
            throw new ConflictException("Resolve this room's open issues before deleting it");
        }
        roomRepository.delete(room);
    }

    /** Puts a student in this room. If they're in another of this landlord's rooms, they're moved. */
    public RoomResponse assignStudent(Long roomId, Long studentId, Long landlordId) {
        Room room = findOwned(roomId, landlordId);
        if (room.isCommunal()) {
            throw new ConflictException("Students can't be assigned to a communal room - everyone in the property can already report issues there");
        }

        User student = userRepository.findById(studentId)
                .filter(user -> user.getRole() == Role.STUDENT)
                .orElseThrow(() -> new NotFoundException("Student not found"));

        Room currentRoom = student.getRoom();
        if (currentRoom != null) {
            if (currentRoom.getId().equals(room.getId())) {
                throw new ConflictException(student.getName() + " is already in this room");
            }
            if (!currentRoom.getProperty().getLandlord().getId().equals(landlordId)) {
                throw new ConflictException("This student already lives in another landlord's room");
            }
        }
        if (room.getResidents().size() >= room.getCapacity()) {
            throw new ConflictException("Room is at capacity - remove a student or raise the capacity");
        }

        // Keep both sides of the relationship in step so the response is correct before the transaction commits.
        if (currentRoom != null) {
            currentRoom.getResidents().remove(student);
        }
        student.setRoom(room);
        room.getResidents().add(student);

        notificationRepository.save(Notification.builder()
                .recipient(student)
                .actor(userRepository.getReferenceById(landlordId))
                .type(NotificationType.ROOM_ASSIGNED)
                .message("You've been added to " + room.getName() + " at " + room.getProperty().getName())
                .build());

        return toResponse(room);
    }

    public RoomResponse removeStudent(Long roomId, Long studentId, Long landlordId) {
        Room room = findOwned(roomId, landlordId);
        User student = room.getResidents().stream()
                .filter(resident -> resident.getId().equals(studentId))
                .findFirst()
                .orElseThrow(() -> new NotFoundException("That student isn't in this room"));
        room.getResidents().remove(student);
        student.setRoom(null);
        return toResponse(room);
    }

    Room findOwned(Long roomId, Long landlordId) {
        return roomRepository.findByIdAndPropertyLandlordId(roomId, landlordId)
                .orElseThrow(() -> new NotFoundException("Room not found"));
    }

    private Property findOwnedProperty(Long propertyId, Long landlordId) {
        return propertyRepository.findByIdAndLandlordId(propertyId, landlordId)
                .orElseThrow(() -> new NotFoundException("Property not found"));
    }

    /** SINGLE is always 1 bed, SHARED needs 2+, COMMUNAL has no beds. */
    private static Integer resolveCapacity(RoomRequest request) {
        Integer capacity = request.capacity();
        return switch (request.occupancyMode()) {
            case SINGLE -> {
                if (capacity != null && capacity != 1) {
                    throw new BadRequestException("A single room always has a capacity of 1");
                }
                yield 1;
            }
            case SHARED -> {
                if (capacity == null || capacity < 2) {
                    throw new BadRequestException("A shared room needs a capacity of at least 2");
                }
                yield capacity;
            }
            case COMMUNAL -> null;
        };
    }

    RoomResponse toResponse(Room room) {
        List<StudentSummary> students = room.getResidents().stream()
                .sorted(Comparator.comparing(User::getName, String.CASE_INSENSITIVE_ORDER))
                .map(StudentSummary::from)
                .toList();
        return new RoomResponse(
                room.getId(),
                room.getProperty().getId(),
                room.getProperty().getName(),
                room.getName(),
                room.getType(),
                room.getOccupancyMode(),
                room.getCapacity(),
                students.size(),
                issueRepository.countByRoomIdAndStatusNot(room.getId(), IssueStatus.RESOLVED),
                students);
    }
}
