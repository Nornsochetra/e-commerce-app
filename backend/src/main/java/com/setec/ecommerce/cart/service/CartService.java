package com.setec.ecommerce.cart.service;

import com.setec.ecommerce.cart.mapper.CartMapper;
import com.setec.ecommerce.cart.payload.AddCartItemRequest;
import com.setec.ecommerce.cart.payload.CartResponse;
import com.setec.ecommerce.cart.payload.UpdateCartItemRequest;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.domain.Cart;
import com.setec.ecommerce.shared.domain.CartItem;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.helper.CurrentUserResolver;
import com.setec.ecommerce.shared.repository.CartItemRepository;
import com.setec.ecommerce.shared.repository.CartRepository;
import com.setec.ecommerce.shared.repository.ProductRepository;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CartService {
  private final CurrentUserResolver currentUserResolver;
  private final CartRepository cartRepository;
  private final CartItemRepository cartItemRepository;
  private final ProductRepository productRepository;
  private final CartMapper cartMapper;

  @Transactional(readOnly = true)
  public CartResponse getCurrentCart() {
    User user = currentUserResolver.require();
    return cartRepository
        .findDetailedByUserId(user.getId())
        .map(cartMapper::toResponse)
        .orElseGet(cartMapper::emptyResponse);
  }

  @Transactional
  public CartResponse addItem(AddCartItemRequest request) {
    User user = currentUserResolver.requireForUpdate();
    Product product = requireVisibleProductForUpdate(request.productId());
    Cart cart =
        cartRepository
            .findDetailedByUserId(user.getId())
            .orElseGet(() -> Cart.builder().user(user).build());
    CartItem item =
        cart.getItems().stream()
            .filter(existing -> existing.getProduct().getId().equals(product.getId()))
            .findFirst()
            .orElse(null);
    long resultingQuantity = (long) request.quantity() + (item == null ? 0L : item.getQuantity());
    validateStock(product, resultingQuantity);
    if (item == null) {
      cart.addItem(CartItem.builder().product(product).quantity(request.quantity()).build());
    } else {
      item.setQuantity((int) resultingQuantity);
    }
    cart.touch();
    return cartMapper.toResponse(cartRepository.saveAndFlush(cart));
  }

  @Transactional
  public CartResponse updateItem(UUID itemId, UpdateCartItemRequest request) {
    User user = currentUserResolver.requireForUpdate();
    CartItem item = requireOwnedItemForUpdate(itemId, user.getId());
    Product product = requireVisibleProductForUpdate(item.getProduct().getUuid());
    validateStock(product, request.quantity());
    item.setQuantity(request.quantity());
    Cart cart = item.getCart();
    cart.touch();
    cartItemRepository.save(item);
    return cartMapper.toResponse(cartRepository.saveAndFlush(cart));
  }

  @Transactional
  public CartResponse removeItem(UUID itemId) {
    User user = currentUserResolver.requireForUpdate();
    CartItem item = requireOwnedItemForUpdate(itemId, user.getId());
    Cart cart = item.getCart();
    cart.removeItem(item);
    cart.touch();
    return cartMapper.toResponse(cartRepository.saveAndFlush(cart));
  }

  private CartItem requireOwnedItemForUpdate(UUID itemId, Long userId) {
    return cartItemRepository
        .findOwnedForUpdate(itemId, userId)
        .orElseThrow(() -> new BusinessException(StatusCode.CART_ITEM_NOT_FOUND));
  }

  private Product requireVisibleProductForUpdate(UUID productId) {
    return productRepository
        .findVisibleForUpdateByUuid(productId)
        .orElseThrow(() -> new BusinessException(StatusCode.PRODUCT_NOT_FOUND));
  }

  private void validateStock(Product product, long quantity) {
    if (product.getAvailableQuantity() == 0) {
      throw new BusinessException(StatusCode.PRODUCT_OUT_OF_STOCK);
    }
    if (quantity > product.getAvailableQuantity()) {
      throw new BusinessException(StatusCode.INSUFFICIENT_STOCK);
    }
  }
}
