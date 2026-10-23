package com.stams.backend.repository;

import com.stams.backend.entity.IssueEvent;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface IssueEventRepository extends JpaRepository<IssueEvent, Long> {

    List<IssueEvent> findByIssueIdOrderByCreatedAtAscIdAsc(Long issueId);
}
