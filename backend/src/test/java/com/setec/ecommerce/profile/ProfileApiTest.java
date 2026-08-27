package com.setec.ecommerce.profile;

import static org.hamcrest.Matchers.hasItems;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.Role;
import com.setec.ecommerce.shared.repository.UserRepository;
import com.setec.ecommerce.shared.security.JwtTokenProvider;
import com.setec.ecommerce.shared.security.TokenType;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class ProfileApiTest {
  @Autowired private MockMvc mockMvc;
  @Autowired private UserRepository userRepository;
  @Autowired private JwtTokenProvider tokenProvider;

  @BeforeEach
  void cleanDatabase() {
    userRepository.deleteAll();
  }

  @Test
  void updateTrimsFieldsNormalizesEmailAndPreservesRole() throws Exception {
    User user = createUser("alex@example.com", "Alex", null);

    mockMvc
        .perform(
            patch("/api/v1/me/profile")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"name\":\"  Alex Morgan  \",\"email\":\" NEW@Example.com \","
                        + "\"phone\":\"  +855 12 345 678  \"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("USR-0401"))
        .andExpect(jsonPath("$.data.name").value("Alex Morgan"))
        .andExpect(jsonPath("$.data.email").value("new@example.com"))
        .andExpect(jsonPath("$.data.phone").value("+855 12 345 678"))
        .andExpect(jsonPath("$.data.role").value("user"))
        .andExpect(jsonPath("$.data.memberSince").isNotEmpty())
        .andExpect(jsonPath("$.data.counts.orders").value(0))
        .andExpect(jsonPath("$.data.counts.wishlistItems").value(0))
        .andExpect(jsonPath("$.data.counts.cartItems").value(0))
        .andExpect(jsonPath("$.data.createdAt").isNotEmpty())
        .andExpect(jsonPath("$.data.updatedAt").isNotEmpty());

    User stored = userRepository.findById(user.getId()).orElseThrow();
    org.assertj.core.api.Assertions.assertThat(stored.getName()).isEqualTo("Alex Morgan");
    org.assertj.core.api.Assertions.assertThat(stored.getEmail()).isEqualTo("new@example.com");
    org.assertj.core.api.Assertions.assertThat(stored.getRole()).isEqualTo(Role.USER);
  }

  @Test
  void partialUpdatePreservesOmittedFieldsAndEmptyPhoneClearsIt() throws Exception {
    User user = createUser("alex@example.com", "Alex Morgan", "+855 12 345 678");

    mockMvc
        .perform(
            patch("/api/v1/me/profile")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"phone\":\"   \"}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.name").value("Alex Morgan"))
        .andExpect(jsonPath("$.data.email").value("alex@example.com"))
        .andExpect(jsonPath("$.data.phone").value((Object) null));
  }

  @Test
  void duplicateEmailIsRejectedCaseInsensitively() throws Exception {
    User user = createUser("alex@example.com", "Alex", null);
    createUser("taken@example.com", "Taken", null);

    mockMvc
        .perform(
            patch("/api/v1/me/profile")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"TAKEN@EXAMPLE.COM\"}"))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("EMAIL_ALREADY_REGISTERED"));
  }

  @Test
  void invalidFieldsAreReported() throws Exception {
    User user = createUser("alex@example.com", "Alex", null);

    mockMvc
        .perform(
            patch("/api/v1/me/profile")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"name\":\"   \",\"email\":\"invalid\","
                        + "\"phone\":\"123456789012345678901234567890123\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"))
        .andExpect(jsonPath("$.error.details[*].field", hasItems("name", "email", "phone")));
  }

  @Test
  void emptyOrUnknownPatchIsRejected() throws Exception {
    User user = createUser("alex@example.com", "Alex", null);

    mockMvc
        .perform(
            patch("/api/v1/me/profile")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));

    mockMvc
        .perform(
            patch("/api/v1/me/profile")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"role\":\"USER\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("INVALID_REQUEST"));
  }

  @Test
  void profileUpdateRequiresAuthentication() throws Exception {
    mockMvc
        .perform(
            patch("/api/v1/me/profile")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"Alex\"}"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
  }

  private User createUser(String email, String name, String phone) {
    return userRepository.saveAndFlush(
        User.builder()
            .name(name)
            .email(email)
            .phone(phone)
            .passwordHash("unused-in-profile-tests")
            .role(Role.USER)
            .active(true)
            .build());
  }

  private String bearer(User user) {
    return "Bearer "
        + tokenProvider.generate(
            user.getId().toString(),
            TokenType.ACCESS,
            List.of(user.getRole().name()),
            user.getTokenVersion());
  }
}
