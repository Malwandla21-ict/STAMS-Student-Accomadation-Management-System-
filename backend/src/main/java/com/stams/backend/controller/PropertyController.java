package com.stams.backend.controller;

import com.stams.backend.dto.property.PropertyRequest;
import com.stams.backend.dto.property.PropertyResponse;
import com.stams.backend.dto.room.RoomRequest;
import com.stams.backend.dto.room.RoomResponse;
import com.stams.backend.security.AuthUser;
import com.stams.backend.service.PropertyService;
import com.stams.backend.service.RoomService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;

/** Landlord only (see SecurityConfig). Every lookup is limited to the signed-in landlord's own properties. */
@RestController
@RequestMapping("/api/properties")
@RequiredArgsConstructor
public class PropertyController {

    private final PropertyService propertyService;
    private final RoomService roomService;

    /** L5 Properties. */
    @GetMapping
    public List<PropertyResponse> list(@AuthenticationPrincipal AuthUser me) {
        return propertyService.listMine(me.id());
    }

    /** L7 Add property. */
    @PostMapping
    public ResponseEntity<PropertyResponse> create(@Valid @RequestBody PropertyRequest request,
                                                   @AuthenticationPrincipal AuthUser me) {
        PropertyResponse created = propertyService.create(request, me.id());
        return ResponseEntity.created(URI.create("/api/properties/" + created.id())).body(created);
    }

    /** L6 Property detail, including its rooms. */
    @GetMapping("/{propertyId}")
    public PropertyResponse get(@PathVariable Long propertyId, @AuthenticationPrincipal AuthUser me) {
        return propertyService.getMine(propertyId, me.id());
    }

    /** L7 Edit property. */
    @PutMapping("/{propertyId}")
    public PropertyResponse update(@PathVariable Long propertyId, @Valid @RequestBody PropertyRequest request,
                                   @AuthenticationPrincipal AuthUser me) {
        return propertyService.update(propertyId, request, me.id());
    }

    /** L7 Delete property - refused while students live there or issues are open. */
    @DeleteMapping("/{propertyId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void delete(@PathVariable Long propertyId, @AuthenticationPrincipal AuthUser me) {
        propertyService.delete(propertyId, me.id());
    }

    @GetMapping("/{propertyId}/rooms")
    public List<RoomResponse> listRooms(@PathVariable Long propertyId, @AuthenticationPrincipal AuthUser me) {
        return roomService.listForProperty(propertyId, me.id());
    }

    /** L9 Add room. */
    @PostMapping("/{propertyId}/rooms")
    public ResponseEntity<RoomResponse> createRoom(@PathVariable Long propertyId,
                                                   @Valid @RequestBody RoomRequest request,
                                                   @AuthenticationPrincipal AuthUser me) {
        RoomResponse created = roomService.create(propertyId, request, me.id());
        return ResponseEntity.created(URI.create("/api/rooms/" + created.id())).body(created);
    }
}
