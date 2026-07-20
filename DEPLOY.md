# Deploy no Render (plano gratuito)

O backend sobe como container Docker no Render (não há runtime Java nativo lá).
O banco fica no [Neon](https://neon.tech) — Postgres gratuito e permanente,
enquanto o Postgres free do próprio Render expira em 30 dias.

## 1. Banco de dados (Neon)

1. Crie uma conta em https://neon.tech e um projeto (ex.: `postsaver`).
2. No dashboard, copie os dados de conexão (host, database, user, password).
   O Flyway cria o schema automaticamente na primeira subida.

## 2. Keystore JWK (chave de assinatura dos tokens)

O perfil `prd` assina os JWTs com uma chave RSA vinda de um keystore PKCS12
(assim os tokens sobrevivem a restarts). Gere o arquivo localmente:

```
keytool -genkeypair -alias postsaver-jwk -keyalg RSA -keysize 2048 \
  -storetype PKCS12 -keystore jwk.p12 -validity 3650 \
  -dname "CN=postsaver" -storepass <ESCOLHA_UMA_SENHA>
```

**Não** comite o `jwk.p12` — ele será enviado como Secret File do Render.

## 3. Serviço no Render

1. Dashboard do Render → **New → Blueprint** → conecte este repositório.
   O `render.yaml` define o serviço `postsaver-api` (Docker, plano free).
2. Na criação, o Render pede os valores das variáveis `sync: false`:

   | Variável | Valor |
   |---|---|
   | `PGHOST` | host do Neon (ex.: `ep-xxx.us-east-2.aws.neon.tech`) |
   | `PGDATABASE` | nome do banco no Neon |
   | `PGUSER` | usuário do Neon |
   | `PGPASSWORD` | senha do Neon |
   | `APP_JWK_KEYSTORE_PASSWORD` | a senha usada no `keytool` acima |

3. Após criar o serviço: **Environment → Secret Files → Add Secret File**,
   nome `jwk.p12`, conteúdo = upload do arquivo gerado no passo 2.
   Ele fica disponível em `/etc/secrets/jwk.p12` (já apontado pelo
   `APP_JWK_KEYSTORE_LOCATION` no blueprint).
4. Se escolher outro nome de serviço que não `postsaver-api`, ajuste
   `APP_OAUTH_ISSUER` no Render **e** `_prodIssuer` em
   `frontend/postsaver/lib/core/config/environment.dart` para a URL real.

## 4. Verificação

Com o deploy no ar:

```
curl https://postsaver-api.onrender.com/.well-known/openid-configuration
```

Deve retornar o discovery document com `"issuer": "https://postsaver-api.onrender.com"`.
O Swagger fica em `https://postsaver-api.onrender.com/swagger-ui.html`.

## 5. App mobile

O build de release já aponta para a URL de produção (`Environment.prod`):

```
cd frontend/postsaver
flutter build apk --release
```

## Limitações do plano free

- **Cold start**: o serviço hiberna após ~15 min sem tráfego; a primeira
  requisição seguinte leva ~30–60 s (Spring Boot + JVM).
- **Sessões OAuth em memória**: refresh tokens e autorizações vivem na memória
  do processo. A cada restart/hibernação, o app pede login de novo. Para
  persistir no Postgres, seria preciso adotar o `JdbcOAuth2AuthorizationService`
  do Spring Authorization Server (migração de schema + beans).
