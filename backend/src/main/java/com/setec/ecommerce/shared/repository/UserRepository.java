package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.User;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface UserRepository extends JpaRepository<User, Long> {
  @Query("select u from User u where lower(u.email) = lower(:email)")
  Optional<User> findByEmailIgnoringCase(@Param("email") String email);

  @Query("select count(u) > 0 from User u where lower(u.email) = lower(:email)")
  boolean existsByEmailIgnoringCase(@Param("email") String email);

  @Query(
      "select count(u) > 0 from User u "
          + "where lower(u.email) = lower(:email) and u.id <> :userId")
  boolean existsByEmailIgnoringCaseAndIdNot(
      @Param("email") String email, @Param("userId") Long userId);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select u from User u where u.id = :userId")
  Optional<User> findByIdForUpdate(@Param("userId") Long userId);
}
