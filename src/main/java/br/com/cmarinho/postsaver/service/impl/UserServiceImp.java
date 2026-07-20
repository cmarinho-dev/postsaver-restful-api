package br.com.cmarinho.postsaver.service.impl;

import br.com.cmarinho.postsaver.controller.dto.request.UserRequest;
import br.com.cmarinho.postsaver.controller.dto.request.UserUpdateRequest;
import br.com.cmarinho.postsaver.domain.model.User;
import br.com.cmarinho.postsaver.domain.repository.UserRepository;
import br.com.cmarinho.postsaver.service.UserService;
import br.com.cmarinho.postsaver.service.exception.BusinessException;
import br.com.cmarinho.postsaver.service.exception.NotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserServiceImp implements UserService {

    private final UserRepository repository;
    private final PasswordEncoder passwordEncoder;

    public UserServiceImp(UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.repository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional(readOnly = true)
    public User findById(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new NotFoundException("User with id %d not found.".formatted(id)));
    }

    @Override
    @Transactional
    public User create(UserRequest request) {
        if (repository.existsByUsernameIgnoreCase(request.username())) {
            throw new BusinessException("Username '%s' is already taken.".formatted(request.username()));
        }
        User user = new User();
        user.setName(request.name());
        user.setUsername(request.username());
        user.setEmail(request.email());
        user.setPassword(passwordEncoder.encode(request.password()));
        return repository.save(user);
    }

    @Override
    @Transactional
    public User update(Long id, UserUpdateRequest request) {
        User user = findById(id);
        if (!user.getUsername().equalsIgnoreCase(request.username())
                && repository.existsByUsernameIgnoreCase(request.username())) {
            throw new BusinessException("Username '%s' is already taken.".formatted(request.username()));
        }
        user.setName(request.name());
        user.setUsername(request.username());
        user.setEmail(request.email());
        if (request.hasPassword()) {
            user.setPassword(passwordEncoder.encode(request.password()));
        }
        return repository.save(user);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        repository.delete(findById(id));
    }
}
