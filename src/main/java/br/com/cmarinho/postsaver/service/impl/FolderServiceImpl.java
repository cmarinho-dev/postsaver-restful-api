package br.com.cmarinho.postsaver.service.impl;

import br.com.cmarinho.postsaver.controller.dto.request.FolderRequest;
import br.com.cmarinho.postsaver.domain.model.Folder;
import br.com.cmarinho.postsaver.domain.repository.FolderRepository;
import br.com.cmarinho.postsaver.domain.repository.PostRepository;
import br.com.cmarinho.postsaver.service.FolderService;
import br.com.cmarinho.postsaver.service.exception.BusinessException;
import br.com.cmarinho.postsaver.service.exception.NotFoundException;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class FolderServiceImpl implements FolderService {

    private final FolderRepository folderRepository;
    private final PostRepository postRepository;

    public FolderServiceImpl(FolderRepository folderRepository, PostRepository postRepository) {
        this.folderRepository = folderRepository;
        this.postRepository = postRepository;
    }

    @Override
    @Transactional(readOnly = true)
    public List<Folder> findAll() {
        return folderRepository.findAll(Sort.by(Sort.Direction.ASC, "name"));
    }

    @Override
    @Transactional(readOnly = true)
    public Folder findById(Long id) {
        return folderRepository.findById(id)
                .orElseThrow(() -> new NotFoundException("Folder with id %d not found.".formatted(id)));
    }

    @Override
    @Transactional
    public Folder create(FolderRequest request) {
        if (folderRepository.existsByNameIgnoreCase(request.name())) {
            throw new BusinessException("A folder named '%s' already exists.".formatted(request.name()));
        }
        Folder folder = new Folder();
        applyRequest(folder, request);
        return folderRepository.save(folder);
    }

    @Override
    @Transactional
    public Folder update(Long id, FolderRequest request) {
        Folder folder = findById(id);
        if (!folder.getName().equalsIgnoreCase(request.name())
                && folderRepository.existsByNameIgnoreCase(request.name())) {
            throw new BusinessException("A folder named '%s' already exists.".formatted(request.name()));
        }
        applyRequest(folder, request);
        return folderRepository.save(folder);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        Folder folder = findById(id);
        if (postRepository.existsByFolderId(id)) {
            throw new BusinessException("Folder contains posts. Move or delete them first.");
        }
        folderRepository.delete(folder);
    }

    private void applyRequest(Folder folder, FolderRequest request) {
        folder.setName(request.name().trim());
        folder.setDescription(request.description());
        folder.setColor(request.color());
    }
}
