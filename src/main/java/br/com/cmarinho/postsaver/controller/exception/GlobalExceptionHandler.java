package br.com.cmarinho.postsaver.controller.exception;

import br.com.cmarinho.postsaver.service.exception.BusinessException;
import br.com.cmarinho.postsaver.service.exception.NotFoundException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger LOGGER = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler
    public ResponseEntity<String> handleBusinessException(BusinessException e) {
        return new ResponseEntity<>(e.getMessage(), HttpStatus.UNPROCESSABLE_ENTITY);
    }

    @ExceptionHandler
    public ResponseEntity<String> handleNotFoundException(NotFoundException e) {
        return new ResponseEntity<>(e.getMessage(), HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler
    public ResponseEntity<String> handleUnexpectedException(Exception e) {
        String msg = "Unexpected error occurred.";
        LOGGER.error(msg, e);
        return new ResponseEntity<>(msg, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
