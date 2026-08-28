package com.setec.ecommerce.catalog.service;

import com.setec.ecommerce.catalog.mapper.CatalogMapper;
import com.setec.ecommerce.catalog.payload.CategoryResponse;
import com.setec.ecommerce.catalog.payload.ProductDetailResponse;
import com.setec.ecommerce.catalog.payload.ProductSummaryResponse;
import com.setec.ecommerce.shared.api.Pagination;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.domain.Category;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.repository.CategoryRepository;
import com.setec.ecommerce.shared.repository.ProductRepository;
import jakarta.persistence.criteria.Join;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class CatalogService {
  private final CategoryRepository categoryRepository;
  private final ProductRepository productRepository;
  private final CatalogMapper catalogMapper;

  @Transactional(readOnly = true)
  public List<CategoryResponse> listCategories() {
    return categoryRepository.findAllByActiveTrueOrderByNameAscIdAsc().stream()
        .map(catalogMapper::toCategoryResponse)
        .toList();
  }

  @Transactional(readOnly = true)
  public Pagination<ProductSummaryResponse> listProducts(
      int page, int size, String sortValue, String query, UUID categoryId, Boolean inStock) {
    Category category =
        categoryId == null
            ? null
            : categoryRepository
                .findByUuidAndActiveTrue(categoryId)
                .orElseThrow(() -> new BusinessException(StatusCode.CATEGORY_NOT_FOUND));
    Specification<Product> specification = visibleProducts(query, category, inStock);
    Page<Product> products =
        productRepository.findAll(
            specification, PageRequest.of(page, size, resolveSort(sortValue)));
    return Pagination.of(products, catalogMapper::toSummaryResponse);
  }

  @Transactional(readOnly = true)
  public ProductDetailResponse getProduct(UUID productId) {
    Product product =
        productRepository
            .findVisibleByUuid(productId)
            .orElseThrow(() -> new BusinessException(StatusCode.PRODUCT_NOT_FOUND));
    return catalogMapper.toDetailResponse(product);
  }

  private Specification<Product> visibleProducts(
      String queryValue, Category category, Boolean inStock) {
    String normalizedQuery =
        queryValue == null || queryValue.isBlank()
            ? null
            : escapeLike(queryValue.trim().toLowerCase(Locale.ROOT));
    return (root, criteriaQuery, criteriaBuilder) -> {
      Join<Product, Category> categoryJoin = root.join("category");
      List<jakarta.persistence.criteria.Predicate> predicates = new ArrayList<>();
      predicates.add(criteriaBuilder.isTrue(root.get("active")));
      predicates.add(criteriaBuilder.isTrue(categoryJoin.get("active")));
      if (normalizedQuery != null) {
        predicates.add(
            criteriaBuilder.like(
                criteriaBuilder.lower(root.get("name")), "%" + normalizedQuery + "%", '\\'));
      }
      if (category != null) {
        predicates.add(criteriaBuilder.equal(categoryJoin.get("id"), category.getId()));
      }
      if (inStock != null) {
        predicates.add(
            inStock
                ? criteriaBuilder.greaterThan(root.get("availableQuantity"), 0)
                : criteriaBuilder.equal(root.get("availableQuantity"), 0));
      }
      return criteriaBuilder.and(predicates.toArray(jakarta.persistence.criteria.Predicate[]::new));
    };
  }

  private Sort resolveSort(String value) {
    return switch (value) {
      case "featured,asc" ->
          Sort.by(
              Sort.Order.desc("featured"),
              Sort.Order.asc("featuredRank").nullsLast(),
              Sort.Order.asc("id"));
      case "price,asc" -> Sort.by(Sort.Order.asc("price"), Sort.Order.asc("id"));
      case "price,desc" -> Sort.by(Sort.Order.desc("price"), Sort.Order.desc("id"));
      case "rating,desc" -> Sort.by(Sort.Order.desc("rating").nullsLast(), Sort.Order.desc("id"));
      case "name,asc" -> Sort.by(Sort.Order.asc("name"), Sort.Order.asc("id"));
      case "createdAt,desc" -> Sort.by(Sort.Order.desc("createdAt"), Sort.Order.desc("id"));
      default -> throw new BusinessException(StatusCode.VALIDATION_ERROR);
    };
  }

  private String escapeLike(String value) {
    return value.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
  }
}
