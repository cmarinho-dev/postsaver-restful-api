# Plano de Melhorias — PostSaver

> Análise técnica do estado atual do projeto (backend Java 17 + Spring Boot 3 / frontend Angular 19 + PrimeNG), com foco no objetivo declarado: evoluir para uma **aplicação completa web + mobile**.
>
> Prioridade: 🔴 Crítico (bloqueia o objetivo mobile/produção) · 🟡 Importante (deve ser feito antes de escalar usuários) · 🟢 Desejável (qualidade/manutenção)

---

## 1. Segurança e Autenticação

Esta é a lacuna mais séria do projeto hoje. Sem resolvê-la, nada do resto importa muito, porque a API está efetivamente aberta.

### 🔴 1.1 Não existe autenticação nem autorização
`SecurityConfig.java` só declara um `PasswordEncoder` (BCrypt) — não há `SecurityFilterChain`, não há login, não há sessão/JWT. O `build.gradle.kts` nem sequer inclui `spring-boot-starter-security`, apenas `spring-security-crypto`. Isso significa que **qualquer pessoa na internet pode chamar `GET /api/v1/users`, ler e-mails de todos os usuários, criar, editar ou apagar usuários e posts de terceiros**, sem nenhuma credencial.

**Por quê importa**: para um app mobile de verdade, o dispositivo do usuário precisa se autenticar contra a API remota. Hoje não existe conceito de "sessão do usuário" nenhum.

**Recomendação**: implementar autenticação stateless com JWT (access + refresh token) via `spring-boot-starter-security` + `spring-security-oauth2-resource-server` (ou `jjwt`), com endpoints `POST /api/v1/auth/login` e `POST /api/v1/auth/refresh`. É o padrão natural para clientes mobile (sem cookies/sessão de servidor).

### 🔴 1.2 Dados não pertencem a usuário nenhum — não há multi-tenancy
`Post`, `Folder` e `Tag` (`domain/model/Post.java:1-145`, `Folder.java`) não têm nenhum vínculo com `User`. `Folder.name` tem `unique = true` **globalmente** (`Folder.java:16`), ou seja, dois usuários diferentes não conseguiriam ter uma pasta chamada "Favoritos" ao mesmo tempo. O endpoint de busca de posts (`PostController.search`, linha 37) não filtra por usuário — é literalmente uma tabela compartilhada por todo mundo que usar a API.

**Contexto histórico**: isso não é um esquecimento novo. O histórico do Git mostra que a versão original do projeto (commits `6548085`/`97659ef`, set/2025) *tinha* um relacionamento `User → Post`, mas ele estava quebrado — mapeado como `@OneToMany(mappedBy = "url")`, um erro de mapeamento JPA que amarrava o relacionamento a um campo `String url` do `Post` em vez de a uma referência para `User`. A reescrita completa do backend em `603efcf` (jul/2026) resolveu o bug **removendo inteiramente** o vínculo `User–Post`, em vez de corrigir o mapeamento. Ou seja: o projeto já teve a noção de "post pertence a um usuário" e a perdeu no processo de "profissionalização". Reintroduzi-la agora, corretamente (com FK explícita `user_id`, não por um campo de conteúdo), é reconstruir algo que já existiu, não inventar do zero.

**Por quê importa**: assim que houver dois usuários reais (web + mobile), um vai ver/editar os posts do outro. Isso é uma falha de isolamento de dados, não só um detalhe de modelagem.

**Recomendação**: adicionar `user_id` (FK) em `Post`, `Folder` e `Tag`; trocar `unique` global por `unique(user_id, name)`; toda query de leitura/escrita deve ser filtrada pelo usuário autenticado (via `principal` extraído do JWT), nunca por parâmetro vindo do cliente.

### 🔴 1.3 Endpoints de usuário expõem operações sensíveis sem controle de acesso
`UserController` permite `GET /users` (lista todo mundo), `PUT/DELETE /users/{id}` para qualquer id, sem checar se quem está chamando é o dono da conta ou um admin. Mesmo depois de adicionar autenticação, isso precisa de checagem de autorização (usuário só edita/exclui a própria conta).

### 🟡 1.4 CORS com `allowedHeaders("*")` e sem `allowCredentials`
`WebConfig.java:16-19` permite qualquer header e não define `allowCredentials`. Isso é razoável para um cenário sem cookies, mas deve ser revisitado junto com a estratégia de auth (se migrar para cookies httpOnly em algum momento, precisa reconfigurar).

### 🟡 1.5 Falta rate limiting e proteção contra brute-force
Sem autenticação hoje, não há o que atacar por brute-force ainda — mas assim que existir login, é necessário limitar tentativas (bucket4j, ou um proxy/API gateway) para evitar credential stuffing, especialmente relevante quando o app mobile também bater na mesma API pública.

