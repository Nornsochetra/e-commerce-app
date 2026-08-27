package com.setec.ecommerce.profile.service;

import com.setec.ecommerce.auth.mapper.AuthMapper;
import com.setec.ecommerce.auth.payload.CurrentUserResponse;
import com.setec.ecommerce.profile.payload.UpdateProfileRequest;
import com.setec.ecommerce.shared.api.StatusCode;
import com.setec.ecommerce.shared.domain.User;
import com.setec.ecommerce.shared.exception.BusinessException;
import com.setec.ecommerce.shared.helper.CurrentUserResolver;
import com.setec.ecommerce.shared.repository.UserRepository;
import java.util.Locale;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class ProfileService {
  private final CurrentUserResolver currentUserResolver;
  private final UserRepository userRepository;
  private final AuthMapper authMapper;

  @Transactional
  public CurrentUserResponse updateCurrentProfile(UpdateProfileRequest request) {
    if (!request.hasChanges()) {
      throw new BusinessException(
          StatusCode.VALIDATION_ERROR, "At least one profile field is required");
    }

    User user = currentUserResolver.require();
    if (request.name() != null) {
      user.setName(request.name());
    }
    if (request.email() != null) {
      String email = request.email().toLowerCase(Locale.ROOT);
      if (userRepository.existsByEmailIgnoringCaseAndIdNot(email, user.getId())) {
        throw new BusinessException(StatusCode.EMAIL_ALREADY_REGISTERED);
      }
      user.setEmail(email);
    }
    if (request.phone() != null) {
      user.setPhone(request.phone().isEmpty() ? null : request.phone());
    }

    try {
      return authMapper.toCurrentUserResponse(userRepository.saveAndFlush(user));
    } catch (DataIntegrityViolationException exception) {
      throw new BusinessException(StatusCode.EMAIL_ALREADY_REGISTERED);
    }
  }
}
