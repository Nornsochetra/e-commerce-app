package com.setec.ecommerce.shared.enums;

import java.util.Locale;

public enum OrderStatus {
  PENDING,
  CONFIRMED,
  SHIPPED,
  DELIVERED;

  public String wireValue() {
    return name().toLowerCase(Locale.ROOT);
  }

  public static OrderStatus fromWireValue(String value) {
    if (value == null) {
      return null;
    }
    for (OrderStatus status : values()) {
      if (status.wireValue().equals(value)) {
        return status;
      }
    }
    throw new IllegalArgumentException("Unsupported order status");
  }
}
