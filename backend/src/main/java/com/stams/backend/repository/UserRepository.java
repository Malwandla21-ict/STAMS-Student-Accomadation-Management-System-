package com.stams.backend.repository;

import com.stams.backend.entity.User;
import com.stams.backend.entity.enums.Role;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);

    /** Registered users of a role whose email contains the search text (used by "Assign student"). */
    @Query("""
            select u from User u
            left join fetch u.room r
            left join fetch r.property
            where u.role = :role and lower(u.email) like lower(concat('%', :emailPart, '%'))
            order by u.email
            """)
    List<User> searchByRoleAndEmail(@Param("role") Role role,
                                    @Param("emailPart") String emailPart,
                                    Pageable pageable);

    long countByRoomId(Long roomId);

    long countByRoomPropertyId(Long propertyId);
}
