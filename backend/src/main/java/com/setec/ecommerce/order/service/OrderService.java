package com.setec.ecommerce.order.service;

import com.setec.ecommerce.order.mapper.OrderMapper;
import com.setec.ecommerce.order.payload.CheckoutPreviewResponse;
import com.setec.ecommerce.order.payload.CheckoutRequest;
import com.setec.ecommerce.order.payload.OrderDetailResponse;
import com.setec.ecommerce.order.payload.OrderSummaryResponse;
import com.setec.ecommerce.shared.api.Pagination;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.domain.Cart;
import com.setec.ecommerce.shared.domain.CartItem;
import com.setec.ecommerce.shared.domain.Order;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.DeliveryMethod;
import com.setec.ecommerce.shared.enums.OrderStatus;
import com.setec.ecommerce.shared.enums.PaymentMethod;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.helper.CurrentUserResolver;
import com.setec.ecommerce.shared.repository.CartRepository;
import com.setec.ecommerce.shared.repository.OrderRepository;
import com.setec.ecommerce.shared.repository.ProductRepository;
import java.math.BigDecimal;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class OrderService {
  private static final BigDecimal DELIVERY_FEE = new BigDecimal("4.00");
  private static final String CURRENCY = "USD";
  private static final Sort NEWEST_FIRST =
      Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));

  private final CurrentUserResolver currentUserResolver;
  private final CartRepository cartRepository;
  private final ProductRepository productRepository;
  private final OrderRepository orderRepository;
  private final OrderMapper orderMapper;

  @Transactional(readOnly = true)
  public CheckoutPreviewResponse preview(CheckoutRequest request) {
    CheckoutSelection selection = resolveSelection(request);
    User user = currentUserResolver.require();
    Cart cart = requireNonEmptyCart(user.getId());
    validateItems(cart.getItems());
    BigDecimal subtotal = subtotal(cart.getItems());
    return orderMapper.toPreviewResponse(
        cart.getItems(),
        selection.deliveryMethod(),
        subtotal,
        DELIVERY_FEE,
        Instant.now().plus(15, ChronoUnit.MINUTES));
  }

  @Transactional
  public OrderDetailResponse placeOrder(CheckoutRequest request, String idempotencyKey) {
    CheckoutSelection selection = resolveSelection(request);
    User user = currentUserResolver.requireForUpdate();
    Order existing =
        orderRepository
            .findDetailedByUserIdAndIdempotencyKey(user.getId(), idempotencyKey)
            .orElse(null);
    if (existing != null) {
      if (!isCompatible(existing, request, selection)) {
        throw new BusinessException(StatusCode.CONFLICT);
      }
      return orderMapper.toDetailResponse(existing);
    }

    Cart cart = requireNonEmptyCart(user.getId());
    lockCurrentProducts(cart.getItems());
    validateItems(cart.getItems());
    BigDecimal subtotal = subtotal(cart.getItems());
    UUID orderUuid = UUID.randomUUID();
    Order order =
        orderMapper.toOrder(
            orderUuid,
            reference(orderUuid),
            user,
            request,
            selection.deliveryMethod(),
            selection.paymentMethod(),
            subtotal,
            DELIVERY_FEE,
            idempotencyKey,
            cart.getItems());

    cart.getItems().forEach(this::decrementStock);
    cart.clearItems();
    cart.touch();
    orderRepository.save(order);
    cartRepository.saveAndFlush(cart);
    return orderMapper.toDetailResponse(order);
  }

  @Transactional(readOnly = true)
  public Pagination<OrderSummaryResponse> listOrders(int page, int size, String statusValue) {
    User user = currentUserResolver.require();
    PageRequest pageable = PageRequest.of(page, size, NEWEST_FIRST);
    Page<Order> orders;
    if (statusValue == null) {
      orders = orderRepository.findPageByUserId(user.getId(), pageable);
    } else {
      OrderStatus status = parseStatus(statusValue);
      orders = orderRepository.findPageByUserIdAndStatus(user.getId(), status, pageable);
    }
    return Pagination.of(orders, orderMapper::toSummaryResponse);
  }

  @Transactional(readOnly = true)
  public OrderDetailResponse getOrder(UUID orderId) {
    User user = currentUserResolver.require();
    Order order =
        orderRepository
            .findDetailedByUserIdAndUuid(user.getId(), orderId)
            .orElseThrow(() -> new BusinessException(StatusCode.ORDER_NOT_FOUND));
    return orderMapper.toDetailResponse(order);
  }

  private Cart requireNonEmptyCart(Long userId) {
    Cart cart =
        cartRepository
            .findDetailedByUserId(userId)
            .orElseThrow(() -> new BusinessException(StatusCode.CART_EMPTY));
    if (cart.getItems().isEmpty()) {
      throw new BusinessException(StatusCode.CART_EMPTY);
    }
    return cart;
  }

  private void lockCurrentProducts(List<CartItem> items) {
    List<Long> productIds =
        items.stream().map(item -> item.getProduct().getId()).distinct().sorted().toList();
    List<Product> lockedProducts = productRepository.findAllForUpdateByIdIn(productIds);
    if (lockedProducts.size() != productIds.size()) {
      throw new BusinessException(StatusCode.CHECKOUT_INVALID);
    }
    Map<Long, Product> productsById = new HashMap<>();
    lockedProducts.forEach(product -> productsById.put(product.getId(), product));
    items.forEach(item -> item.setProduct(productsById.get(item.getProduct().getId())));
  }

  private void validateItems(List<CartItem> items) {
    for (CartItem item : items) {
      Product product = item.getProduct();
      if (product == null
          || !product.isActive()
          || !product.getCategory().isActive()
          || !CURRENCY.equals(product.getCurrency())) {
        throw new BusinessException(StatusCode.CHECKOUT_INVALID);
      }
      if (item.getQuantity() > product.getAvailableQuantity()) {
        throw new BusinessException(StatusCode.INSUFFICIENT_STOCK);
      }
    }
  }

  private BigDecimal subtotal(List<CartItem> items) {
    return items.stream()
        .map(item -> item.getProduct().getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
        .reduce(BigDecimal.ZERO, BigDecimal::add);
  }

  private void decrementStock(CartItem item) {
    Product product = item.getProduct();
    product.setAvailableQuantity(product.getAvailableQuantity() - item.getQuantity());
  }

  private CheckoutSelection resolveSelection(CheckoutRequest request) {
    try {
      return new CheckoutSelection(
          DeliveryMethod.fromWireValue(request.deliveryMethod()),
          PaymentMethod.fromWireValue(request.paymentMethod()));
    } catch (IllegalArgumentException exception) {
      throw new BusinessException(StatusCode.CHECKOUT_INVALID);
    }
  }

  private OrderStatus parseStatus(String value) {
    try {
      return OrderStatus.fromWireValue(value);
    } catch (IllegalArgumentException exception) {
      throw new BusinessException(StatusCode.VALIDATION_ERROR);
    }
  }

  private boolean isCompatible(Order order, CheckoutRequest request, CheckoutSelection selection) {
    return order.getRecipientName().equals(request.delivery().recipientName())
        && order.getDeliveryEmail().equals(request.delivery().email())
        && order.getDeliveryAddress().equals(request.delivery().address())
        && order.getDeliveryMethod() == selection.deliveryMethod()
        && order.getPaymentMethod() == selection.paymentMethod();
  }

  private String reference(UUID uuid) {
    return "MC-" + uuid.toString().replace("-", "").substring(0, 12).toUpperCase(Locale.ROOT);
  }

  private record CheckoutSelection(DeliveryMethod deliveryMethod, PaymentMethod paymentMethod) {}
}
