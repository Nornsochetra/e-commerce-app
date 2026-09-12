package com.setec.ecommerce.wishlist.service;

import com.setec.ecommerce.shared.api.Pagination;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.domain.WishlistItem;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.helper.CurrentUserResolver;
import com.setec.ecommerce.shared.repository.ProductRepository;
import com.setec.ecommerce.shared.repository.WishlistItemRepository;
import com.setec.ecommerce.wishlist.mapper.WishlistMapper;
import com.setec.ecommerce.wishlist.payload.ProductSummaryResponse;
import com.setec.ecommerce.wishlist.payload.SaveWishlistItemRequest;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class WishlistService {
  private static final Sort NEWEST_FIRST =
      Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));

  private final CurrentUserResolver currentUserResolver;
  private final WishlistItemRepository wishlistItemRepository;
  private final ProductRepository productRepository;
  private final WishlistMapper wishlistMapper;

  @Transactional(readOnly = true)
  public Pagination<ProductSummaryResponse> listItems(int page, int size) {
    User user = currentUserResolver.require();
    Page<WishlistItem> items =
        wishlistItemRepository.findPageByUserId(
            user.getId(), PageRequest.of(page, size, NEWEST_FIRST));
    return Pagination.of(items, item -> wishlistMapper.toProductSummary(item.getProduct()));
  }

  @Transactional
  public SaveResult saveItem(SaveWishlistItemRequest request) {
    User user = currentUserResolver.requireForUpdate();
    WishlistItem existing =
        wishlistItemRepository
            .findByUserIdAndProductUuid(user.getId(), request.productId())
            .orElse(null);
    if (existing != null) {
      return new SaveResult(wishlistMapper.toProductSummary(existing.getProduct()), false);
    }
    Product product =
        productRepository
            .findVisibleByUuid(request.productId())
            .orElseThrow(() -> new BusinessException(StatusCode.PRODUCT_NOT_FOUND));
    return saveNewItem(user, product);
  }

  @Transactional
  public void removeItem(UUID productId) {
    User user = currentUserResolver.requireForUpdate();
    WishlistItem item =
        wishlistItemRepository
            .findByUserIdAndProductUuid(user.getId(), productId)
            .orElseThrow(() -> new BusinessException(StatusCode.WISHLIST_ITEM_NOT_FOUND));
    wishlistItemRepository.delete(item);
  }

  private SaveResult saveNewItem(User user, Product product) {
    WishlistItem saved =
        wishlistItemRepository.saveAndFlush(
            WishlistItem.builder().user(user).product(product).build());
    return new SaveResult(wishlistMapper.toProductSummary(saved.getProduct()), true);
  }

  public record SaveResult(ProductSummaryResponse product, boolean created) {}
}
