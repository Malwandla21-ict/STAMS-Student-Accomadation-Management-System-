package com.stams.backend.service;

import com.stams.backend.dto.room.StudentSearchResult;
import com.stams.backend.dto.room.StudentSearchResult.Placement;
import com.stams.backend.entity.Room;
import com.stams.backend.entity.User;
import com.stams.backend.entity.enums.Role;
import com.stams.backend.exception.BadRequestException;
import com.stams.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StudentService {

    private static final int MIN_SEARCH_LENGTH = 3;
    private static final int MAX_RESULTS = 10;

    private final UserRepository userRepository;

    /** "Assign student" search: registered students whose email contains the text typed. */
    @Transactional(readOnly = true)
    public List<StudentSearchResult> searchByEmail(String emailPart, Long landlordId) {
        String query = emailPart == null ? "" : emailPart.trim();
        if (query.length() < MIN_SEARCH_LENGTH) {
            throw new BadRequestException("Type at least " + MIN_SEARCH_LENGTH + " characters of the student's email");
        }
        return userRepository.searchByRoleAndEmail(Role.STUDENT, query, PageRequest.of(0, MAX_RESULTS)).stream()
                .map(student -> toResult(student, landlordId))
                .toList();
    }

    private static StudentSearchResult toResult(User student, Long landlordId) {
        Room room = student.getRoom();
        if (room == null) {
            return new StudentSearchResult(student.getId(), student.getName(), student.getEmail(),
                    Placement.NOT_IN_A_ROOM, null, null, null);
        }
        if (room.getProperty().getLandlord().getId().equals(landlordId)) {
            return new StudentSearchResult(student.getId(), student.getName(), student.getEmail(),
                    Placement.IN_YOUR_PROPERTY, room.getId(), room.getName(), room.getProperty().getName());
        }
        return new StudentSearchResult(student.getId(), student.getName(), student.getEmail(),
                Placement.WITH_ANOTHER_LANDLORD, null, null, null);
    }
}
