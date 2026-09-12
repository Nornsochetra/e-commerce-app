package com.setec.ecommerce.wishlist.mapper;

import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.wishlist.payload.CategorySummaryResponse;
import com.setec.ecommerce.wishlist.payload.MoneyResponse;
import com.setec.ecommerce.wishlist.payload.ProductSummaryResponse;
import java.math.BigDecimal;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public class WishlistMapper {
  public ProductSummaryResponse toProductSummary(Product product) {
    return new ProductSummaryResponse(
        product.getUuid(),
        product.getName(),
        new CategorySummaryResponse(
            product.getCategory().getUuid(), product.getCategory().getName()),
        new MoneyResponse(product.getPrice().setScale(2).toPlainString(), product.getCurrency()),
        product.getAvailableQuantity(),
        formatDecimal(product.getRating()),
        product.getImageUrl(),
        product.getBadges().stream()
            .map(badge -> badge.getBadge().name().toLowerCase(Locale.ROOT))
            .toList(),
        product.isFeatured());
  }

  private String formatDecimal(BigDecimal value) {
    return value == null ? null : value.stripTrailingZeros().toPlainString();
  }
}
