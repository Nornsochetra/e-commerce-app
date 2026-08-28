package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.CartItem;
import jakarta.persistence.LockModeType;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface CartItemRepository extends JpaRepository<CartItem, Long> {
  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select i from CartItem i where i.uuid = :uuid and i.cart.user.id = :userId")
  Optional<CartItem> findOwnedForUpdate(@Param("uuid") UUID uuid, @Param("userId") Long userId);

  @Query("select coalesce(sum(i.quantity), 0) from CartItem i " + "where i.cart.user.id = :userId")
  long sumQuantityByUserId(@Param("userId") Long userId);
}
