package com.setec.ecommerce.shared.filter;

import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.helper.HeaderContext;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import lombok.extern.slf4j.Slf4j;
import org.slf4j.MDC;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.AnnotatedElementUtils;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerExecutionChain;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

@Slf4j
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class TraceContextFilter extends OncePerRequestFilter {
  public static final String REQUEST_ID_HEADER = "X-Request-Id";
  public static final String API_ID_HEADER = "X-Api-Id";
  private static final String MDC_REQUEST_ID = "requestId";
  private static final String MDC_API_ID = "apiId";

  private final ObjectProvider<RequestMappingHandlerMapping> mappingProvider;
  private final Set<String> warnedHandlers = ConcurrentHashMap.newKeySet();

  public TraceContextFilter(ObjectProvider<RequestMappingHandlerMapping> mappingProvider) {
    this.mappingProvider = mappingProvider;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {
    String inboundRequestId = request.getHeader(REQUEST_ID_HEADER);
    String requestId =
        StringUtils.hasText(inboundRequestId) ? inboundRequestId : UUID.randomUUID().toString();
    String apiId = resolveApiId(request);

    HeaderContext.set(requestId, apiId);
    MDC.put(MDC_REQUEST_ID, requestId);
    MDC.put(MDC_API_ID, apiId);
    response.setHeader(REQUEST_ID_HEADER, requestId);
    response.setHeader(API_ID_HEADER, apiId);
    try {
      chain.doFilter(request, response);
    } finally {
      HeaderContext.clear();
      MDC.remove(MDC_REQUEST_ID);
      MDC.remove(MDC_API_ID);
    }
  }

  private String resolveApiId(HttpServletRequest request) {
    try {
      RequestMappingHandlerMapping mapping = mappingProvider.getIfAvailable();
      if (mapping == null) {
        return HeaderContext.UNKNOWN_API_ID;
      }
      HandlerExecutionChain chain = mapping.getHandler(request);
      if (chain == null || !(chain.getHandler() instanceof HandlerMethod method)) {
        return HeaderContext.UNKNOWN_API_ID;
      }
      ApiId apiId = AnnotatedElementUtils.findMergedAnnotation(method.getMethod(), ApiId.class);
      if (apiId == null) {
        apiId = AnnotatedElementUtils.findMergedAnnotation(method.getBeanType(), ApiId.class);
      }
      if (apiId != null) {
        return apiId.value();
      }
      String handlerKey = method.toString();
      if (warnedHandlers.add(handlerKey)) {
        log.warn("Handler has no @ApiId: {}", handlerKey);
      }
    } catch (Exception exception) {
      log.debug("Could not resolve @ApiId", exception);
    }
    return HeaderContext.UNKNOWN_API_ID;
  }
}
