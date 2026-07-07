package br.com.cmarinho.postsaver.controller;

import br.com.cmarinho.postsaver.controller.dto.request.UserRequest;
import br.com.cmarinho.postsaver.controller.dto.response.UserResponse;
import br.com.cmarinho.postsaver.security.CurrentUserProvider;
import br.com.cmarinho.postsaver.service.UserService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.net.URI;

@RestController
@RequestMapping("/api/v1/users")
@Tag(name = "Users", description = "Manage the authenticated user's account")
public class UserController {

    private final UserService userService;
    private final CurrentUserProvider currentUserProvider;

    public UserController(UserService userService, CurrentUserProvider currentUserProvider) {
        this.userService = userService;
        this.currentUserProvider = currentUserProvider;
    }

    @PostMapping
    @Operation(summary = "Register a new user", description = "Public endpoint, does not require authentication")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "User created successfully"),
            @ApiResponse(responseCode = "422", description = "Invalid user data provided")
    })
    public ResponseEntity<UserResponse> create(@Valid @RequestBody UserRequest request) {
        var user = userService.create(request);
        URI location = ServletUriComponentsBuilder.fromCurrentContextPath()
                .path("/api/v1/users/me")
                .build()
                .toUri();
        return ResponseEntity.created(location).body(UserResponse.from(user));
    }

    @GetMapping("/me")
    @Operation(summary = "Get the authenticated user")
    @ApiResponses(@ApiResponse(responseCode = "200", description = "Operation successful"))
    public ResponseEntity<UserResponse> me() {
        return ResponseEntity.ok(UserResponse.from(userService.findById(currentUserProvider.getUserId())));
    }

    @PutMapping("/me")
    @Operation(summary = "Update the authenticated user")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "User updated successfully"),
            @ApiResponse(responseCode = "422", description = "Invalid user data provided")
    })
    public ResponseEntity<UserResponse> updateMe(@Valid @RequestBody UserRequest request) {
        return ResponseEntity.ok(UserResponse.from(userService.update(currentUserProvider.getUserId(), request)));
    }

    @DeleteMapping("/me")
    @Operation(summary = "Delete the authenticated user")
    @ApiResponses(@ApiResponse(responseCode = "204", description = "User deleted successfully"))
    public ResponseEntity<Void> deleteMe() {
        userService.delete(currentUserProvider.getUserId());
        return ResponseEntity.noContent().build();
    }
}
