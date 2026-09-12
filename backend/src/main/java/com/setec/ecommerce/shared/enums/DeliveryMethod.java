package com.setec.ecommerce.shared.enums;

public enum DeliveryMethod {
  STANDARD("standard");

  private final String wireValue;

  DeliveryMethod(String wireValue) {
    this.wireValue = wireValue;
  }

  public String wireValue() {
    return wireValue;
  }

  public static DeliveryMethod fromWireValue(String value) {
    for (DeliveryMethod method : values()) {
      if (method.wireValue.equals(value)) {
        return method;
      }
    }
    throw new IllegalArgumentException("Unsupported delivery method");
  }
}
