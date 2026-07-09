# PostSaver Mobile — Requisitos (Flutter · Android + iOS)

> Documento de **requisitos** para construir o app mobile do PostSaver em Flutter, consumindo a API RESTful já existente (Spring Boot 3 + OAuth2 Authorization Server). Este arquivo descreve *o que é necessário*, não a implementação. Serve de base para o planejamento e a execução posteriores.
>
> Escopo: um único código-fonte Flutter gerando apps nativos **Android e iOS**, com paridade funcional com o frontend web Angular e a feature-chave de **salvar posts via share sheet** do sistema.

---

## 1. Contexto e premissas

- **Backend já pronto e mirando mobile**: o Authorization Server (Spring Authorization Server) já tem um client público registrado para o app — `postsaver-mobile`, com:
  - `client_id`: `postsaver-mobile`
  - Autenticação de client: **nenhuma** (client público) — **sem client secret embarcado no app**
  - Grants: `authorization_code` + `refresh_token`
  - **PKCE obrigatório** (`requireProofKey(true)`)
  - `redirect_uri`: `br.com.cmarinho.postsaver://callback` (custom scheme)
  - Access token: validade ~15 min · Refresh token: ~30 dias, **com rotação** (`reuseRefreshTokens(false)`)
  - Scopes: `openid profile`
  - Claim customizada no token: **`uid`** (id numérico do usuário) — usada implicitamente pelo backend para escopar os dados; o app **não** envia `userId`, o backend deduz do token.
- **Multi-tenancy no servidor**: cada usuário só enxerga seus próprios posts/pastas/tags. O app não precisa filtrar por usuário — basta enviar o token.
- **Login é hospedado pelo servidor**: a tela de login é servida pelo próprio backend (form login do Spring). O app **não** implementa formulário de login nativo; abre o navegador do sistema no `/oauth2/authorize` e recebe o retorno via deep link. (O **cadastro**, sim, pode ser um formulário nativo — ver §6.)

## 2. Stack e dependências

- **Flutter** (canal stable recente) + **Dart 3**.
- Gerenciamento de estado: **Riverpod** (recomendado) ou Bloc — decisão a confirmar (§13).
- Pacotes essenciais (nomes de referência, versões a fixar na implementação):
  - **`flutter_appauth`** — fluxo OAuth2 **Authorization Code + PKCE** usando o navegador do sistema (ASWebAuthenticationSession no iOS, Custom Tabs no Android). Lida com discovery, PKCE, troca de código e refresh. *(Alternativa: `openid_client` + `flutter_web_auth_2`, caso se queira mais controle.)*
  - **`flutter_secure_storage`** — armazenamento seguro do **refresh token** (Keychain no iOS, Keystore/EncryptedSharedPreferences no Android).
  - **`dio`** — cliente HTTP com interceptors (anexar `Authorization: Bearer`, tratar 401/refresh).
  - **`receive_sharing_intent`** (ou equivalente) — receber conteúdo compartilhado por outros apps (a feature-chave). Ver §8 para a parte nativa que este pacote **não** cobre sozinho.
  - **`json_serializable` / `freezed`** — modelos imutáveis + (de)serialização.
  - **`go_router`** — navegação/deep links.
- **Não usar** nenhuma lib que exija client secret ou fluxo *implicit* — só Authorization Code + PKCE.

## 3. Arquitetura

Camadas sugeridas (a detalhar no plano de implementação):

```
lib/
  core/
    auth/        # AuthService (login/logout/refresh), token storage, AuthInterceptor
    api/         # ApiClient (dio), tratamento de ApiError, paginação
    config/      # environments (issuer, apiBase por ambiente)
    models/      # espelham os DTOs do backend (§7)
  features/
    posts/       # lista (busca+filtros+paginação), criar/editar, favoritar
    folders/     # CRUD
    tags/        # CRUD
    auth/        # tela "Entrar", tela de cadastro, callback
    profile/     # /me, logout, excluir conta
    share/       # entrada via share sheet -> pré-preenche "salvar post"
```

Princípio: a **camada de contrato** (`models` + `api`) deve refletir 1:1 o backend, de forma que web (Angular) e mobile concordem sobre os formatos. Divergência de contrato é o principal risco de longo prazo (o app instalado vive anos com versões antigas).