### 🟢 1.6 Sem HTTPS/HSTS explícito, sem cabeçalhos de segurança (Helmet-equivalent)
Nenhuma configuração de `Strict-Transport-Security`, `X-Content-Type-Options`, `Content-Security-Policy`. Normalmente resolvido no load balancer/proxy reverso, mas vale documentar como requisito de deploy.

---

## 2. Persistência e Schema do Banco

### 🔴 2.1 Não há controle de migração de schema (Flyway/Liquibase)
Hoje o schema é gerado via `hibernate.ddl-auto: update` em dev (`application-dev.yaml:10`) e `validate` em produção (`application-prd.yaml:9`). Isso quer dizer que em produção **nada cria as tabelas** — alguém precisa rodar isso manualmente, e não há histórico versionado de mudanças de schema.

**Por quê importa**: ao evoluir o modelo (ex.: adicionar `user_id` em `Post`, do item 1.2), sem migrations você não tem como aplicar a mudança em produção de forma segura e repetível, nem fazer rollback.

**Recomendação**: adotar Flyway (mais simples de integrar com Spring Boot) com migrations versionadas em `src/main/resources/db/migration`. Trocar `ddl-auto` para `validate` em todos os ambientes.

### 🟡 2.2 Falta de índices explícitos
Campos usados em filtros (`source`, `folder_id`, `favorite`, e futuramente `user_id`) não têm índice declarado — o Hibernate cria FK automaticamente mas não índices de busca. Em `PostSpecifications.matchesText` (linha 35-46) o `LIKE '%texto%'` não pode usar índice B-tree; para busca textual mais séria, considerar um índice `GIN`/full-text (Postgres) no futuro.

### 🟢 2.3 H2 em dev vs Postgres em produção
Funciona, mas divergência de dialeto SQL entre ambientes é uma fonte clássica de "funciona local, quebra em prod". Vale considerar rodar Postgres via Docker também em dev (ver seção 5) para eliminar essa divergência, especialmente à medida que a aplicação cresce.

---

## 3. Design de API / Preparação para consumo mobile

O objetivo declarado é ter um cliente mobile futuro. Isso muda bastante o que "boa API" significa — o cliente mobile não tem os mesmos recursos de recuperação de um browser (não há reload de página, precisa lidar melhor com rede intermitente, cache offline, etc).

### 🟡 3.1 Formato de resposta de erro inconsistente com formato de sucesso
`ApiError` (usado no `GlobalExceptionHandler`) parece ser um envelope customizado só para erros, enquanto respostas de sucesso retornam o objeto/página "nu" (`ResponseEntity<Page<PostResponse>>`, `ResponseEntity<PostResponse>`). Isso é aceitável, mas exige que o cliente mobile trate dois formatos de payload completamente diferentes dependendo do HTTP status. Vale documentar isso explicitamente no OpenAPI (hoje `GlobalExceptionHandler` não declara `@ApiResponse` para os erros 500/400 nos controllers).

### 🟡 3.2 Versionamento de API já existe (`/api/v1`), mas não há política de evolução
O prefixo `/api/v1/*` está certo como prática (bom sinal). Falta, porém, uma política documentada de: quando quebrar para `v2`, como deprecar campos, e como o app mobile deve reagir a um `410 Gone`/aviso de versão mínima suportada (comum em apps mobile, já que o usuário não atualiza a versão do app imediatamente).

**Recomendação**: documentar essa política agora, antes de existir um cliente mobile em produção com versões antigas circulando.

### 🟡 3.3 Paginação usa `Pageable`/`Page` padrão do Spring — expõe estrutura interna do Spring Data
`Page<PostResponse>` (`PostController.java:44`) serializa campos como `pageable`, `sort`, `numberOfElements` que vazam detalhes de implementação do Spring Data. Um DTO de paginação próprio e estável (`{items, page, size, totalItems, totalPages}`) desacopla o contrato de API da biblioteca usada no backend — importante porque o app mobile vai depender desse contrato por anos.

### 🟡 3.4 Sem suporte a atualização parcial (PATCH) consistente
Só existe `PATCH /posts/{id}/favorite` como PATCH; todo o resto usa `PUT` (substituição completa). Para um cliente mobile com conectividade instável, PATCH parcial (JSON merge patch ou DTOs de update parcial) reduz payload e risco de sobrescrever campos não enviados.

### 🟢 3.5 Sem suporte a "sync" incremental
Apps mobile tipicamente precisam de um endpoint tipo `GET /posts?updatedSince=...` para sincronizar apenas o que mudou (economiza bateria/dados). Hoje só existe busca completa com filtros. Vale planejar isso desde já no modelo (`updatedAt` já existe em `Post`, é um bom começo).

