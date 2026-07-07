package br.com.cmarinho.postsaver.service.impl;

import br.com.cmarinho.postsaver.controller.dto.request.TagRequest;
import br.com.cmarinho.postsaver.domain.model.Tag;
import br.com.cmarinho.postsaver.domain.repository.TagRepository;
import br.com.cmarinho.postsaver.domain.repository.UserRepository;
import br.com.cmarinho.postsaver.security.CurrentUserProvider;
import br.com.cmarinho.postsaver.service.TagService;
import br.com.cmarinho.postsaver.service.exception.BusinessException;
import br.com.cmarinho.postsaver.service.exception.NotFoundException;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class TagServiceImpl implements TagService {

    private final TagRepository tagRepository;
    private final UserRepository userRepository;
    private final CurrentUserProvider currentUserProvider;

    public TagServiceImpl(TagRepository tagRepository, UserRepository userRepository,
                           CurrentUserProvider currentUserProvider) {
        this.tagRepository = tagRepository;
        this.userRepository = userRepository;
        this.currentUserProvider = currentUserProvider;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Tag> findAll() {
        return tagRepository.findAllByUserId(currentUserProvider.getUserId(), Sort.by(Sort.Direction.ASC, "name"));
    }

    @Override
    @Transactional(readOnly = true)
    public Tag findById(Long id) {
        return tagRepository.findByIdAndUserId(id, currentUserProvider.getUserId())
                .orElseThrow(() -> new NotFoundException("Tag with id %d not found.".formatted(id)));
    }

    @Override
    @Transactional
    public Tag create(TagRequest request) {
        Long userId = currentUserProvider.getUserId();
        if (tagRepository.existsByNameIgnoreCaseAndUserId(request.name(), userId)) {
            throw new BusinessException("A tag named '%s' already exists.".formatted(request.name()));
        }
        Tag tag = new Tag();
        tag.setUser(userRepository.getReferenceById(userId));
        applyRequest(tag, request);
        return tagRepository.save(tag);
    }

    @Override
    @Transactional
    public Tag update(Long id, TagRequest request) {
        Tag tag = findById(id);
        if (!tag.getName().equalsIgnoreCase(request.name())
                && tagRepository.existsByNameIgnoreCaseAndUserId(request.name(), currentUserProvider.getUserId())) {
            throw new BusinessException("A tag named '%s' already exists.".formatted(request.name()));
        }
        applyRequest(tag, request);
        return tagRepository.save(tag);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        Tag tag = findById(id);
        tagRepository.detachFromPosts(id);
        tagRepository.delete(tag);
    }

    private void applyRequest(Tag tag, TagRequest request) {
        tag.setName(request.name().trim());
        tag.setColor(request.color());
    }
}
