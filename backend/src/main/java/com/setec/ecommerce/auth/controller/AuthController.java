package com.setec.ecommerce.auth.controller;

import com.setec.ecommerce.auth.payload.AuthResponse;
import com.setec.ecommerce.auth.payload.ForgotPasswordRequest;
import com.setec.ecommerce.auth.payload.LoginRequest;
import com.setec.ecommerce.auth.payload.RefreshTokenRequest;
import com.setec.ecommerce.auth.payload.RegisterRequest;
import com.setec.ecommerce.auth.payload.TokenResponse;
import com.setec.ecommerce.auth.payload.UserIdentityResponse;
import com.setec.ecommerce.auth.service.AuthService;
import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import com.setec.ecommerce.shared.api.EmptyJsonResponse;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@RequiredArgsConstructor
@Tag(name = "Authentication")
public class AuthController extends BaseController {
  private final AuthService authService;

  @PostMapping("/login")
  @ApiId("AUT-0201")
  @SecurityRequirements
  @Operation(summary = "Log in")
  public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest request) {
    return ok(authService.login(request));
  }

  @PostMapping("/register")
  @ApiId("AUT-0202")
  @SecurityRequirements
  @Operation(summary = "Register an account")
  public ResponseEntity<ApiResponse<AuthResponse>> register(
      @Valid @RequestBody RegisterRequest request) {
    return created(authService.register(request));
  }

  @PostMapping("/refresh")
  @ApiId("AUT-0203")
  @SecurityRequirements
  @Operation(summary = "Rotate a refresh token")
  public ResponseEntity<ApiResponse<TokenResponse>> refresh(
      @Valid @RequestBody RefreshTokenRequest request) {
    return ok(authService.refresh(request));
  }

  @PostMapping("/forgot-password")
  @ApiId("AUT-0204")
  @SecurityRequirements
  @Operation(summary = "Request password recovery")
  public ResponseEntity<ApiResponse<EmptyJsonResponse>> forgotPassword(
      @Valid @RequestBody ForgotPasswordRequest request) {
    authService.forgotPassword(request);
    return noContent();
  }

  @PostMapping("/logout")
  @ApiId("AUT-0205")
  @PreAuthorize("isAuthenticated()")
  @Operation(summary = "Log out")
  public ResponseEntity<ApiResponse<EmptyJsonResponse>> logout() {
    authService.logout();
    return noContent();
  }

  @GetMapping("/me")
  @ApiId("AUT-0601")
  @Operation(summary = "Read the current identity")
  public ResponseEntity<ApiResponse<UserIdentityResponse>> me() {
    return ok(authService.me());
  }
}
