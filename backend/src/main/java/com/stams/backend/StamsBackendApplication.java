package com.stams.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.security.servlet.UserDetailsServiceAutoConfiguration;

// UserDetailsServiceAutoConfiguration is excluded because we sign users in with JWTs,
// not Spring's default in-memory user (that's what printed the "generated security password").
@SpringBootApplication(exclude = UserDetailsServiceAutoConfiguration.class)
public class StamsBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(StamsBackendApplication.class, args);
    }

}
