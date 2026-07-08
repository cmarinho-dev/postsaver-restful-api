package br.com.cmarinho.postsaver.domain.repository;

import br.com.cmarinho.postsaver.domain.model.Post;
import br.com.cmarinho.postsaver.domain.model.SocialSource;
import jakarta.persistence.criteria.JoinType;
import org.springframework.data.jpa.domain.Specification;

public final class PostSpecifications {

    private PostSpecifications() {
    }

    public static Specification<Post> belongsToUser(Long userId) {
        return (root, query, cb) -> cb.equal(root.get("user").get("id"), userId);
    }

    public static Specification<Post> hasSource(SocialSource source) {
        return (root, query, cb) -> source == null ? null : cb.equal(root.get("source"), source);
    }

    public static Specification<Post> inFolder(Long folderId) {
        return (root, query, cb) -> folderId == null ? null : cb.equal(root.get("folder").get("id"), folderId);
    }

    public static Specification<Post> hasTag(Long tagId) {
        return (root, query, cb) -> {
            if (tagId == null) {
                return null;
            }
            query.distinct(true);
            return cb.equal(root.join("tags", JoinType.INNER).get("id"), tagId);
        };
    }

    public static Specification<Post> isFavorite(Boolean favorite) {
        return (root, query, cb) -> favorite == null ? null : cb.equal(root.get("favorite"), favorite);
    }

    public static Specification<Post> matchesText(String text) {
        return (root, query, cb) -> {
            if (text == null || text.isBlank()) {
                return null;
            }
            String pattern = "%" + text.trim().toLowerCase() + "%";
            return cb.or(
                    cb.like(cb.lower(root.get("title")), pattern),
                    cb.like(cb.lower(root.get("description")), pattern)
            );
        };
    }
}
