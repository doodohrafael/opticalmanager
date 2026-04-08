# pom.xml — Documentação do Build Maven

> Arquivo de configuração central do projeto Maven. Define identidade, dependências, plugins de build e repositórios externos.

---

## Identidade do Projeto

| Campo         | Valor                                      |
|---------------|--------------------------------------------|
| `groupId`     | `br.com.rebootsystems`                     |
| `artifactId`  | `opticalmanager`                           |
| `version`     | `1.0.0-SNAPSHOT`                           |
| `name`        | Optical Manager MVP                        |
| `description` | Intelligent management system for optical stores with AI integration. |
| `url`         | https://rebootsystems.com.br               |
| `parent`      | `spring-boot-starter-parent` `4.0.5`       |

### Desenvolvedor

| Campo              | Valor                         |
|--------------------|-------------------------------|
| `id`               | `douglasrafael`               |
| `name`             | Douglas Rafael                |
| `email`            | doodohrafael@gmail.com        |
| `organization`     | Reboot Systems                |
| `organizationUrl`  | https://rebootsystems.com.br  |
| `roles`            | Architect, Developer          |
| `timezone`         | -3                            |

### Licença

| Campo          | Valor                                      |
|----------------|--------------------------------------------|
| `name`         | Proprietary License                        |
| `url`          | https://rebootsystems.com.br/license       |
| `distribution` | `repo`                                     |
| `comments`     | All rights reserved to Reboot Systems.     |

### SCM (Controle de Versão)

| Campo                 | Valor                                                       |
|-----------------------|-------------------------------------------------------------|
| `connection`          | `scm:git:git://github.com/doodohrafael/opticalmanager.git`  |
| `developerConnection` | `scm:git:ssh://github.com:doodohrafael/opticalmanager.git`  |
| `url`                 | https://github.com/doodohrafael/opticalmanager              |
| `tag`                 | `HEAD`                                                      |

---

## Propriedades Globais (`<properties>`)

| Propriedade                        | Valor          | Descrição                                      |
|------------------------------------|----------------|------------------------------------------------|
| `java.version`                     | `25`           | Versão do Java utilizada                       |
| `project.build.sourceEncoding`     | `UTF-8`        | Encoding dos fontes                            |
| `project.reporting.outputEncoding` | `UTF-8`        | Encoding dos relatórios                        |
| `spring-ai.version`                | `2.0.0-M4`     | Versão da BOM do Spring AI                     |
| `jjwt.version`                     | `0.12.6`       | Versão da lib JJWT para JWT                    |
| `springdoc.version`                | `3.0.2`        | Versão do SpringDoc OpenAPI (Swagger)          |
| `testcontainers.version`           | `1.20.4`       | Versão do Testcontainers                       |
| `mapstruct.version`                | `1.6.3`        | Versão do MapStruct                            |
| `mercadopago.version`              | `2.8.0`        | Versão do SDK Mercado Pago                     |
| `resend.version`                   | `4.13.0`       | Versão da lib Resend (email transacional)      |
| `aws.sdk.version`                  | `2.29.43`      | Versão do AWS SDK v2 (usado para Cloudflare R2)|
| `openpdf.version`                  | `2.0.3`        | Versão do OpenPDF (geração de PDF)             |

---

## Dependências

### Spring Boot Core

| artifactId                          | Escopo    | Descrição                                          |
|-------------------------------------|-----------|----------------------------------------------------|
| `spring-boot-starter-web`           | compile   | API REST com Tomcat embutido                       |
| `spring-boot-starter-validation`    | compile   | Bean Validation (Hibernate Validator)              |
| `spring-boot-starter-actuator`      | compile   | Endpoints de health e métricas                     |

### Agendamento de Jobs

| artifactId                        | Escopo  | Descrição                                     |
|-----------------------------------|---------|-----------------------------------------------|
| `spring-boot-starter-quartz`      | compile | Agendamento de tarefas com Quartz Scheduler    |

> Usado para o job de alerta de receitas vencendo (`@Scheduled`), que roda diariamente às 8h.

### Segurança

| artifactId                          | Escopo    | Descrição                                  |
|-------------------------------------|-----------|--------------------------------------------|
| `spring-boot-starter-security`      | compile   | Spring Security (filtros, auth, RBAC)      |
| `jjwt-api`                          | compile   | API do JJWT — geração e assinatura de JWT  |
| `jjwt-impl`                         | runtime   | Implementação interna do JJWT              |
| `jjwt-jackson`                      | runtime   | Serialização Jackson para payloads JWT     |

> Todos os artefatos JJWT usam a versão `${jjwt.version}`.

### Banco de Dados

| artifactId                          | Escopo    | Descrição                                        |
|-------------------------------------|-----------|--------------------------------------------------|
| `spring-boot-starter-data-jpa`      | compile   | Spring Data JPA + Hibernate                      |
| `postgresql`                        | runtime   | Driver JDBC do PostgreSQL                        |
| `flyway-core`                       | compile   | Migração de schema — engine principal            |
| `flyway-database-postgresql`        | compile   | Suporte específico ao PostgreSQL no Flyway       |

### Inteligência Artificial

| artifactId                                      | Escopo  | Descrição                                        |
|-------------------------------------------------|---------|--------------------------------------------------|
| `spring-ai-starter-model-vertex-ai-gemini`      | compile | Integração com Gemini via Vertex AI (Google)     |

> Versão controlada pela BOM `spring-ai-bom` no `<dependencyManagement>`.
> Modelo configurado: `gemini-2.5-flash`. Usado para leitura de receita por foto (AI sugere, humano valida).

### Documentação da API

