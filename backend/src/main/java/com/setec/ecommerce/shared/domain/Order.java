package com.setec.ecommerce.shared.domain;

import com.setec.ecommerce.shared.enums.DeliveryMethod;
import com.setec.ecommerce.shared.enums.OrderStatus;
import com.setec.ecommerce.shared.enums.PaymentMethod;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
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

@Entity(name = "CustomerOrder")
@Table(
    name = "orders",
    uniqueConstraints =
        @UniqueConstraint(
            name = "uq_orders_user_idempotency",
            columnNames = {"user_id", "idempotency_key"}))
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
public class Order extends BaseEntity {
  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;

  @Builder.Default
  @Column(nullable = false, unique = true, updatable = false)
  private UUID uuid = UUID.randomUUID();

  @Column(nullable = false, unique = true, length = 32, updatable = false)
  private String reference;

  @ManyToOne(fetch = FetchType.LAZY, optional = false)
  @JoinColumn(name = "user_id", nullable = false, updatable = false)
  private User user;

  @Builder.Default
  @Enumerated(EnumType.STRING)
  @Column(nullable = false, length = 24)
  private OrderStatus status = OrderStatus.PENDING;

  @Column(name = "recipient_name", nullable = false, length = 120, updatable = false)
  private String recipientName;

  @Column(name = "delivery_email", nullable = false, length = 255, updatable = false)
  private String deliveryEmail;

  @Column(name = "delivery_address", nullable = false, columnDefinition = "TEXT", updatable = false)
  private String deliveryAddress;

  @Enumerated(EnumType.STRING)
  @Column(name = "delivery_method", nullable = false, length = 24, updatable = false)
  private DeliveryMethod deliveryMethod;

  @Enumerated(EnumType.STRING)
  @Column(name = "payment_method", nullable = false, length = 32, updatable = false)
  private PaymentMethod paymentMethod;

  @Column(nullable = false, precision = 12, scale = 2, updatable = false)
  private BigDecimal subtotal;

  @Column(name = "delivery_fee", nullable = false, precision = 12, scale = 2, updatable = false)
  private BigDecimal deliveryFee;

  @Column(nullable = false, precision = 12, scale = 2, updatable = false)
  private BigDecimal total;

  @Column(nullable = false, columnDefinition = "CHAR(3)", updatable = false)
  @JdbcTypeCode(SqlTypes.CHAR)
  private String currency;

  @Column(name = "idempotency_key", nullable = false, length = 128, updatable = false)
  private String idempotencyKey;

  @Builder.Default
  @BatchSize(size = 100)
  @OrderBy("id ASC")
  @OneToMany(mappedBy = "order", cascade = CascadeType.ALL)
  private List<OrderItem> items = new ArrayList<>();

  public void addItem(OrderItem item) {
    item.setOrder(this);
    items.add(item);
  }
}
