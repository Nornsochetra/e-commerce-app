package com.setec.ecommerce.shared.security;

public enum TokenType {
  ACCESS,
  REFRESH;

  public static final String CLAIM = "token_type";
}
