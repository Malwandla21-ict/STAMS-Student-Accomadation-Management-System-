package com.stams.backend.controller;

import com.stams.backend.dto.issue.CreateIssueRequest;
import com.stams.backend.dto.issue.IssueResponse;
import com.stams.backend.dto.issue.UpdateIssueRequest;
import com.stams.backend.security.AuthUser;
import com.stams.backend.service.IssueService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.net.URI;
import java.util.List;

/**
 * Both roles. Who may create, update or nudge is set in SecurityConfig;
 * which issues you can see is decided per user in IssueService.
 */
@RestController
@RequestMapping("/api/issues")
@RequiredArgsConstructor
public class IssueController {

    private final IssueService issueService;

    /** Landlord: L1/L2 inbox. Student: S5 "My issues". */
    @GetMapping
    public List<IssueResponse> list(@AuthenticationPrincipal AuthUser me) {
        return issueService.listMine(me);
    }

    /** L3 / S6 issue detail with its timeline. */
    @GetMapping("/{issueId}")
    public IssueResponse get(@PathVariable Long issueId, @AuthenticationPrincipal AuthUser me) {
        return issueService.get(issueId, me);
    }

    /** S3 submit report (students only). */
    @PostMapping
    public ResponseEntity<IssueResponse> create(@Valid @RequestBody CreateIssueRequest request,
                                                @AuthenticationPrincipal AuthUser me) {
        IssueResponse created = issueService.create(request, me.id());
        return ResponseEntity.created(URI.create("/api/issues/" + created.id())).body(created);
    }

    /** L4 update status / priority / note (landlords only). */
    @PatchMapping("/{issueId}")
    public IssueResponse update(@PathVariable Long issueId, @Valid @RequestBody UpdateIssueRequest request,
                                @AuthenticationPrincipal AuthUser me) {
        return issueService.update(issueId, request, me.id());
    }

    /** S6a nudge the landlord (students only). */
    @PostMapping("/{issueId}/nudge")
    public IssueResponse nudge(@PathVariable Long issueId, @AuthenticationPrincipal AuthUser me) {
        return issueService.nudge(issueId, me.id());
    }
}
