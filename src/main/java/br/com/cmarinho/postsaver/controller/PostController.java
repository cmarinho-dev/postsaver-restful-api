package br.com.cmarinho.postsaver.controller;

import br.com.cmarinho.postsaver.service.UserService;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/users/{id}")
public record PostController(UserService userService) {

}
