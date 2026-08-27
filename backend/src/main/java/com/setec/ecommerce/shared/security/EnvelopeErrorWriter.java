package com.setec.ecommerce.shared.security;

import com.setec.ecommerce.shared.api.ApiError;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.StatusCode;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import tools.jackson.databind.ObjectMapper;

@Component
public class EnvelopeErrorWriter {
  private final ObjectMapper objectMapper;

  public EnvelopeErrorWriter(ObjectMapper objectMapper) {
    this.objectMapper = objectMapper;
  }

  public void write(HttpServletResponse response, StatusCode statusCode) throws IOException {
    response.setStatus(statusCode.getHttpStatus().value());
    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
    response.setCharacterEncoding(StandardCharsets.UTF_8.name());
    ApiError error = ApiError.of(statusCode, statusCode.getMessage());
    objectMapper.writeValue(response.getWriter(), ApiResponse.failure(statusCode, error));
  }
}
