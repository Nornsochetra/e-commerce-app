package com.setec.ecommerce.shared.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "order_items")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
public class OrderItem {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "order_id", nullable = false, updatable = false)
  private Order order;

  @ManyToOne(fetch = FetchType.LAZY)
  @JoinColumn(name = "product_id", updatable = false)
  private Product product;

  @Column(name = "product_uuid", nullable = false, updatable = false)
  private UUID productUuid;

  @Column(name = "product_name", nullable = false, length = 180, updatable = false)
  private String productName;

  @Column(name = "image_url", length = 2048, updatable = false)
  private String imageUrl;

  @Column(nullable = false, updatable = false)
  private int quantity;

  @Column(name = "unit_price", nullable = false, precision = 12, scale = 2, updatable = false)
  private BigDecimal unitPrice;

  @Column(name = "line_total", nullable = false, precision = 12, scale = 2, updatable = false)
  private BigDecimal lineTotal;

  @Column(nullable = false, columnDefinition = "CHAR(3)", updatable = false)
  @JdbcTypeCode(SqlTypes.CHAR)
  private String currency;

  @CreationTimestamp
  @Column(name = "created_at", nullable = false, updatable = false)
  private Instant createdAt;
}
