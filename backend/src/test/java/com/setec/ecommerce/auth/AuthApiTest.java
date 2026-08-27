package com.setec.ecommerce.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.blankOrNullString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.jayway.jsonpath.JsonPath;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.Role;
import com.setec.ecommerce.shared.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class AuthApiTest {
  @Autowired private MockMvc mockMvc;
  @Autowired private UserRepository userRepository;
  @Autowired private PasswordEncoder passwordEncoder;

  @BeforeEach
  void cleanDatabase() {
    userRepository.deleteAll();
  }

  @Test
  void registrationCreatesUserAndReturnsTokenPair() throws Exception {
    MvcResult result = register("Alex Morgan", " Alex@Example.com ", "password123");

    String body = result.getResponse().getContentAsString();
    assertThat(JsonPath.<String>read(body, "$.data.accessToken")).isNotBlank();
    assertThat(JsonPath.<String>read(body, "$.data.refreshToken")).isNotBlank();
    assertThat(JsonPath.<Integer>read(body, "$.data.expiresIn")).isEqualTo(900);
    assertThat(JsonPath.<String>read(body, "$.data.user.email")).isEqualTo("alex@example.com");
    assertThat(JsonPath.<String>read(body, "$.data.user.role")).isEqualTo("user");
    assertThat(JsonPath.<String>read(body, "$.data.user.id")).isNotBlank();

    User stored = userRepository.findByEmailIgnoringCase("ALEX@EXAMPLE.COM").orElseThrow();
    assertThat(stored.getPasswordHash()).isNotEqualTo("password123");
    assertThat(passwordEncoder.matches("password123", stored.getPasswordHash())).isTrue();
  }

  @Test
  void duplicateRegistrationIsCaseInsensitive() throws Exception {
    register("Alex Morgan", "alex@example.com", "password123");

    mockMvc
        .perform(
            post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"name\":\"Other\",\"email\":\"ALEX@EXAMPLE.COM\",\"password\":\"password123\"}"))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("EMAIL_ALREADY_REGISTERED"));
  }

  @Test
  void loginReturnsTokensAndUpdatesLastLogin() throws Exception {
    createUser("alex@example.com", "password123", true);

    mockMvc
        .perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"ALEX@example.com\",\"password\":\"password123\"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status.code").value("SUCCESS"))
        .andExpect(jsonPath("$.data.accessToken", not(blankOrNullString())))
        .andExpect(jsonPath("$.data.refreshToken", not(blankOrNullString())))
        .andExpect(jsonPath("$.data.user.role").value("user"));

    assertThat(
            userRepository
                .findByEmailIgnoringCase("alex@example.com")
                .orElseThrow()
                .getLastLoginAt())
        .isNotNull();
  }

  @Test
  void wrongEmailAndWrongPasswordUseSameErrorCode() throws Exception {
    createUser("alex@example.com", "password123", true);

    assertInvalidCredentials("missing@example.com", "password123");
    assertInvalidCredentials("alex@example.com", "nottherightpassword");
  }

  @Test
  void disabledAccountCannotLogin() throws Exception {
    createUser("alex@example.com", "password123", false);

    mockMvc
        .perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"alex@example.com\",\"password\":\"password123\"}"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("ACCOUNT_DISABLED"));
  }

  @Test
  void refreshIssuesANewPairAndOldTokenRemainsValidUntilExpiry() throws Exception {
    MvcResult registration = register("Alex", "alex@example.com", "password123");
    String oldRefresh =
        JsonPath.read(registration.getResponse().getContentAsString(), "$.data.refreshToken");

    MvcResult refreshResult =
        mockMvc
            .perform(
                post("/api/v1/auth/refresh")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(jsonToken(oldRefresh)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.data.accessToken", not(blankOrNullString())))
            .andExpect(jsonPath("$.data.refreshToken", not(blankOrNullString())))
            .andReturn();
    String newRefresh =
        JsonPath.read(refreshResult.getResponse().getContentAsString(), "$.data.refreshToken");
    assertThat(newRefresh).isNotEqualTo(oldRefresh);

    mockMvc
        .perform(
            post("/api/v1/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonToken(oldRefresh)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status.code").value("SUCCESS"));
  }

  @Test
  void accessTokenCannotBeUsedAsRefreshToken() throws Exception {
    MvcResult registration = register("Alex", "alex@example.com", "password123");
    String accessToken =
        JsonPath.read(registration.getResponse().getContentAsString(), "$.data.accessToken");

    mockMvc
        .perform(
            post("/api/v1/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonToken(accessToken)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("INVALID_REFRESH_TOKEN"));
  }

  @Test
  void logoutRevokesAccessAndRefreshTokensWithoutRequestBody() throws Exception {
    MvcResult registration = register("Alex", "alex@example.com", "password123");
    String body = registration.getResponse().getContentAsString();
    String accessToken = JsonPath.read(body, "$.data.accessToken");
    String refreshToken = JsonPath.read(body, "$.data.refreshToken");

    mockMvc
        .perform(post("/api/v1/auth/logout").header("Authorization", "Bearer " + accessToken))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data").isMap());

    mockMvc
        .perform(
            post("/api/v1/auth/refresh")
                .contentType(MediaType.APPLICATION_JSON)
                .content(jsonToken(refreshToken)))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("INVALID_REFRESH_TOKEN"));

    mockMvc
        .perform(get("/api/v1/auth/me").header("Authorization", "Bearer " + accessToken))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("INVALID_TOKEN"));
  }

  @Test
  void currentIdentityRequiresAccessToken() throws Exception {
    MvcResult registration = register("Alex", "alex@example.com", "password123");
    String body = registration.getResponse().getContentAsString();
    String accessToken = JsonPath.read(body, "$.data.accessToken");

    mockMvc
        .perform(get("/api/v1/auth/me").header("Authorization", "Bearer " + accessToken))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("AUT-0601"))
        .andExpect(jsonPath("$.data.name").value("Alex"))
        .andExpect(jsonPath("$.data.email").value("alex@example.com"))
        .andExpect(jsonPath("$.data.phone").value((Object) null))
        .andExpect(jsonPath("$.data.role").value("user"))
        .andExpect(jsonPath("$.data.memberSince").isNotEmpty())
        .andExpect(jsonPath("$.data.createdAt").isNotEmpty())
        .andExpect(jsonPath("$.data.updatedAt").isNotEmpty())
        .andExpect(jsonPath("$.data.counts.orders").value(0))
        .andExpect(jsonPath("$.data.counts.wishlistItems").value(0))
        .andExpect(jsonPath("$.data.counts.cartItems").value(0));

    mockMvc
        .perform(get("/api/v1/auth/me"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
  }

  @Test
  void forgotPasswordDoesNotRevealAccountExistence() throws Exception {
    createUser("known@example.com", "password123", true);

    for (String email : new String[] {"known@example.com", "missing@example.com"}) {
      mockMvc
          .perform(
              post("/api/v1/auth/forgot-password")
                  .contentType(MediaType.APPLICATION_JSON)
                  .content("{\"email\":\"" + email + "\"}"))
          .andExpect(status().isOk())
          .andExpect(jsonPath("$.status.code").value("SUCCESS"))
          .andExpect(jsonPath("$.data").isMap());
    }
  }

  @Test
  void requestValidationRejectsShortPasswordAndUnknownField() throws Exception {
    mockMvc
        .perform(
            post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"name\":\"Alex\",\"email\":\"alex@example.com\",\"password\":\"short\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));

    mockMvc
        .perform(
            post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"name\":\"Alex\",\"email\":\"alex@example.com\",\"password\":\"password123\",\"role\":\"GUEST\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("INVALID_REQUEST"));
  }

  private MvcResult register(String name, String email, String password) throws Exception {
    return mockMvc
        .perform(
            post("/api/v1/auth/register")
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"name\":\""
                        + name
                        + "\",\"email\":\""
                        + email
                        + "\",\"password\":\""
                        + password
                        + "\"}"))
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.status.code").value("CREATED"))
        .andExpect(jsonPath("$.common.apiId").value("AUT-0202"))
        .andReturn();
  }

  private User createUser(String email, String password, boolean active) {
    return userRepository.saveAndFlush(
        User.builder()
            .name("Alex")
            .email(email)
            .passwordHash(passwordEncoder.encode(password))
            .role(Role.USER)
            .active(active)
            .build());
  }

  private void assertInvalidCredentials(String email, String password) throws Exception {
    mockMvc
        .perform(
            post("/api/v1/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"" + email + "\",\"password\":\"" + password + "\"}"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("INVALID_CREDENTIALS"));
  }

  private String jsonToken(String token) {
    return "{\"refreshToken\":\"" + token + "\"}";
  }
}
