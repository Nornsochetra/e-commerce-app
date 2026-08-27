package com.setec.ecommerce.shared.helper;

public final class HeaderContext {
  public static final String UNKNOWN_API_ID = "UNKNOWN";
  private static final ThreadLocal<Context> CONTEXT = new ThreadLocal<>();

  private HeaderContext() {}

  public static void set(String requestId, String apiId) {
    CONTEXT.set(new Context(requestId, apiId));
  }

  public static void clear() {
    CONTEXT.remove();
  }

  public static String requestId() {
    Context context = CONTEXT.get();
    return context == null ? "" : context.requestId();
  }

  public static String apiId() {
    Context context = CONTEXT.get();
    return context == null ? UNKNOWN_API_ID : context.apiId();
  }

  private record Context(String requestId, String apiId) {}
}
