package com.setec.ecommerce.shared.repository;

import com.setec.ecommerce.shared.domain.OrderItem;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {}
