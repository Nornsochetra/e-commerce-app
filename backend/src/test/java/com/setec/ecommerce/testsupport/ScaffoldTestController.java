package com.setec.ecommerce.testsupport;

import com.setec.ecommerce.shared.api.ApiId;
import com.setec.ecommerce.shared.api.ApiResponse;
import com.setec.ecommerce.shared.api.BaseController;
import com.setec.ecommerce.shared.api.EmptyJsonResponse;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.exception.BusinessException;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/test-support")
public class ScaffoldTestController extends BaseController {
  @GetMapping("/secure")
  @ApiId("TST-0601")
  public ResponseEntity<ApiResponse<EmptyJsonResponse>> secure() {
    return noContent();
  }

  @PostMapping("/echo")
  @ApiId("TST-0201")
  public ResponseEntity<ApiResponse<Echo>> echo(@Valid @RequestBody Echo echo) {
    return ok(echo);
  }

  @DeleteMapping("/user-only")
  @ApiId("TST-0501")
  @PreAuthorize("hasRole('USER')")
  public ResponseEntity<ApiResponse<EmptyJsonResponse>> userOnly() {
    return noContent();
  }

  @GetMapping("/business-error")
  @ApiId("TST-0602")
  public ResponseEntity<ApiResponse<EmptyJsonResponse>> businessError() {
    throw new BusinessException(StatusCode.NOT_FOUND, "test resource");
  }

  @GetMapping("/number/{id}")
  @ApiId("TST-0603")
  public ResponseEntity<ApiResponse<Long>> number(@PathVariable Long id) {
    return ok(id);
  }

  @GetMapping("/require-param")
  @ApiId("TST-0604")
  public ResponseEntity<ApiResponse<String>> requireParam(@RequestParam String value) {
    return ok(value);
  }

  @GetMapping("/untraced")
  public ResponseEntity<ApiResponse<EmptyJsonResponse>> untraced() {
    return noContent();
  }

  public record Echo(
      @NotBlank(message = "Name is required") String name,
      @NotNull(message = "Mode is required") Mode mode) {}

  public enum Mode {
    FAST,
    SLOW
  }
}
