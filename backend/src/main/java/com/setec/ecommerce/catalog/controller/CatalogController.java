package com.setec.ecommerce.catalog.controller;

import com.setec.ecommerce.catalog.payload.CategoryResponse;
import com.setec.ecommerce.catalog.payload.ProductDetailResponse;
import com.setec.ecommerce.catalog.payload.ProductSummaryResponse;
import com.setec.ecommerce.catalog.service.CatalogService;
import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import com.setec.ecommerce.shared.api.Pagination;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.Size;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1")
@RequiredArgsConstructor
@Tag(name = "Product Catalog")
@SecurityRequirements
public class CatalogController extends BaseController {
  private final CatalogService catalogService;

  @GetMapping("/categories")
  @ApiId("CAT-0101")
  @Operation(summary = "List active categories")
  public ResponseEntity<ApiResponse<List<CategoryResponse>>> listCategories() {
    return ok(catalogService.listCategories());
  }

  @GetMapping("/products")
  @ApiId("CAT-0102")
  @Operation(summary = "List visible products")
  public ResponseEntity<ApiResponse<Pagination<ProductSummaryResponse>>> listProducts(
      @RequestParam(defaultValue = "0") @Min(value = 0, message = "Page must not be negative")
          int page,
      @RequestParam(defaultValue = "20")
          @Min(value = 1, message = "Size must be at least 1")
          @Max(value = 100, message = "Size must not exceed 100")
          int size,
      @RequestParam(defaultValue = "featured,asc")
          @Size(max = 40, message = "Sort must not exceed 40 characters")
          String sort,
      @RequestParam(required = false)
          @Size(max = 180, message = "Query must not exceed 180 characters")
          String query,
      @RequestParam(required = false) UUID categoryId,
      @RequestParam(required = false) Boolean inStock) {
    return ok(catalogService.listProducts(page, size, sort, query, categoryId, inStock));
  }

  @GetMapping("/products/{productId}")
  @ApiId("CAT-0601")
  @Operation(summary = "Read a visible product")
  public ResponseEntity<ApiResponse<ProductDetailResponse>> getProduct(
      @PathVariable UUID productId) {
    return ok(catalogService.getProduct(productId));
  }
}
