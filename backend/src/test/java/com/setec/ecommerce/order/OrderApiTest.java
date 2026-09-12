package com.setec.ecommerce.order;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.matchesPattern;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.setec.ecommerce.shared.domain.Cart;
import com.setec.ecommerce.shared.domain.CartItem;
import com.setec.ecommerce.shared.domain.Category;
import com.setec.ecommerce.shared.domain.Order;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.OrderStatus;
import com.setec.ecommerce.shared.enums.Role;
import com.setec.ecommerce.shared.repository.CartItemRepository;
import com.setec.ecommerce.shared.repository.CartRepository;
import com.setec.ecommerce.shared.repository.CategoryRepository;
import com.setec.ecommerce.shared.repository.NotificationRepository;
import com.setec.ecommerce.shared.repository.OrderItemRepository;
import com.setec.ecommerce.shared.repository.OrderRepository;
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
class OrderApiTest {
  private static final String CHECKOUT_BODY =
      """
      {
        "delivery": {
          "recipientName": "  Alex Morgan  ",
          "email": " ALEX@EXAMPLE.COM ",
          "address": "  12 Riverside Street, Phnom Penh  "
        },
        "deliveryMethod": "standard",
        "paymentMethod": "cash_on_delivery"
      }
      """;

  @Autowired private MockMvc mockMvc;
  @Autowired private UserRepository userRepository;
  @Autowired private CategoryRepository categoryRepository;
  @Autowired private ProductRepository productRepository;
  @Autowired private CartRepository cartRepository;
  @Autowired private CartItemRepository cartItemRepository;
  @Autowired private WishlistItemRepository wishlistItemRepository;
  @Autowired private OrderRepository orderRepository;
  @Autowired private OrderItemRepository orderItemRepository;
  @Autowired private NotificationRepository notificationRepository;
  @Autowired private JwtTokenProvider tokenProvider;

  @BeforeEach
  void cleanDatabase() {
    notificationRepository.deleteAll();
    orderItemRepository.deleteAll();
    orderRepository.deleteAll();
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
  void previewCalculatesCurrentTotalsWithoutPersistingOrChangingCart() throws Exception {
    User user = createUser("preview@example.com");
    Product watch = createProduct("Minimal Watch", "89.00", 8, true, true);
    watch.setImageUrl("https://cdn.example.com/minimal-watch.jpg");
    productRepository.saveAndFlush(watch);
    Product bag = createProduct("Canvas Backpack", "58.00", 6, true, true);
    createCart(user, new CartLine(watch, 1), new CartLine(bag, 2));

    preview(user, CHECKOUT_BODY)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("ORD-0201"))
        .andExpect(jsonPath("$.data.items", hasSize(2)))
        .andExpect(jsonPath("$.data.items[0].productId").value(watch.getUuid().toString()))
        .andExpect(jsonPath("$.data.items[0].imageUrl").value(watch.getImageUrl()))
        .andExpect(jsonPath("$.data.items[0].unitPrice.amount").value("89.00"))
        .andExpect(jsonPath("$.data.items[0].lineTotal.amount").value("89.00"))
        .andExpect(jsonPath("$.data.items[1].lineTotal.amount").value("116.00"))
        .andExpect(jsonPath("$.data.deliveryMethod").value("standard"))
        .andExpect(jsonPath("$.data.estimatedDelivery").value("2–4 business days"))
        .andExpect(jsonPath("$.data.subtotal.amount").value("205.00"))
        .andExpect(jsonPath("$.data.deliveryFee.amount").value("4.00"))
        .andExpect(jsonPath("$.data.total.amount").value("209.00"))
        .andExpect(jsonPath("$.data.expiresAt").isNotEmpty());

    org.assertj.core.api.Assertions.assertThat(orderRepository.count()).isZero();
    org.assertj.core.api.Assertions.assertThat(cartItemRepository.count()).isEqualTo(2);
    org.assertj.core.api.Assertions.assertThat(
            productRepository.findById(watch.getId()).orElseThrow().getAvailableQuantity())
        .isEqualTo(8);
  }

  @Test
  void previewAndPlacementRejectEmptyInvalidAndInsufficientCarts() throws Exception {
    User user = createUser("invalid-checkout@example.com");

    preview(user, CHECKOUT_BODY)
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("CART_EMPTY"));

