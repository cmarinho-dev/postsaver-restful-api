package br.com.cmarinho.postsaver.controller.dto.request;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Payload do PUT /users/me. Difere do {@link UserRequest} porque a senha é
 * opcional: quando ausente ou em branco, a senha atual é mantida.
 */
public record UserUpdateRequest(
        @NotBlank @Size(max = 50) String name,
        @NotBlank @Size(max = 20) String username,
        @NotBlank @Email @Size(max = 120) String email,
        @Size(min = 6, max = 72) String password
) {

    public boolean hasPassword() {
        return password != null && !password.isBlank();
    }
}
