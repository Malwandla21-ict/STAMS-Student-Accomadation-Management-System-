package com.stams.backend.service;

import com.stams.backend.dto.user.UserResponse;
import com.stams.backend.exception.NotFoundException;
import com.stams.backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public UserResponse getProfile(Long userId) {
        return userRepository.findById(userId)
                .map(UserResponse::from)
                .orElseThrow(() -> new NotFoundException("Account not found"));
    }
}
