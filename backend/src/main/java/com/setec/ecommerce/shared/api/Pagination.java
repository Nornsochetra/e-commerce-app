package com.setec.ecommerce.shared.api;

import java.util.List;
import java.util.function.Function;
import org.springframework.data.domain.Page;

public record Pagination<T>(
    List<T> items, int page, int size, long totalElements, int totalPages, boolean hasNext) {
  public static <T> Pagination<T> of(Page<T> source) {
    return new Pagination<>(
        source.getContent(),
        source.getNumber(),
        source.getSize(),
        source.getTotalElements(),
        source.getTotalPages(),
        source.hasNext());
  }

  public static <S, T> Pagination<T> of(Page<S> source, Function<S, T> mapper) {
    return of(source.map(mapper));
  }
}
