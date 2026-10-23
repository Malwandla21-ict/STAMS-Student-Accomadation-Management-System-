package com.stams.backend.service;

import com.stams.backend.dto.property.PropertyRequest;
import com.stams.backend.dto.property.PropertyResponse;
import com.stams.backend.dto.room.RoomResponse;
import com.stams.backend.entity.Property;
import com.stams.backend.entity.enums.IssueStatus;
import com.stams.backend.exception.ConflictException;
import com.stams.backend.exception.NotFoundException;
import com.stams.backend.repository.IssueRepository;
import com.stams.backend.repository.PropertyRepository;
import com.stams.backend.repository.RoomRepository;
import com.stams.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Transactional
public class PropertyService {

    private final PropertyRepository propertyRepository;
    private final RoomRepository roomRepository;
    private final UserRepository userRepository;
    private final IssueRepository issueRepository;
    private final RoomService roomService;

    @Transactional(readOnly = true)
    public List<PropertyResponse> listMine(Long landlordId) {
        return propertyRepository.findByLandlordIdOrderByNameAsc(landlordId).stream()
                .map(property -> toResponse(property, null))
                .toList();
    }

    @Transactional(readOnly = true)
    public PropertyResponse getMine(Long propertyId, Long landlordId) {
        Property property = findOwned(propertyId, landlordId);
        List<RoomResponse> rooms = roomService.listForProperty(propertyId, landlordId);
        return toResponse(property, rooms);
    }

    public PropertyResponse create(PropertyRequest request, Long landlordId) {
        Property property = new Property();
        property.setLandlord(userRepository.getReferenceById(landlordId));
        apply(property, request);
        return toResponse(propertyRepository.save(property), List.of());
    }

    public PropertyResponse update(Long propertyId, PropertyRequest request, Long landlordId) {
        Property property = findOwned(propertyId, landlordId);
        apply(property, request);
        return toResponse(property, null);
    }

    public void delete(Long propertyId, Long landlordId) {
        Property property = findOwned(propertyId, landlordId);
        if (userRepository.countByRoomPropertyId(propertyId) > 0) {
            throw new ConflictException("Move or remove the students living here before deleting this property");
        }
        if (issueRepository.countByRoomPropertyIdAndStatusNot(propertyId, IssueStatus.RESOLVED) > 0) {
            throw new ConflictException("Resolve this property's open issues before deleting it");
        }
        propertyRepository.delete(property);
    }

    /** Other landlords' properties are reported as "not found" rather than "forbidden", so ids can't be probed. */
    Property findOwned(Long propertyId, Long landlordId) {
        return propertyRepository.findByIdAndLandlordId(propertyId, landlordId)
                .orElseThrow(() -> new NotFoundException("Property not found"));
    }

    private static void apply(Property property, PropertyRequest request) {
        property.setName(request.name().trim());
        property.setAddressLine1(request.addressLine1().trim());
        property.setAddressLine2(blankToNull(request.addressLine2()));
        property.setCity(request.city().trim());
        property.setPostalCode(request.postalCode().trim().toUpperCase());
    }

    private PropertyResponse toResponse(Property property, List<RoomResponse> rooms) {
        Long id = property.getId();
        return new PropertyResponse(
                id,
                property.getName(),
                property.getAddressLine1(),
                property.getAddressLine2(),
                property.getCity(),
                property.getPostalCode(),
                roomRepository.countByPropertyId(id),
                userRepository.countByRoomPropertyId(id),
                roomRepository.sumCapacityByPropertyId(id),
                issueRepository.countByRoomPropertyIdAndStatusNot(id, IssueStatus.RESOLVED),
                issueRepository.sumNudgesByPropertyIdAndStatusNot(id, IssueStatus.RESOLVED),
                property.getCreatedAt(),
                rooms);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
