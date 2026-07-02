package br.com.cmarinho.postsaver.controller.dto.request;

import br.com.cmarinho.postsaver.domain.model.SocialSource;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import org.hibernate.validator.constraints.URL;

import java.util.Set;

public record PostRequest(
        @NotBlank @Size(max = 120) String title,
        @NotBlank @URL @Size(max = 500) String url,
        @Size(max = 500) String description,
        @NotNull SocialSource source,
        @URL @Size(max = 500) String thumbnailUrl,
        Boolean favorite,
        Long folderId,
        Set<Long> tagIds
) {
}
