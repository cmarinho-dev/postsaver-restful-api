package br.com.cmarinho.postsaver.domain.repository;

import br.com.cmarinho.postsaver.domain.model.Post;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PostRepository extends JpaRepository<Post, Long>, JpaSpecificationExecutor<Post> {
    boolean existsByFolderId(Long folderId);

    Optional<Post> findByIdAndUserId(Long id, Long userId);
}
