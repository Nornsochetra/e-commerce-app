package com.setec.ecommerce.auth.payload;

public record CurrentUserCountsResponse(long orders, long wishlistItems, long cartItems) {}
