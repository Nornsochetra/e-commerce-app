package com.setec.ecommerce.catalog.mapper;

import com.setec.ecommerce.catalog.payload.CategoryResponse;
import com.setec.ecommerce.catalog.payload.CategorySummaryResponse;
import com.setec.ecommerce.catalog.payload.MoneyResponse;
import com.setec.ecommerce.catalog.payload.ProductDetailResponse;
import com.setec.ecommerce.catalog.payload.ProductSummaryResponse;
import com.setec.ecommerce.shared.domain.Category;
import com.setec.ecommerce.shared.domain.Product;
import java.math.BigDecimal;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public class CatalogMapper {
  public CategoryResponse toCategoryResponse(Category category) {
    return new CategoryResponse(category.getUuid(), category.getName(), category.getSlug());
  }

  public ProductSummaryResponse toSummaryResponse(Product product) {
    return new ProductSummaryResponse(
        product.getUuid(),
        product.getName(),
        toCategorySummary(product.getCategory()),
        toMoney(product),
        product.getAvailableQuantity(),
        formatDecimal(product.getRating()),
        product.getImageUrl(),
        product.getBadges().stream()
            .map(badge -> badge.getBadge().name().toLowerCase(Locale.ROOT))
            .toList(),
        product.isFeatured());
  }

  public ProductDetailResponse toDetailResponse(Product product) {
    return new ProductDetailResponse(
        product.getUuid(),
        product.getName(),
        product.getDescription(),
        toCategorySummary(product.getCategory()),
        toMoney(product),
        product.getAvailableQuantity(),
        formatDecimal(product.getRating()),
        product.getImageUrl(),
        product.getBadges().stream()
            .map(badge -> badge.getBadge().name().toLowerCase(Locale.ROOT))
            .toList(),
        product.isFeatured());
  }

  private CategorySummaryResponse toCategorySummary(Category category) {
    return new CategorySummaryResponse(category.getUuid(), category.getName());
  }

  private MoneyResponse toMoney(Product product) {
    return new MoneyResponse(product.getPrice().setScale(2).toPlainString(), product.getCurrency());
  }

  private String formatDecimal(BigDecimal value) {
    return value == null ? null : value.stripTrailingZeros().toPlainString();
  }
}
