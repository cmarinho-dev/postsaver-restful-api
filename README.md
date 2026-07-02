# PostSaver

Aplicação para salvar e organizar posts de redes sociais (Instagram, TikTok, Facebook, Kwai, YouTube e outras) em pastas, com tags/categorias e favoritos.

- **Backend**: API RESTful com Java 17 + Spring Boot 3 (JPA, Bean Validation, Springdoc/Swagger)
- **Frontend**: Angular 19 + PrimeNG (pasta [`frontend/`](frontend/))

## Funcionalidades

- Salvar posts com título, URL, descrição, thumbnail e rede social de origem
- Organizar posts em **pastas** e categorizá-los com **tags** (com cores)
- Marcar/desmarcar posts como **favoritos**
- Busca por texto e filtros por rede social, pasta, tag e favoritos, com paginação
- Cadastro de usuários com senha criptografada (BCrypt)
- Documentação interativa da API via Swagger

## Backend

### Executar em desenvolvimento (H2 em memória)

```bash
SPRING_PROFILES_ACTIVE=dev ./gradlew bootRun
```

- API: http://localhost:8080/api/v1
- Swagger UI: http://localhost:8080/swagger-ui.html
- Console H2: http://localhost:8080/h2-console

### Executar testes

```bash
./gradlew test
```

### Produção (PostgreSQL)

``` properties
SPRING_PROFILES_ACTIVE=prd
PGHOST=host-do-banco
PGPORT=5432
PGDATABASE=postsaver
PGUSER=postgres
PGPASSWORD=senha
```

A variável opcional `APP_CORS_ALLOWED_ORIGINS` define as origens permitidas para CORS (padrão: `http://localhost:4200`).

### Principais endpoints

| Método | Rota | Descrição |
|---|---|---|
| GET | `/api/v1/posts` | Busca paginada com filtros (`q`, `source`, `folderId`, `tagId`, `favorite`) |
| POST | `/api/v1/posts` | Salva um novo post |
| PUT | `/api/v1/posts/{id}` | Atualiza um post |
| PATCH | `/api/v1/posts/{id}/favorite` | Alterna favorito |
| DELETE | `/api/v1/posts/{id}` | Exclui um post |
| GET/POST/PUT/DELETE | `/api/v1/folders` | CRUD de pastas |
| GET/POST/PUT/DELETE | `/api/v1/tags` | CRUD de tags |
| GET/POST/PUT/DELETE | `/api/v1/users` | CRUD de usuários |

## Frontend

```bash
cd frontend
npm install
npm start   # http://localhost:4200 (proxy /api -> localhost:8080)
```

Build de produção:

```bash
npm run build
```
