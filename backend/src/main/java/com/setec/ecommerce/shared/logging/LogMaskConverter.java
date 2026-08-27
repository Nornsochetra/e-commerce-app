package com.setec.ecommerce.shared.logging;

import ch.qos.logback.classic.pattern.MessageConverter;
import ch.qos.logback.classic.spi.ILoggingEvent;
import java.util.regex.Pattern;

public class LogMaskConverter extends MessageConverter {
  private static final String TERMS =
      "password|passwd|pwd|secret|token|credential|authorization|bearer|api[_-]?key|access[_-]?key|private[_-]?key";
  private static final String KEY = "[a-z0-9_.-]*(?:" + TERMS + ")[a-z0-9_.-]*";
  private static final Pattern JSON_PATTERN =
      Pattern.compile("(\\\"" + KEY + "\\\"\\s*:\\s*\\\")[^\\\"]*(\\\")", Pattern.CASE_INSENSITIVE);
  private static final Pattern FORM_PATTERN =
      Pattern.compile("(" + KEY + "=)[^&\\s]*", Pattern.CASE_INSENSITIVE);

  @Override
  public String convert(ILoggingEvent event) {
    return mask(event.getFormattedMessage());
  }

  public static String mask(String message) {
    if (message == null) {
      return null;
    }
    String jsonMasked = JSON_PATTERN.matcher(message).replaceAll("$1***$2");
    return FORM_PATTERN.matcher(jsonMasked).replaceAll("$1***");
  }
}
