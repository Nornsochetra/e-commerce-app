package com.setec.ecommerce.wishlist.controller;

import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import com.setec.ecommerce.shared.api.EmptyJsonResponse;
import com.setec.ecommerce.shared.api.Pagination;
import com.setec.ecommerce.wishlist.payload.ProductSummaryResponse;
import com.setec.ecommerce.wishlist.payload.SaveWishlistItemRequest;
import com.setec.ecommerce.wishlist.service.WishlistService;
import com.setec.ecommerce.wishlist.service.WishlistService.SaveResult;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/wishlist/items")
@RequiredArgsConstructor
@Tag(name = "Wishlist")
public class WishlistController extends BaseController {
  private final WishlistService wishlistService;

  @GetMapping
  @ApiId("WSH-0101")
  @Operation(summary = "List current wishlist items")
  public ResponseEntity<ApiResponse<Pagination<ProductSummaryResponse>>> listItems(
      @RequestParam(defaultValue = "0") @Min(value = 0, message = "Page must not be negative")
          int page,
      @RequestParam(defaultValue = "20")
          @Min(value = 1, message = "Size must be at least 1")
          @Max(value = 100, message = "Size must not exceed 100")
          int size) {
    return ok(wishlistService.listItems(page, size));
  }

  @PostMapping
  @ApiId("WSH-0201")
  @Operation(summary = "Save a product to the current wishlist")
  public ResponseEntity<ApiResponse<ProductSummaryResponse>> saveItem(
      @Valid @RequestBody SaveWishlistItemRequest request) {
    SaveResult result = wishlistService.saveItem(request);
    return result.created() ? created(result.product()) : ok(result.product());
  }

  @DeleteMapping("/{productId}")
  @ApiId("WSH-0501")
  @Operation(summary = "Remove a product from the current wishlist")
  public ResponseEntity<ApiResponse<EmptyJsonResponse>> removeItem(@PathVariable UUID productId) {
    wishlistService.removeItem(productId);
    return noContent();
  }
}
