package br.com.cmarinho.postsaver.service;

import br.com.cmarinho.postsaver.controller.dto.request.FolderRequest;
import br.com.cmarinho.postsaver.domain.model.Folder;

import java.util.List;

public interface FolderService {
    List<Folder> findAll();
    Folder findById(Long id);
    Folder create(FolderRequest request);
    Folder update(Long id, FolderRequest request);
    void delete(Long id);
}
