package com.setec.ecommerce.catalog;

import static org.hamcrest.Matchers.contains;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.setec.ecommerce.shared.domain.Category;
import com.setec.ecommerce.shared.domain.Product;
import com.setec.ecommerce.shared.enums.ProductBadgeType;
import com.setec.ecommerce.shared.repository.CategoryRepository;
import com.setec.ecommerce.shared.repository.ProductRepository;
import java.math.BigDecimal;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
class CatalogApiTest {
  @Autowired private MockMvc mockMvc;
  @Autowired private CategoryRepository categoryRepository;
  @Autowired private ProductRepository productRepository;

  @BeforeEach
  void cleanDatabase() {
    productRepository.deleteAll();
    categoryRepository.deleteAll();
  }

  @Test
  void categoriesArePublicActiveAndOrdered() throws Exception {
    createCategory("Footwear", "footwear", true);
    createCategory("Accessories", "accessories", true);
    createCategory("Hidden", "hidden", false);

    mockMvc
        .perform(get("/api/v1/categories"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("CAT-0101"))
        .andExpect(jsonPath("$.data", hasSize(2)))
        .andExpect(jsonPath("$.data[*].name", contains("Accessories", "Footwear")))
        .andExpect(jsonPath("$.data[0].slug").value("accessories"));
  }

  @Test
  void defaultListUsesFeaturedOrderAndReturnsSummaryShape() throws Exception {
    Category category = createCategory("Accessories", "accessories", true);
    createProduct(category, "Normal Product", "30.00", 2, null, false, null, true);
    createProduct(category, "Featured Two", "20.00", 3, "4.4", true, 2, true);
    Product first = createProduct(category, "Featured One", "10.00", 8, "4.8", true, 1, true);
    first.setImageUrl("https://cdn.example.com/featured-one.jpg");
    first.addBadge(ProductBadgeType.NEW);
    first.addBadge(ProductBadgeType.PREMIUM_PICK);
    productRepository.saveAndFlush(first);

    mockMvc
        .perform(get("/api/v1/products"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("CAT-0102"))
        .andExpect(
            jsonPath(
                "$.data.items[*].name", contains("Featured One", "Featured Two", "Normal Product")))
        .andExpect(jsonPath("$.data.items[0].category.name").value("Accessories"))
        .andExpect(jsonPath("$.data.items[0].price.amount").value("10.00"))
        .andExpect(jsonPath("$.data.items[0].price.currency").value("USD"))
        .andExpect(jsonPath("$.data.items[0].rating").value("4.8"))
        .andExpect(jsonPath("$.data.items[0].badges", contains("new", "premium_pick")))
        .andExpect(jsonPath("$.data.items[0].featured").value(true))
        .andExpect(jsonPath("$.data.page").value(0))
        .andExpect(jsonPath("$.data.size").value(20))
        .andExpect(jsonPath("$.data.totalElements").value(3))
        .andExpect(jsonPath("$.data.hasNext").value(false));
  }

  @Test
  void listFiltersBySearchCategoryAndStockAndHidesInactiveRows() throws Exception {
    Category accessories = createCategory("Accessories", "accessories", true);
    Category footwear = createCategory("Footwear", "footwear", true);
    Category hidden = createCategory("Hidden", "hidden", false);
    createProduct(accessories, "Minimal Watch", "89.00", 8, "4.8", false, null, true);
    createProduct(accessories, "Empty Watch", "49.00", 0, null, false, null, true);
    createProduct(footwear, "Watch Shoe", "59.00", 4, null, false, null, true);
    createProduct(accessories, "Inactive Watch", "39.00", 2, null, false, null, false);
    createProduct(hidden, "Hidden Watch", "29.00", 2, null, false, null, true);

    mockMvc
        .perform(
            get("/api/v1/products")
                .param("query", "WATCH")
                .param("categoryId", accessories.getUuid().toString())
                .param("inStock", "true"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.totalElements").value(1))
        .andExpect(jsonPath("$.data.items[0].name").value("Minimal Watch"));

    mockMvc
        .perform(get("/api/v1/products").param("inStock", "false"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items", hasSize(1)))
        .andExpect(jsonPath("$.data.items[0].name").value("Empty Watch"));
  }

  @Test
  void paginationAndPriceSortAreStable() throws Exception {
    Category category = createCategory("Accessories", "accessories", true);
    createProduct(category, "Ten", "10.00", 1, null, false, null, true);
    createProduct(category, "Thirty", "30.00", 1, null, false, null, true);
    createProduct(category, "Twenty", "20.00", 1, null, false, null, true);

    mockMvc
        .perform(
            get("/api/v1/products")
                .param("page", "0")
                .param("size", "2")
                .param("sort", "price,desc"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.data.items[*].name", contains("Thirty", "Twenty")))
        .andExpect(jsonPath("$.data.totalElements").value(3))
        .andExpect(jsonPath("$.data.totalPages").value(2))
        .andExpect(jsonPath("$.data.hasNext").value(true));
  }

  @Test
  void invalidSortBoundsAndCategoryAreRejected() throws Exception {
    mockMvc
        .perform(get("/api/v1/products").param("sort", "unknown,asc"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));

    mockMvc
        .perform(get("/api/v1/products").param("size", "101"))
        .andExpect(status().isBadRequest())
        .andExpect(jsonPath("$.status.code").value("VALIDATION_ERROR"));

    mockMvc
        .perform(
            get("/api/v1/products").param("categoryId", "00000000-0000-0000-0000-000000000001"))
        .andExpect(status().isNotFound())
        .andExpect(jsonPath("$.status.code").value("CATEGORY_NOT_FOUND"));
  }

  @Test
  void productDetailIsPublicAndIncludesDescription() throws Exception {
    Category category = createCategory("Accessories", "accessories", true);
    Product product = createProduct(category, "Minimal Watch", "89.00", 8, "4.8", true, 1, true);
    product.setDescription("A minimal everyday watch.");
    product.addBadge(ProductBadgeType.BESTSELLER);
    productRepository.saveAndFlush(product);

    mockMvc
        .perform(get("/api/v1/products/{productId}", product.getUuid()))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.common.apiId").value("CAT-0601"))
        .andExpect(jsonPath("$.data.name").value("Minimal Watch"))
        .andExpect(jsonPath("$.data.description").value("A minimal everyday watch."))
        .andExpect(jsonPath("$.data.availableQuantity").value(8))
        .andExpect(jsonPath("$.data.badges[0]").value("bestseller"));
  }

  @Test
  void missingInactiveAndHiddenCategoryProductsReturnNotFound() throws Exception {
    Category active = createCategory("Active", "active", true);
    Category hidden = createCategory("Hidden", "hidden", false);
    Product inactive = createProduct(active, "Inactive", "10.00", 1, null, false, null, false);
    Product hiddenProduct =
        createProduct(hidden, "Hidden Product", "10.00", 1, null, false, null, true);

    for (Object id :
        new Object[] {
          inactive.getUuid(), hiddenProduct.getUuid(), "00000000-0000-0000-0000-000000000001"
        }) {
      mockMvc
          .perform(get("/api/v1/products/{productId}", id))
          .andExpect(status().isNotFound())
          .andExpect(jsonPath("$.status.code").value("PRODUCT_NOT_FOUND"));
    }
  }

  private Category createCategory(String name, String slug, boolean active) {
    return categoryRepository.saveAndFlush(
        Category.builder().name(name).slug(slug).active(active).build());
  }

  private Product createProduct(
      Category category,
      String name,
      String price,
      int quantity,
      String rating,
      boolean featured,
      Integer featuredRank,
      boolean active) {
    return productRepository.saveAndFlush(
        Product.builder()
            .category(category)
            .name(name)
            .price(new BigDecimal(price))
            .currency("USD")
            .availableQuantity(quantity)
            .rating(rating == null ? null : new BigDecimal(rating))
            .featured(featured)
            .featuredRank(featuredRank)
            .active(active)
            .build());
  }
}
