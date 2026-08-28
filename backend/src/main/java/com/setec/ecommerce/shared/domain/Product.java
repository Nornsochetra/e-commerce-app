package com.setec.ecommerce.shared.domain;

import com.setec.ecommerce.shared.enums.ProductBadgeType;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;
import org.hibernate.annotations.BatchSize;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "products")
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
public class Product extends BaseEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Builder.Default
  @Column(nullable = false, unique = true, updatable = false)
  private UUID uuid = UUID.randomUUID();

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "category_id", nullable = false)
  private Category category;

  @Column(nullable = false, length = 180)
  private String name;

  @Column(columnDefinition = "TEXT")
  private String description;

  @Column(nullable = false, precision = 12, scale = 2)
  private BigDecimal price;

  @Builder.Default
  @Column(nullable = false, columnDefinition = "CHAR(3)")
  @JdbcTypeCode(SqlTypes.CHAR)
  private String currency = "USD";

  @Builder.Default
  @Column(name = "available_quantity", nullable = false)
  private int availableQuantity = 0;

  @Column(precision = 2, scale = 1)
  private BigDecimal rating;

  @Column(name = "image_url", length = 2048)
  private String imageUrl;

  @Builder.Default
  @Column(name = "is_featured", nullable = false)
  private boolean featured = false;

  @Column(name = "featured_rank")
  private Integer featuredRank;

  @Builder.Default
  @Column(name = "is_active", nullable = false)
  private boolean active = true;

  @Builder.Default
  @BatchSize(size = 100)
  @OrderBy("id ASC")
  @OneToMany(mappedBy = "product", cascade = CascadeType.ALL, orphanRemoval = true)
  private List<ProductBadge> badges = new ArrayList<>();

  public void addBadge(ProductBadgeType badge) {
    badges.add(ProductBadge.builder().product(this).badge(badge).build());
  }
}
