package com.setec.ecommerce.shared;

import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.containsInAnyOrder;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.Role;
import com.setec.ecommerce.shared.properties.JwtProperties;
import com.setec.ecommerce.shared.repository.UserRepository;
import com.setec.ecommerce.shared.security.JwtTokenProvider;
import com.setec.ecommerce.shared.security.RsaKeyProvider;
import com.setec.ecommerce.shared.security.TokenType;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.core.io.DefaultResourceLoader;
import org.springframework.http.MediaType;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ScaffoldingApiTest {
  @Autowired private MockMvc mockMvc;
  @Autowired private JwtTokenProvider tokenProvider;
  @Autowired private UserRepository userRepository;
  private String userId;

  @BeforeEach
  void createAuthenticatedUser() {
    userRepository.deleteAll();
    User user =
        userRepository.saveAndFlush(
            User.builder()
                .name("Test User")
                .email("test-user@example.com")
                .passwordHash("unused-in-scaffolding-tests")
                .role(Role.USER)
                .active(true)
                .build());
    userId = user.getId().toString();
  }

  @Test
  void healthIsPublicAndCarriesApiIdAndTraceId() throws Exception {
    mockMvc
        .perform(get("/api/v1/health"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status.code").value("SUCCESS"))
        .andExpect(jsonPath("$.data.status").value("UP"))
        .andExpect(jsonPath("$.common.apiId").value("HLT-0601"))
        .andExpect(jsonPath("$.common.requestId", not(blankOrNullString())))
        .andExpect(header().exists("X-Request-Id"))
        .andExpect(header().string("X-Api-Id", "HLT-0601"));
  }

  @Test
  void inboundRequestIdIsHonored() throws Exception {
    mockMvc
        .perform(get("/api/v1/health").header("X-Request-Id", "trace-from-client"))
        .andExpect(header().string("X-Request-Id", "trace-from-client"))
        .andExpect(jsonPath("$.common.requestId").value("trace-from-client"));
  }

  @Test
  void missingTokenIsUnauthorized() throws Exception {
    mockMvc
        .perform(get("/api/v1/test-support/secure"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"))
        .andExpect(jsonPath("$.data").doesNotExist())
        .andExpect(jsonPath("$.error.type").value("AUTHENTICATION"));
  }

  @Test
  void garbageTokenIsInvalid() throws Exception {
    mockMvc
        .perform(get("/api/v1/test-support/secure").header("Authorization", "Bearer garbage"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("INVALID_TOKEN"));
  }

  @Test
  void refreshTokenCannotAuthorizeApiRequest() throws Exception {
    String refresh = tokenProvider.generate(userId, TokenType.REFRESH, List.of("USER"), 0);
    mockMvc
        .perform(get("/api/v1/test-support/secure").header("Authorization", "Bearer " + refresh))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("INVALID_TOKEN"));
  }

  @Test
  void accessTokenAuthorizesApiRequest() throws Exception {
    mockMvc
        .perform(get("/api/v1/test-support/secure").header("Authorization", bearer(userId, "USER")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status.code").value("SUCCESS"));
  }

  @Test
  void methodSecurityReturnsForbiddenForWrongRole() throws Exception {
    mockMvc
        .perform(
            delete("/api/v1/test-support/user-only")
                .header("Authorization", bearer(userId, "GUEST")))
        .andExpect(status().isForbidden())
        .andExpect(jsonPath("$.status.code").value("FORBIDDEN"))
        .andExpect(jsonPath("$.error.type").value("AUTHORIZATION"));
  }

  @Test
  void methodSecurityAllowsCorrectRole() throws Exception {
    mockMvc
        .perform(
            delete("/api/v1/test-support/user-only")
                .header("Authorization", bearer(userId, "USER")))
        .andExpect(status().isOk());
  }

  @Test
  void validationReturnsEveryRejectedField() throws Exception {
    mockMvc
        .perform(
            post("/api/v1/test-support/echo")
                .header("Authorization", bearer(userId, "USER"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"\",\"mode\":null}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"))
        .andExpect(jsonPath("$.error.details", hasSize(2)))
        .andExpect(jsonPath("$.error.details[*].field", containsInAnyOrder("name", "mode")));
  }

  @Test
  void invalidEnumListsAcceptedValues() throws Exception {
    mockMvc
        .perform(
            post("/api/v1/test-support/echo")
                .header("Authorization", bearer(userId, "USER"))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"Job\",\"mode\":\"MEDIUM\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("INVALID_REQUEST"))
        .andExpect(
            jsonPath("$.error.message").value(org.hamcrest.Matchers.containsString("FAST, SLOW")));
  }

  @Test
  void businessExceptionUsesEnvelope() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/test-support/business-error")
                .header("Authorization", bearer(userId, "USER")))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("NOT_FOUND"));
  }

  @Test
  void pathTypeMismatchIsBadRequest() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/test-support/number/abc").header("Authorization", bearer(userId, "USER")))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("INVALID_REQUEST"));
  }

  @Test
  void missingParameterIsBadRequest() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/test-support/require-param")
                .header("Authorization", bearer(userId, "USER")))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("INVALID_REQUEST"));
  }

  @Test
  void unsupportedMethodIsNotAllowed() throws Exception {
    mockMvc
        .perform(post("/api/v1/health"))
        .andExpect(status().isMethodNotAllowed())
        .andExpect(jsonPath("$.status.code").value("METHOD_NOT_ALLOWED"));
  }

  @Test
  void unknownUrlUsesNotFoundEnvelope() throws Exception {
    mockMvc
        .perform(get("/api/v1/not-a-route").header("Authorization", bearer(userId, "USER")))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("NOT_FOUND"));
  }

  @Test
  void missingApiIdDegradesToUnknown() throws Exception {
    mockMvc
        .perform(
            get("/api/v1/test-support/untraced").header("Authorization", bearer(userId, "USER")))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("UNKNOWN"));
  }

  @Test
  void unblessedProfileRequiresConfiguredRsaKeys() {
    JwtProperties properties = new JwtProperties();
    MockEnvironment environment = new MockEnvironment();
    environment.setActiveProfiles("staging");

    assertThatThrownBy(
            () -> new RsaKeyProvider(properties, new DefaultResourceLoader(), environment))
        .isInstanceOf(IllegalStateException.class)
        .hasMessageContaining("No RSA keypair configured");
  }

  private String bearer(String subject, String... roles) {
    return "Bearer " + tokenProvider.generate(subject, TokenType.ACCESS, List.of(roles), 0);
  }
}
