# docker-compose.yml — Documentação

> Orquestra o ambiente de desenvolvimento local completo com dois serviços: banco de dados PostgreSQL e API Spring Boot.

---

## Visão Geral

```
services:
  db   → PostgreSQL 17 (banco de dados)
  api  → Spring Boot (backend dessa aplicação)

volumes:
  postgres_data  → persistência dos dados do banco

networks:
  optical_manager_network  → rede interna bridge entre os serviços
```

---

## Serviço `db` — PostgreSQL

| Configuração        | Valor                                          |
|---------------------|------------------------------------------------|
| `container_name`    | `optical-manager-db`                           |
| `image`             | `postgres:17-alpine`                           |
| `restart`           | `always`                                       |
| `command`           | `["postgres", "-p", "5432"]`                   |
| `port`              | `5432:5432`                                    |
| `volume`            | `postgres_data:/var/lib/postgresql/data`       |
| `network`           | `optical_manager_network`                      |

### Variáveis de Ambiente

| Variável           | Valor padrão      | Variável `.env` usada |
|--------------------|-------------------|-----------------------|
| `POSTGRES_USER`    | `user`            | `${DB_USERNAME}`      |
| `POSTGRES_PASSWORD`| `password`        | `${DB_PASSWORD}`      |
| `POSTGRES_DB`      | `opticalmanager`  | `${DB_NAME}`          |

> A sintaxe `${VAR:-default}` usa o `.env` quando disponível; caso contrário, aplica o valor padrão.

### Healthcheck

```yaml
test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
interval: 10s
timeout: 5s
retries: 5
start_period: 10s
```

O serviço `api` só sobe após o banco estar saudável (`condition: service_healthy`).

---

## Serviço `api` — Spring Boot

| Configuração        | Valor                                                                                                  |
|---------------------|--------------------------------------------------------------------------------------------------------|
| `container_name`    | `optical-manager-api`                                                                                  |
| `build.context`     | `.` (raiz do projeto)                                                                                  |
| `build.dockerfile`  | `Dockerfile`                                                                                           |
| `build.target`      | `runtime` (stage 2 do multi-stage) |
| `restart`           | `unless-stopped (Se o container cair (erro), o Docker reinicia automaticamente)`                       |
| `port`              | `8080:8080`                                                                                            |
| `network`           | `optical_manager_network`                                                                              |
| `depends_on`        | `db` (condition: `service_healthy`)                                                                    |

### Variáveis de Ambiente Injetadas (mais detalhes sobres as vars no arquivo `env.md`)

#### Banco de Dados

| Variável de Ambiente               | Valor                                                          |
|------------------------------------|----------------------------------------------------------------|
| `DB_HOST`                          | `${DB_HOST:-optical-manager-db}`                               |
| `DB_NAME`                          | `${DB_NAME:-opticalmanager}`                                   |
| `DB_USERNAME`                      | `${DB_USERNAME-user}`                                          |
| `DB_PASSWORD`                      | `${DB_PASSWORD-password}`                                      |
| `SPRING_DATASOURCE_URL`            | `jdbc:postgresql://$${DB_HOST}/$${DB_NAME}`                    |

> A URL usa o nome do container `optical-manager-db` como hostname — resolução via rede interna Docker.

#### Flyway

| Variável de Ambiente                   | Valor    | Descrição                                        |
|----------------------------------------|----------|--------------------------------------------------|
| `SPRING_FLYWAY_ENABLED`                | `true`   | Executa migrations automaticamente ao subir      |
| `SPRING_FLYWAY_BASELINE_ON_MIGRATE`    | `true`   | Cria uma nova baseline se o banco já possuir tabelas e dados        |

#### JWT

| Variável de Ambiente                         | Fonte `.env`                            |
|----------------------------------------------|-----------------------------------------|
| `JWT_SECRET`                                 | `${JWT_SECRET:-}`                       |
| `JWT_ACCESS_TOKEN_EXPIRATION_HOURS`          | `${JWT_ACCESS_TOKEN_EXPIRATION_HOURS:-}`|
| `JWT_REFRESH_TOKEN_EXPIRATION_DAYS`          | `${JWT_REFRESH_TOKEN_EXPIRATION_DAYS:-}`|

#### AI — Gemini (Google)

| Variável de Ambiente                            | Valor / Fonte              |
|-------------------------------------------------|----------------------------|
| `SPRING_AI_VERTEX_AI_GEMINI_PROJECT_ID`         | `${PROJECT_ID:-}`          |
| `SPRING_AI_VERTEX_AI_GEMINI_LOCATION`           | `southamerica-east1` (fixo)          |
| `SPRING_AI_VERTEX_AI_GEMINI_CHAT_OPTIONS_MODEL` | `gemini-2.5-flash` (fixo)  |

#### Mercado Pago

| Variável de Ambiente         | Fonte `.env`                    |
|------------------------------|---------------------------------|
| `MERCADOPAGO_ACCESS_TOKEN`   | `${MERCADOPAGO_ACCESS_TOKEN:-}` |

#### Resend (Email Transacional)

| Variável de Ambiente | Fonte `.env`          |
|----------------------|-----------------------|
| `RESEND_API_KEY`     | `${RESEND_API_KEY:-}` |

#### Cloudflare R2 (Storage de Fotos)

| Variável de Ambiente         | Fonte `.env`                      |
|------------------------------|-----------------------------------|
| `CLOUDFLARE_TOKEN`           | `${CLOUDFLARE_TOKEN:-}`           |
| `CLOUDFLARE_R2_ACCOUNT_ID`   | `${CLOUDFLARE_R2_ACCOUNT_ID:-}`   |
| `CLOUDFLARE_R2_ACCESS_KEY`   | `${CLOUDFLARE_R2_ACCESS_KEY:-}`   |
| `CLOUDFLARE_R2_SECRET_KEY`   | `${CLOUDFLARE_R2_SECRET_KEY:-}`   |
| `CLOUDFLARE_R2_BUCKET`       | `${CLOUDFLARE_R2_BUCKET:-}`       |

#### Ambiente / Servidor

| Variável de Ambiente      | Valor / Fonte                      |
|---------------------------|------------------------------------|
| `SPRING_PROFILES_ACTIVE`  | `${SPRING_PROFILES_ACTIVE:-dev}`   |
| `SERVER_PORT`             | `8080` (fixo)                      |

---

## Volumes

| Volume          | Descrição                                                                                                                               |
|-----------------|-----------------------------------------------------------------------------------------------------------------------------------------|
| `postgres_data` | Volume nomeado para persistência do banco de dados. Isso permite que os dados do PostgreSQL sobrevivem a reinicializações do container. |

---

## Rede

| Rede                       | Driver   | Descrição                                                    |
|----------------------------|----------|--------------------------------------------------------------|
| `optical_manager_network`  | `bridge` | Rede interna isolada. Os serviços se comunicam pelo nome do container. |

---

## Comandos de Uso

```bash
# Subir todos os serviços (em background)
docker compose up -d

# Subir reconstruindo a imagem da API
docker compose up -d --build

# Ver logs da API em tempo real
docker compose logs -f api

# Parar e remover containers (preserva volumes)
docker compose down

# Parar e remover containers + volumes (apaga dados do banco)
docker compose down -v
```

---

## Fluxo de Inicialização

```
1. Docker sobe o container "db" (PostgreSQL)
2. Healthcheck verifica pg_isready a cada 10s
3. Após 5 tentativas bem-sucedidas → db marcado como healthy
4. Docker sobe o container "api" (Spring Boot)
5. Flyway executa as migrations pendentes ao iniciar a aplicação
6. API disponível em http://localhost:8080
```
