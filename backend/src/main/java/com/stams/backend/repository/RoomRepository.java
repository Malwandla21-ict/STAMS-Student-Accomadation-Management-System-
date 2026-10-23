package com.stams.backend.repository;

import com.stams.backend.entity.Room;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface RoomRepository extends JpaRepository<Room, Long> {

    List<Room> findByPropertyIdOrderByNameAsc(Long propertyId);

    /** Looks a room up only if its property belongs to this landlord. */
    Optional<Room> findByIdAndPropertyLandlordId(Long id, Long landlordId);

    long countByPropertyId(Long propertyId);

    /** Total beds in a property. Communal rooms have no capacity, so SUM skips them. */
    @Query("select coalesce(sum(r.capacity), 0) from Room r where r.property.id = :propertyId")
    long sumCapacityByPropertyId(@Param("propertyId") Long propertyId);
}
