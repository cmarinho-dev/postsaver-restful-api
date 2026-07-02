package br.com.cmarinho.postsaver.service;

import br.com.cmarinho.postsaver.controller.dto.request.TagRequest;
import br.com.cmarinho.postsaver.domain.model.Tag;

import java.util.List;

public interface TagService {
    List<Tag> findAll();
    Tag findById(Long id);
    Tag create(TagRequest request);
    Tag update(Long id, TagRequest request);
    void delete(Long id);
}
