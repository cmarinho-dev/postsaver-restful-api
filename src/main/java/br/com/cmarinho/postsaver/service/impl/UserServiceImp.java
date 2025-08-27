package br.com.cmarinho.postsaver.service.impl;

import br.com.cmarinho.postsaver.domain.model.User;
import br.com.cmarinho.postsaver.domain.repository.UserRepository;
import br.com.cmarinho.postsaver.service.UserService;
import br.com.cmarinho.postsaver.service.exception.BusinessException;
import br.com.cmarinho.postsaver.service.exception.NotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;
import java.util.Optional;

@Service
public class UserServiceImp implements UserService {

    private final UserRepository repository;

    public UserServiceImp(UserRepository userRepository) {
        this.repository = userRepository;
    }

    @Override
    public List<User> findAll() {
        return repository.findAll();
    }

    @Override
    public User findById(Long id) {
        return this.repository.findById(id).orElseThrow(NotFoundException::new);
    }

    @Override
    public User create(User userToCreate) {
        Optional.ofNullable(userToCreate).orElseThrow(() -> new BusinessException("User to create must not be null."));
        Optional.ofNullable(userToCreate.getName()).orElseThrow(() -> new BusinessException("User name must not be null."));
        Optional.ofNullable(userToCreate.getUsername()).orElseThrow(() -> new BusinessException("User username must not be null."));
        Optional.ofNullable(userToCreate.getPassword()).orElseThrow(() -> new BusinessException("User password must not be null."));

        return this.repository.save(userToCreate);
    }

    @Override
    public User update(Long id, User userToUpdate) {
        Optional.ofNullable(userToUpdate).orElseThrow(() -> new BusinessException("User to update must not be null."));
        User dbUser = this.findById(id);
        if (!Objects.equals(dbUser.getId(), userToUpdate.getId())) {
            throw new BusinessException("Update IDs must be the same.");
        }
        dbUser.setName(userToUpdate.getName());
        dbUser.setEmail(userToUpdate.getEmail());
        dbUser.setUsername(userToUpdate.getUsername());
        dbUser.setPassword(userToUpdate.getPassword());

        return this.repository.save(dbUser);
    }

    @Override
    public void delete(Long id) {
        User dbUser = this.findById(id);
        this.repository.delete(dbUser);
    }
}
