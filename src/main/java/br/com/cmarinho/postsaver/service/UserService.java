package br.com.cmarinho.postsaver.service;

import br.com.cmarinho.postsaver.controller.dto.request.UserRequest;
import br.com.cmarinho.postsaver.domain.model.User;

import java.util.List;

public interface UserService {
    List<User> findAll();
    User findById(Long id);
    User create(UserRequest request);
    User update(Long id, UserRequest request);
    void delete(Long id);
}
