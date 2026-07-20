package br.com.cmarinho.postsaver.service;

import br.com.cmarinho.postsaver.controller.dto.response.UrlMetadataResponse;

public interface UrlMetadataService {
    UrlMetadataResponse fetch(String url);
}
