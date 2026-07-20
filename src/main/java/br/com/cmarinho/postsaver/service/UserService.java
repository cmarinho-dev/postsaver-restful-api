package br.com.cmarinho.postsaver.service;

import br.com.cmarinho.postsaver.controller.dto.request.UserRequest;
import br.com.cmarinho.postsaver.controller.dto.request.UserUpdateRequest;
import br.com.cmarinho.postsaver.domain.model.User;

public interface UserService {
    User findById(Long id);
    User create(UserRequest request);
    User update(Long id, UserUpdateRequest request);
    void delete(Long id);
}
