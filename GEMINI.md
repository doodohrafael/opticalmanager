# Regras do Projeto — Optical Manager MVP SaaS
> Este arquivo é o índice mestre e a fonte da verdade do projeto.
> **Toda IA ou desenvolvedor deve consultar este índice para localizar as regras detalhadas antes de qualquer implementação.**
> Atualizado em: 2026-04-30

---

## 1. Princípios de Arquitetura (Resumo)
- **Multi-tenancy Rígido**: Isolamento total de dados via `tenant_id`.
- **Arquitetura DDD**: Monolito modular. `API -> Application -> Domain <- Infrastructure`.
- **Qualidade**: TDD obrigatório (Pirâmide 70/20/10).
- **Consultas**: **Sempre** utilizar Native Queries (SQL Puro).

---

## 2. Índice de Documentação Detalhada

| Assunto | O que encontrar aqui? | Arquivo de Referência |
|---|---|---|
| **Visão do Produto** | Posicionamento, diferenciais, comparativo de mercado e análise financeira. | [`docs/product.md`](docs/product.md) |
| **Arquitetura** | Camadas, módulos, isolamento de tenant e decisões técnicas de alto nível. | [`docs/architecture.md`](docs/architecture.md) |
| **Regras de Negócio** | Máquina de estados da OS, trial, estoque, sequenciais e fiscal. | [`docs/business-rules.md`](docs/business-rules.md) |
| **Padrões de Código** | Stack (Java 25, Spring 4), injeção, idioma, records e exceções. | [`docs/development.md`](docs/development.md) |
| **Convenções** | Estilo de código, nomenclatura e padrões de organização. | [`docs/conventions.md`](docs/conventions.md) |
| **Segurança** | Stateless JWT, payload, roles e catálogo de permissões RBAC. | [`docs/security.md`](docs/security.md) |
| **Banco de Dados** | Convenções de schema, migrations Flyway e Native Queries. | [`docs/database.md`](docs/database.md) |
| **Inteligência Artificial** | Integração com Gemini, leitura de receitas e confirmação humana. | [`docs/ai.md`](docs/ai.md) |
| **Testes e Qualidade** | Padrões de TDD, Mockito e Testcontainers. | [`docs/tests.md`](docs/tests.md) |
| **Variáveis de Ambiente** | Documentação do `.env` e segredos necessários. | [`docs/env.md`](docs/env.md) |
| **Observabilidade** | Grafana Cloud, Prometheus, métricas customizadas e logs. | [`docs/observability.md`](docs/observability.md) |
| **Infraestrutura/CI-CD** | Docker, GitHub Actions, Cloud Run e deploy. | [`docs/ci.md`](docs/ci.md), [`docs/cd.md`](docs/cd.md) |
| **Histórico do Banco** | Documentação detalhada de cada migration SQL. | [`docs/database.md#flyway-migrations`](docs/database.md#flyway-migrations) |

---

## 3. Comandos Rápidos
- **Build**: `./mvnw clean install`
- **Testes**: `./mvnw test`
- **Execução**: `./mvnw spring-boot:run`
