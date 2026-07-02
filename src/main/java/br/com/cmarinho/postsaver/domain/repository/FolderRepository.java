package br.com.cmarinho.postsaver.domain.repository;

import br.com.cmarinho.postsaver.domain.model.Folder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface FolderRepository extends JpaRepository<Folder, Long> {
    boolean existsByNameIgnoreCase(String name);
}
