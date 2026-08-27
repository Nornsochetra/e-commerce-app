package com.setec.ecommerce.health.controller;

import com.setec.ecommerce.health.payload.HealthResponse;
import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/health")
@Tag(name = "Health")
public class HealthController extends BaseController {
  @Value("${spring.application.name}")
  private String serviceName;

  @GetMapping
  @ApiId("HLT-0601")
  @SecurityRequirements
  @Operation(summary = "Liveness check")
  public ResponseEntity<ApiResponse<HealthResponse>> health() {
    return ok(new HealthResponse("UP", serviceName));
  }
}
