# Optical Manager — Backend

Sistema de gestão para óticas com foco em automação e melhoria de processos junto a inteligência artificial.

## 🚀 Tecnologias utilizadas nesse projeto

O projeto utiliza o ecossistema Java e computação em nuvem:

### **Linguagem e Framework Core**
- **Java 25**: Utilizando recursos mais recentes do Java.
- **Spring Boot 4.0.5**: Base para toda a infraestrutura da aplicação.
- **Spring Web & Validation**: Construção de APIs REST robustas com validação rigorosa.
- **Spring Security & JJWT**: Autenticação e autorização baseada em tokens JWT.

### **Persistência e Inteligência**
- **PostgreSQL 17**: Banco de dados relacional principal.
- **Spring Data JPA & Hibernate**: Camada de persistência com suporte a Multi-tenancy.
- **Flyway**: Evolução controlada do schema do banco de dados.

### **Inteligência Artificial**
- **Spring AI utilizando Vertex AI Gemini**: Integração nativa com o modelo **Gemini 2.5 Flash do Google**.

### **Serviços e Integrações**
- **Cloudflare R2 (AWS S3 SDK)**: Armazenamento de arquivos.
- **Mercado Pago SDK**: Gestão de pagamentos via PIX e assinaturas recorrentes.
- **Resend SDK**: Comunicação transacional via e-mail.
- **OpenPDF**: Gerar documentos e ordens de serviço em PDF.

### **Observabilidade e Qualidade**
- **Micrometer & Prometheus**: Exposição de métricas para monitoramento (Grafana).
- **SpringDoc OpenAPI (Swagger)**: Documentação interativa e atualizada da API.
- **Testcontainers**: Testes de integração reais utilizando containers Docker para garantir qualidade.
- **JUnit 5 & Mockito**: Testes unitários para garantir qualidade.

### **Infraestrutura**
- **Docker & Docker Compose**: Padronização do ambiente de desenvolvimento.
- **Railway**: Plataforma de deploy e hospedagem.

## 🏗️ Arquitetura e Padrões

O projeto segue os princípios de **Clean Architecture** e **DDD (Domain-Driven Design)** estruturado como um **Monolito Modular**.

### Estrutura de Camadas
1. **API:** Controllers, DTOs e Specs do Swagger.
2. **Application:** Casos de Uso (Use Cases) e Orquestração.
3. **Domain:** Entidades, Value Objects e Interfaces de Repositório (Core do negócio).
4. **Infra:** Implementações concretas (JPA, Clientes de API, Segurança).

### Principais Padrões
- **Multi-tenancy:** Isolamento de dados via `tenant_id` em nível de banco (Hibernate Filters) garantindo consistência.
- **Use Cases:** Uma classe por ação de negócio para garantir o princípio de responsabilidade única.
- **Records:** Uso extensivo de Java Records para imutabilidade em DTOs e VOs.
- **Global Error Handling:** Hierarquia customizada baseada em `OticaException`.

## 🛠️ Como Executar

### Pré-requisitos
- Docker e Docker Compose
- Java 25 (se for executar fora do Docker)
- Maven 3.9+

### Passo a Passo

1. **Configurar Ambiente:**
   Crie um arquivo `.env` na raiz do projeto com base nas variáveis descritas abaixo.

2. **Subir com Docker Compose:**
   ```bash
   docker compose up -d
   ```
   Isso iniciará o banco de dados PostgreSQL e a aplicação Spring Boot.

3. **Acessar a API:**
   A aplicação estará disponível em `http://localhost:8080`.

## 🔑 Variáveis de Ambiente

As principais variáveis necessárias no `.env` são:

```dotenv
# Banco de Dados
DB_USERNAME=user
DB_PASSWORD=password
DB_NAME=opticalmanager

# JWT
JWT_SECRET=sua_chave_secreta_hex_32_chars
JWT_ACCESS_TOKEN_EXPIRATION_HOURS=1

# Google Cloud (IA)
PROJECT_ID=seu-id-no-gcp

# Integrações
MERCADOPAGO_ACCESS_TOKEN=seu_tokenno read
RESEND_API_KEY=sua_chave
CLOUDFLARE_R2_BUCKET=nome_do_bucket
# (Veja docs/env.md para a lista completa)
```

## 📖 Documentação Adicional
A documentação detalhada está disponível na pasta `docs/` (atualmente ignorada no repositório remoto para proteção de detalhes arquiteturais sensíveis).
