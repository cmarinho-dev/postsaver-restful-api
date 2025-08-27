package br.com.cmarinho.postsaver.service.exception;

public class NotFoundException extends BusinessException {
    public NotFoundException() {
        super("Resource not found");
    }
}
