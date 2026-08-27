package com.setec.ecommerce.shared.helper;

import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
@RequiredArgsConstructor
public class CurrentUserResolver {
  private final AuthHelper authHelper;
  private final UserRepository userRepository;

  @Transactional(readOnly = true)
  public User require() {
    final Long userId;
    try {
      userId = Long.valueOf(authHelper.currentUserId());
    } catch (NumberFormatException exception) {
      throw new BusinessException(StatusCode.UNAUTHORIZED);
    }
    User user =
        userRepository
            .findById(userId)
            .orElseThrow(() -> new BusinessException(StatusCode.UNAUTHORIZED));
    if (!user.isActive()) {
      throw new BusinessException(StatusCode.ACCOUNT_DISABLED);
    }
    return user;
  }
}
