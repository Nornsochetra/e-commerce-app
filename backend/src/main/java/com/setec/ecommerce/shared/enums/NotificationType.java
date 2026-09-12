package com.setec.ecommerce.shared.enums;

import java.util.Locale;

public enum NotificationType {
  ORDER,
  OFFER,
  STOCK;

  public String wireValue() {
    return name().toLowerCase(Locale.ROOT);
  }
}
