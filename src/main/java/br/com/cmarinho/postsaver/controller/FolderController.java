package br.com.cmarinho.postsaver.controller;

import br.com.cmarinho.postsaver.controller.dto.request.FolderRequest;
import br.com.cmarinho.postsaver.controller.dto.response.FolderResponse;
import br.com.cmarinho.postsaver.service.FolderService;
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
@RequestMapping("/api/v1/folders")
@Tag(name = "Folders", description = "Organize posts into folders")
public class FolderController {

    private final FolderService folderService;

    public FolderController(FolderService folderService) {
        this.folderService = folderService;
    }

    @GetMapping
    @Operation(summary = "Get all folders")
    @ApiResponses(@ApiResponse(responseCode = "200", description = "Operation successful"))
    public ResponseEntity<List<FolderResponse>> findAll() {
        return ResponseEntity.ok(folderService.findAll().stream().map(FolderResponse::from).toList());
    }

    @GetMapping("/{id}")
    @Operation(summary = "Get a folder by ID")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Operation successful"),
            @ApiResponse(responseCode = "404", description = "Folder not found")
    })
    public ResponseEntity<FolderResponse> findById(@PathVariable("id") Long id) {
        return ResponseEntity.ok(FolderResponse.from(folderService.findById(id)));
    }

    @PostMapping
    @Operation(summary = "Create a new folder")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Folder created successfully"),
            @ApiResponse(responseCode = "422", description = "Invalid folder data provided")
    })
    public ResponseEntity<FolderResponse> create(@Valid @RequestBody FolderRequest request) {
        var folder = folderService.create(request);
        URI location = ServletUriComponentsBuilder.fromCurrentRequest()
                .path("/{id}")
                .buildAndExpand(folder.getId())
                .toUri();
        return ResponseEntity.created(location).body(FolderResponse.from(folder));
    }

    @PutMapping("/{id}")
    @Operation(summary = "Update a folder")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Folder updated successfully"),
            @ApiResponse(responseCode = "404", description = "Folder not found"),
            @ApiResponse(responseCode = "422", description = "Invalid folder data provided")
    })
    public ResponseEntity<FolderResponse> update(@PathVariable("id") Long id, @Valid @RequestBody FolderRequest request) {
        return ResponseEntity.ok(FolderResponse.from(folderService.update(id, request)));
    }

    @DeleteMapping("/{id}")
    @Operation(summary = "Delete a folder")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Folder deleted successfully"),
            @ApiResponse(responseCode = "404", description = "Folder not found"),
            @ApiResponse(responseCode = "422", description = "Folder still contains posts")
    })
    public ResponseEntity<Void> delete(@PathVariable("id") Long id) {
        folderService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
