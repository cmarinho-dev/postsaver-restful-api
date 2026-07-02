package br.com.cmarinho.postsaver.controller.dto.response;

import br.com.cmarinho.postsaver.domain.model.Folder;

import java.time.LocalDateTime;

public record FolderResponse(Long id, String name, String description, String color, LocalDateTime createdAt) {
    public static FolderResponse from(Folder folder) {
        return new FolderResponse(
                folder.getId(),
                folder.getName(),
                folder.getDescription(),
                folder.getColor(),
                folder.getCreatedAt()
        );
    }
}
