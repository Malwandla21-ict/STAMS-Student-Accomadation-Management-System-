package com.stams.backend.config;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

/**
 * Small database fixes that ddl-auto=update can't make on its own.
 * Hibernate adds a CHECK constraint listing an enum's values when it first creates the column,
 * and never updates it - so new enum values (NotificationType.NEW_ISSUE) would be rejected.
 * Remove this class once the schema is managed by Flyway.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class SchemaFixes implements ApplicationRunner {

    private final JdbcTemplate jdbc;

    @Override
    public void run(ApplicationArguments args) {
        try {
            jdbc.execute("ALTER TABLE IF EXISTS notifications DROP CONSTRAINT IF EXISTS notifications_type_check");
        } catch (RuntimeException e) {
            log.warn("Couldn't drop notifications_type_check - new notification types may be rejected", e);
        }
    }
}
