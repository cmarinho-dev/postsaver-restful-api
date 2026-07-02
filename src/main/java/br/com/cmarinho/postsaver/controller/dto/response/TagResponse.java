package br.com.cmarinho.postsaver.controller.dto.response;

import br.com.cmarinho.postsaver.domain.model.Tag;

public record TagResponse(Long id, String name, String color) {
    public static TagResponse from(Tag tag) {
        return new TagResponse(tag.getId(), tag.getName(), tag.getColor());
    }
}
