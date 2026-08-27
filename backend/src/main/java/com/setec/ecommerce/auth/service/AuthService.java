package com.setec.ecommerce.auth.service;

import com.setec.ecommerce.auth.mapper.AuthMapper;
import com.setec.ecommerce.auth.payload.AuthResponse;
import com.setec.ecommerce.auth.payload.CurrentUserResponse;
import com.setec.ecommerce.auth.payload.ForgotPasswordRequest;
import com.setec.ecommerce.auth.payload.LoginRequest;
import com.setec.ecommerce.auth.payload.RefreshTokenRequest;
import com.setec.ecommerce.auth.payload.RegisterRequest;
import com.setec.ecommerce.auth.payload.TokenResponse;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.helper.CurrentUserResolver;
import com.setec.ecommerce.shared.properties.JwtProperties;
import com.setec.ecommerce.shared.repository.UserRepository;
import com.setec.ecommerce.shared.security.JwtClaims;
import com.setec.ecommerce.shared.security.JwtTokenProvider;
import com.setec.ecommerce.shared.security.TokenType;
import java.time.Instant;
import java.util.List;
import java.util.Locale;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {
  private final UserRepository userRepository;
  private final PasswordEncoder passwordEncoder;
  private final JwtTokenProvider tokenProvider;
  private final JwtProperties jwtProperties;
  private final CurrentUserResolver currentUserResolver;
  private final AuthMapper authMapper;

  @Transactional
  public AuthResponse register(RegisterRequest request) {
    String email = normalizeEmail(request.email());
    if (userRepository.existsByEmailIgnoringCase(email)) {
      throw new BusinessException(StatusCode.EMAIL_ALREADY_REGISTERED);
    }

    User user = authMapper.toUser(request, email, passwordEncoder.encode(request.password()));
    try {
      userRepository.saveAndFlush(user);
    } catch (DataIntegrityViolationException exception) {
      throw new BusinessException(StatusCode.EMAIL_ALREADY_REGISTERED);
    }
    TokenBundle tokens = issueTokens(user);
    return authMapper.toAuthResponse(
        user,
        tokens.accessToken(),
        tokens.refreshToken(),
        jwtProperties.getAccessTokenTtl().toSeconds());
  }

  @Transactional
  public AuthResponse login(LoginRequest request) {
    User user =
        userRepository
            .findByEmailIgnoringCase(normalizeEmail(request.email()))
            .orElseThrow(() -> new BusinessException(StatusCode.INVALID_CREDENTIALS));
    if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
      throw new BusinessException(StatusCode.INVALID_CREDENTIALS);
    }
    if (!user.isActive()) {
      throw new BusinessException(StatusCode.ACCOUNT_DISABLED);
    }
    user.setLastLoginAt(Instant.now());
    TokenBundle tokens = issueTokens(user);
    return authMapper.toAuthResponse(
        user,
        tokens.accessToken(),
        tokens.refreshToken(),
        jwtProperties.getAccessTokenTtl().toSeconds());
  }

  @Transactional
  public TokenResponse refresh(RefreshTokenRequest request) {
    JwtClaims claims = parseRefreshClaims(request.refreshToken());
    User user = requireRefreshUser(claims);
    if (!user.isActive()) {
      throw new BusinessException(StatusCode.INVALID_REFRESH_TOKEN);
    }

    TokenBundle tokens = issueTokens(user);
    return authMapper.toTokenResponse(
        tokens.accessToken(), tokens.refreshToken(), jwtProperties.getAccessTokenTtl().toSeconds());
  }

  @Transactional
  public void logout() {
    User caller = currentUserResolver.require();
    caller.setTokenVersion(caller.getTokenVersion() + 1);
  }

  @Transactional(readOnly = true)
  public CurrentUserResponse me() {
    return authMapper.toCurrentUserResponse(currentUserResolver.require());
  }

  @Transactional(readOnly = true)
  public void forgotPassword(ForgotPasswordRequest request) {
    log.debug("Accepted password recovery request");
  }

  private TokenBundle issueTokens(User user) {
    List<String> roles = List.of(user.getRole().name());
    String accessToken =
        tokenProvider.generate(
            user.getId().toString(), TokenType.ACCESS, roles, user.getTokenVersion());
    String refreshToken =
        tokenProvider.generate(
            user.getId().toString(), TokenType.REFRESH, roles, user.getTokenVersion());
    return new TokenBundle(accessToken, refreshToken);
  }

  private User requireRefreshUser(JwtClaims claims) {
    Long subject = parseSubject(claims.subject());
    User user =
        userRepository
            .findById(subject)
            .orElseThrow(() -> new BusinessException(StatusCode.INVALID_REFRESH_TOKEN));
    if (user.getTokenVersion() != claims.tokenVersion()) {
      throw new BusinessException(StatusCode.INVALID_REFRESH_TOKEN);
    }
    return user;
  }

  private JwtClaims parseRefreshClaims(String token) {
    try {
      JwtClaims claims = tokenProvider.parse(token);
      if (claims.tokenType() != TokenType.REFRESH) {
        throw new BusinessException(StatusCode.INVALID_REFRESH_TOKEN);
      }
      return claims;
    } catch (BusinessException exception) {
      throw new BusinessException(StatusCode.INVALID_REFRESH_TOKEN);
    }
  }

  private Long parseSubject(String subject) {
    try {
      return Long.valueOf(subject);
    } catch (NumberFormatException exception) {
      throw new BusinessException(StatusCode.INVALID_REFRESH_TOKEN);
    }
  }

  private String normalizeEmail(String email) {
    return email.trim().toLowerCase(Locale.ROOT);
  }

  private record TokenBundle(String accessToken, String refreshToken) {}
}
