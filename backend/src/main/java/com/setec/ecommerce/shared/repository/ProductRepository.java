package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.Product;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ProductRepository
    extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {
  @Query(
      "select p from Product p join fetch p.category c "
          + "where p.uuid = :uuid and p.active = true and c.active = true")
  Optional<Product> findVisibleByUuid(@Param("uuid") UUID uuid);
}
