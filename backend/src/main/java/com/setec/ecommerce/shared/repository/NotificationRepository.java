package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.Notification;
import java.time.Instant;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
  Page<Notification> findPageByUserIdAndClearedAtIsNull(Long userId, Pageable pageable);

  Page<Notification> findPageByUserIdAndReadAtIsNullAndClearedAtIsNull(
      Long userId, Pageable pageable);

  Optional<Notification> findByUserIdAndUuidAndClearedAtIsNull(Long userId, UUID uuid);

  long countByUserIdAndReadAtIsNullAndClearedAtIsNull(Long userId);

  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query(
      "update Notification n set n.readAt = :readAt "
          + "where n.user.id = :userId and n.readAt is null and n.clearedAt is null")
  int markAllVisibleRead(@Param("userId") Long userId, @Param("readAt") Instant readAt);

  @Modifying(clearAutomatically = true, flushAutomatically = true)
  @Query(
      "update Notification n set n.clearedAt = :clearedAt "
          + "where n.user.id = :userId and n.clearedAt is null")
  int clearAllVisible(@Param("userId") Long userId, @Param("clearedAt") Instant clearedAt);
}
