package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.Category;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CategoryRepository extends JpaRepository<Category, Long> {
  List<Category> findAllByActiveTrueOrderByNameAscIdAsc();

  Optional<Category> findByUuidAndActiveTrue(UUID uuid);
}
