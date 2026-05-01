# Arquitetura — Optical Manager

## Padrão: Monolito Modular com DDD

O sistema é estruturado como um monolito modular, seguindo os princípios do Domain-Driven Design (DDD) para garantir manutenibilidade e isolamento de regras de negócio.

### Camadas e Regra de Dependência
**NUNCA violar a direção das dependências:**
`API Layer → Application Layer → Domain Layer ← Infrastructure Layer`

1. **API Layer**: Controllers, DTOs, filtros HTTP, documentação Swagger (interfaces). Zero lógica de negócio.
2. **Application Layer**: Use Cases (Commands), Events, DTO Mappers. Orquestra a execução, mas não contém regras de domínio.
3. **Domain Layer (Coração)**: Entidades, Value Objects, Domain Services e interfaces de Repository. Java puro, sem dependências de frameworks (Spring, JPA, etc).
4. **Infrastructure Layer**: Implementações de Repositories JPA, Flyway, Clientes de AI, Storage (R2), Configurações de Segurança e JWT.

### Módulos do Sistema
Cada domínio de negócio possui seu próprio módulo:
- `shared`: TenantContext, Filial, TenantSettings e utilitários comuns.
- `identidade`: Usuários, Roles, Permissões e autenticação JWT.
- `clientes`: Clientes, Contatos, Receitas e Histórico.
- `produtos`: Armações (Frame/SKU), Lentes Oftálmicas, Lentes de Contato.
- `estoque`: Movimentações e Reservas.
- `vendas`: Ordem de Serviço (OS), Vendas e Itens.
- `financeiro`: Caixa, Lançamentos e Categorias.
- `notificacoes`: Alertas de Receita e Serviços de Mensageria.

---

## Multi-tenancy Rígido

O isolamento de dados entre clientes (tenants) é a prioridade máxima de segurança.

- **Identificador**: Todo registro no banco possui uma coluna `tenant_id UUID NOT NULL`.
- **Contexto**: O `TenantContext` (usando `ThreadLocal`) armazena o tenant da requisição atual, populado pelo `JwtAuthFilter`.
- **Filtro Automático**: O Hibernate Filter aplica automaticamente `WHERE tenant_id = ?` em todas as consultas (SELECT).
- **Injeção Automática**: `@PrePersist` injeta o `tenant_id` em novos registros; `@PreUpdate` valida se o tenant não foi alterado.
- **Segurança**: Nunca deve-se escrever queries manuais que omitam o `tenant_id`.

---

## Filiais (Branches)

- **Estrutura**: Preparada desde o início com `branch_id` nas tabelas principais.
- **MVP**: Suporte a apenas **uma filial padrão** por tenant.
- **Expansão**: Múltiplas filiais habilitáveis apenas no plano Max (Fase 2).

---

## SOLID e Design Patterns Aplicados

- **Single Responsibility**: Cada Use Case executa exatamente uma ação de negócio.
- **Dependency Inversion**: Camadas superiores e de domínio dependem de interfaces, não de implementações concretas da infraestrutura.
- **Repository Pattern**: Abstração total do acesso a dados por domínio.
- **Strategy**: Utilizado para precificação de lentes (FIXED vs GRADE_RANGE).
- **State Pattern**: Gerenciamento da máquina de estados complexa de Ordens de Serviço e Vendas.
- **Observer/Event**: Desacoplamento de ações (ex: Venda Confirmada → Gera Lançamento no Caixa).

---

## Observabilidade: Grafana Cloud

- **Motivação**: Centralização de métricas e logs com baixa carga operacional.
- **Stack**: Micrometer -> Prometheus -> Grafana Cloud.
- **Tracing**: Implementação futura com OpenTelemetry/Tempo.
