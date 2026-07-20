package br.com.cmarinho.postsaver.controller;

import br.com.cmarinho.postsaver.controller.dto.response.UrlMetadataResponse;
import br.com.cmarinho.postsaver.service.UrlMetadataService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.constraints.NotBlank;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/url-metadata")
@Validated
@Tag(name = "Url Metadata", description = "Extract title, description and thumbnail from a shared link")
public class UrlMetadataController {

    private final UrlMetadataService urlMetadataService;

    public UrlMetadataController(UrlMetadataService urlMetadataService) {
        this.urlMetadataService = urlMetadataService;
    }

    @GetMapping
    @Operation(summary = "Fetch metadata for a URL",
            description = "Resolves oEmbed/Open Graph data; fields are null when the site blocks anonymous access")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Operation successful"),
            @ApiResponse(responseCode = "422", description = "Invalid or disallowed URL")
    })
    public ResponseEntity<UrlMetadataResponse> fetch(@RequestParam(name = "url") @NotBlank String url) {
        return ResponseEntity.ok(urlMetadataService.fetch(url));
    }
}
