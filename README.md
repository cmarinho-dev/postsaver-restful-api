<div align="center">

# PostSaver

[Backend](#backend) • [Frontend](#frontend) • [Endpoints](#principais-endpoints) • [Deploy](#deploy)

![Java](https://img.shields.io/badge/Java-17-ED8B00?logo=openjdk&logoColor=white)
![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3-6DB33F?logo=springboot&logoColor=white)
![Angular](https://img.shields.io/badge/Angular-19-DD0031?logo=angular&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-prod-4169E1?logo=postgresql&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?logo=docker&logoColor=white)

</div>

---

### Sumário
- [Introdução](#introdução)
- [Funcionalidades](#funcionalidades)
- [Backend](#backend)
- [Principais Endpoints](#principais-endpoints)
- [Frontend](#frontend)
- [Deploy](#deploy)
- [Estrutura do Projeto](#estrutura-do-projeto)

# Introdução

**PostSaver** é uma aplicação para salvar e organizar posts de redes sociais — Instagram, TikTok, Facebook, Kwai, YouTube e outras — em pastas, com tags/categorias e favoritos. O projeto é dividido em duas partes:

- **Backend**: API RESTful em **Java 17 + Spring Boot 3** (JPA, Bean Validation, Springdoc/Swagger);
- **Frontend**: aplicação em **Angular 19 + PrimeNG**, na pasta [`frontend/`](frontend).

# Funcionalidades

- Salvar posts com título, URL, descrição, thumbnail e rede social de origem;
- Organizar posts em **pastas** e categorizá-los com **tags** (com cores);
- Marcar/desmarcar posts como **favoritos**;
- Busca por texto e filtros por rede social, pasta, tag e favoritos, com paginação;
- Cadastro de usuários, com senha criptografada via **BCrypt**;
- Documentação interativa da API através do Swagger.

# Backend

### Rodando em desenvolvimento (H2 em memória)

```sh
SPRING_PROFILES_ACTIVE=dev ./gradlew bootRun
```

- API: `http://localhost:8080/api/v1`
- Swagger UI: `http://localhost:8080/swagger-ui.html`
- Console H2: `http://localhost:8080/h2-console`

### Rodando os testes

```sh
./gradlew test
```

### Produção (PostgreSQL)

Configure as variáveis de ambiente abaixo antes de subir em produção:

```sh
SPRING_PROFILES_ACTIVE=prd
PGHOST=host-do-banco
PGPORT=5432
PGDATABASE=postsaver
PGUSER=postgres
PGPASSWORD=senha
```

A variável opcional `APP_CORS_ALLOWED_ORIGINS` define as origens permitidas para CORS (padrão: `http://localhost:4200`).

# Principais Endpoints

| Método | Rota | Descrição |
| --- | --- | --- |
| `GET` | `/api/v1/posts` | Busca paginada com filtros (`q`, `source`, `folderId`, `tagId`, `favorite`) |
| `POST` | `/api/v1/posts` | Salva um novo post |
| `PUT` | `/api/v1/posts/{id}` | Atualiza um post |
| `PATCH` | `/api/v1/posts/{id}/favorite` | Alterna favorito |
| `DELETE` | `/api/v1/posts/{id}` | Exclui um post |
| `GET/POST/PUT/DELETE` | `/api/v1/folders` | CRUD de pastas |
| `GET/POST/PUT/DELETE` | `/api/v1/tags` | CRUD de tags |
| `GET/POST/PUT/DELETE` | `/api/v1/users` | CRUD de usuários |

# Frontend

```sh
cd frontend
npm install
npm start   # http://localhost:4200 (proxy /api -> localhost:8080)
```

Build de produção:

```sh
npm run build
```

# Deploy

O repositório já inclui os artefatos necessários para deploy em containers/PaaS:

- `Dockerfile` — build da imagem do backend;
- `Procfile` e `render.yaml` — configuração pronta para deploy no Render;
- Detalhes adicionais em [`DEPLOY.md`](DEPLOY.md).

# Estrutura do Projeto

```
postsaver-restful-api/
├── frontend/               # Aplicação Angular 19 + PrimeNG
├── src/                    # Código-fonte do backend (Spring Boot)
├── gradle/wrapper/          # Gradle Wrapper
├── build.gradle.kts        # Configuração do build (Gradle Kotlin DSL)
├── settings.gradle.kts
├── Dockerfile
├── Procfile
├── render.yaml
└── DEPLOY.md               # Guia de deploy
```

---

<div align="center">

Feito com Spring Boot + Angular, para não perder mais aquele post salvo em algum lugar.

</div>
