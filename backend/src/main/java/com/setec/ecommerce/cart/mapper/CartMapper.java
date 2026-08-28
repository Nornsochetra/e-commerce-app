package com.setec.ecommerce.cart.mapper;

import com.setec.ecommerce.cart.payload.CartItemResponse;
import com.setec.ecommerce.cart.payload.CartProductResponse;
import com.setec.ecommerce.cart.payload.CartResponse;
import com.setec.ecommerce.cart.payload.MoneyResponse;
import com.setec.ecommerce.shared.domain.Cart;
import com.setec.ecommerce.shared.domain.CartItem;
import com.setec.ecommerce.shared.domain.Product;
import java.math.BigDecimal;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class CartMapper {
  private static final String DEFAULT_CURRENCY = "USD";

  public CartResponse emptyResponse() {
    return new CartResponse(null, List.of(), money(BigDecimal.ZERO, DEFAULT_CURRENCY), 0, null);
  }

  public CartResponse toResponse(Cart cart) {
    List<CartItemResponse> items = cart.getItems().stream().map(this::toItemResponse).toList();
    BigDecimal subtotal =
        cart.getItems().stream().map(this::lineTotal).reduce(BigDecimal.ZERO, BigDecimal::add);
    long itemCount = cart.getItems().stream().mapToLong(CartItem::getQuantity).sum();
    return new CartResponse(
        cart.getUuid(), items, money(subtotal, DEFAULT_CURRENCY), itemCount, cart.getUpdatedAt());
  }

  private CartItemResponse toItemResponse(CartItem item) {
    Product product = item.getProduct();
    return new CartItemResponse(
        item.getUuid(),
        new CartProductResponse(
            product.getUuid(),
            product.getName(),
            product.getImageUrl(),
            product.getAvailableQuantity()),
        item.getQuantity(),
        money(product.getPrice(), product.getCurrency()),
        money(lineTotal(item), product.getCurrency()));
  }

  private BigDecimal lineTotal(CartItem item) {
    return item.getProduct().getPrice().multiply(BigDecimal.valueOf(item.getQuantity()));
  }

  private MoneyResponse money(BigDecimal amount, String currency) {
    return new MoneyResponse(amount.setScale(2).toPlainString(), currency);
  }
}
