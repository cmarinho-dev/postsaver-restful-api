package br.com.cmarinho.postsaver.controller;

import br.com.cmarinho.postsaver.controller.dto.request.TagRequest;
import br.com.cmarinho.postsaver.controller.dto.response.TagResponse;
import br.com.cmarinho.postsaver.service.TagService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;
import java.util.List;

@RestController
@RequestMapping("/api/v1/tags")
@Tag(name = "Tags", description = "Categorize posts with tags")
public class TagController {

    private final TagService tagService;

    public TagController(TagService tagService) {
        this.tagService = tagService;
    }

    @GetMapping
    @Operation(summary = "Get all tags")
    @ApiResponses(@ApiResponse(responseCode = "200", description = "Operation successful"))
    public ResponseEntity<List<TagResponse>> findAll() {
        return ResponseEntity.ok(tagService.findAll().stream().map(TagResponse::from).toList());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a tag by ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Operation successful"),
            @ApiResponse(responseCode = "404", description = "Tag not found")
    })
    public ResponseEntity<TagResponse> findById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(TagResponse.from(tagService.findById(id)));
    }

    @PostMapping
    @Operation(summary = "Create a new tag")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Tag created successfully"),
            @ApiResponse(responseCode = "422", description = "Invalid tag data provided")
    })
    public ResponseEntity<TagResponse> create(@Valid @RequestBody TagRequest request) {
        var tag = tagService.create(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(tag.getId())
                .toUri();
        return ResponseEntity.created(location).body(TagResponse.from(tag));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a tag")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Tag updated successfully"),
            @ApiResponse(responseCode = "404", description = "Tag not found"),
            @ApiResponse(responseCode = "422", description = "Invalid tag data provided")
    })
    public ResponseEntity<TagResponse> update(@PathVariable("id") Long id, @Valid @RequestBody TagRequest request) {
        return ResponseEntity.ok(TagResponse.from(tagService.update(id, request)));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a tag")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Tag deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Tag not found")
    })
    public ResponseEntity<Void> delete(@PathVariable("id") Long id) {
        tagService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
