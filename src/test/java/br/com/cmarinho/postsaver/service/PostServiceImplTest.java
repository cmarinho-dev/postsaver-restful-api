package br.com.cmarinho.postsaver.service;

import br.com.cmarinho.postsaver.controller.dto.request.PostRequest;
import br.com.cmarinho.postsaver.domain.model.Folder;
import br.com.cmarinho.postsaver.domain.model.Post;
import br.com.cmarinho.postsaver.domain.model.SocialSource;
import br.com.cmarinho.postsaver.domain.model.Tag;
import br.com.cmarinho.postsaver.domain.repository.FolderRepository;
import br.com.cmarinho.postsaver.domain.repository.PostRepository;
import br.com.cmarinho.postsaver.domain.repository.TagRepository;
import br.com.cmarinho.postsaver.service.exception.BusinessException;
import br.com.cmarinho.postsaver.service.exception.NotFoundException;
import br.com.cmarinho.postsaver.service.impl.PostServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PostServiceImplTest {

    @Mock
    private PostRepository postRepository;

    @Mock
    private FolderRepository folderRepository;

    @Mock
    private TagRepository tagRepository;

    @InjectMocks
    private PostServiceImpl postService;

    private PostRequest request(Long folderId, Set<Long> tagIds) {
        return new PostRequest(
                "Receita de bolo",
                "https://www.instagram.com/p/abc123",
                "Receita rápida",
                SocialSource.INSTAGRAM,
                null,
                true,
                folderId,
                tagIds
        );
    }

    @Test
    void createShouldResolveFolderAndTags() {
        Folder folder = new Folder();
        folder.setId(1L);
        Tag tag = new Tag();
        tag.setId(2L);

        when(folderRepository.findById(1L)).thenReturn(Optional.of(folder));
        when(tagRepository.findById(2L)).thenReturn(Optional.of(tag));
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        Post created = postService.create(request(1L, Set.of(2L)));

        assertThat(created.getFolder()).isEqualTo(folder);
        assertThat(created.getTags()).containsExactly(tag);
        assertThat(created.isFavorite()).isTrue();
        verify(postRepository).save(any(Post.class));
    }

    @Test
    void createShouldFailWhenFolderDoesNotExist() {
        when(folderRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> postService.create(request(99L, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Folder with id 99");
    }

    @Test
    void createShouldFailWhenTagDoesNotExist() {
        when(tagRepository.findById(77L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> postService.create(request(null, Set.of(77L))))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("Tag with id 77");
    }

    @Test
    void findByIdShouldThrowNotFound() {
        when(postRepository.findById(5L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> postService.findById(5L))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void toggleFavoriteShouldFlipFlag() {
        Post post = new Post();
        post.setId(3L);
        post.setFavorite(false);

        when(postRepository.findById(3L)).thenReturn(Optional.of(post));
        when(postRepository.save(any(Post.class))).thenAnswer(inv -> inv.getArgument(0));

        Post toggled = postService.toggleFavorite(3L);

        assertThat(toggled.isFavorite()).isTrue();
    }
}
