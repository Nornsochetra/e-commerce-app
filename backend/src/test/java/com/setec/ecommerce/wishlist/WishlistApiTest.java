package com.setec.ecommerce.wishlist;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.setec.ecommerce.shared.domain.Category;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.ProductBadgeType;
import com.setec.ecommerce.shared.enums.Role;
import com.setec.ecommerce.shared.repository.CartItemRepository;
import com.setec.ecommerce.shared.repository.CartRepository;
import com.setec.ecommerce.shared.repository.CategoryRepository;
import com.setec.ecommerce.shared.repository.ProductRepository;
import com.setec.ecommerce.shared.repository.UserRepository;
import com.setec.ecommerce.shared.repository.WishlistItemRepository;
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
import org.springframework.test.web.servlet.ResultActions;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class WishlistApiTest {
  @Autowired private MockMvc mockMvc;
  @Autowired private UserRepository userRepository;
  @Autowired private CategoryRepository categoryRepository;
  @Autowired private ProductRepository productRepository;
  @Autowired private CartRepository cartRepository;
  @Autowired private CartItemRepository cartItemRepository;
  @Autowired private WishlistItemRepository wishlistItemRepository;
  @Autowired private JwtTokenProvider tokenProvider;

  @BeforeEach
  void cleanDatabase() {
    wishlistItemRepository.deleteAll();
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
  void emptyWishlistReturnsPaginationWithoutCreatingRows() throws Exception {
    User user = createUser("empty-wishlist@example.com");

    mockMvc
        .perform(get("/api/v1/wishlist/items").header("Authorization", bearer(user)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("WSH-0101"))
        .andExpect(jsonPath("$.data.items", hasSize(0)))
        .andExpect(jsonPath("$.data.page").value(0))
        .andExpect(jsonPath("$.data.size").value(20))
        .andExpect(jsonPath("$.data.totalElements").value(0))
        .andExpect(jsonPath("$.data.totalPages").value(0))
        .andExpect(jsonPath("$.data.hasNext").value(false));

    org.assertj.core.api.Assertions.assertThat(wishlistItemRepository.count()).isZero();
  }

  @Test
  void saveIsCreatedThenIdempotentAndUpdatesCurrentUserCount() throws Exception {
    User user = createUser("save-wishlist@example.com");
    Product product = createProduct("Minimal Watch", "89.00", 8, true, true);
    product.setRating(new BigDecimal("4.8"));
    product.setImageUrl("https://cdn.example.com/minimal-watch.jpg");
    product.setFeatured(true);
    product.setFeaturedRank(1);
    product.addBadge(ProductBadgeType.BESTSELLER);
    productRepository.saveAndFlush(product);

    saveItem(user, product.getUuid())
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.status.code").value("CREATED"))
        .andExpect(jsonPath("$.common.apiId").value("WSH-0201"))
        .andExpect(jsonPath("$.data.id").value(product.getUuid().toString()))
        .andExpect(jsonPath("$.data.name").value("Minimal Watch"))
        .andExpect(jsonPath("$.data.category.name").isNotEmpty())
        .andExpect(jsonPath("$.data.price.amount").value("89.00"))
        .andExpect(jsonPath("$.data.price.currency").value("USD"))
        .andExpect(jsonPath("$.data.availableQuantity").value(8))
        .andExpect(jsonPath("$.data.rating").value("4.8"))
        .andExpect(jsonPath("$.data.imageUrl").value("https://cdn.example.com/minimal-watch.jpg"))
        .andExpect(jsonPath("$.data.badges", contains("bestseller")))
        .andExpect(jsonPath("$.data.featured").value(true));

    saveItem(user, product.getUuid())
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status.code").value("SUCCESS"))
        .andExpect(jsonPath("$.data.id").value(product.getUuid().toString()));

    mockMvc
        .perform(get("/api/v1/auth/me").header("Authorization", bearer(user)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.counts.wishlistItems").value(1));

    org.assertj.core.api.Assertions.assertThat(wishlistItemRepository.count()).isEqualTo(1);
  }

  @Test
  void listIsNewestFirstStableAndPaginated() throws Exception {
    User user = createUser("page-wishlist@example.com");
    Product first = createProduct("First", "10.00", 1, true, true);
    Product second = createProduct("Second", "20.00", 1, true, true);
    Product third = createProduct("Third", "30.00", 1, true, true);
    saveItem(user, first.getUuid());
    saveItem(user, second.getUuid());
    saveItem(user, third.getUuid());

    mockMvc
        .perform(
            get("/api/v1/wishlist/items")
                .header("Authorization", bearer(user))
                .param("page", "0")
                .param("size", "2"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items[*].name", contains("Third", "Second")))
        .andExpect(jsonPath("$.data.page").value(0))
        .andExpect(jsonPath("$.data.size").value(2))
        .andExpect(jsonPath("$.data.totalElements").value(3))
        .andExpect(jsonPath("$.data.totalPages").value(2))
        .andExpect(jsonPath("$.data.hasNext").value(true));
  }

  @Test
  void savedUnavailableProductRemainsVisibleWithCurrentState() throws Exception {
    User user = createUser("unavailable-wishlist@example.com");
    Product product = createProduct("Saved Product", "25.00", 3, true, true);
    saveItem(user, product.getUuid());

    product.setAvailableQuantity(0);
    product.setActive(false);
    product.getCategory().setActive(false);
    categoryRepository.saveAndFlush(product.getCategory());
    productRepository.saveAndFlush(product);

    mockMvc
        .perform(get("/api/v1/wishlist/items").header("Authorization", bearer(user)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items", hasSize(1)))
        .andExpect(jsonPath("$.data.items[0].id").value(product.getUuid().toString()))
        .andExpect(jsonPath("$.data.items[0].availableQuantity").value(0));

    saveItem(user, product.getUuid())
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.id").value(product.getUuid().toString()))
        .andExpect(jsonPath("$.data.availableQuantity").value(0));
  }

  @Test
  void saveRejectsMissingInactiveAndHiddenCategoryProducts() throws Exception {
    User user = createUser("invalid-wishlist@example.com");
    Product inactive = createProduct("Inactive", "10.00", 1, false, true);
    Product hiddenCategory = createProduct("Hidden", "10.00", 1, true, false);

    for (UUID productId :
        List.of(UUID.randomUUID(), inactive.getUuid(), hiddenCategory.getUuid())) {
      saveItem(user, productId)
          .andExpect(status().isNotFound())
          .andExpect(jsonPath("$.status.code").value("PRODUCT_NOT_FOUND"));
    }
  }

  @Test
  void removeIsOwnerScopedAndMissingItemReturnsNotFound() throws Exception {
    User owner = createUser("wishlist-owner@example.com");
    User other = createUser("wishlist-other@example.com");
    Product product = createProduct("Saved Product", "25.00", 3, true, true);
    saveItem(owner, product.getUuid());

    mockMvc
        .perform(
            delete("/api/v1/wishlist/items/{productId}", product.getUuid())
                .header("Authorization", bearer(other)))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("WISHLIST_ITEM_NOT_FOUND"));

    mockMvc
        .perform(
            delete("/api/v1/wishlist/items/{productId}", product.getUuid())
                .header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("WSH-0501"))
        .andExpect(jsonPath("$.data").isEmpty());

    mockMvc
        .perform(
            delete("/api/v1/wishlist/items/{productId}", product.getUuid())
                .header("Authorization", bearer(owner)))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("WISHLIST_ITEM_NOT_FOUND"));
  }

  @Test
  void wishlistRequiresAuthenticationAndValidatesInputs() throws Exception {
    User user = createUser("wishlist-validation@example.com");

    mockMvc
        .perform(get("/api/v1/wishlist/items"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
    mockMvc
        .perform(
            post("/api/v1/wishlist/items")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"productId\":\"" + UUID.randomUUID() + "\"}"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
    mockMvc
        .perform(
            post("/api/v1/wishlist/items")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
    mockMvc
        .perform(
            post("/api/v1/wishlist/items")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"productId\":\"" + UUID.randomUUID() + "\",\"userId\":1}"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("INVALID_REQUEST"));
    mockMvc
        .perform(
            get("/api/v1/wishlist/items")
                .header("Authorization", bearer(user))
                .param("size", "101"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
  }

  private ResultActions saveItem(User user, UUID productId) throws Exception {
    return mockMvc.perform(
        post("/api/v1/wishlist/items")
            .header("Authorization", bearer(user))
            .contentType(MediaType.APPLICATION_JSON)
            .content("{\"productId\":\"" + productId + "\"}"));
  }

  private User createUser(String email) {
    return userRepository.saveAndFlush(
        User.builder()
            .name("Wishlist User")
            .email(email)
            .passwordHash("unused-in-wishlist-tests")
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
