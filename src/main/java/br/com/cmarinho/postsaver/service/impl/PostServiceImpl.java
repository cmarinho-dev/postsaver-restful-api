package br.com.cmarinho.postsaver.service.impl;

import br.com.cmarinho.postsaver.controller.dto.request.PostRequest;
import br.com.cmarinho.postsaver.domain.model.Post;
import br.com.cmarinho.postsaver.domain.model.SocialSource;
import br.com.cmarinho.postsaver.domain.model.Tag;
import br.com.cmarinho.postsaver.domain.repository.FolderRepository;
import br.com.cmarinho.postsaver.domain.repository.PostRepository;
import br.com.cmarinho.postsaver.domain.repository.TagRepository;
import br.com.cmarinho.postsaver.service.PostService;
import br.com.cmarinho.postsaver.service.exception.BusinessException;
import br.com.cmarinho.postsaver.service.exception.NotFoundException;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.Set;

import static br.com.cmarinho.postsaver.domain.repository.PostSpecifications.*;

@Service
public class PostServiceImpl implements PostService {

    private final PostRepository postRepository;
    private final FolderRepository folderRepository;
    private final TagRepository tagRepository;

    public PostServiceImpl(PostRepository postRepository,
                           FolderRepository folderRepository,
                           TagRepository tagRepository) {
        this.postRepository = postRepository;
        this.folderRepository = folderRepository;
        this.tagRepository = tagRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public Page<Post> search(String text, SocialSource source, Long folderId, Long tagId,
                             Boolean favorite, Pageable pageable) {
        Specification<Post> spec = Specification.allOf(
                matchesText(text),
                hasSource(source),
                inFolder(folderId),
                hasTag(tagId),
                isFavorite(favorite)
        );
        return postRepository.findAll(spec, pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public Post findById(Long id) {
        return postRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Post with id %d not found.".formatted(id)));
    }

    @Override
    @Transactional
    public Post create(PostRequest request) {
        Post post = new Post();
        applyRequest(post, request);
        return postRepository.save(post);
    }

    @Override
    @Transactional
    public Post update(Long id, PostRequest request) {
        Post post = findById(id);
        applyRequest(post, request);
        return postRepository.save(post);
    }

    @Override
    @Transactional
    public Post toggleFavorite(Long id) {
        Post post = findById(id);
        post.setFavorite(!post.isFavorite());
        return postRepository.save(post);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        postRepository.delete(findById(id));
    }

    private void applyRequest(Post post, PostRequest request) {
        post.setTitle(request.title());
        post.setUrl(request.url());
        post.setDescription(request.description());
        post.setSource(request.source());
        post.setThumbnailUrl(request.thumbnailUrl());
        if (request.favorite() != null) {
            post.setFavorite(request.favorite());
        }

        if (request.folderId() == null) {
            post.setFolder(null);
        } else {
            post.setFolder(folderRepository.findById(request.folderId())
                    .orElseThrow(() -> new BusinessException(
                            "Folder with id %d does not exist.".formatted(request.folderId()))));
        }

        Set<Tag> tags = new HashSet<>();
        if (request.tagIds() != null) {
            for (Long tagId : request.tagIds()) {
                tags.add(tagRepository.findById(tagId)
                        .orElseThrow(() -> new BusinessException(
                                "Tag with id %d does not exist.".formatted(tagId))));
            }
        }
        post.setTags(tags);
    }
}
