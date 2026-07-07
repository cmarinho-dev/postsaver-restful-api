package br.com.cmarinho.postsaver.controller;

import br.com.cmarinho.postsaver.domain.model.Folder;
import br.com.cmarinho.postsaver.domain.model.Post;
import br.com.cmarinho.postsaver.domain.model.SocialSource;
import br.com.cmarinho.postsaver.domain.model.User;
import br.com.cmarinho.postsaver.domain.repository.FolderRepository;
import br.com.cmarinho.postsaver.domain.repository.PostRepository;
import br.com.cmarinho.postsaver.domain.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.hamcrest.Matchers.is;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Verifies the security foundation added in this branch: no token -> 401, and a
 * post belonging to one user is invisible (404, not 403) to every other user.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@Transactional
class PostControllerAuthorizationIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FolderRepository folderRepository;

    @Autowired
    private PostRepository postRepository;

    private User userA;
    private User userB;
    private Post postA;

    @BeforeEach
    void setUp() {
        userA = userRepository.save(newUser("alice_post_it", "alice_post_it@example.com"));
        userB = userRepository.save(newUser("bob_post_it", "bob_post_it@example.com"));

        Folder folder = new Folder();
        folder.setName("Receitas");
        folder.setUser(userA);
        folder = folderRepository.save(folder);

        Post post = new Post();
        post.setTitle("Alice's post");
        post.setUrl("https://instagram.com/p/alice");
        post.setSource(SocialSource.INSTAGRAM);
        post.setFolder(folder);
        post.setUser(userA);
        postA = postRepository.save(post);
    }

    private User newUser(String username, String email) {
        User user = new User();
        user.setName(username);
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword("irrelevant-hash");
        return user;
    }

    @Test
    void listWithoutTokenIsUnauthorized() throws Exception {
        mockMvc.perform(get("/api/v1/posts"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    void ownerCanReadTheirOwnPost() throws Exception {
        mockMvc.perform(get("/api/v1/posts/{id}", postA.getId())
                        .with(jwt().jwt(j -> j.claim("uid", userA.getId()))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id", is(postA.getId().intValue())));
    }

    @Test
    void otherUserCannotReadPost() throws Exception {
        mockMvc.perform(get("/api/v1/posts/{id}", postA.getId())
                        .with(jwt().jwt(j -> j.claim("uid", userB.getId()))))
                .andExpect(status().isNotFound());
    }

    @Test
    void otherUserCannotDeletePost() throws Exception {
        mockMvc.perform(delete("/api/v1/posts/{id}", postA.getId())
                        .with(jwt().jwt(j -> j.claim("uid", userB.getId()))))
                .andExpect(status().isNotFound());
    }

    @Test
    void otherUserCannotToggleFavorite() throws Exception {
        mockMvc.perform(patch("/api/v1/posts/{id}/favorite", postA.getId())
                        .with(jwt().jwt(j -> j.claim("uid", userB.getId()))))
                .andExpect(status().isNotFound());
    }

    @Test
    void ownerListSeesOnlyOwnPosts() throws Exception {
        mockMvc.perform(get("/api/v1/posts")
                        .with(jwt().jwt(j -> j.claim("uid", userB.getId()))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements", is(0)));

        mockMvc.perform(get("/api/v1/posts")
                        .with(jwt().jwt(j -> j.claim("uid", userA.getId()))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalElements", is(1)));
    }
}
