package com.stams.backend.service;

import com.stams.backend.dto.room.StudentSummary;
import com.stams.backend.dto.student.MyRoomResponse;
import com.stams.backend.entity.Room;
import com.stams.backend.entity.User;
import com.stams.backend.entity.enums.Role;
import com.stams.backend.exception.BadRequestException;
import com.stams.backend.exception.NotFoundException;
import com.stams.backend.repository.RoomRepository;
import com.stams.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Comparator;
import java.util.Optional;

/** The signed-in student's room, roommates, landlord and the shared spaces they can report in. */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class MyRoomService {

    private final UserRepository userRepository;
    private final RoomRepository roomRepository;
    private final RoomService roomService;

    /** Empty while the student hasn't been assigned to a room yet (S1u). */
    public Optional<MyRoomResponse> getMyRoom(Long userId) {
        User me = userRepository.findById(userId).orElseThrow(() -> new NotFoundException("Account not found"));
        if (me.getRole() != Role.STUDENT) {
            throw new BadRequestException("Only students live in a room");
        }
        Room room = me.getRoom();
        if (room == null) {
            return Optional.empty();
        }
        return Optional.of(new MyRoomResponse(
                roomService.toResponse(room),
                room.getProperty().getName(),
                room.getProperty().getLandlord().getName(),
                room.getResidents().stream()
                        .filter(resident -> !resident.getId().equals(userId))
                        .sorted(Comparator.comparing(User::getName, String.CASE_INSENSITIVE_ORDER))
                        .map(StudentSummary::from)
                        .toList(),
                roomRepository.findByPropertyIdOrderByNameAsc(room.getProperty().getId()).stream()
                        .filter(Room::isCommunal)
                        .map(roomService::toResponse)
                        .toList()));
    }
}
