package com.setec.ecommerce.cart;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.nullValue;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.setec.ecommerce.shared.domain.Cart;
import com.setec.ecommerce.shared.domain.CartItem;
import com.setec.ecommerce.shared.domain.Category;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.Role;
import com.setec.ecommerce.shared.repository.CartItemRepository;
import com.setec.ecommerce.shared.repository.CartRepository;
import com.setec.ecommerce.shared.repository.CategoryRepository;
import com.setec.ecommerce.shared.repository.ProductRepository;
import com.setec.ecommerce.shared.repository.UserRepository;
import com.setec.ecommerce.shared.security.JwtTokenProvider;
import com.setec.ecommerce.shared.security.TokenType;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.AfterEach;
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
class CartApiTest {
  @Autowired private MockMvc mockMvc;
  @Autowired private UserRepository userRepository;
  @Autowired private CategoryRepository categoryRepository;
  @Autowired private ProductRepository productRepository;
  @Autowired private CartRepository cartRepository;
  @Autowired private CartItemRepository cartItemRepository;
  @Autowired private JwtTokenProvider tokenProvider;

  @BeforeEach
  void cleanDatabase() {
    cartItemRepository.deleteAll();
    cartRepository.deleteAll();
    productRepository.deleteAll();
    categoryRepository.deleteAll();
    userRepository.deleteAll();
  }

  @AfterEach
  void cleanDatabaseAfterTest() {
    cleanDatabase();
  }

