package br.com.cmarinho.postsaver.controller.dto;

import br.com.cmarinho.postsaver.domain.model.Post;

import java.time.LocalDateTime;
import java.util.List;

public record PostDto(
        Long id,
        String title,
        String url,
        String description,
        String source,
        String thumbnailUrl,
        List<String> tags,
        List<String> collection,
        Boolean isFavorite,
        LocalDateTime createdAt
) {
    public PostDto(Post model) {
        this(
                model.getId(),
                model.getTitle(),
                model.getUrl(),
                model.getDescription(),
                model.getSource(),
                model.getThumbnailUrl(),
                model.getTags(),
                model.getCollection(),
                model.isFavorite(),
                model.getCreatedAt()
        );
    }

    public Post toModel() {
        Post model = new Post();
        model.setId(this.id);
        model.setTitle(this.title);
        model.setUrl(this.url);
        model.setDescription(this.description);
        model.setSource(this.source);
        model.setThumbnailUrl(this.thumbnailUrl);
        model.setTags(this.tags);
        model.setCollection(this.collection);
        model.setFavorite(this.isFavorite);
        model.setCreatedAt(this.createdAt);
        return model;
    }
}
