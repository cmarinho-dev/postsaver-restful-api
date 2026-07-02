package br.com.cmarinho.postsaver.controller.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record FolderRequest(
        @NotBlank @Size(max = 60) String name,
        @Size(max = 160) String description,
        @Size(max = 20) String color
) {
}
