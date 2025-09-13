### Configurações Necessárias


Utilize a [API com Swagger](https://postsaver.up.railway.app/swagger-ui.html)

> As seguintes váriaveis de ambiente devem ser configuradas na sua IDE:

``` properties
# PERFIL DE DESENVOLVIMENTO - dev

SPRING_PROFILES_ACTIVE=dev
```

``` properties
# PERFIL DE PRODUÇÃO - prd

SPRING_PROFILES_ACTIVE=prd
PGHOST=https://url.com
PGPORT=8080
PGDATABASE=
PGUSER=postgres
PGPASSWORD=1234
```
