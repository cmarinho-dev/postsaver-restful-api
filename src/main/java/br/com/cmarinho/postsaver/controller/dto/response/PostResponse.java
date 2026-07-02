package br.com.cmarinho.postsaver.controller.dto.response;

import br.com.cmarinho.postsaver.domain.model.Post;
import br.com.cmarinho.postsaver.domain.model.SocialSource;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;

public record PostResponse(
        Long id,
        String title,
        String url,
        String description,
        SocialSource source,
        String thumbnailUrl,
        boolean favorite,
        FolderResponse folder,
        List<TagResponse> tags,
        LocalDateTime createdAt,
        LocalDateTime updatedAt
) {
    public static PostResponse from(Post post) {
        return new PostResponse(
                post.getId(),
                post.getTitle(),
                post.getUrl(),
                post.getDescription(),
                post.getSource(),
                post.getThumbnailUrl(),
                post.isFavorite(),
                post.getFolder() == null ? null : FolderResponse.from(post.getFolder()),
                post.getTags().stream()
                        .map(TagResponse::from)
                        .sorted(Comparator.comparing(TagResponse::name))
                        .toList(),
                post.getCreatedAt(),
                post.getUpdatedAt()
        );
    }
}
