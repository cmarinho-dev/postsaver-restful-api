package br.com.cmarinho.postsaver.service.impl;

import br.com.cmarinho.postsaver.controller.dto.request.TagRequest;
import br.com.cmarinho.postsaver.domain.model.Tag;
import br.com.cmarinho.postsaver.domain.repository.TagRepository;
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

    public TagServiceImpl(TagRepository tagRepository) {
        this.tagRepository = tagRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Tag> findAll() {
        return tagRepository.findAll(Sort.by(Sort.Direction.ASC, "name"));
    }

    @Override
    @Transactional(readOnly = true)
    public Tag findById(Long id) {
        return tagRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Tag with id %d not found.".formatted(id)));
    }

    @Override
    @Transactional
    public Tag create(TagRequest request) {
        if (tagRepository.existsByNameIgnoreCase(request.name())) {
            throw new BusinessException("A tag named '%s' already exists.".formatted(request.name()));
        }
        Tag tag = new Tag();
        applyRequest(tag, request);
        return tagRepository.save(tag);
    }

    @Override
    @Transactional
    public Tag update(Long id, TagRequest request) {
        Tag tag = findById(id);
        if (!tag.getName().equalsIgnoreCase(request.name())
                && tagRepository.existsByNameIgnoreCase(request.name())) {
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
