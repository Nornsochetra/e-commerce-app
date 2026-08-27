package com.setec.ecommerce.profile.controller;

import com.setec.ecommerce.auth.payload.CurrentUserResponse;
import com.setec.ecommerce.profile.payload.UpdateProfileRequest;
import com.setec.ecommerce.profile.service.ProfileService;
import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/me/profile")
@RequiredArgsConstructor
@Tag(name = "User Profile")
public class ProfileController extends BaseController {
  private final ProfileService profileService;

  @PatchMapping
  @ApiId("USR-0401")
  @Operation(summary = "Update the current user profile")
  public ResponseEntity<ApiResponse<CurrentUserResponse>> updateCurrentProfile(
      @Valid @RequestBody UpdateProfileRequest request) {
    return ok(profileService.updateCurrentProfile(request));
  }
}
