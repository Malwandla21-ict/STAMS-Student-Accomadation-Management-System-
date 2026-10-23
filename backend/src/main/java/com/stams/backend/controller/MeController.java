package com.stams.backend.controller;

import com.stams.backend.dto.student.MyRoomResponse;
import com.stams.backend.dto.user.UserResponse;
import com.stams.backend.security.AuthUser;
import com.stams.backend.service.MyRoomService;
import com.stams.backend.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/me")
@RequiredArgsConstructor
public class MeController {

    private final UserService userService;
    private final MyRoomService myRoomService;

    /** The signed-in user's account - the app calls this on launch to check the saved token still works. */
    @GetMapping
    public UserResponse me(@AuthenticationPrincipal AuthUser me) {
        return userService.getProfile(me.id());
    }

    /** S1 / S2: the student's room and shared spaces. 204 No Content while they aren't in a room yet (S1u). */
    @GetMapping("/room")
    public ResponseEntity<MyRoomResponse> myRoom(@AuthenticationPrincipal AuthUser me) {
        return myRoomService.getMyRoom(me.id())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }
}
