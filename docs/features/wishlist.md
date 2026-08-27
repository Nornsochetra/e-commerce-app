# Wishlist

## 1. Overview

The wishlist feature allows users to mark products as favorites and review those products in one place.

## 2. Goals

- Allow products to be saved or unsaved with clear feedback.
- Present saved products in a dedicated screen.
- Provide a route from a saved product to its details.

## 3. Actor

- Authenticated user

## 4. Screen

### 4.1 Wishlist/Favorite Products

- Display saved products.
- Allow a saved product to be opened.
- Allow a saved product to be removed.
- Display an informative empty state.

## 5. Functional Requirements

- WISHLIST-FR-001: A user must be able to mark an eligible product as a favorite from approved product screens.
- WISHLIST-FR-002: The selected favorite state must be visible.
- WISHLIST-FR-003: A user must be able to view saved products on the wishlist screen.
- WISHLIST-FR-004: A user must be able to remove a saved product.
- WISHLIST-FR-005: Selecting a saved product must open its product details.
- WISHLIST-FR-006: An empty wishlist must provide a route to product discovery.

## 6. Business and Validation Rules

- A wishlist belongs to one authenticated user and persists across sessions.
- A product can appear only once; saving it again is idempotent.
- Saved items are displayed newest first.
- An unavailable product remains visible with its current availability and cannot be added to cart.
- V1 has no explicit wishlist limit.

## 7. UI States

- Loading
- Wishlist with products
- Empty wishlist
- Saving or removing favorite
- Operation failure
- Saved product unavailable

## 8. Dependencies

- Product catalog
- Authentication
- Wishlist API specification

## 9. Acceptance Criteria

- Favorite controls visibly reflect the current mock state.
- Saved products appear on the wishlist screen.
- Removing a favorite updates the wishlist.
- A user can navigate from a saved product to its details.
- Empty and failure states provide clear feedback.

## 10. Out of Scope

- Sharing wishlists
- Multiple named wishlists
- Guest wishlists, sharing, and multiple named wishlists
