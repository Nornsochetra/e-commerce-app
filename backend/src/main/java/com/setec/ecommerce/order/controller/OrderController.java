package com.setec.ecommerce.order.controller;

import com.setec.ecommerce.order.payload.CheckoutPreviewResponse;
import com.setec.ecommerce.order.payload.CheckoutRequest;
import com.setec.ecommerce.order.payload.OrderDetailResponse;
import com.setec.ecommerce.order.payload.OrderSummaryResponse;
import com.setec.ecommerce.order.service.OrderService;
import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import com.setec.ecommerce.shared.api.Pagination;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/api/v1/orders")
@RequiredArgsConstructor
@Tag(name = "Orders and Checkout")
public class OrderController extends BaseController {
  private final OrderService orderService;

  @PostMapping("/preview")
  @ApiId("ORD-0201")
  @Operation(summary = "Preview checkout totals")
  public ResponseEntity<ApiResponse<CheckoutPreviewResponse>> preview(
      @Valid @RequestBody CheckoutRequest request) {
    return ok(orderService.preview(request));
  }

  @PostMapping
  @ApiId("ORD-0202")
  @Operation(summary = "Place an order from the current cart")
  public ResponseEntity<ApiResponse<OrderDetailResponse>> placeOrder(
      @RequestHeader("Idempotency-Key")
          @NotBlank(message = "Idempotency-Key is required")
          @Size(max = 128, message = "Idempotency-Key must not exceed 128 characters")
          String idempotencyKey,
      @Valid @RequestBody CheckoutRequest request) {
    return created(orderService.placeOrder(request, idempotencyKey));
  }

  @GetMapping
  @ApiId("ORD-0101")
  @Operation(summary = "List current user orders")
  public ResponseEntity<ApiResponse<Pagination<OrderSummaryResponse>>> listOrders(
      @RequestParam(defaultValue = "0") @Min(value = 0, message = "Page must not be negative")
          int page,
      @RequestParam(defaultValue = "20")
          @Min(value = 1, message = "Size must be at least 1")
          @Max(value = 100, message = "Size must not exceed 100")
          int size,
      @RequestParam(required = false)
          @Size(max = 24, message = "Status must not exceed 24 characters")
          String status) {
    return ok(orderService.listOrders(page, size, status));
  }

  @GetMapping("/{orderId}")
  @ApiId("ORD-0601")
  @Operation(summary = "Read one current user order")
  public ResponseEntity<ApiResponse<OrderDetailResponse>> getOrder(@PathVariable UUID orderId) {
    return ok(orderService.getOrder(orderId));
  }
}
