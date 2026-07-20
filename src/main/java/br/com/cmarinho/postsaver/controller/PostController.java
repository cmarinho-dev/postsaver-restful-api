package br.com.cmarinho.postsaver.controller;

import br.com.cmarinho.postsaver.controller.dto.request.PostRequest;
import br.com.cmarinho.postsaver.controller.dto.response.PostResponse;
import br.com.cmarinho.postsaver.domain.model.SocialSource;
import br.com.cmarinho.postsaver.service.PostService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springdoc.core.annotations.ParameterObject;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;

@RestController
@RequestMapping("/api/v1/posts")
@Tag(name = "Posts", description = "Manage saved social media posts")
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @GetMapping
    @Operation(summary = "Search posts", description = "Search saved posts with optional filters and pagination")
    @ApiResponses(@ApiResponse(responseCode = "200", description = "Operation successful"))
    public ResponseEntity<Page<PostResponse>> search(
            @RequestParam(name = "q", required = false) String q,
            @RequestParam(name = "source", required = false) SocialSource source,
            @RequestParam(name = "folderId", required = false) Long folderId,
            @RequestParam(name = "tagId", required = false) Long tagId,
            @RequestParam(name = "favorite", required = false) Boolean favorite,
            @ParameterObject @PageableDefault(size = 12, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        var page = postService.search(q, source, folderId, tagId, favorite, pageable);
        return ResponseEntity.ok(page.map(PostResponse::from));
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a post by ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Operation successful"),
            @ApiResponse(responseCode = "404", description = "Post not found")
    })
    public ResponseEntity<PostResponse> findById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(PostResponse.from(postService.findById(id)));
    }

    @PostMapping
    @Operation(summary = "Save a new post")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Post created successfully"),
            @ApiResponse(responseCode = "422", description = "Invalid post data provided")
    })
    public ResponseEntity<PostResponse> create(@Valid @RequestBody PostRequest request) {
        var post = postService.create(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(post.getId())
                .toUri();
        return ResponseEntity.created(location).body(PostResponse.from(post));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a post")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Post updated successfully"),
            @ApiResponse(responseCode = "404", description = "Post not found"),
            @ApiResponse(responseCode = "422", description = "Invalid post data provided")
    })
    public ResponseEntity<PostResponse> update(@PathVariable("id") Long id, @Valid @RequestBody PostRequest request) {
        return ResponseEntity.ok(PostResponse.from(postService.update(id, request)));
    }

    @PatchMapping("/{id}/favorite")
    @Operation(summary = "Toggle favorite", description = "Toggle the favorite flag of a post")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Favorite toggled successfully"),
            @ApiResponse(responseCode = "404", description = "Post not found")
    })
    public ResponseEntity<PostResponse> toggleFavorite(@PathVariable("id") Long id) {
        return ResponseEntity.ok(PostResponse.from(postService.toggleFavorite(id)));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a post")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Post deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Post not found")
    })
    public ResponseEntity<Void> delete(@PathVariable("id") Long id) {
        postService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
