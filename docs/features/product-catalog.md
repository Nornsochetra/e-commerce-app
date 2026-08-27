# Product Catalog

## 1. Overview

The product-catalog feature enables users to discover products from the home screen, browse categories and lists, inspect product details, search, and filter results.

## 2. Goals

- Make product discovery simple and visually clear.
- Allow browsing by category.
- Support product search and filtering.
- Present enough product information for a user to make a shopping decision.

## 3. Actors

- Guest
- Authenticated user

Guests and authenticated users have the same read-only catalog access. Shopping actions require
authentication.

## 4. Screens

### 4.1 Home

- Present navigation and approved product-discovery sections.
- Display the current featured collection, category shortcuts, and popular products.

### 4.2 Product Categories

- Display available categories.
- Open the relevant product list when a category is selected.

### 4.3 Product List

- Display product summaries in the approved layout.
- Support navigation to product details.
- Represent loading, empty, error, and loaded results.

### 4.4 Product Details

- Display approved product information and available shopping actions.
- Display the product's available stock quantity.
- Display the description when one is provided; omit the description section when it is absent.
- Allow the user to select a purchase quantity, starting at one and not exceeding the available stock quantity.
- Product variants are deferred. An absent image uses the approved application placeholder.

#### Product Content

| Field | Required | Notes |
|---|---|---|
| Name | Yes | Display name of the product |
| Price | Yes | Current product price |
| Description | No | Optional descriptive content; the UI must handle a missing value cleanly |
| Quantity | Yes | Available stock quantity represented by a non-negative whole number |
| Image | No | Absolute image URL; use the application placeholder when absent |
| Category | Yes | One active flat category in v1 |

### 4.5 Search Products

- Allow entry and submission of a search query.
- Display matching products or a no-results state.
- Search suggestions and history are TBD.

### 4.6 Product Filtering

- Allow users to apply and clear approved filters.
- Display active filters and update the result set.
- Filtering is presented as a bottom sheet on mobile.

## 5. Functional Requirements

- PRODUCT-FR-001: Users must be able to navigate from home to product discovery screens.
- PRODUCT-FR-002: Users must be able to browse products by category.
- PRODUCT-FR-003: Selecting a product must open its details.
- PRODUCT-FR-004: Users must be able to submit a product search.
- PRODUCT-FR-005: Users must receive clear feedback when no search results exist.
- PRODUCT-FR-006: Users must be able to apply and clear approved filters.
- PRODUCT-FR-007: Product collections must represent loading, empty, loaded, and error states.
- PRODUCT-FR-008: Product details must display the available stock quantity.
- PRODUCT-FR-009: A missing optional description must not leave an empty or broken UI section.
- PRODUCT-FR-010: The selected purchase quantity must not exceed the available stock quantity.

## 6. Business and Validation Rules

- A product description is optional.
- Available quantity must be a non-negative whole number.
- A quantity of zero represents an out-of-stock product.
- The selected purchase quantity must be at least one and must not exceed available quantity.
- Only active products in active categories are visible.
- V1 prices are USD current catalog prices.
- Search is a case-insensitive product-name contains match.
- Filters are category and in-stock availability.
- Supported sorts are newest, name ascending, price ascending, and price descending.
- Product lists are zero-based pages with default size 20 and maximum size 100.

## 7. UI States

- Loading
- Loaded
- Empty catalog
- No search results
- Error
- Filters inactive
- Filters active
- Product unavailable

## 8. Dependencies

- Product and category data models
- Product API specification
- Shopping cart
- Wishlist

## 9. Acceptance Criteria

- All six product-related screens or approved presentations are reachable.
- Users can move from a category or result list to product details.
- Search and filtering visibly affect the displayed results.
- Users can clear active search/filter criteria.
- Loading, empty, unavailable, and failure cases have clear UI states.
- A product without a description is displayed without an empty description section.
- Available stock and the permitted purchase quantity are represented correctly.

## 10. Out of Scope

- Product administration
- Product variants, product administration, recommendations, search history, and review submission
- Real inventory updates in the prototype
