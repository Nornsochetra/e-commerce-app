package com.setec.ecommerce.shared.security;

import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.exception.BusinessException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
  public static final String INVALID_TOKEN_ATTRIBUTE =
      JwtAuthenticationFilter.class.getName() + ".invalidToken";
  private static final String BEARER_PREFIX = "Bearer ";

  private final JwtTokenProvider tokenProvider;

  public JwtAuthenticationFilter(JwtTokenProvider tokenProvider) {
    this.tokenProvider = tokenProvider;
  }

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain chain)
      throws ServletException, IOException {
    String authorization = request.getHeader("Authorization");
    if (authorization != null && authorization.startsWith(BEARER_PREFIX)) {
      String token = authorization.substring(BEARER_PREFIX.length());
      try {
        JwtClaims claims = tokenProvider.parse(token);
        if (claims.tokenType() != TokenType.ACCESS) {
          throw new BusinessException(StatusCode.INVALID_TOKEN);
        }
        var authorities =
            claims.roles().stream()
                .map(role -> new SimpleGrantedAuthority("ROLE_" + role))
                .toList();
        SecurityContextHolder.getContext()
            .setAuthentication(
                new UsernamePasswordAuthenticationToken(claims.subject(), null, authorities));
      } catch (BusinessException exception) {
        SecurityContextHolder.clearContext();
        request.setAttribute(INVALID_TOKEN_ATTRIBUTE, Boolean.TRUE);
      }
    }
    chain.doFilter(request, response);
  }
}