## 4. Requisitos de autenticação (OAuth2 / OIDC / PKCE)

- **RA-1** — Login via `flutter_appauth` apontando para o **issuer** do backend, usando discovery (`/.well-known/openid-configuration`), `client_id=postsaver-mobile`, `redirect_uri=br.com.cmarinho.postsaver://callback`, scopes `openid profile`, PKCE automático.
- **RA-2** — **Refresh token** guardado **apenas** em `flutter_secure_storage`. Access token pode ficar em memória. **Nunca** persistir tokens em `SharedPreferences`/`NSUserDefaults` em texto claro.
- **RA-3** — **Refresh automático**: interceptor detecta expiração/`401`, faz refresh **uma vez**, repete a requisição; se o refresh falhar, limpa a sessão e volta para a tela "Entrar".
- **RA-4** — **Rotação de refresh token**: como o servidor rotaciona (`reuseRefreshTokens(false)`), o app deve **sempre substituir** o refresh token guardado pelo novo retornado a cada refresh.
- **RA-5** — **Logout**: limpar tokens do secure storage e do estado. (Logout de sessão do AS via browser é opcional; o essencial é invalidar localmente.)
- **RA-6** — O app **nunca** manda `uid`/`userId` em nenhuma chamada; a identidade vem sempre do token.
- **RA-7** — Deep link de callback (`br.com.cmarinho.postsaver://callback`) registrado nas duas plataformas (§9) e roteado para completar o fluxo.

## 5. Requisitos da camada de API

- **API base**: `"/api/v1"` sobre o host do backend (ver §10 sobre host por ambiente).
- **RAPI-1** — Todas as chamadas a `/api/v1/**` levam `Authorization: Bearer <access_token>` (exceto o cadastro público, §6).
- **RAPI-2** — **Tratamento de erro** padronizado: o backend responde erros no formato `ApiError`:
  ```json
  { "status": 422, "message": "...", "details": ["campo: msg"], "timestamp": "..." }
  ```
  O app deve exibir `message` (e `details` quando houver), mapeando status → UX (401 → re-login; 404 → "não encontrado"; 422 → validação; 5xx → erro genérico).
- **RAPI-3** — **Paginação**: `GET /api/v1/posts` aceita `page`, `size`, `sort` (padrão `createdAt,desc`) e retorna um envelope estilo Spring `Page` (`content`, `totalElements`, `totalPages`, `number`, `size`). O app deve tolerar esse formato e, idealmente, isolá-lo num modelo `Page<T>` próprio para não acoplar a UI à estrutura do Spring. *(Nota: há um item no `MELHORIAS.md` para estabilizar esse contrato num DTO próprio — se/quando isso for feito, ajustar aqui.)*
- **RAPI-4** — **Timeouts e retry** sensatos para rede móvel; falha de rede tratada com mensagem clara e opção de tentar de novo.

### Endpoints a consumir (paridade com o web)

| Recurso | Método | Rota | Observação |
|---|---|---|---|
| Cadastro | POST | `/api/v1/users` | **Público** (sem token) |
| Meu usuário | GET/PUT/DELETE | `/api/v1/users/me` | id vem do token |
| Posts (busca) | GET | `/api/v1/posts` | filtros: `q`, `source`, `folderId`, `tagId`, `favorite` + paginação |
| Posts | POST/PUT/DELETE | `/api/v1/posts`, `/api/v1/posts/{id}` | |
| Favorito | PATCH | `/api/v1/posts/{id}/favorite` | alterna |
| Pastas | GET/POST/PUT/DELETE | `/api/v1/folders` | CRUD |
| Tags | GET/POST/PUT/DELETE | `/api/v1/tags` | CRUD |

## 6. Requisitos de telas / paridade funcional (v1)

- **RT-1 — Entrar**: botão que dispara o fluxo OAuth no navegador do sistema.
- **RT-2 — Cadastro**: formulário **nativo** (nome, usuário, e-mail, senha) → `POST /api/v1/users` (público) → redireciona para "Entrar". Validações espelham o backend (`name` ≤50, `username` ≤20, `email` válido ≤120, `password` 6–72).
- **RT-3 — Lista de posts**: busca por texto, filtros (rede social, pasta, tag, favoritos), paginação/scroll infinito, estado vazio, pull-to-refresh.
- **RT-4 — Criar/editar post**: título, URL, rede social (enum, §7), descrição, thumbnail, favorito, pasta, tags.
- **RT-5 — Favoritar**: alternar direto na lista/detalhe.
- **RT-6 — Pastas**: CRUD.
- **RT-7 — Tags**: CRUD.
- **RT-8 — Perfil**: ver/editar dados (`/me`), **sair**, excluir conta.
- **RT-9 — Estados de erro/carregamento/offline** consistentes em todas as telas.

