package com.setec.ecommerce.notification;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.setec.ecommerce.shared.domain.Cart;
import com.setec.ecommerce.shared.domain.CartItem;
import com.setec.ecommerce.shared.domain.Category;
import com.setec.ecommerce.shared.domain.Notification;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.enums.NotificationType;
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
import java.time.Instant;
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
class NotificationApiTest {
  private static final String CHECKOUT_BODY =
      """
      {
        "delivery": {
          "recipientName": "Alex Morgan",
          "email": "alex@example.com",
          "address": "12 Riverside Street, Phnom Penh"
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
  void listIsOwnerScopedNewestFirstPaginatedAndMapsWireTypes() throws Exception {
    User owner = createUser("notification-list@example.com");
    User other = createUser("notification-list-other@example.com");
    Notification first = createNotification(owner, NotificationType.ORDER, "First", null, null);
    Notification second = createNotification(owner, NotificationType.OFFER, "Second", null, null);
    createNotification(owner, NotificationType.STOCK, "Cleared", null, Instant.now());
    createNotification(other, NotificationType.STOCK, "Other", null, null);

    mockMvc
        .perform(
            get("/api/v1/notifications")
                .header("Authorization", bearer(owner))
                .param("page", "0")
                .param("size", "1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("NTF-0101"))
        .andExpect(jsonPath("$.data.items", hasSize(1)))
        .andExpect(jsonPath("$.data.items[0].id").value(second.getUuid().toString()))
        .andExpect(jsonPath("$.data.items[0].type").value("offer"))
        .andExpect(jsonPath("$.data.items[0].title").value("Second"))
        .andExpect(jsonPath("$.data.items[0].message").value("Second message"))
        .andExpect(jsonPath("$.data.items[0].readAt").doesNotExist())
        .andExpect(jsonPath("$.data.items[0].createdAt").isNotEmpty())
        .andExpect(jsonPath("$.data.totalElements").value(2))
        .andExpect(jsonPath("$.data.totalPages").value(2))
        .andExpect(jsonPath("$.data.hasNext").value(true));

    mockMvc
        .perform(
            get("/api/v1/notifications")
                .header("Authorization", bearer(owner))
                .param("page", "1")
                .param("size", "1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items[*].id", contains(first.getUuid().toString())));
  }

  @Test
  void unreadFilterAndCountExcludeReadClearedAndOtherUsers() throws Exception {
    User owner = createUser("notification-count@example.com");
    User other = createUser("notification-count-other@example.com");
    createNotification(owner, NotificationType.ORDER, "Unread", null, null);
    createNotification(owner, NotificationType.OFFER, "Read", Instant.now(), null);
    createNotification(owner, NotificationType.STOCK, "Cleared", null, Instant.now());
    createNotification(other, NotificationType.ORDER, "Other", null, null);

    mockMvc
        .perform(
            get("/api/v1/notifications")
                .header("Authorization", bearer(owner))
                .param("filter", "unread"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items", hasSize(1)))
        .andExpect(jsonPath("$.data.items[0].title").value("Unread"))
        .andExpect(jsonPath("$.data.totalElements").value(1));

    mockMvc
        .perform(get("/api/v1/notifications/unread-count").header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("NTF-0601"))
        .andExpect(jsonPath("$.data.unreadCount").value(1));
  }

  @Test
  void markOneReadIsIdempotentAndOwnerScoped() throws Exception {
    User owner = createUser("notification-read@example.com");
    User other = createUser("notification-read-other@example.com");
    Notification notification =
        createNotification(owner, NotificationType.ORDER, "Order update", null, null);

    mockMvc
        .perform(
            post("/api/v1/notifications/{notificationId}/read", notification.getUuid())
                .header("Authorization", bearer(other)))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("NOTIFICATION_NOT_FOUND"));

    mockMvc
        .perform(
            post("/api/v1/notifications/{notificationId}/read", notification.getUuid())
                .header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("NTF-0201"))
        .andExpect(jsonPath("$.data.id").value(notification.getUuid().toString()))
        .andExpect(jsonPath("$.data.readAt").isNotEmpty());
    Instant firstReadAt =
        notificationRepository.findById(notification.getId()).orElseThrow().getReadAt();

    mockMvc
        .perform(
            post("/api/v1/notifications/{notificationId}/read", notification.getUuid())
                .header("Authorization", bearer(owner)))
        .andExpect(status().isOk());

    org.assertj.core.api.Assertions.assertThat(
            notificationRepository.findById(notification.getId()).orElseThrow().getReadAt())
        .isEqualTo(firstReadAt);
  }

  @Test
  void missingOrClearedNotificationCannotBeMarkedRead() throws Exception {
    User owner = createUser("notification-missing@example.com");
    Notification cleared =
        createNotification(owner, NotificationType.ORDER, "Cleared", null, Instant.now());

    for (UUID notificationId : List.of(UUID.randomUUID(), cleared.getUuid())) {
      mockMvc
          .perform(
              post("/api/v1/notifications/{notificationId}/read", notificationId)
                  .header("Authorization", bearer(owner)))
          .andExpect(status().isNotFound())
          .andExpect(jsonPath("$.status.code").value("NOTIFICATION_NOT_FOUND"));
    }
  }

  @Test
  void markAllReadReturnsAffectedCountAndIsIdempotent() throws Exception {
    User owner = createUser("notification-read-all@example.com");
    User other = createUser("notification-read-all-other@example.com");
    createNotification(owner, NotificationType.ORDER, "Unread one", null, null);
    createNotification(owner, NotificationType.OFFER, "Unread two", null, null);
    createNotification(owner, NotificationType.STOCK, "Already read", Instant.now(), null);
    createNotification(other, NotificationType.ORDER, "Other", null, null);

    mockMvc
        .perform(post("/api/v1/notifications/read-all").header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("NTF-0202"))
        .andExpect(jsonPath("$.data.updatedCount").value(2))
        .andExpect(jsonPath("$.data.unreadCount").value(0));
    mockMvc
        .perform(post("/api/v1/notifications/read-all").header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.updatedCount").value(0))
        .andExpect(jsonPath("$.data.unreadCount").value(0));

    org.assertj.core.api.Assertions.assertThat(
            notificationRepository.countByUserIdAndReadAtIsNullAndClearedAtIsNull(other.getId()))
        .isEqualTo(1);
  }

  @Test
  void clearAllSoftClearsVisibleRowsAndIsIdempotent() throws Exception {
    User owner = createUser("notification-clear@example.com");
    User other = createUser("notification-clear-other@example.com");
    Notification unread = createNotification(owner, NotificationType.ORDER, "Unread", null, null);
    Notification read =
        createNotification(owner, NotificationType.OFFER, "Read", Instant.now(), null);
    Notification otherNotification =
        createNotification(other, NotificationType.STOCK, "Other", null, null);

    mockMvc
        .perform(delete("/api/v1/notifications").header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("NTF-0501"))
        .andExpect(jsonPath("$.data.clearedCount").value(2))
        .andExpect(jsonPath("$.data.unreadCount").value(0));
    mockMvc
        .perform(delete("/api/v1/notifications").header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.clearedCount").value(0));
    mockMvc
        .perform(get("/api/v1/notifications").header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items", hasSize(0)));

    org.assertj.core.api.Assertions.assertThat(notificationRepository.count()).isEqualTo(3);
    org.assertj.core.api.Assertions.assertThat(
            notificationRepository.findById(unread.getId()).orElseThrow().getClearedAt())
        .isNotNull();
    org.assertj.core.api.Assertions.assertThat(
            notificationRepository.findById(read.getId()).orElseThrow().getClearedAt())
        .isNotNull();
    org.assertj.core.api.Assertions.assertThat(
            notificationRepository.findById(otherNotification.getId()).orElseThrow().getClearedAt())
        .isNull();
  }

  @Test
  void endpointsRequireAuthenticationAndListValidatesPaginationAndFilter() throws Exception {
    User owner = createUser("notification-validation@example.com");

    mockMvc
        .perform(get("/api/v1/notifications"))
        .andExpect(status().isUnauthorized())
        .andExpect(jsonPath("$.status.code").value("UNAUTHORIZED"));
    mockMvc.perform(get("/api/v1/notifications/unread-count")).andExpect(status().isUnauthorized());
    mockMvc.perform(post("/api/v1/notifications/read-all")).andExpect(status().isUnauthorized());
    mockMvc.perform(delete("/api/v1/notifications")).andExpect(status().isUnauthorized());
    mockMvc
        .perform(
            get("/api/v1/notifications")
                .header("Authorization", bearer(owner))
                .param("filter", "ALL"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
    mockMvc
        .perform(
            get("/api/v1/notifications").header("Authorization", bearer(owner)).param("page", "-1"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
    mockMvc
        .perform(
            get("/api/v1/notifications")
                .header("Authorization", bearer(owner))
                .param("size", "101"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));
  }

  @Test
  void placingOrderCreatesOneUnreadNotificationAndReplayDoesNotDuplicateIt() throws Exception {
    User owner = createUser("notification-order@example.com");
    Product product = createProduct();
    Cart cart = Cart.builder().user(owner).build();
    cart.addItem(CartItem.builder().product(product).quantity(1).build());
    cartRepository.saveAndFlush(cart);

    placeOrder(owner, "notification-order-key").andExpect(status().isCreated());
    placeOrder(owner, "notification-order-key").andExpect(status().isCreated());

    org.assertj.core.api.Assertions.assertThat(notificationRepository.count()).isEqualTo(1);
    Notification notification = notificationRepository.findAll().getFirst();
    org.assertj.core.api.Assertions.assertThat(notification.getType())
        .isEqualTo(NotificationType.ORDER);
    org.assertj.core.api.Assertions.assertThat(notification.getReadAt()).isNull();
    org.assertj.core.api.Assertions.assertThat(notification.getTitle()).isEqualTo("Order placed");
    org.assertj.core.api.Assertions.assertThat(notification.getMessage())
        .contains(orderRepository.findAll().getFirst().getReference());

    mockMvc
        .perform(get("/api/v1/notifications/unread-count").header("Authorization", bearer(owner)))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.unreadCount").value(1));
  }

  @Test
  void failedCheckoutDoesNotCreateNotification() throws Exception {
    User owner = createUser("notification-failed-order@example.com");

    placeOrder(owner, "failed-order-key")
        .andExpect(status().isConflict())
        .andExpect(jsonPath("$.status.code").value("CART_EMPTY"));

    org.assertj.core.api.Assertions.assertThat(notificationRepository.count()).isZero();
  }

  private org.springframework.test.web.servlet.ResultActions placeOrder(
      User user, String idempotencyKey) throws Exception {
    return mockMvc.perform(
        post("/api/v1/orders")
            .header("Authorization", bearer(user))
            .header("Idempotency-Key", idempotencyKey)
            .contentType(MediaType.APPLICATION_JSON)
            .content(CHECKOUT_BODY));
  }

  private Notification createNotification(
      User user, NotificationType type, String title, Instant readAt, Instant clearedAt) {
    return notificationRepository.saveAndFlush(
        Notification.builder()
            .user(user)
            .type(type)
            .title(title)
            .message(title + " message")
            .readAt(readAt)
            .clearedAt(clearedAt)
            .build());
  }

  private User createUser(String email) {
    return userRepository.saveAndFlush(
        User.builder()
            .name("Notification User")
            .email(email)
            .passwordHash("unused-in-notification-tests")
            .role(Role.USER)
            .active(true)
            .build());
  }

  private Product createProduct() {
    String suffix = UUID.randomUUID().toString();
    Category category =
        categoryRepository.saveAndFlush(
            Category.builder()
                .name("Notification Category " + suffix)
                .slug("notification-category-" + suffix)
                .active(true)
                .build());
    return productRepository.saveAndFlush(
        Product.builder()
            .category(category)
            .name("Notification Product")
            .price(new BigDecimal("25.00"))
            .currency("USD")
            .availableQuantity(5)
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
