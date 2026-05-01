# Migration V2 — Create Identity

## Visão Geral
Esta migration estabelece o controle de acesso e autenticação do sistema utilizando o modelo RBAC (Role-Based Access Control).

- **Módulo**: `identity`
- **Tabelas**: `permission`, `role`, `role_permission`, `app_user`, `refresh_token`
- **Objetivo**: Prover autenticação segura e autorização granular por tenant.

---

## Convenções Adotadas
- **app_user**: Nomeado assim para evitar conflito com a palavra reservada `user` do PostgreSQL.
- **RBAC**: Permissões baseadas em slugs no formato `recurso:ação` (ex: `sales:create`).
- **Token Rotation**: Refresh tokens são rotacionados a cada uso e armazenados como hash SHA-256.
- **Token Version**: Controle para invalidação forçada de sessões quando as permissões mudam.

---

## Tabelas Criadas

### 1. `permission`
Catálogo global de permissões do sistema.
- **Campos Principais**:
  - `slug`: Identificador único (ex: `stock:view`).
- **Dados Iniciais**: Inclui permissões para vendas, clientes, estoque, caixa, relatórios, IA, etc.

### 2. `role`
Conjunto nomeado de permissões definido por tenant.
- **Escopo**: Cada tenant possui seus próprios perfis (OWNER, MANAGER, VENDOR, etc.).
- **Unicidade**: O nome do perfil é único dentro de um tenant.

### 3. `role_permission`
Associação entre perfis e permissões.
- **Performance**: Armazena o `permission_slug` diretamente para evitar joins excessivos durante a autorização.

### 4. `app_user`
Usuários do sistema.
- **Campos Principais**:
  - `password_hash`: Hash BCrypt(12).
  - `token_version`: Usado para invalidar JWTs antigos.
  - `active`: Permite desativação lógica (soft deactivation).
- **Isolamento**: Email é único por tenant.

### 5. `refresh_token`
Tokens de renovação de sessão.
- **Segurança**: Armazena apenas o hash SHA-256 do token.
- **Rotação**: Registro antigo é deletado e um novo é criado a cada renovação.

---

## Índices e Constraints
- **Unicidade**: Slug na `permission`, (tenant_id, name) na `role`, (tenant_id, email) no `app_user`.
- **FKs**: Relacionam usuários a tenants, filiais e perfis.
- **Índices**: Otimizam buscas por email, tenant, filial e expiração de tokens.