## 7. Modelos de dados (espelhar os DTOs do backend)

- **`SocialSource`** (enum): `INSTAGRAM`, `TIKTOK`, `FACEBOOK`, `KWAI`, `YOUTUBE`, `TWITTER`, `OTHER`.
- **`Post`**: `id`, `title`, `url`, `description?`, `source`, `thumbnailUrl?`, `favorite`, `folder?`, `tags[]`, `createdAt`, `updatedAt`.
- **`PostRequest`** (criar/editar): `title`, `url`, `description?`, `source`, `thumbnailUrl?`, `favorite?`, `folderId?`, `tagIds[]?`.
- **`Folder`**: `id`, `name`, `description?`, `color?`, `createdAt`.
- **`Tag`**: `id`, `name`, `color?`.
- **`User`**: `id`, `name`, `username`, `email`. **`UserRequest`**: `name`, `username`, `email`, `password`.
- **`Page<T>`**: `content[]`, `totalElements`, `totalPages`, `number`, `size`.

## 8. Feature-chave: salvar via Share Sheet (a razão de existir do app)

O diferencial mobile é: estar no Instagram/TikTok/YouTube, tocar em **Compartilhar → PostSaver**, e o app abrir já no "salvar post" com a URL pré-preenchida.

- **RS-1 — Android (mais simples)**: `intent-filter` para `ACTION_SEND` (`text/plain`). O `receive_sharing_intent` entrega o texto/URL compartilhado ao app.
- **RS-2 — iOS (exige target nativo)**: é preciso criar uma **Share Extension** (target nativo em Swift, separado do app Flutter), com **App Group** para passar o conteúdo compartilhado ao app principal. Este trabalho **não é 100% Dart** e deve ser tratado como um workstream próprio.
- **RS-3 — Fluxo pós-share**: ao receber uma URL, o app deve (a) exigir sessão válida (ou levar ao login e retomar), (b) abrir "criar post" com `url` preenchida e, quando possível, tentar inferir `source` a partir do domínio.
- **RS-4 — App fechado vs. aberto**: tratar tanto o caso de share com o app já rodando quanto o cold start via share.

> Observação: essa é a parte mais cara e específica de plataforma do projeto — vale isolá-la numa fase própria e não subestimar o iOS.

## 9. Configuração de plataforma

**Android**
- **RP-A1** — Registrar o custom scheme do callback (`br.com.cmarinho.postsaver`) — no `flutter_appauth`, via `manifestPlaceholders` (`appAuthRedirectScheme`) no `build.gradle`, e/ou `intent-filter` no `AndroidManifest`.
- **RP-A2** — `intent-filter` de **share** (`ACTION_SEND`, `text/plain`) — §8.
- **RP-A3** — `minSdkVersion` compatível com as libs (definir na implementação); permissão de internet.

**iOS**
- **RP-I1** — Registrar o custom scheme em `CFBundleURLTypes` (Info.plist).
- **RP-I2** — Criar o target de **Share Extension** + **App Group** — §8.
- **RP-I3** — **ATS (App Transport Security)**: produção é HTTPS. Para desenvolvimento contra `http://<ip-lan>:8080`, adicionar exceção ATS temporária no Info.plist (nunca em produção).

## 10. Rede / ambientes (gotcha importante)

- **RN-1 — `localhost` não funciona no device**: o backend em dev roda em `localhost:8080` na sua máquina, mas no aparelho/emulador `localhost` é o próprio device. Configurar por ambiente:
  - Emulador Android → `http://10.0.2.2:8080`
  - Simulador iOS → `http://localhost:8080`
  - Device físico → `http://<IP-da-máquina-na-LAN>:8080`
