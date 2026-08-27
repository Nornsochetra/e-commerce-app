package com.setec.ecommerce.shared.security;

import com.setec.ecommerce.shared.api.StatusCode;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.stereotype.Component;

@Component
public class RestAuthenticationEntryPoint implements AuthenticationEntryPoint {
  private final EnvelopeErrorWriter writer;

  public RestAuthenticationEntryPoint(EnvelopeErrorWriter writer) {
    this.writer = writer;
  }

  @Override
  public void commence(
      HttpServletRequest request,
      HttpServletResponse response,
      AuthenticationException authException)
      throws IOException, ServletException {
    boolean invalidToken =
        Boolean.TRUE.equals(request.getAttribute(JwtAuthenticationFilter.INVALID_TOKEN_ATTRIBUTE));
    writer.write(response, invalidToken ? StatusCode.INVALID_TOKEN : StatusCode.UNAUTHORIZED);
  }
}
