package br.com.cmarinho.postsaver.controller.dto.response;

import br.com.cmarinho.postsaver.domain.model.SocialSource;

/**
 * Metadados extraídos de um link compartilhado (Open Graph/oEmbed), usados
 * pelos clientes para pré-preencher o formulário de salvar post. Campos podem
 * vir nulos quando a rede social bloqueia a leitura não autenticada.
 */
public record UrlMetadataResponse(
        String url,
        String title,
        String description,
        String thumbnailUrl,
        SocialSource source
) {
}
