package com.setec.ecommerce.order.mapper;

import com.setec.ecommerce.order.payload.CheckoutItemResponse;
import com.setec.ecommerce.order.payload.CheckoutPreviewResponse;
import com.setec.ecommerce.order.payload.CheckoutRequest;
import com.setec.ecommerce.order.payload.DeliveryResponse;
import com.setec.ecommerce.order.payload.MoneyResponse;
import com.setec.ecommerce.order.payload.OrderDetailResponse;
import com.setec.ecommerce.order.payload.OrderItemResponse;
import com.setec.ecommerce.order.payload.OrderSummaryResponse;
import com.setec.ecommerce.shared.domain.CartItem;
import com.setec.ecommerce.shared.domain.Order;
import com.setec.ecommerce.shared.domain.OrderItem;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.DeliveryMethod;
import com.setec.ecommerce.shared.enums.OrderStatus;
import com.setec.ecommerce.shared.enums.PaymentMethod;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Component;

@Component
public class OrderMapper {
  public CheckoutPreviewResponse toPreviewResponse(
      List<CartItem> items,
      DeliveryMethod deliveryMethod,
      BigDecimal subtotal,
      BigDecimal deliveryFee,
      Instant expiresAt) {
    return new CheckoutPreviewResponse(
        items.stream().map(this::toCheckoutItemResponse).toList(),
        deliveryMethod.wireValue(),
        estimatedDelivery(deliveryMethod),
        money(subtotal, "USD"),
        money(deliveryFee, "USD"),
        money(subtotal.add(deliveryFee), "USD"),
        expiresAt);
  }

  public Order toOrder(
      UUID uuid,
      String reference,
      User user,
      CheckoutRequest request,
      DeliveryMethod deliveryMethod,
      PaymentMethod paymentMethod,
      BigDecimal subtotal,
      BigDecimal deliveryFee,
      String idempotencyKey,
      List<CartItem> cartItems) {
    Order order =
        Order.builder()
            .uuid(uuid)
            .reference(reference)
            .user(user)
            .status(OrderStatus.PENDING)
            .recipientName(request.delivery().recipientName())
            .deliveryEmail(request.delivery().email())
            .deliveryAddress(request.delivery().address())
            .deliveryMethod(deliveryMethod)
            .paymentMethod(paymentMethod)
            .subtotal(subtotal)
            .deliveryFee(deliveryFee)
            .total(subtotal.add(deliveryFee))
            .currency("USD")
            .idempotencyKey(idempotencyKey)
            .build();
    cartItems.forEach(item -> order.addItem(toOrderItem(item)));
    return order;
  }

  public OrderSummaryResponse toSummaryResponse(Order order) {
    return new OrderSummaryResponse(
        order.getUuid(),
        order.getReference(),
        order.getStatus().wireValue(),
        order.getItems().stream().mapToLong(OrderItem::getQuantity).sum(),
        money(order.getTotal(), order.getCurrency()),
        order.getCreatedAt());
  }

  public OrderDetailResponse toDetailResponse(Order order) {
    return new OrderDetailResponse(
        order.getUuid(),
        order.getReference(),
        order.getStatus().wireValue(),
        order.getItems().stream().map(this::toOrderItemResponse).toList(),
        new DeliveryResponse(
            order.getRecipientName(), order.getDeliveryEmail(), order.getDeliveryAddress()),
        order.getDeliveryMethod().wireValue(),
        estimatedDelivery(order.getDeliveryMethod()),
        order.getPaymentMethod().wireValue(),
        money(order.getSubtotal(), order.getCurrency()),
        money(order.getDeliveryFee(), order.getCurrency()),
        money(order.getTotal(), order.getCurrency()),
        order.getCreatedAt(),
        order.getUpdatedAt());
  }

  private CheckoutItemResponse toCheckoutItemResponse(CartItem item) {
    Product product = item.getProduct();
    BigDecimal lineTotal = product.getPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
    return new CheckoutItemResponse(
        product.getUuid(),
        product.getName(),
        product.getImageUrl(),
        item.getQuantity(),
        money(product.getPrice(), product.getCurrency()),
        money(lineTotal, product.getCurrency()));
  }

  private OrderItem toOrderItem(CartItem item) {
    Product product = item.getProduct();
    BigDecimal lineTotal = product.getPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
    return OrderItem.builder()
        .product(product)
        .productUuid(product.getUuid())
        .productName(product.getName())
        .imageUrl(product.getImageUrl())
        .quantity(item.getQuantity())
        .unitPrice(product.getPrice())
        .lineTotal(lineTotal)
        .currency(product.getCurrency())
        .build();
  }

  private OrderItemResponse toOrderItemResponse(OrderItem item) {
    return new OrderItemResponse(
        item.getProductUuid(),
        item.getProductName(),
        item.getQuantity(),
        money(item.getUnitPrice(), item.getCurrency()),
        money(item.getLineTotal(), item.getCurrency()));
  }

  private MoneyResponse money(BigDecimal amount, String currency) {
    return new MoneyResponse(amount.setScale(2).toPlainString(), currency);
  }

  private String estimatedDelivery(DeliveryMethod deliveryMethod) {
    return switch (deliveryMethod) {
      case STANDARD -> "2–4 business days";
    };
  }
}
