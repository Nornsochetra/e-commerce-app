package com.setec.ecommerce.cart.controller;

import com.setec.ecommerce.cart.payload.AddCartItemRequest;
import com.setec.ecommerce.cart.payload.CartResponse;
import com.setec.ecommerce.cart.payload.UpdateCartItemRequest;
import com.setec.ecommerce.cart.service.CartService;
import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/cart")
@RequiredArgsConstructor
@Tag(name = "Shopping Cart")
public class CartController extends BaseController {
  private final CartService cartService;

  @GetMapping
  @ApiId("CRT-0601")
  @Operation(summary = "Read the current cart")
  public ResponseEntity<ApiResponse<CartResponse>> getCurrentCart() {
    return ok(cartService.getCurrentCart());
  }

  @PostMapping("/items")
  @ApiId("CRT-0201")
  @Operation(summary = "Add a product to the current cart")
  public ResponseEntity<ApiResponse<CartResponse>> addItem(
      @Valid @RequestBody AddCartItemRequest request) {
    return ok(cartService.addItem(request));
  }

  @PatchMapping("/items/{itemId}")
  @ApiId("CRT-0401")
  @Operation(summary = "Set a cart item quantity")
  public ResponseEntity<ApiResponse<CartResponse>> updateItem(
      @PathVariable UUID itemId, @Valid @RequestBody UpdateCartItemRequest request) {
    return ok(cartService.updateItem(itemId, request));
  }

  @DeleteMapping("/items/{itemId}")
  @ApiId("CRT-0501")
  @Operation(summary = "Remove an item from the current cart")
  public ResponseEntity<ApiResponse<CartResponse>> removeItem(@PathVariable UUID itemId) {
    return ok(cartService.removeItem(itemId));
  }
}
