# Segurança — Optical Manager

## Spring Security — JWT e RBAC

O sistema utiliza autenticação stateless baseada em JSON Web Tokens (JWT) e controle de acesso baseado em permissões (RBAC).

### 1. Payload do JWT
O token gerado após o login contém as informações necessárias para autorizar a requisição sem consultar o banco de dados:
```
sub          → userId (UUID)
tenantId     → UUID do tenant (ótica)
branchId     → UUID da filial (branch)
role         → Nome do papel principal (ex: VENDOR)
permissions  → Lista de slugs (ex: ["sales:create", "clients:view"])
tokenVersion → Versão do token para invalidação (default: 0)
exp          → Expiração (Access Token: 1 hora)
```

**Expiração e Rotação:**
- **Access Token**: 1 hora.
- **Refresh Token**: 7 dias, armazenado como SHA-256 no banco e rotacionado a cada uso.
- **Token Versioning**: Ao mudar permissões críticas, incrementa-se o `token_version` no banco. JWTs com versão divergente são rejeitados (401), forçando novo login.

### 2. Papéis Padrão (Roles)
Cada tenant nasce com papéis pré-configurados:

| Papel | Permissões | Descrição |
|---|---|---|
| **OWNER** | Todas | Acesso total, incluindo gestão de usuários e papéis. |
| **MANAGER** | Todas exceto `users:*` | Acesso operacional e financeiro total. |
| **VENDOR** | Vendas e Clientes | Sem acesso ao financeiro/caixa ou administração. |

### 3. Catálogo de Permissões (`resource:action`)

| Recurso | Ações Disponíveis |
|---|---|
| **Sales** | `create`, `view`, `cancel`, `discount` |
| **Clients** | `create`, `view`, `edit` |
| **Stock** | `view`, `edit`, `purchase-order` |
| **Cash** | `open`, `close`, `view` |
| **AI** | `read-prescription` |
| **Admin** | `users:manage`, `roles:configure`, `notifications:view` |
| **Reports** | `view` |
| **Labels** | `print` |

---

## Práticas de Implementação Segura

- **Segredos**: O `JWT_SECRET` é lido exclusivamente de variáveis de ambiente.
- **Isolamento**: O `tenantId` no token é a única fonte da verdade para o `TenantContext`.
- **Senhas**: Armazenadas com BCrypt (strength 12).
- **Swagger**: Para evitar poluição visual do código de negócio, as anotações do Swagger ficam em interfaces separadas na camada de API.

**Exemplo de Interface de API:**
```java
@Tag(name = "Service Orders")
public interface ServiceOrderApi {
    @Operation(summary = "Open service order")
    @ApiResponse(responseCode = "201", description = "OS created")
    ResponseEntity<ServiceOrderResponse> create(@RequestBody CreateServiceOrderRequest req);
}
```

**Exemplo de Controller Limpo:**
```java
@RestController
public class ServiceOrderController implements ServiceOrderApi {
    @Override
    @RequirePermissao("sales:create")
    public ResponseEntity<ServiceOrderResponse> create(CreateServiceOrderRequest req) {
        // Implementação...
    }
}
```