| artifactId                                  | Escopo  | Descrição                               |
|---------------------------------------------|---------|-----------------------------------------|
| `springdoc-openapi-starter-webmvc-ui`       | compile | Swagger UI + OpenAPI 3 em `/swagger-ui.html` |

### Geração de PDF

| artifactId   | Escopo  | Descrição                             |
|--------------|---------|---------------------------------------|
| `openpdf`    | compile | Geração de comprovantes PDF (OS, venda domiciliar) |

### Pagamentos

| artifactId   | Escopo  | Descrição                                    |
|--------------|---------|----------------------------------------------|
| `sdk-java`   | compile | SDK Mercado Pago — PIX QR Code e assinaturas SaaS |

### Email Transacional

| artifactId      | Escopo  | Descrição                              |
|-----------------|---------|----------------------------------------|
| `resend-java`   | compile | Envio de emails via Resend API         |

### Storage em Nuvem

| artifactId | Escopo  | Descrição                                            |
|------------|---------|------------------------------------------------------|
| `s3`       | compile | AWS SDK v2 — cliente S3-compatible para Cloudflare R2 |

> O Cloudflare R2 expõe API compatível com S3, por isso o SDK da AWS é usado.

### Mapeamento de Objetos

| artifactId   | Escopo  | Descrição                                          |
|--------------|---------|----------------------------------------------------|
| `mapstruct`  | compile | Mapeamento entre entidades de domínio e DTOs/Records |

> O `mapstruct-processor` é configurado como `annotationProcessorPath` no Maven Compiler Plugin para geração de código em tempo de compilação.

### Testes

| artifactId                    | Escopo | Descrição                                           |
|-------------------------------|--------|-----------------------------------------------------|
| `spring-boot-starter-test`    | test   | JUnit 5 + Mockito + MockMvc                         |
| `spring-security-test`        | test   | Suporte a testes de autenticação/autorização        |
| `testcontainers:junit-jupiter`| test   | Integração Testcontainers + JUnit 5                 |
| `testcontainers:postgresql`   | test   | Container PostgreSQL real para testes de integração |

### Desenvolvimento Local

| artifactId                  | Escopo  | Descrição                             |
|-----------------------------|---------|---------------------------------------|
| `spring-boot-devtools`       | runtime | Hot reload em desenvolvimento local   |
| `spring-boot-docker-compose`| runtime | Gerenciamento automático de containers Docker |

> Opcional (`<optional>true</optional>`), não incluído no JAR de produção.


---

## Gerenciamento de Dependências (`<dependencyManagement>`)

| BOM                  | Versão         | Finalidade                                            |
|----------------------|----------------|-------------------------------------------------------|
| `spring-ai-bom`      | `2.0.0-M4`     | Alinha versões de todos os artefatos Spring AI        |

---

## Build — Plugins

### `spring-boot-maven-plugin`

Gera o JAR executável (`fat jar`) do projeto.

| Configuração      | Valor               | Descrição                         |
|-------------------|---------------------|-----------------------------------|
| `jvmArguments`    | `--enable-preview`  | Habilita features preview Java 25 |

### `maven-compiler-plugin`

Compila o projeto com Java 25.

| Configuração           | Valor               | Descrição                                    |
|------------------------|---------------------|----------------------------------------------|
| `source`               | `25`                | Versão de origem do compilador               |
| `target`               | `25`                | Versão de destino do compilador              |
| `compilerArgs`         | `--enable-preview`  | Habilita syntax preview do Java 25           |
| `annotationProcessorPaths` | `mapstruct-processor` `${mapstruct.version}` | Geração de mappers em compile-time |

### `maven-surefire-plugin`

Executa **testes unitários** (ciclo padrão `mvn test`).

| Configuração | Valor                                                     |
|--------------|-----------------------------------------------------------|
| `argLine`    | `--enable-preview`                                        |
| `excludes`   | `**/*IT.java`, `**/*IntegrationTest.java`                 |

> Testes de integração são **excluídos** do ciclo padrão e executados pelo Failsafe.

### `maven-failsafe-plugin`

Executa **testes de integração** (fase `integration-test`).

| Configuração | Valor                                                     |
|--------------|-----------------------------------------------------------|
| `argLine`    | `--enable-preview`                                        |
| `includes`   | `**/*IT.java`, `**/*IntegrationTest.java`                 |
| `executions` | `integration-test`, `verify`                             |

> Convenção de nomenclatura: classes de teste de integração devem terminar com `IT` ou `IntegrationTest`.

**Comandos:**
```bash
# Testes unitários
mvn test

# Testes de integração
mvn verify

# Build sem testes
mvn package -DskipTests
```

---

## Repositórios Externos

O Spring AI está em fase milestone/snapshot e não está disponível no Maven Central. Os repositórios abaixo são necessários para baixar seus artefatos.

| id                  | Nome                | URL                                    | Snapshots | Releases |
|---------------------|---------------------|----------------------------------------|-----------|----------|
| `spring-milestones` | Spring Milestones   | https://repo.spring.io/milestone       | disabled  | enabled  |
| `spring-snapshots`  | Spring Snapshots    | https://repo.spring.io/snapshot        | enabled   | disabled |

Os mesmos repositórios são declarados em `<pluginRepositories>` para que os plugins Maven também possam ser resolvidos.

---

## Mapa de Versões Fixadas

```
spring-boot-starter-parent  4.0.5
java                        25
spring-ai-bom               2.0.0-M4
jjwt                        0.12.6
springdoc-openapi            3.0.2
testcontainers              1.20.4
mapstruct                   1.6.3
mercadopago SDK             2.8.0
resend-java                 4.13.0
aws-sdk-v2 (S3)             2.29.43
openpdf                     2.0.3
```
