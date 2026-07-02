package br.com.cmarinho.postsaver.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI openApi() {
        return new OpenAPI().info(new Info()
                .title("PostSaver API")
                .description("RESTful API for saving and organizing social media posts "
                        + "(Instagram, TikTok, Facebook, Kwai, YouTube and more) into folders and tags.")
                .version("v1"));
    }
}
