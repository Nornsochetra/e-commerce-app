# User Profile

## 1. Overview

The user-profile feature allows an authenticated user to view and update approved account information.

## 2. Goals

- Present the user's account information clearly.
- Allow editable information to be changed through a dedicated flow.
- Communicate validation and update results.

## 3. Actor

- Authenticated user

## 4. Screens

### 4.1 User Profile

- Display the approved profile fields.
- Provide navigation to edit the profile.
- Provide navigation to orders, wishlist, cart, and sign out.

### 4.2 Edit Profile

- Display editable profile fields.
- Validate changes before submission.
- Allow the user to save or cancel changes.
- Editable fields are name, email, and optional phone. Avatar support is deferred.

## 5. Functional Requirements

- PROFILE-FR-001: The application must display the current user's approved profile information.
- PROFILE-FR-002: The application must provide a clear edit action.
- PROFILE-FR-003: The user must be able to cancel editing without saving changes.
- PROFILE-FR-004: Invalid fields must be identified before submission.
- PROFILE-FR-005: Saving must display loading, success, and failure feedback.
- PROFILE-FR-006: The profile screen must reflect successfully saved changes.

## 6. Business and Validation Rules

- Name is required, trimmed, and limited to 120 characters.
- Email is required, trimmed, validated, and unique case-insensitively.
- Phone is optional, may be cleared, and is limited to 32 characters; international normalization is
  deferred.
- Changing profile fields does not require re-authentication in v1.
- Password and role are not profile fields.

## 7. UI States

- Loading profile
- Profile loaded
- Profile unavailable
- Editing
- Invalid changes
- Saving
- Save success
- Save failure

## 8. Dependencies

- Authentication
- Final user data model
- User-profile API specification

## 9. Acceptance Criteria

- An authenticated user can reach the profile and edit-profile screens.
- Current approved profile information is visible.
- Canceling an edit does not apply changes.
- Successful changes appear on the profile screen.
- Validation and request failures provide understandable feedback.

## 10. Out of Scope

- Authentication flows
- Settings, avatar upload, password change, and account deletion
