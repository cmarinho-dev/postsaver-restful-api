package br.com.cmarinho.postsaver.controller;

import br.com.cmarinho.postsaver.controller.dto.request.FolderRequest;
import br.com.cmarinho.postsaver.domain.model.Folder;
import br.com.cmarinho.postsaver.domain.model.User;
import br.com.cmarinho.postsaver.domain.repository.FolderRepository;
import br.com.cmarinho.postsaver.domain.repository.UserRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.hamcrest.Matchers.hasSize;
import static org.hamcrest.Matchers.is;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Confirms a folder is invisible to any user but its owner, and that the
 * per-user unique constraint (not the old global one) is what's enforced now.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("dev")
@Transactional
class FolderControllerAuthorizationIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private FolderRepository folderRepository;

    @Autowired
    private ObjectMapper objectMapper;

    private User userA;
    private User userB;
    private Folder folderA;

    @BeforeEach
    void setUp() {
        userA = userRepository.save(newUser("alice_folder_it", "alice_folder_it@example.com"));
        userB = userRepository.save(newUser("bob_folder_it", "bob_folder_it@example.com"));

        Folder folder = new Folder();
        folder.setName("Receitas");
        folder.setUser(userA);
        folderA = folderRepository.save(folder);
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
    void otherUserCannotReadFolder() throws Exception {
        mockMvc.perform(get("/api/v1/folders/{id}", folderA.getId())
                        .with(jwt().jwt(j -> j.claim("uid", userB.getId()))))
                .andExpect(status().isNotFound());
    }

    @Test
    void otherUserCannotDeleteFolder() throws Exception {
        mockMvc.perform(delete("/api/v1/folders/{id}", folderA.getId())
                        .with(jwt().jwt(j -> j.claim("uid", userB.getId()))))
                .andExpect(status().isNotFound());
    }

    @Test
    void bothUsersCanHaveAFolderWithTheSameName() throws Exception {
        FolderRequest request = new FolderRequest("Receitas", null, null);
        mockMvc.perform(post("/api/v1/folders")
                        .with(jwt().jwt(j -> j.claim("uid", userB.getId())))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.name", is("Receitas")));
    }

    @Test
    void ownerListSeesOnlyOwnFolders() throws Exception {
        mockMvc.perform(get("/api/v1/folders")
                        .with(jwt().jwt(j -> j.claim("uid", userB.getId()))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(0)));

        mockMvc.perform(get("/api/v1/folders")
                        .with(jwt().jwt(j -> j.claim("uid", userA.getId()))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(1)));
    }
}
