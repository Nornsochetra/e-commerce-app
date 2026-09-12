package com.setec.ecommerce.shared.enums;

public enum PaymentMethod {
  CASH_ON_DELIVERY("cash_on_delivery");

  private final String wireValue;

  PaymentMethod(String wireValue) {
    this.wireValue = wireValue;
  }

  public String wireValue() {
    return wireValue;
  }

  public static PaymentMethod fromWireValue(String value) {
    for (PaymentMethod method : values()) {
      if (method.wireValue.equals(value)) {
        return method;
      }
    }
    throw new IllegalArgumentException("Unsupported payment method");
  }
}