- **RN-2 — O `issuer` precisa bater exatamente**: o backend valida o `iss` do token contra `app.oauth.issuer` (hoje `http://localhost:8080` em dev). O host usado pelo app **tem que coincidir** com o issuer configurado no backend, senão a validação falha. Ou seja: para testar em device, o `app.oauth.issuer` do backend precisa ser o mesmo host alcançável pelo device (ex.: o IP da LAN), não `localhost`.
- **RN-3 — Produção**: backend atrás de **HTTPS** com domínio real; `issuer`, `apiBase` e o `redirect_uri` (custom scheme continua valendo) configurados por ambiente no app (dev/staging/prod), sem hardcode espalhado.
- **RN-4 — CORS não se aplica** ao HTTP nativo do Flutter (CORS é do navegador). Mas o navegador do sistema usado no login **usa** as páginas do AS normalmente — nenhuma mudança de CORS específica de mobile é necessária além do que já existe.

## 11. Requisitos de segurança

- **RSEC-1** — Refresh token só em armazenamento seguro do SO (Keychain/Keystore).
- **RSEC-2** — **Sem segredos no app** (client público + PKCE; nada de client secret).
- **RSEC-3** — PKCE obrigatório (garantido pela lib + exigido pelo servidor).
- **RSEC-4** — HTTPS obrigatório em produção; exceções de cleartext só em dev.
- **RSEC-5** *(opcional/futuro)* — bloqueio por biometria para reabrir o app; certificate pinning.

## 12. Testes e qualidade

- **RQ-1** — Testes unitários de `AuthService` (refresh/rotação/expiração) e do parsing de modelos.
- **RQ-2** — Testes de widget das telas principais.
- **RQ-3** — Teste de integração do fluxo de login (mock do AS) e de um fluxo ponta-a-ponta de "salvar post".
- **RQ-4** — Lint (`flutter analyze`) + formatação no CI.
- **RQ-5** *(desejável)* — pipeline de build para Android (APK/AAB) e iOS, alinhado ao item de CI/CD do `MELHORIAS.md`.

## 13. Decisões em aberto (a confirmar antes de codar)

1. **Gerenciamento de estado**: Riverpod (recomendado) vs. Bloc.
2. **Lib de OAuth**: `flutter_appauth` (recomendada) vs. `openid_client` + `flutter_web_auth_2`.
3. **Onde mora o código mobile**: pasta `mobile/` neste mesmo repo (monorepo) vs. repositório separado.
4. **Cadastro**: formulário nativo (proposto) vs. também via página web do backend.
5. **Offline/sync**: v1 é *online-only*? Se for necessário funcionamento offline, depende de um endpoint de sync incremental (`updatedSince`) — hoje inexistente (é item do `MELHORIAS.md`). Definir se entra no escopo.
6. **Domínio/HTTPS de dev para device físico**: usar IP da LAN + ajustar `issuer`, ou subir um túnel (ex.: ngrok) com HTTPS.

## 14. Fora do escopo da v1 (explicitamente)

- Push notifications.
- Modo offline completo / sincronização bidirecional.
- Login social (Google/Apple) — exigiria evolução do Authorization Server.
- Compartilhar **para fora** (o foco da v1 é **receber** shares, não exportar).

## 15. Pré-requisitos no backend antes de começar o app

- **RB-1** — Garantir que o backend rode num **host alcançável pelo device** com `app.oauth.issuer` batendo esse host (§10, RN-2). Em produção, HTTPS + domínio real.
- **RB-2** — O client `postsaver-mobile` já existe; confirmar que o `redirect_uri` do app (`br.com.cmarinho.postsaver://callback`) continua registrado.
- **RB-3** *(recomendado, não bloqueante)* — Estabilizar o contrato de paginação e publicar uma **política de versionamento de API** (itens do `MELHORIAS.md`), já que um app instalado depende do contrato por muito tempo.

## 16. Marcos sugeridos (entrega em fases)

1. **Fundação**: projeto Flutter, config de ambientes, camada de API + modelos, tratamento de `ApiError`.
2. **Auth**: login PKCE via browser, secure storage, refresh/rotação, interceptor, guarda de rotas, logout.
3. **Paridade CRUD**: posts (lista/filtros/paginação/criar/editar/favoritar), pastas, tags, perfil `/me`.
4. **Feature-chave**: share sheet Android → salvar post; depois Share Extension iOS.
5. **Polimento**: estados de erro/offline, testes, biometria (opcional), build/release.
