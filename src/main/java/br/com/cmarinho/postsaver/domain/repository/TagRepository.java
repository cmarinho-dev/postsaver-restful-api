package br.com.cmarinho.postsaver.domain.repository;

import br.com.cmarinho.postsaver.domain.model.Tag;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TagRepository extends JpaRepository<Tag, Long> {
    boolean existsByNameIgnoreCase(String name);
    Optional<Tag> findByNameIgnoreCase(String name);

    @Modifying
    @Query(value = "DELETE FROM tb_post_tag WHERE tag_id = :tagId", nativeQuery = true)
    void detachFromPosts(@Param("tagId") Long tagId);
}