### 🟢 3.6 Content negotiation / compressão
Não há evidência de `gzip`/Brotli habilitado nem `ETag`/`If-None-Match` para cache condicional — relevante para app mobile em rede móvel, onde economizar banda importa mais do que em web.

---

## 4. Qualidade de Código e Testes

### 🟡 4.1 Cobertura de testes muito baixa e incompleta
Só existem 2 testes de service (`PostServiceImplTest`, 115 linhas; `FolderServiceImplTest`, 68 linhas) e um smoke test de contexto (`ApplicationTests`, 15 linhas). **Não há testes de**:
- `TagService`, `UserService` (nenhum teste)
- Nenhum teste de `Controller` (`@WebMvcTest`/`MockMvc`) — ou seja, roteamento, validação de request, serialização de resposta e status HTTP não são verificados automaticamente
- Nenhum teste de integração (`@SpringBootTest` com banco real/Testcontainers) cobrindo o fluxo ponta a ponta
- Nenhum teste do frontend Angular além do boilerplate padrão do CLI (`*.spec.ts` não explorados, mas o `karma.conf` padrão sugere specs não customizados)

**Por quê importa**: ao adicionar autenticação e multi-tenancy (itens 1.1/1.2), qualquer regressão de segurança (ex.: um usuário acessando dado de outro) só será pega se houver teste de integração cobrindo isso.

**Recomendação**: priorizar testes de controller com MockMvc para os fluxos de auth e de isolamento por usuário assim que forem implementados; usar Testcontainers com Postgres para testes de integração próximos da realidade de produção.

### 🟡 4.2 Sem CI/CD configurado
Não há `.github/workflows` (nem outro pipeline) no repositório — testes e build não rodam automaticamente em PRs. Combinado com a cobertura baixa de testes, regressões podem chegar em produção sem aviso.

**Recomendação**: GitHub Actions com pelo menos: (1) `./gradlew test` no backend, (2) `ng test`/`ng build` no frontend, (3) lint, rodando em todo PR contra `main`.

### 🟢 4.3 Sem lint/formatter configurado
Não há Checkstyle/Spotless no backend nem ESLint configurado no `frontend/package.json` (Angular 19 CLI moderno costuma vir sem ESLint por padrão agora). Vale adicionar Spotless (Java) e ESLint + Prettier (Angular) para manter consistência conforme o time/código cresce.

### 🟢 4.4 `pnpm-lock.yaml` não commitado, mas presente no working tree
O projeto usa `npm` (README, `package-lock.json` já commitado), mas existe um `frontend/pnpm-lock.yaml` não rastreado (`git status` mostra `?? frontend/pnpm-lock.yaml`). Alguém rodou `pnpm install` localmente em algum momento. Isso deve ser removido ou o projeto deve padronizar explicitamente em um único gerenciador de pacotes (recomendo manter `npm`, já documentado no README) para evitar dois lockfiles divergentes.

### 🟢 4.5 Getters/setters manuais nos modelos JPA
`Post`, `User`, `Folder` (e provavelmente `Tag`) escrevem getters/setters manualmente. Não é um bug, mas usar Lombok (`@Getter/@Setter` ou `@Data` com cuidado em entidades JPA) reduziria boilerplate e risco de erro ao adicionar campos (ex.: esquecer de atualizar um getter). Prioridade baixa — é estilo, não correção.

### 🟢 4.6 Pequenas inconsistências de nomenclatura e cobertura
`UserServiceImp.java` tem um typo no nome da classe (falta o "l" final de "Impl", inconsistente com `PostServiceImpl`/`FolderServiceImpl`/`TagServiceImpl`). Além disso, não há JaCoCo configurado no `build.gradle.kts` para medir cobertura de teste — sem número de cobertura, é difícil saber objetivamente o quão fraca ela está além da contagem manual de arquivos.

### 🟢 4.7 Frontend já usa TypeScript em modo estrito (ponto positivo a preservar)
`frontend/tsconfig.json` já habilita `strict: true` mais flags adicionais rígidas (`noImplicitOverride`, `noPropertyAccessFromIndexSignature`, `noImplicitReturns`, `noFallthroughCasesInSwitch`, `isolatedModules`) e o Angular compiler roda com `strictTemplates`/`strictInjectionParameters`/`strictInputAccessModifiers`. Isso é uma boa base — vale manter essa disciplina ao adicionar as novas features (auth, sync) em vez de relaxar essas flags para ir mais rápido. Vale notar também que os schematics do Angular estão configurados com `skipTests: true` (`angular.json`), o que explica por que nenhum arquivo `.spec.ts` existe hoje — path de menor resistência ao gerar componentes novos é não escrever teste nenhum; isso deveria ser revertido ao mesmo tempo em que se define a estratégia de testes do frontend (item 4.1).

