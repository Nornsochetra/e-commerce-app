package com.setec.ecommerce.cart.payload;

import java.util.UUID;

public record CartProductResponse(UUID id, String name, String imageUrl, int availableQuantity) {}
