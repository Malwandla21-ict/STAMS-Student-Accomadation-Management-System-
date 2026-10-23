package com.stams.backend.repository;

import com.stams.backend.entity.Issue;
import com.stams.backend.entity.enums.IssueStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface IssueRepository extends JpaRepository<Issue, Long> {

    long countByRoomIdAndStatusNot(Long roomId, IssueStatus status);

    long countByRoomPropertyIdAndStatusNot(Long propertyId, IssueStatus status);

    /** Total nudges across a property's issues that aren't resolved yet. */
    @Query("""
            select coalesce(sum(i.nudgeCount), 0) from Issue i
            where i.room.property.id = :propertyId and i.status <> :excluded
            """)
    long sumNudgesByPropertyIdAndStatusNot(@Param("propertyId") Long propertyId,
                                           @Param("excluded") IssueStatus excluded);

    /** Landlord inbox (L1/L2): every issue in any of their properties. */
    List<Issue> findByRoomPropertyLandlordIdOrderByCreatedAtDesc(Long landlordId);

    /** Student's "My issues" (S5). */
    List<Issue> findByReporterIdOrderByCreatedAtDesc(Long reporterId);

    /** Room detail (L8). */
    List<Issue> findByRoomIdOrderByCreatedAtDesc(Long roomId);
}
