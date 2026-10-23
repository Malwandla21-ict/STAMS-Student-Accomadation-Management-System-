package com.stams.backend.controller;

import com.stams.backend.dto.issue.IssueResponse;
import com.stams.backend.dto.room.AssignStudentRequest;
import com.stams.backend.dto.room.RoomRequest;
import com.stams.backend.dto.room.RoomResponse;
import com.stams.backend.security.AuthUser;
import com.stams.backend.service.IssueService;
import com.stams.backend.service.RoomService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/** Landlord only. Rooms are created under a property - see PropertyController. */
@RestController
@RequestMapping("/api/rooms")
@RequiredArgsConstructor
public class RoomController {

    private final RoomService roomService;
    private final IssueService issueService;

    /** L8 Room detail. */
    @GetMapping("/{roomId}")
    public RoomResponse get(@PathVariable Long roomId, @AuthenticationPrincipal AuthUser me) {
        return roomService.get(roomId, me.id());
    }

    /** L8 "Issues in this room". */
    @GetMapping("/{roomId}/issues")
    public List<IssueResponse> issues(@PathVariable Long roomId, @AuthenticationPrincipal AuthUser me) {
        return issueService.listForRoom(roomId, me.id());
    }

    /** L9 Edit room. */
    @PutMapping("/{roomId}")
    public RoomResponse update(@PathVariable Long roomId, @Valid @RequestBody RoomRequest request,
                               @AuthenticationPrincipal AuthUser me) {
        return roomService.update(roomId, request, me.id());
    }

    @DeleteMapping("/{roomId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long roomId, @AuthenticationPrincipal AuthUser me) {
        roomService.delete(roomId, me.id());
    }

    /** L10 Assign (or move) a student into this room. */
    @PostMapping("/{roomId}/students")
    public RoomResponse assignStudent(@PathVariable Long roomId, @Valid @RequestBody AssignStudentRequest request,
                                      @AuthenticationPrincipal AuthUser me) {
        return roomService.assignStudent(roomId, request.studentId(), me.id());
    }

    /** L8 Remove a student from this room. */
    @DeleteMapping("/{roomId}/students/{studentId}")
    public RoomResponse removeStudent(@PathVariable Long roomId, @PathVariable Long studentId,
                                      @AuthenticationPrincipal AuthUser me) {
        return roomService.removeStudent(roomId, studentId, me.id());
    }
}
