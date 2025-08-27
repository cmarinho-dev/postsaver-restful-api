package br.com.cmarinho.postsaver.controller.dto;

import br.com.cmarinho.postsaver.domain.model.User;

import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static java.util.stream.Collectors.toList;

public record UserDto(
        Long id,
        String name,
        String username,
        String email,
        String password,
        List<PostDto> posts
) {
    public UserDto(User model) {
        this(
                model.getId(),
                model.getName(),
                model.getUsername(),
                model.getEmail(),
                model.getPassword(),
                Optional.ofNullable(model.getPosts()).orElse(Collections.emptyList()).stream().map(PostDto::new).collect(toList())
        );
    }

    public User toModel() {
        User model = new User();
        model.setId(this.id);
        model.setName(this.name);
        model.setUsername(this.username);
        model.setEmail(this.email);
        model.setPassword(this.password);
        model.setPosts(Optional.ofNullable(this.posts).orElse(Collections.emptyList()).stream().map(PostDto::toModel).collect(toList()));
        return model;
    }
}
