package com.setec.ecommerce.wishlist.payload;

import jakarta.validation.constraints.NotNull;
import java.util.UUID;

public record SaveWishlistItemRequest(
    @NotNull(message = "Product id is required") UUID productId) {}
