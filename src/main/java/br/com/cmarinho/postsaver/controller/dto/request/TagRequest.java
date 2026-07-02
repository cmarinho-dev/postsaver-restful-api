package br.com.cmarinho.postsaver.controller.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record TagRequest(
        @NotBlank @Size(max = 40) String name,
        @Size(max = 20) String color
) {
}
