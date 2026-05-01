# Convenções de Banco de Dados — Optical Manager

## Convenções de Nomenclatura
- **Tabelas**: `snake_case` plural (ex: `service_orders`, `stock_movements`).
- **Colunas**: `snake_case` (ex: `tenant_id`, `created_at`).
- **PKs**: Sempre `UUID DEFAULT gen_random_uuid()`.
- **FKs**: `{entidade}_id` (ex: `client_id`, `vendor_id`).
- **Índices**: `idx_{tabela}_{coluna}`.

---

## Tipos e Tamanhos de Campo (Padrão)

| Tipo | Tamanho | Uso Comum |
|---|---|---|
| Nome de pessoa | `VARCHAR(100)` | Clientes, Usuários |
| Nome de empresa | `VARCHAR(60)` | Tenant Name |
| Email | `VARCHAR(100)` | - |
| Telefone | `VARCHAR(20)` | Celulares, WhatsApp |
| CPF | `CHAR(11)` | - |
| CNPJ | `CHAR(14)` | - |
| Senha | `CHAR(60)` | Hash BCrypt |
| Enums | `VARCHAR(30)` | Status, Tipos |
| Slugs | `VARCHAR(50)` | Permissões |
| Descrições | `VARCHAR(200)` | - |
| Observações | `VARCHAR(500)` | - |
| Valores | `NUMERIC(10,2)` | **NUNCA usar FLOAT/DOUBLE** |

---

## Índices Obrigatórios
- **tenant_id**: Deve estar indexado em todas as tabelas (usado em toda query).
- **Busca**: Campos como `name`, `cpf` e `email`.
- **Relatórios**: Campos de data (`created_at`, `closed_at`).
- **FKs**: Todo campo de chave estrangeira deve ter índice.

---

## Flyway (Migrations)
- **Nomenclatura**: `V{n}__{descricao_snake_case}.sql`.
- **Imutabilidade**: Arquivos já executados no banco **nunca** devem ser alterados. Se precisar corrigir algo, crie uma nova versão.
- **Estrutura**: Um arquivo por domínio na criação inicial (V1).
---

## Histórico de Migrations
Documentação detalhada de cada migration e qualquer alteração no schema do banco de dados:

- [**V1 — Create Shared**](migrations/V1__create_shared.md): Tabelas base de Multi-tenancy, Branches e Configurações.

