package br.com.cmarinho.postsaver.controller.dto.response;

import br.com.cmarinho.postsaver.domain.model.User;

public record UserResponse(Long id, String name, String username, String email) {
    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getName(), user.getUsername(), user.getEmail());
    }
}
