# Dockerfile — Documentação

> Build multi-stage para o backend **Optical Manager SaaS MVP**.
>
```
Stage 1 compila o projeto com Maven. 
Stage 2 gera a imagem de runtime enxuta, apenas com o JAR final.
```
---

## Visão Geral

```
Stage 1 (builder)  → eclipse-temurin:25-jdk-alpine  →  compila e gera o JAR
Stage 2 (runtime)  → eclipse-temurin:25-jre-alpine   →  executa apenas o JAR
```

A separação em dois stages mantém a imagem final pequena — o JDK e o Maven **não** existem na imagem de produção, apenas o JRE.

---

## Stage 1 — Builder

**Base:** `eclipse-temurin:25-jdk-alpine`

| Passo | Instrução | Descrição |
|-------|-----------|-----------|
| 1 | `WORKDIR /app` | Define o diretório de trabalho |
| 2 | `COPY pom.xml .` | Copia o POM para aproveitar cache de camadas |
| 3 | `COPY .mvn/ .mvn/` | Copia configurações do Maven Wrapper |
| 4 | `COPY mvnw .` | Copia o script do Maven Wrapper |
| 5 | `RUN ./mvnw dependency:go-offline -B` | Baixa todas as dependências **sem compilar** — camada cacheada enquanto `pom.xml` não mudar |
| 6 | `COPY src/ src/` | Copia o código-fonte |
| 7 | `RUN ./mvnw package -DskipTests` | Compila e empacota o JAR (sem executar testes) |

> **Estratégia de cache:** `pom.xml` é copiado **antes** do código-fonte. Se apenas o código mudar, a etapa de download das dependências é reutilizada do cache do Docker, tornando o build muito mais rápido.

---

## Stage 2 — Runtime

**Base:** `eclipse-temurin:25-jre-alpine`

### Metadados (LABEL)

| Label           | Valor                                                                 |
|-----------------|-----------------------------------------------------------------------|
| `maintainer`    | `opticalmanager`                                                      |
| `description`   | Intelligent management system for optical stores with AI integration. |
| `version`       | `1.0.0-SNAPSHOT`                                                      |

### Segurança — Usuário Não-Root

```dockerfile
RUN addgroup -S opticalmanagergroup && adduser -S opticalmanageruser -G opticalmanagergroup
USER opticalmanageruser
```

O container roda com um usuário sem privilégios de root. Boa prática de segurança para ambientes de produção.

### Cópia do JAR

```dockerfile
COPY --from=builder /app/target/*.jar app.jar
```

Copia apenas o JAR gerado no stage `builder`. Nenhum arquivo de build, dependências temporárias ou JDK são incluídos.

### Porta Exposta

```
EXPOSE 8080
```

### Healthcheck

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD wget -qO- http://localhost:8080/actuator/health || exit 1
```

| Parâmetro       | Valor  | Descrição                                                 |
|-----------------|--------|-----------------------------------------------------------|
| `--interval`    | 30s    | Intervalo entre cada verificação                          |
| `--timeout`     | 10s    | Tempo máximo para a resposta do health check              |
| `--start-period`| 60s    | Tempo de inicialização antes de começar as verificações   |
| `--retries`     | 3      | Falhas consecutivas para marcar como `unhealthy`          |

> Usa o endpoint `/actuator/health` exposto pelo `spring-boot-starter-actuator`.
> Compatível com Railway e Google Cloud Run.

### Entrypoint — JVM Tuning

```dockerfile
ENTRYPOINT ["java",
    "-XX:+UseContainerSupport",
    "-XX:MaxRAMPercentage=70.0",
    "-XX:+OptimizeStringConcat",
    "--enable-preview",
    "-jar", "app.jar"]
```

| Flag JVM                    | Descrição                                                                                      |
|-----------------------------|-----------------------------------------------------------------------------------------------|
| `-XX:+UseContainerSupport`  | Respeita os limites de memória do container (cgroups) ao invés de usar a RAM total do host    |
| `-XX:MaxRAMPercentage=70.0` | A JVM usa no máximo 70% da RAM disponível no container (ideal para Railway/GCloud e2-micro 1GB) |
| `-XX:+OptimizeStringConcat` | Otimização de concatenação de strings em tempo de execução                                    |
| `--enable-preview`          | Habilita features de preview do Java 25 (necessário por conta do compilador configurado)      |

---

## Uso

```bash
# Build da imagem
docker build -t optical-manager-api .

# Executar com variáveis de ambiente do arquivo .env
docker run -p 8080:8080 --env-file .env optical-manager-api
```

> Para uso local com banco de dados, prefira o `docker-compose.yml`, que sobe a API e o PostgreSQL juntos.

---

## Imagens de Base

| Stage   | Imagem                          | Tamanho aproximado |
|---------|---------------------------------|--------------------|
| Builder | `eclipse-temurin:25-jdk-alpine` | ~370MB             |
| Runtime | `eclipse-temurin:25-jre-alpine` | ~180MB             |

A escolha da variante `-alpine` reduz significativamente o tamanho em relação às imagens Debian/Ubuntu.
