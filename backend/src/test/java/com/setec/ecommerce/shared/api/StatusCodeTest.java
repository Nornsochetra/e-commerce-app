package com.setec.ecommerce.shared.api;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

class StatusCodeTest {
  @Test
  void codeAlwaysMatchesEnumName() {
    for (StatusCode code : StatusCode.values()) {
      assertThat(code.getCode()).isEqualTo(code.name());
    }
  }

  @Test
  void formatLeavesTemplateUntouchedWithoutArguments() {
    assertThat(StatusCode.NOT_FOUND.format()).isEqualTo("The resource {0} was not found");
  }

  @Test
  void formatDoesNotAddNumberGrouping() {
    assertThat(StatusCode.NOT_FOUND.format(999999L)).isEqualTo("The resource 999999 was not found");
  }

  @Test
  void onlySuccessCodesHaveNoneErrorType() {
    for (StatusCode code : StatusCode.values()) {
      if (code == StatusCode.SUCCESS || code == StatusCode.CREATED || code == StatusCode.ACCEPTED) {
        assertThat(code.getErrorType()).isEqualTo(ErrorType.NONE);
      } else {
        assertThat(code.getErrorType()).isNotEqualTo(ErrorType.NONE);
      }
    }
  }
}