    Product limited = createProduct("Limited", "10.00", 1, true, true);
    createCart(user, new CartLine(limited, 2));
    preview(user, CHECKOUT_BODY)
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("INSUFFICIENT_STOCK"));
    place(user, "insufficient-key", CHECKOUT_BODY)
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("INSUFFICIENT_STOCK"));

    org.assertj.core.api.Assertions.assertThat(orderRepository.count()).isZero();
    org.assertj.core.api.Assertions.assertThat(cartItemRepository.count()).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(
            productRepository.findById(limited.getId()).orElseThrow().getAvailableQuantity())
        .isEqualTo(1);
  }

  @Test
  void checkoutValidatesRequiredFieldsAndApprovedMethods() throws Exception {
    User user = createUser("checkout-validation@example.com");
    Product product = createProduct("Product", "10.00", 2, true, true);
    createCart(user, new CartLine(product, 1));

    preview(user, "{}")
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
    preview(user, CHECKOUT_BODY.replace("standard", "express"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("CHECKOUT_INVALID"));
    preview(user, CHECKOUT_BODY.replace("cash_on_delivery", "card"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("CHECKOUT_INVALID"));
    preview(user, CHECKOUT_BODY.replace("ALEX@EXAMPLE.COM", "not-an-email"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
  }

  @Test
  void placeOrderSnapshotsDataDecrementsStockClearsCartAndUpdatesCount() throws Exception {
    User user = createUser("place@example.com");
    Product product = createProduct("Minimal Watch", "89.00", 8, true, true);
    product.setImageUrl("https://cdn.example.com/minimal-watch.jpg");
    productRepository.saveAndFlush(product);
    createCart(user, new CartLine(product, 2));

    place(user, "place-order-key", CHECKOUT_BODY)
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.status.code").value("CREATED"))
        .andExpect(jsonPath("$.common.apiId").value("ORD-0202"))
        .andExpect(jsonPath("$.data.id").isNotEmpty())
        .andExpect(jsonPath("$.data.reference", matchesPattern("MC-[A-F0-9]{12}")))
        .andExpect(jsonPath("$.data.status").value("pending"))
        .andExpect(jsonPath("$.data.items", hasSize(1)))
        .andExpect(jsonPath("$.data.items[0].productId").value(product.getUuid().toString()))
        .andExpect(jsonPath("$.data.items[0].name").value("Minimal Watch"))
        .andExpect(jsonPath("$.data.items[0].quantity").value(2))
        .andExpect(jsonPath("$.data.items[0].lineTotal.amount").value("178.00"))
        .andExpect(jsonPath("$.data.delivery.recipientName").value("Alex Morgan"))
        .andExpect(jsonPath("$.data.delivery.email").value("alex@example.com"))
        .andExpect(jsonPath("$.data.delivery.address").value("12 Riverside Street, Phnom Penh"))
        .andExpect(jsonPath("$.data.deliveryMethod").value("standard"))
        .andExpect(jsonPath("$.data.paymentMethod").value("cash_on_delivery"))
        .andExpect(jsonPath("$.data.subtotal.amount").value("178.00"))
        .andExpect(jsonPath("$.data.deliveryFee.amount").value("4.00"))
        .andExpect(jsonPath("$.data.total.amount").value("182.00"))
        .andExpect(jsonPath("$.data.createdAt").isNotEmpty())
        .andExpect(jsonPath("$.data.updatedAt").isNotEmpty());

    org.assertj.core.api.Assertions.assertThat(orderRepository.count()).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(orderItemRepository.count()).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(notificationRepository.count()).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(cartItemRepository.count()).isZero();
    org.assertj.core.api.Assertions.assertThat(
            productRepository.findById(product.getId()).orElseThrow().getAvailableQuantity())
        .isEqualTo(6);

    mockMvc
        .perform(get("/api/v1/auth/me").header("Authorization", bearer(user)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.counts.orders").value(1))
        .andExpect(jsonPath("$.data.counts.cartItems").value(0));
  }

  @Test
  void compatibleIdempotencyReplayReturnsOriginalAndChangedPayloadConflicts() throws Exception {
    User user = createUser("idempotency@example.com");
    Product product = createProduct("Product", "20.00", 5, true, true);
    createCart(user, new CartLine(product, 2));

    place(user, "stable-key", CHECKOUT_BODY).andExpect(status().isCreated());
    Order original = orderRepository.findAll().getFirst();
    place(user, "stable-key", CHECKOUT_BODY)
        .andExpect(status().isCreated())
        .andExpect(jsonPath("$.data.id").value(original.getUuid().toString()))
        .andExpect(jsonPath("$.data.reference").value(original.getReference()));
    place(user, "stable-key", CHECKOUT_BODY.replace("Alex Morgan", "Different Person"))
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("CONFLICT"));

    org.assertj.core.api.Assertions.assertThat(orderRepository.count()).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(notificationRepository.count()).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(
            productRepository.findById(product.getId()).orElseThrow().getAvailableQuantity())
        .isEqualTo(3);
  }

  @Test
  void orderDetailsUseSnapshotsAndHideAnotherUsersOrder() throws Exception {
    User owner = createUser("order-owner@example.com");
    User other = createUser("order-other@example.com");
    Product product = createProduct("Original Name", "35.00", 4, true, true);
    createCart(owner, new CartLine(product, 1));
    place(owner, "snapshot-key", CHECKOUT_BODY).andExpect(status().isCreated());
    Order order = orderRepository.findAll().getFirst();

    product.setName("Changed Name");
    product.setPrice(new BigDecimal("99.00"));
    productRepository.saveAndFlush(product);

    mockMvc
        .perform(
            get("/api/v1/orders/{orderId}", order.getUuid()).header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("ORD-0601"))
        .andExpect(jsonPath("$.data.items[0].name").value("Original Name"))
        .andExpect(jsonPath("$.data.items[0].unitPrice.amount").value("35.00"));
    mockMvc
        .perform(
            get("/api/v1/orders/{orderId}", order.getUuid()).header("Authorization", bearer(other)))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("ORDER_NOT_FOUND"));
    mockMvc
        .perform(
            get("/api/v1/orders/{orderId}", UUID.randomUUID())
                .header("Authorization", bearer(owner)))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("ORDER_NOT_FOUND"));
  }

  @Test
  void orderHistoryIsNewestFirstPaginatedAndSupportsStatusFilter() throws Exception {
    User user = createUser("history@example.com");
    Product product = createProduct("Product", "10.00", 10, true, true);
    createCart(user, new CartLine(product, 1));
    place(user, "history-one", CHECKOUT_BODY).andExpect(status().isCreated());
    Order first = orderRepository.findAll().getFirst();
    first.setStatus(OrderStatus.CONFIRMED);
    orderRepository.saveAndFlush(first);
    addCartLine(user, product, 2);
    place(user, "history-two", CHECKOUT_BODY).andExpect(status().isCreated());

    mockMvc
        .perform(
            get("/api/v1/orders")
                .header("Authorization", bearer(user))
                .param("page", "0")
                .param("size", "1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("ORD-0101"))
        .andExpect(jsonPath("$.data.items", hasSize(1)))
        .andExpect(jsonPath("$.data.items[0].status").value("pending"))
        .andExpect(jsonPath("$.data.items[0].itemCount").value(2))
        .andExpect(jsonPath("$.data.totalElements").value(2))
        .andExpect(jsonPath("$.data.totalPages").value(2))
        .andExpect(jsonPath("$.data.hasNext").value(true));

    mockMvc
        .perform(
            get("/api/v1/orders")
                .header("Authorization", bearer(user))
                .param("status", "confirmed"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items[*].id", contains(first.getUuid().toString())))
        .andExpect(jsonPath("$.data.totalElements").value(1));
    mockMvc
        .perform(
            get("/api/v1/orders").header("Authorization", bearer(user)).param("status", "unknown"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
  }

  @Test
  void checkoutRequiresAuthenticationAndOrderRequiresValidIdempotencyKey() throws Exception {
    User user = createUser("order-auth@example.com");

    mockMvc
        .perform(
            post("/api/v1/orders/preview")
                .contentType(MediaType.APPLICATION_JSON)
                .content(CHECKOUT_BODY))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
    mockMvc
        .perform(get("/api/v1/orders"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
    mockMvc
        .perform(
            post("/api/v1/orders")
                .header("Authorization", bearer(user))
                .contentType(MediaType.APPLICATION_JSON)
                .content(CHECKOUT_BODY))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("INVALID_REQUEST"));
    mockMvc
        .perform(
            post("/api/v1/orders")
                .header("Authorization", bearer(user))
                .header("Idempotency-Key", " ")
                .contentType(MediaType.APPLICATION_JSON)
                .content(CHECKOUT_BODY))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
  }

  private ResultActions preview(User user, String body) throws Exception {
    return mockMvc.perform(
        post("/api/v1/orders/preview")
            .header("Authorization", bearer(user))
            .contentType(MediaType.APPLICATION_JSON)
            .content(body));
  }

  private ResultActions place(User user, String idempotencyKey, String body) throws Exception {
    return mockMvc.perform(
        post("/api/v1/orders")
            .header("Authorization", bearer(user))
            .header("Idempotency-Key", idempotencyKey)
            .contentType(MediaType.APPLICATION_JSON)
            .content(body));
  }

  private Cart createCart(User user, CartLine... lines) {
    Cart cart = Cart.builder().user(user).build();
    for (CartLine line : lines) {
      cart.addItem(CartItem.builder().product(line.product()).quantity(line.quantity()).build());
    }
    return cartRepository.saveAndFlush(cart);
  }

  private void addCartLine(User user, Product product, int quantity) {
    Cart cart = cartRepository.findDetailedByUserId(user.getId()).orElseThrow();
    cart.addItem(CartItem.builder().product(product).quantity(quantity).build());
    cart.touch();
    cartRepository.saveAndFlush(cart);
  }

  private User createUser(String email) {
    return userRepository.saveAndFlush(
        User.builder()
            .name("Order User")
            .email(email)
            .passwordHash("unused-in-order-tests")
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

  private record CartLine(Product product, int quantity) {}
}
