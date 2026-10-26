package com.setec.ecommerce.shared;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.options;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

/** Uses the dev-style pattern list, so any localhost port is allowed and other sites are not. */
@SpringBootTest(properties = "app.cors.allowed-origins=http://localhost:*,http://127.0.0.1:*")
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CorsApiTest {
  @Autowired private MockMvc mockMvc;

  @Test
  void flutterWebOnARandomLocalhostPortIsAllowed() throws Exception {
    mockMvc
        .perform(
            options("/api/v1/products")
                .header("Origin", "http://localhost:57457")
                .header("Access-Control-Request-Method", "GET"))
        .andExpect(status().isOk())
        .andExpect(header().string("Access-Control-Allow-Origin", "http://localhost:57457"));
  }

  @Test
  void otherOriginsAreRejected() throws Exception {
    mockMvc
        .perform(
            options("/api/v1/products")
                .header("Origin", "http://evil.example.com")
                .header("Access-Control-Request-Method", "GET"))
        .andExpect(status().isForbidden())
        .andExpect(header().doesNotExist("Access-Control-Allow-Origin"));
  }
}
