package com.setec.ecommerce.shared.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.core.env.Environment;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.ContentCachingRequestWrapper;
import org.springframework.web.util.ContentCachingResponseWrapper;

@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 1)
public class RequestResponseLoggingFilter extends OncePerRequestFilter {
  private static final int MAX_REQUEST_BODY_LENGTH = 2000;
  private static final List<String> LOGGED_HEADERS =
      List.of("content-type", "accept", "user-agent", "x-request-id", "x-api-id");

  private final boolean logHeaders;
  private final boolean logRequestBody;
  private final boolean logResponseBody;

  public RequestResponseLoggingFilter(Environment environment) {
    boolean isDev = environment.matchesProfiles("dev", "local", "test");
    this.logHeaders = isDev;
    this.logRequestBody = isDev;
    this.logResponseBody = isDev;
  }

  @Override
  protected boolean shouldNotFilter(HttpServletRequest request) {
    String path = request.getRequestURI();
    return path.startsWith("/swagger-ui")
        || path.startsWith("/v3/api-docs")
        || path.startsWith("/webjars")
        || path.equals("/favicon.ico");
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {
    long startedAt = System.nanoTime();
    if (isStreaming(request)) {
      log.info(">>> {} {} [stream]", request.getMethod(), request.getRequestURI());
      try {
        chain.doFilter(request, response);
      } finally {
        log.info(
            "<<< {} {} status={} durationMs={}",
            request.getMethod(),
            request.getRequestURI(),
            response.getStatus(),
            elapsedMillis(startedAt));
      }
      return;
    }

    ContentCachingRequestWrapper wrappedRequest =
        logRequestBody ? new ContentCachingRequestWrapper(request, MAX_REQUEST_BODY_LENGTH) : null;
    ContentCachingResponseWrapper wrappedResponse =
        logResponseBody ? new ContentCachingResponseWrapper(response) : null;
    HttpServletRequest effectiveRequest = wrappedRequest == null ? request : wrappedRequest;
    HttpServletResponse effectiveResponse = wrappedResponse == null ? response : wrappedResponse;

    try {
      chain.doFilter(effectiveRequest, effectiveResponse);
    } finally {
      log.info(
          ">>> {} {}{}{}",
          request.getMethod(),
          request.getRequestURI(),
          querySuffix(request),
          requestDetails(request, wrappedRequest));
      log.info(
          "<<< {} {} status={} durationMs={}{}",
          request.getMethod(),
          request.getRequestURI(),
          response.getStatus(),
          elapsedMillis(startedAt),
          responseDetails(response, wrappedResponse));
      if (wrappedResponse != null) {
        wrappedResponse.copyBodyToResponse();
      }
    }
  }

  private String requestDetails(
      HttpServletRequest request, ContentCachingRequestWrapper wrappedRequest) {
    String headers = logHeaders ? " headers=" + allowedHeaders(request) : "";
    String body =
        logRequestBody && wrappedRequest != null
            ? " body="
                + body(
                    wrappedRequest.getContentAsByteArray(),
                    request.getContentType(),
                    MAX_REQUEST_BODY_LENGTH)
            : "";
    return headers + body;
  }

  private String responseDetails(
      HttpServletResponse response, ContentCachingResponseWrapper wrappedResponse) {
    return logResponseBody && wrappedResponse != null
        ? " body="
            + body(
                wrappedResponse.getContentAsByteArray(),
                response.getContentType(),
                Integer.MAX_VALUE)
        : "";
  }

  private String allowedHeaders(HttpServletRequest request) {
    return LOGGED_HEADERS.stream()
        .filter(name -> request.getHeader(name) != null)
        .map(name -> name + "=" + request.getHeader(name))
        .collect(Collectors.joining(",", "{", "}"));
  }

  private String body(byte[] content, String contentType, int limit) {
    if (content.length == 0) {
      return "";
    }
    if (!isText(contentType)) {
      return "[" + content.length + " bytes " + contentType + "]";
    }
    String text = new String(content, StandardCharsets.UTF_8);
    return text.length() <= limit ? text : text.substring(0, limit) + "…";
  }

  private boolean isText(String contentType) {
    if (!StringUtils.hasText(contentType)) {
      return true;
    }
    String normalized = contentType.toLowerCase(Locale.ROOT);
    return normalized.contains("json")
        || normalized.startsWith("text/")
        || normalized.contains("xml")
        || normalized.contains("form-urlencoded");
  }

  private boolean isStreaming(HttpServletRequest request) {
    String accept = request.getHeader("Accept");
    return (accept != null && accept.contains(MediaType.TEXT_EVENT_STREAM_VALUE))
        || request.getRequestURI().contains("/stream");
  }

  private String querySuffix(HttpServletRequest request) {
    return request.getQueryString() == null ? "" : "?" + request.getQueryString();
  }

  private long elapsedMillis(long startedAt) {
    return (System.nanoTime() - startedAt) / 1_000_000;
  }
}
