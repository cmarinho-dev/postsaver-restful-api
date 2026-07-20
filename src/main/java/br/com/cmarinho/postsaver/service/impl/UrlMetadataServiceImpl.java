package br.com.cmarinho.postsaver.service.impl;

import br.com.cmarinho.postsaver.controller.dto.response.UrlMetadataResponse;
import br.com.cmarinho.postsaver.domain.model.SocialSource;
import br.com.cmarinho.postsaver.service.UrlMetadataService;
import br.com.cmarinho.postsaver.service.exception.BusinessException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.net.InetAddress;
import java.net.URI;
import java.net.URLEncoder;
import java.net.UnknownHostException;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.Locale;

/**
 * Extrai título/descrição/thumbnail de um link compartilhado. YouTube e TikTok
 * expõem oEmbed público (JSON estável, sem scraping); os demais caem no parse
 * das meta tags Open Graph. Falhas de rede/bloqueio degradam para uma resposta
 * parcial em vez de erro: o cliente preenche o que der.
 */
@Service
public class UrlMetadataServiceImpl implements UrlMetadataService {

    private static final Logger LOGGER = LoggerFactory.getLogger(UrlMetadataServiceImpl.class);

    private static final Duration FETCH_TIMEOUT = Duration.ofSeconds(6);
    private static final int MAX_BODY_BYTES = 2 * 1024 * 1024;
    private static final String USER_AGENT =
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) "
                    + "Chrome/124.0.0.0 Safari/537.36";

    private final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(FETCH_TIMEOUT)
            .followRedirects(HttpClient.Redirect.NORMAL)
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public UrlMetadataResponse fetch(String url) {
        URI uri = validate(url);
        SocialSource source = detectSource(uri);

        UrlMetadataResponse fromOembed = switch (source) {
            case YOUTUBE -> fromOembed(url, source, "https://www.youtube.com/oembed?format=json&url=");
            case TIKTOK -> fromOembed(url, source, "https://www.tiktok.com/oembed?url=");
            default -> null;
        };
        if (fromOembed != null) {
            return fromOembed;
        }
        return fromOpenGraph(url, source);
    }

    private URI validate(String url) {
        URI uri;
        try {
            uri = URI.create(url.trim());
        } catch (IllegalArgumentException ex) {
            throw new BusinessException("Invalid URL.");
        }
        String scheme = uri.getScheme();
        if (scheme == null || !(scheme.equalsIgnoreCase("http") || scheme.equalsIgnoreCase("https"))
                || uri.getHost() == null) {
            throw new BusinessException("Only http(s) URLs are supported.");
        }
        rejectPrivateHosts(uri.getHost());
        return uri;
    }

    /** Evita SSRF: o servidor não deve buscar endereços internos da rede. */
    private void rejectPrivateHosts(String host) {
        try {
            InetAddress address = InetAddress.getByName(host);
            if (address.isLoopbackAddress() || address.isSiteLocalAddress()
                    || address.isLinkLocalAddress() || address.isAnyLocalAddress()) {
                throw new BusinessException("URL host is not allowed.");
            }
        } catch (UnknownHostException ex) {
            throw new BusinessException("URL host could not be resolved.");
        }
    }

    private SocialSource detectSource(URI uri) {
        String host = uri.getHost().toLowerCase(Locale.ROOT);
        if (host.contains("instagram.com")) return SocialSource.INSTAGRAM;
        if (host.contains("tiktok.com")) return SocialSource.TIKTOK;
        if (host.contains("facebook.com") || host.contains("fb.watch")) return SocialSource.FACEBOOK;
        if (host.contains("kwai")) return SocialSource.KWAI;
        if (host.contains("youtube.com") || host.contains("youtu.be")) return SocialSource.YOUTUBE;
        if (host.contains("twitter.com") || host.equals("x.com") || host.endsWith(".x.com")) {
            return SocialSource.TWITTER;
        }
        return SocialSource.OTHER;
    }

    private UrlMetadataResponse fromOembed(String url, SocialSource source, String endpointPrefix) {
        try {
            HttpRequest request = HttpRequest.newBuilder()
                    .uri(URI.create(endpointPrefix + URLEncoder.encode(url, StandardCharsets.UTF_8)))
                    .timeout(FETCH_TIMEOUT)
                    .header("User-Agent", USER_AGENT)
                    .GET()
                    .build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() != 200) {
                return null;
            }
            JsonNode json = objectMapper.readTree(response.body());
            return new UrlMetadataResponse(
                    url,
                    text(json, "title"),
                    text(json, "author_name"),
                    text(json, "thumbnail_url"),
                    source);
        } catch (InterruptedException ex) {
            Thread.currentThread().interrupt();
            return null;
        } catch (Exception ex) {
            LOGGER.debug("oEmbed lookup failed for {}: {}", url, ex.getMessage());
            return null;
        }
    }

    private UrlMetadataResponse fromOpenGraph(String url, SocialSource source) {
        try {
            Document document = Jsoup.connect(url)
                    .userAgent(USER_AGENT)
                    .timeout((int) FETCH_TIMEOUT.toMillis())
                    .maxBodySize(MAX_BODY_BYTES)
                    .followRedirects(true)
                    .get();
            String title = dropGenericTitle(firstNonBlank(
                    meta(document, "og:title"),
                    meta(document, "twitter:title"),
                    document.title()));
            String description = firstNonBlank(
                    meta(document, "og:description"),
                    meta(document, "twitter:description"),
                    metaByName(document, "description"));
            String thumbnail = firstNonBlank(
                    meta(document, "og:image"),
                    meta(document, "twitter:image"));
            return new UrlMetadataResponse(url, title, description, thumbnail, source);
        } catch (Exception ex) {
            LOGGER.debug("Open Graph lookup failed for {}: {}", url, ex.getMessage());
            return new UrlMetadataResponse(url, null, null, null, source);
        }
    }

    private String text(JsonNode json, String field) {
        JsonNode node = json.get(field);
        return node == null || node.isNull() ? null : node.asText();
    }

    private String meta(Document document, String property) {
        var element = document.selectFirst("meta[property=" + property + "]");
        if (element == null) {
            element = document.selectFirst("meta[name=" + property + "]");
        }
        return element == null ? null : element.attr("content");
    }

    private String metaByName(Document document, String name) {
        var element = document.selectFirst("meta[name=" + name + "]");
        return element == null ? null : element.attr("content");
    }

    /**
     * Redes que bloqueiam leitura anônima devolvem só o nome do site como
     * título; melhor nenhum título do que "Instagram" no formulário.
     */
    private String dropGenericTitle(String title) {
        if (title == null) {
            return null;
        }
        return switch (title.trim().toLowerCase(Locale.ROOT)) {
            case "instagram", "facebook", "tiktok", "youtube", "twitter", "x", "kwai" -> null;
            default -> title;
        };
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value.trim();
            }
        }
        return null;
    }
}