  @Test
  void emptyCartDoesNotCreatePersistentCart() throws Exception {
    User user = createUser("empty@example.com");

    mockMvc
        .perform(get("/api/v1/cart").header("Authorization", bearer(user)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("CRT-0601"))
        .andExpect(jsonPath("$.data.id").value(nullValue()))
        .andExpect(jsonPath("$.data.items", hasSize(0)))
        .andExpect(jsonPath("$.data.subtotal.amount").value("0.00"))
        .andExpect(jsonPath("$.data.subtotal.currency").value("USD"))
        .andExpect(jsonPath("$.data.itemCount").value(0))
        .andExpect(jsonPath("$.data.updatedAt").value(nullValue()));

    org.assertj.core.api.Assertions.assertThat(cartRepository.count()).isZero();
  }

  @Test
  void addCreatesCartAndRepeatedAddIncreasesQuantityAndTotals() throws Exception {
    User user = createUser("cart@example.com");
    Product product = createProduct("Minimal Watch", "89.00", 8, true, true);

    addItem(user, product.getUuid(), 1)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("CRT-0201"))
        .andExpect(jsonPath("$.data.id").isNotEmpty())
        .andExpect(jsonPath("$.data.items", hasSize(1)))
        .andExpect(jsonPath("$.data.items[0].product.id").value(product.getUuid().toString()))
        .andExpect(jsonPath("$.data.items[0].product.name").value("Minimal Watch"))
        .andExpect(jsonPath("$.data.items[0].product.availableQuantity").value(8))
        .andExpect(jsonPath("$.data.items[0].quantity").value(1))
        .andExpect(jsonPath("$.data.items[0].unitPrice.amount").value("89.00"))
        .andExpect(jsonPath("$.data.items[0].lineTotal.amount").value("89.00"))
        .andExpect(jsonPath("$.data.subtotal.amount").value("89.00"))
        .andExpect(jsonPath("$.data.itemCount").value(1));

    addItem(user, product.getUuid(), 2)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items", hasSize(1)))
        .andExpect(jsonPath("$.data.items[0].quantity").value(3))
        .andExpect(jsonPath("$.data.items[0].lineTotal.amount").value("267.00"))
        .andExpect(jsonPath("$.data.subtotal.amount").value("267.00"))
        .andExpect(jsonPath("$.data.itemCount").value(3));

    mockMvc
        .perform(get("/api/v1/auth/me").header("Authorization", bearer(user)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.counts.cartItems").value(3));

    org.assertj.core.api.Assertions.assertThat(cartRepository.count()).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(cartItemRepository.count()).isEqualTo(1);
  }

  @Test
  void cartSubtotalAndBadgeUseAllItemQuantities() throws Exception {
    User user = createUser("totals@example.com");
    Product first = createProduct("First", "10.50", 5, true, true);
    Product second = createProduct("Second", "20.00", 5, true, true);
    addItem(user, first.getUuid(), 2);
    addItem(user, second.getUuid(), 3);

    mockMvc
        .perform(get("/api/v1/cart").header("Authorization", bearer(user)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items", hasSize(2)))
        .andExpect(jsonPath("$.data.subtotal.amount").value("81.00"))
        .andExpect(jsonPath("$.data.itemCount").value(5));
  }

  @Test
  void addRejectsMissingHiddenOutOfStockAndInsufficientProducts() throws Exception {
    User user = createUser("stock@example.com");
    Product outOfStock = createProduct("Empty", "10.00", 0, true, true);
    Product insufficient = createProduct("Limited", "10.00", 2, true, true);
    Product inactive = createProduct("Inactive", "10.00", 2, false, true);
    Product hiddenCategory = createProduct("Hidden", "10.00", 2, true, false);

    addItem(user, UUID.randomUUID(), 1)
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("PRODUCT_NOT_FOUND"));
    addItem(user, inactive.getUuid(), 1)
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("PRODUCT_NOT_FOUND"));
    addItem(user, hiddenCategory.getUuid(), 1)
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("PRODUCT_NOT_FOUND"));
    addItem(user, outOfStock.getUuid(), 1)
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("PRODUCT_OUT_OF_STOCK"));
    addItem(user, insufficient.getUuid(), 3)
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("INSUFFICIENT_STOCK"));
  }

  @Test
  void quantityValidationRejectsMissingZeroAndUnknownFields() throws Exception {
    User user = createUser("validation@example.com");
    Product product = createProduct("Product", "10.00", 5, true, true);

    for (String body :
        List.of(
            "{\"productId\":\"" + product.getUuid() + "\"}",
            "{\"productId\":\"" + product.getUuid() + "\",\"quantity\":0}")) {
      mockMvc
          .perform(
              post("/api/v1/cart/items")
                  .header("Authorization", bearer(user))
                  .contentType(MediaType.APPLICATION_JSON)
                  .content(body))
          .andExpect(status().isBadRequest())
          .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
    }

    mockMvc
        .perform(
            post("/api/v1/cart/items")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content(
                    "{\"productId\":\""
                        + product.getUuid()
                        + "\",\"quantity\":1,\"price\":\"1.00\"}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("INVALID_REQUEST"));
  }

  @Test
  void patchSetsQuantityAndRevalidatesCurrentStock() throws Exception {
    User user = createUser("patch@example.com");
    Product product = createProduct("Product", "12.00", 4, true, true);
    addItem(user, product.getUuid(), 2);
    CartItem item = currentItem(user);

    mockMvc
        .perform(
            patch("/api/v1/cart/items/{itemId}", item.getUuid())
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"quantity\":3}"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("CRT-0401"))
        .andExpect(jsonPath("$.data.items[0].quantity").value(3))
        .andExpect(jsonPath("$.data.subtotal.amount").value("36.00"));

    mockMvc
        .perform(
            patch("/api/v1/cart/items/{itemId}", item.getUuid())
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"quantity\":5}"))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("INSUFFICIENT_STOCK"));

    product.setAvailableQuantity(0);
    productRepository.saveAndFlush(product);
    mockMvc
        .perform(
            patch("/api/v1/cart/items/{itemId}", item.getUuid())
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"quantity\":1}"))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("PRODUCT_OUT_OF_STOCK"));
  }

  @Test
  void deleteRemovesItemAndReturnsPersistedEmptyCart() throws Exception {
    User user = createUser("delete@example.com");
    Product product = createProduct("Product", "12.00", 4, true, true);
    addItem(user, product.getUuid(), 1);
    CartItem item = currentItem(user);

    mockMvc
        .perform(
            delete("/api/v1/cart/items/{itemId}", item.getUuid())
                .header("Authorization", bearer(user)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("CRT-0501"))
        .andExpect(jsonPath("$.data.id").isNotEmpty())
        .andExpect(jsonPath("$.data.items", hasSize(0)))
        .andExpect(jsonPath("$.data.subtotal.amount").value("0.00"))
        .andExpect(jsonPath("$.data.itemCount").value(0));

    org.assertj.core.api.Assertions.assertThat(cartItemRepository.count()).isZero();
    org.assertj.core.api.Assertions.assertThat(cartRepository.count()).isEqualTo(1);
  }

  @Test
  void cartItemsAreOwnerScopedAndCartEndpointsRequireAuthentication() throws Exception {
    User owner = createUser("owner@example.com");
    User other = createUser("other@example.com");
    Product product = createProduct("Product", "12.00", 4, true, true);
    addItem(owner, product.getUuid(), 1);
    CartItem item = currentItem(owner);

    mockMvc
        .perform(
            patch("/api/v1/cart/items/{itemId}", item.getUuid())
                .header("Authorization", bearer(other))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"quantity\":2}"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("CART_ITEM_NOT_FOUND"));
    mockMvc
        .perform(
            delete("/api/v1/cart/items/{itemId}", item.getUuid())
                .header("Authorization", bearer(other)))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("CART_ITEM_NOT_FOUND"));
    mockMvc
        .perform(get("/api/v1/cart"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
    mockMvc
        .perform(
            post("/api/v1/cart/items")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"productId\":\"" + product.getUuid() + "\",\"quantity\":1}"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
  }

  private org.springframework.test.web.servlet.ResultActions addItem(
      User user, UUID productId, int quantity) throws Exception {
    return mockMvc.perform(
        post("/api/v1/cart/items")
            .header("Authorization", bearer(user))
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"productId\":\"" + productId + "\",\"quantity\":" + quantity + "}"));
  }

  private CartItem currentItem(User user) {
    Cart cart = cartRepository.findDetailedByUserId(user.getId()).orElseThrow();
    return cart.getItems().getFirst();
  }

  private User createUser(String email) {
    return userRepository.saveAndFlush(
        User.builder()
            .name("Cart User")
            .email(email)
            .passwordHash("unused-in-cart-tests")
            .role(Role.USER)
            .active(true)
            .build());
  }

  private Product createProduct(
      String name, String price, int quantity, boolean productActive, boolean categoryActive) {
    String suffix = UUID.randomUUID().toString();
    Category category =
        categoryRepository.saveAndFlush(
            Category.builder()
                .name("Category " + suffix)
                .slug("category-" + suffix)
                .active(categoryActive)
                .build());
    return productRepository.saveAndFlush(
        Product.builder()
            .category(category)
            .name(name)
            .price(new BigDecimal(price))
            .currency("USD")
            .availableQuantity(quantity)
            .active(productActive)
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