---

## 5. Infraestrutura, Deploy e Observabilidade

### 🟡 5.1 Sem Docker/docker-compose
Não há `Dockerfile` nem `docker-compose.yml` no repositório. O deploy hoje é via `Procfile` (`web: java -jar build/libs/PostSaver-0.0.1-SNAPSHOT.jar`), sugerindo Heroku. Para evoluir para uma aplicação "completa" com ambientes reprodutíveis (dev/staging/prod) e eventualmente orquestração (para escalar horizontalmente quando o app mobile trouxer mais tráfego), containerizar é básico.

**Recomendação**: `Dockerfile` multi-stage para o backend (build com Gradle, runtime com JRE slim) e `docker-compose.yml` com Postgres para desenvolvimento local — isso também resolve a divergência H2/Postgres do item 2.3.

### 🟡 5.2 Sem observabilidade (logs estruturados, métricas, tracing)
O único logging visível é o `LOGGER.error` genérico no `GlobalExceptionHandler.java:49` para exceções não tratadas. Não há:
- Logs estruturados (JSON) para agregação em ferramentas tipo ELK/Datadog
- Métricas (Spring Boot Actuator + Micrometer/Prometheus) — nem o `actuator` está nas dependências do `build.gradle.kts`
- Tracing distribuído (relevante quando o app mobile fizer múltiplas chamadas e for preciso correlacionar uma sessão de usuário através de requests)

**Por quê importa**: sem isso, debugar problemas em produção (ex.: por que o app mobile está lento nas buscas) vira adivinhação.

**Recomendação**: adicionar `spring-boot-starter-actuator` (health, metrics) desde já — é barato e essencial mesmo antes do mobile existir.

### 🟢 5.3 Configuração de segredos via variáveis de ambiente já é boa prática
`application-prd.yaml` já usa `${PGHOST}`, `${PGUSER}`, etc. (bom). Ponto de atenção: quando adicionar JWT (item 1.1), garantir que o *secret* de assinatura também venha de variável de ambiente/secret manager, nunca hardcoded ou em arquivo versionado.

---

## 6. Frontend (Angular) e Preparação Multiplataforma

### 🟡 6.1 Sem tela de login/autenticação
Consistente com o achado da seção 1: `frontend/src/app/features/` só tem `posts`, `folders`, `tags` — nenhuma feature de autenticação/usuário. Precisa ser criada junto com o backend de auth, incluindo armazenamento seguro do token (em mobile isso vai para Keychain/Keystore; na web, considerar cuidado com `localStorage` vs cookie httpOnly para XSS).

### 🟡 6.2 Nenhuma camada de estado/cache compartilhável entre web e mobile
`core/api.service.ts` parece ser um serviço HTTP direto (não visto em detalhe, mas a estrutura sugere chamadas diretas). Se o plano é ter web + mobile consumindo a mesma API, vale desenhar desde já um contrato de tipos (`core/models.ts`) que possa ser compartilhado ou espelhado facilmente entre Angular (web) e o stack mobile escolhido (Flutter/React Native/Ionic) — isso evita duplicar/discordar sobre o formato dos dados nas duas plontas.

### 🟢 6.3 Escolha de stack mobile ainda em aberto
Vale decidir cedo entre: (a) Ionic + Angular (reaproveita quase todo o código/skills do frontend atual), (b) Flutter (melhor performance nativa, stack novo), (c) React Native. Essa decisão afeta como desenhar a API (ex.: se for Ionic/Capacitor, menos necessidade de otimizar payloads pois roda em WebView; se for nativo, mais motivo para investir em sync incremental e payloads enxutos — itens 3.5/3.6).

---

## Resumo de Prioridades (ordem sugerida de execução)

1. 🔴 **Autenticação (JWT) + multi-tenancy (`user_id` em Post/Folder/Tag)** — bloqueia qualquer uso real multiusuário, web ou mobile.
2. 🔴 **Autorização por dono do recurso** nos controllers (usuário só vê/edita o que é seu).
3. 🔴 **Flyway** para versionar schema — necessário antes de alterar o modelo de dados no item 1.
4. 🟡 **Docker/docker-compose** + **Actuator** (observabilidade básica) — barato e paga dividendos rapidamente.
5. 🟡 **CI (GitHub Actions)** rodando testes de backend e frontend em todo PR.
6. 🟡 **Testes de controller + integração** cobrindo os novos fluxos de auth/isolamento.
7. 🟡 **DTO de paginação próprio** e política de versionamento de API documentada — antes de existir um app mobile publicado dependendo do contrato atual.
8. 🟢 Lint/formatter, Lombok, sync incremental, escolha de stack mobile — melhorias incrementais de qualidade e preparação de longo prazo.
