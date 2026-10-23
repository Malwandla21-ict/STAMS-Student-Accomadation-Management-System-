package com.stams.backend.repository;

import com.stams.backend.entity.Property;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PropertyRepository extends JpaRepository<Property, Long> {

    List<Property> findByLandlordIdOrderByNameAsc(Long landlordId);

    /** Looks a property up only if it belongs to this landlord. */
    Optional<Property> findByIdAndLandlordId(Long id, Long landlordId);
}
