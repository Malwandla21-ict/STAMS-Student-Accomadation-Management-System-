package com.stams.backend.controller;

import com.stams.backend.dto.room.StudentSearchResult;
import com.stams.backend.security.AuthUser;
import com.stams.backend.service.StudentService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/** Landlord only. */
@RestController
@RequestMapping("/api/students")
@RequiredArgsConstructor
public class StudentController {

    private final StudentService studentService;

    /** L10 "Search registered emails", e.g. GET /api/students/search?email=maya.t */
    @GetMapping("/search")
    public List<StudentSearchResult> search(@RequestParam String email, @AuthenticationPrincipal AuthUser me) {
        return studentService.searchByEmail(email, me.id());
    }
}
