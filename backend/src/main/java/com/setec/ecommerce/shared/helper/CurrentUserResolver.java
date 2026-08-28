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
    return resolve(false);
  }

  @Transactional
  public User requireForUpdate() {
    return resolve(true);
  }

  private User resolve(boolean lock) {
    final Long userId;
    try {
      userId = Long.valueOf(authHelper.currentUserId());
    } catch (NumberFormatException exception) {
      throw new BusinessException(StatusCode.UNAUTHORIZED);
    }
    User user =
        (lock ? userRepository.findByIdForUpdate(userId) : userRepository.findById(userId))
            .orElseThrow(() -> new BusinessException(StatusCode.USER_NOT_FOUND));
    if (!user.isActive()) {
      throw new BusinessException(StatusCode.ACCOUNT_DISABLED);
    }
    return user;
  }
}
