package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.Product;
import jakarta.persistence.LockModeType;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductRepository
    extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {
  @Query(
      "select p from Product p join fetch p.category c "
          + "where p.uuid = :uuid and p.active = true and c.active = true")
  Optional<Product> findVisibleByUuid(@Param("uuid") UUID uuid);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query(
      "select p from Product p join fetch p.category c "
          + "where p.uuid = :uuid and p.active = true and c.active = true")
  Optional<Product> findVisibleForUpdateByUuid(@Param("uuid") UUID uuid);

  @Lock(LockModeType.PESSIMISTIC_WRITE)
  @Query("select p from Product p where p.id in :ids order by p.id")
  List<Product> findAllForUpdateByIdIn(@Param("ids") List<Long> ids);
}
