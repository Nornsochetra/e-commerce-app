package com.setec.ecommerce.shared.helper;

import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.exception.BusinessException;
import java.util.Optional;
import org.springframework.security.authentication.AnonymousAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class AuthHelper {
  public String currentUserId() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !auth.isAuthenticated() || auth instanceof AnonymousAuthenticationToken) {
      throw new BusinessException(StatusCode.UNAUTHORIZED);
    }
    return auth.getName();
  }

  /** The signed-in caller's id on a public endpoint, or empty for a guest. */
  public Optional<String> currentUserIdIfSignedIn() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    if (auth == null || !auth.isAuthenticated() || auth instanceof AnonymousAuthenticationToken) {
      return Optional.empty();
    }
    return Optional.of(auth.getName());
  }

  public boolean hasRole(String role) {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    return auth != null
        && auth.getAuthorities().stream()
            .anyMatch(authority -> authority.getAuthority().equals("ROLE_" + role));
  }
}
