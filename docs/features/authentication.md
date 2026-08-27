# Authentication

## 1. Overview

Authentication provides the initial application entry and the flows required for a user to access or create an account and recover access to an existing account.

## 2. Goals

- Introduce the application through a splash screen.
- Allow an existing user to log in.
- Allow a new user to register.
- Allow a user to begin password recovery.
- Provide clear validation, loading, success, and failure feedback.

## 3. Actors

- Guest
- Registered user who is not currently authenticated

## 4. Screens

### 4.1 Splash

- Display the application identity while initialization takes place.
- Continue to the appropriate next screen after initialization.
- Restore a valid refresh session and open Home; otherwise open Login.

### 4.2 Login

- Display the credentials required to log in.
- Submit valid credentials.
- Provide navigation to registration and forgot-password flows.
- Use case-insensitive email and password credentials.

### 4.3 Register

- Display the fields required to create an account.
- Validate the provided information before submission.
- Require name, email, password, and matching password confirmation. Registration signs the user in;
  email verification and consent capture are deferred.

### 4.4 Forgot Password

- Allow a user to request account recovery.
- Explain the next recovery step after a successful request.
- Accept email and always show the same acknowledgement. Delivery and reset completion are deferred
  until an email provider is selected.

## 5. Primary User Flows

### 5.1 Application Entry

1. The user opens the application.
2. The splash screen is displayed.
3. The application completes its initialization checks.
4. The user is routed according to the approved session rules.

### 5.2 Login

1. The user opens the login screen.
2. The user enters the required credentials.
3. The application validates the input.
4. The application displays a loading state during submission.
5. On success, the user is sent to the approved destination.
6. On failure, the application displays an actionable error message.

### 5.3 Registration

1. The user opens the registration screen.
2. The user completes the required fields.
3. The application validates the input.
4. The user submits the form.
5. The application displays the appropriate success or error state.

### 5.4 Forgot Password

1. The user opens the forgot-password screen.
2. The user supplies the required account identifier.
3. The application validates and submits the request.
4. The application displays recovery instructions or an error.

## 6. Functional Requirements

- AUTH-FR-001: The application must display a splash screen when launched.
- AUTH-FR-002: The application must provide navigation from login to registration.
- AUTH-FR-003: The application must provide navigation from login to forgot password.
- AUTH-FR-004: The application must prevent submission when required visible fields are invalid.
- AUTH-FR-005: The application must show submission progress.
- AUTH-FR-006: The application must show understandable success and error feedback.
- AUTH-FR-007: The application must prevent duplicate submissions while a request is in progress.

## 7. Business and Validation Rules

- Email comparison is case-insensitive and stored email is trimmed.
- Passwords contain at least 8 characters and are never logged or returned.
- Registration rejects a normalized email already in use and signs the new user in immediately.
- Access tokens expire after 15 minutes.
- Refresh sessions expire after 7 days, rotate on use, and are revoked on logout.
- A refresh token cannot authorize a normal API request.
- Login uses one `INVALID_CREDENTIALS` result for wrong email or password.
- Recovery requests do not reveal whether an account exists.

## 8. UI States

- Initial
- Input focused
- Invalid input
- Submitting/loading
- Submission success
- Submission failure
- Offline or unavailable service

## 9. Security Requirements

- Passwords are stored only as adaptive one-way hashes with a work factor of at least 10.
- Access and refresh tokens are stored using the platform's secure credential storage in production.
- Raw passwords, token values, and password hashes must not appear in application logs.
- HTTPS is required outside local development.

## 10. Dependencies

- Authentication API specification
- Session and authorization conventions
- Approved navigation flow

## 11. Acceptance Criteria

- All four authentication screens are reachable through the defined navigation flow.
- Forms communicate required fields and validation errors clearly.
- A submission displays progress and cannot be triggered repeatedly while loading.
- Success and failure outcomes are visually distinct.
- Splash opens Home for a restored valid session and Login otherwise.

## 12. Out of Scope

- User profile management
- Product browsing
- Shopping and ordering
- Email verification, social login, multi-factor authentication, and completed password-reset delivery
