package br.com.cmarinho.postsaver.service;

import br.com.cmarinho.postsaver.controller.dto.request.PostRequest;
import br.com.cmarinho.postsaver.domain.model.Post;
import br.com.cmarinho.postsaver.domain.model.SocialSource;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface PostService {
    Page<Post> search(String text, SocialSource source, Long folderId, Long tagId, Boolean favorite, Pageable pageable);
    Post findById(Long id);
    Post create(PostRequest request);
    Post update(Long id, PostRequest request);
    Post toggleFavorite(Long id);
    void delete(Long id);
}
