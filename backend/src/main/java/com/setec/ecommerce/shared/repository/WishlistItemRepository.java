package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.WishlistItem;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface WishlistItemRepository extends JpaRepository<WishlistItem, Long> {
  @Query(
      value =
          "select w from WishlistItem w join fetch w.product p join fetch p.category "
              + "where w.user.id = :userId",
      countQuery = "select count(w) from WishlistItem w where w.user.id = :userId")
  Page<WishlistItem> findPageByUserId(@Param("userId") Long userId, Pageable pageable);

  @Query(
      "select w from WishlistItem w join fetch w.product p join fetch p.category "
          + "where w.user.id = :userId and p.uuid = :productUuid")
  Optional<WishlistItem> findByUserIdAndProductUuid(
      @Param("userId") Long userId, @Param("productUuid") UUID productUuid);

  long countByUserId(Long userId);
}
