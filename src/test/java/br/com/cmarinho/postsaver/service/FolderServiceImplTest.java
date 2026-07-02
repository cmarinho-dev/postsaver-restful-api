package br.com.cmarinho.postsaver.service;

import br.com.cmarinho.postsaver.controller.dto.request.FolderRequest;
import br.com.cmarinho.postsaver.domain.model.Folder;
import br.com.cmarinho.postsaver.domain.repository.FolderRepository;
import br.com.cmarinho.postsaver.domain.repository.PostRepository;
import br.com.cmarinho.postsaver.service.exception.BusinessException;
import br.com.cmarinho.postsaver.service.impl.FolderServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FolderServiceImplTest {

    @Mock
    private FolderRepository folderRepository;

    @Mock
    private PostRepository postRepository;

    @InjectMocks
    private FolderServiceImpl folderService;

    @Test
    void createShouldRejectDuplicateName() {
        when(folderRepository.existsByNameIgnoreCase("Receitas")).thenReturn(true);

        assertThatThrownBy(() -> folderService.create(new FolderRequest("Receitas", null, null)))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("already exists");
    }

    @Test
    void createShouldTrimName() {
        when(folderRepository.existsByNameIgnoreCase("  Receitas  ")).thenReturn(false);
        when(folderRepository.save(any(Folder.class))).thenAnswer(inv -> inv.getArgument(0));

        Folder created = folderService.create(new FolderRequest("  Receitas  ", "desc", "#ff0000"));

        assertThat(created.getName()).isEqualTo("Receitas");
        assertThat(created.getColor()).isEqualTo("#ff0000");
    }

    @Test
    void deleteShouldRejectFolderWithPosts() {
        Folder folder = new Folder();
        folder.setId(1L);
        when(folderRepository.findById(1L)).thenReturn(Optional.of(folder));
        when(postRepository.existsByFolderId(1L)).thenReturn(true);

        assertThatThrownBy(() -> folderService.delete(1L))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("contains posts");
        verify(folderRepository, never()).delete(any());
    }
}
