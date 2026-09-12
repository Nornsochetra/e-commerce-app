package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.Order;
import com.setec.ecommerce.shared.enums.OrderStatus;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface OrderRepository extends JpaRepository<Order, Long> {
  @Query(
      "select distinct o from CustomerOrder o left join fetch o.items "
          + "where o.user.id = :userId and o.uuid = :uuid")
  Optional<Order> findDetailedByUserIdAndUuid(
      @Param("userId") Long userId, @Param("uuid") UUID uuid);

  @Query(
      "select distinct o from CustomerOrder o left join fetch o.items "
          + "where o.user.id = :userId and o.idempotencyKey = :idempotencyKey")
  Optional<Order> findDetailedByUserIdAndIdempotencyKey(
      @Param("userId") Long userId, @Param("idempotencyKey") String idempotencyKey);

  @Query("select o from CustomerOrder o where o.user.id = :userId")
  Page<Order> findPageByUserId(@Param("userId") Long userId, Pageable pageable);

  @Query("select o from CustomerOrder o " + "where o.user.id = :userId and o.status = :status")
  Page<Order> findPageByUserIdAndStatus(
      @Param("userId") Long userId, @Param("status") OrderStatus status, Pageable pageable);

  long countByUserId(Long userId);
}
