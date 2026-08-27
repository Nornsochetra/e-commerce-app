package com.setec.ecommerce.auth.mapper;

import com.setec.ecommerce.auth.payload.AuthResponse;
import com.setec.ecommerce.auth.payload.RegisterRequest;
import com.setec.ecommerce.auth.payload.TokenResponse;
import com.setec.ecommerce.auth.payload.UserIdentityResponse;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.Role;
import java.util.Locale;
import org.springframework.stereotype.Component;

@Component
public class AuthMapper {
  public User toUser(RegisterRequest request, String normalizedEmail, String passwordHash) {
    return User.builder()
        .name(request.name())
        .email(normalizedEmail)
        .passwordHash(passwordHash)
        .role(Role.USER)
        .active(true)
        .build();
  }

  public UserIdentityResponse toIdentityResponse(User user) {
    return new UserIdentityResponse(
        user.getUuid(),
        user.getName(),
        user.getEmail(),
        user.getPhone(),
        user.getRole().name().toLowerCase(Locale.ROOT));
  }

  public AuthResponse toAuthResponse(
      User user, String accessToken, String refreshToken, long expiresIn) {
    return new AuthResponse(accessToken, refreshToken, expiresIn, toIdentityResponse(user));
  }

  public TokenResponse toTokenResponse(String accessToken, String refreshToken, long expiresIn) {
    return new TokenResponse(accessToken, refreshToken, expiresIn);
  }
}
