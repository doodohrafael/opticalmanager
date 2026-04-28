# application.properties — Documentação

> Configuração padrão aplicada em toda a aplicação independente de perfis de ambiente.
> Valores sensíveis são lidos de variáveis de ambiente, nunca hardcoded.

---

## Arquivos de Propriedades

| Arquivo                         | Perfil   | Descrição                                                |
|---------------------------------|----------|----------------------------------------------------------|
| `application.properties`        | (todos)  | Configurações base — sempre carregadas                   |
| `application-dev.properties`    | `dev`    | Configurações para desenvolvimento local                 |
| `application-prd.properties`    | `prd`    | Configurações para produção                              |

O perfil ativo é definido pela variável de ambiente `SPRING_PROFILES_ACTIVE` no docker-compose.yml e application.properties padrão.

----

## `application.properties` — Base

### Identificação da Aplicação

```properties
spring.application.name=opticalmanager
```

---

### Banco de Dados

| Propriedade                          | Valor / Variável de Ambiente                   | Padrão Local     |
|--------------------------------------|------------------------------------------------|------------------|
| `spring.datasource.url`              | `jdbc:postgresql://${DB_HOST}:5432/${DB_NAME}` | `localhost:5432/opticalmanager` |
| `spring.datasource.username`         | `${DB_USERNAME}`                               | `user`           |
| `spring.datasource.password`         | `${DB_PASSWORD}`                               | `password`       |
| `spring.datasource.driver-class-name`| `org.postgresql.Driver`                        | —                |
| `spring.jpa.database-platform`       | `org.hibernate.dialect.PostgreSQLDialect`      | —                |

> A sintaxe `${VAR:default}` usa a variável de ambiente se definida; caso contrário, aplica o valor padrão após `:`.

---

### Flyway (Migrations)

| Propriedade                          | Valor  | Descrição                                                    |
|--------------------------------------|--------|--------------------------------------------------------------|
| `spring.flyway.enable`               | `true` | Ativa o Flyway — executa migrations ao iniciar               |
| `spring.flyway.baseline.on.migrate`  | `true` | Cria uma nova baseline se o banco já possuir tabelas e dados |

> Scripts de migration ficam em `src/main/resources/db/migration/` com o padrão de nomenclatura `V{n}__{descricao}.sql`.

---

### Inteligência Artificial — Gemini (Vertex AI)

| Propriedade                                          | Valor / Variável de Ambiente                       |
|------------------------------------------------------|----------------------------------------------------|
| `spring.ai.vertex.ai.gemini.project-id`              | `${PROJECT_ID}` Gerado no projeto criado na GCloud |
| `spring.ai.vertex.ai.gemini.location`                | `southamerica-east1` (fixo) Região mais próxima do Brasil    |
| `spring.ai.vertex.ai.gemini.chat.options.model`      | `gemini-2.5-flash` (fixo) Modelo LLM               |

> Autenticação com o Google Cloud é feita via **Application Default Credentials (ADC)** — não requer chave de API explícita no properties.
> Em desenvolvimento local, configure com: `gcloud auth application-default login`

---

### Documentação da API (Springdoc / Swagger)

| Propriedade                    | Valor  | Descrição                             |
|--------------------------------|--------|---------------------------------------|
| `springdoc.api-docs.enabled`   | `true` | Habilita o endpoint `/v3/api-docs`    |
| `springdoc.swagger-ui.enabled` | `true` | Habilita o Swagger UI em `/swagger-ui.html` |

> Em produção (`prd`), ambos são desabilitados (ver `application-prd.properties`).

---

### JWT (Autenticação)

| Propriedade                              | Variável de Ambiente                    |
|------------------------------------------|-----------------------------------------| 
| `jwt.secret`                             | `${JWT_SECRET}`                         |
| `jwt.access.token.expiration.hours`      | `${JWT_ACCESS_TOKEN_EXPIRATION_HOURS}`  |
| `jwt.refresh.token.expiration.days`      | `${JWT_REFRESH_TOKEN_EXPIRATION_DAYS}`  |

> Estas propriedades são personalizadas (não são do Spring) e são lidas via `@Value` ou `@ConfigurationProperties` na camada de infraestrutura.

---

### Mercado Pago

| Propriedade                   | Variável de Ambiente          |
|-------------------------------|-------------------------------|
| `mercadopago.access.token`    | `${MERCADOPAGO_ACCESS_TOKEN}` |

---

### Cloudflare R2 (Storage)

| Propriedade                    | Variável de Ambiente             |
|--------------------------------|----------------------------------|
| `cloudflare.token`             | `${CLOUDFLARE_TOKEN}`            |
| `cloudflare.r2.account.id`     | `${CLOUDFLARE_R2_ACCOUNT_ID}`    |
| `cloudflare.r2.access.key`     | `${CLOUDFLARE_R2_ACCESS_KEY}`    |
| `cloudflare.r2.secret.key`     | `${CLOUDFLARE_R2_SECRET_KEY}`    |
| `cloudflare.r2.bucket`         | `${CLOUDFLARE_R2_BUCKET}`        |

---

## `application-dev.properties` — Perfil de Desenvolvimento

Ativado quando `SPRING_PROFILES_ACTIVE=dev`.

| Propriedade                                   | Valor  | Descrição                                       |
|-----------------------------------------------|--------|-------------------------------------------------|
| `spring.jpa.show-sql`                         | `true` | Exibe as queries SQL no console                 |
| `spring.jpa.properties.hibernate.format_sql`  | `true` | Formata as queries SQL para leitura facilitada  |

> Útil para depuração de queries Hibernate e verificação do filtro de multi-tenancy (veja sobre multi-tenancy no arquivo [`docs/technical-rules.md`](technical-rules.md)).

---

## `application-prd.properties` — Perfil de Produção

Ativado quando `SPRING_PROFILES_ACTIVE=prd`.

| Propriedade                    | Valor   | Descrição                                              |
|--------------------------------|---------|--------------------------------------------------------|
| `springdoc.api-docs.enabled`   | `false` | Desabilita endpoint de documentação da API em produção |
| `springdoc.swagger-ui.enabled` | `false` | Desabilita o Swagger UI em produção                    |

> O Swagger é exclusivo para ambientes de desenvolvimento e staging.
> Em produção, a documentação da API é gerenciada internamente.

---

## Resumo por Perfil

| Funcionalidade         | dev   | prd   |
|------------------------|-------|-------|
| SQL no console         | ✅    | ❌    |
| SQL formatado          | ✅    | ❌    |
| Swagger UI             | ✅    | ❌    |
| API Docs (`/v3/...`)   | ✅    | ❌    |
| Flyway migrations      | ✅    | ✅    |
| Gemini AI              | ✅    | ✅    |

---

## Convenção de Variáveis de Ambiente

Todas as configurações sensíveis seguem o padrão:

```properties
# propriedade=${VARIAVEL_AMBIENTE:valor_padrao_opcional}
spring.datasource.username=${DB_USERNAME:user}

# sem valor padrão — obrigatório em todos os ambientes
jwt.secret=${JWT_SECRET}
```

> Variáveis sem valor padrão lançam `IllegalStateException` ao iniciar se não forem definidas.
