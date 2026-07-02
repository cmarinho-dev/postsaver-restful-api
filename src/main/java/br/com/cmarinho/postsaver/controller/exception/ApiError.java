package br.com.cmarinho.postsaver.controller.exception;

import java.time.LocalDateTime;
import java.util.List;

public record ApiError(
        int status,
        String message,
        List<String> details,
        LocalDateTime timestamp
) {
    public static ApiError of(int status, String message) {
        return new ApiError(status, message, List.of(), LocalDateTime.now());
    }

    public static ApiError of(int status, String message, List<String> details) {
        return new ApiError(status, message, details, LocalDateTime.now());
    }
}
