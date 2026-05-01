# Segurança — Optical Manager

## Spring Security — JWT e RBAC

O sistema utiliza autenticação stateless baseada em JSON Web Tokens (JWT) e controle de acesso baseado em permissões (RBAC).

### 1. Payload do JWT
O token gerado após o login contém as informações necessárias para autorizar a requisição sem consultar o banco de dados:
```
sub         → userId (UUID)
tenantId    → UUID do tenant (ótica)
branchId    → UUID da filial (branch)
role        → Nome do papel principal (ex: VENDOR)
permissions → Lista de slugs (ex: ["sales:create", "clients:view"])
exp         → Expiração (Padrão: 8 horas)
```

### 2. Padrão de Permissão
As permissões seguem o formato `resource:action`:
- `sales:create`, `sales:cancel`, `sales:discount`
- `clients:create`, `clients:view`, `clients:edit`
- `stock:view`, `stock:edit`
- `cash:open`, `cash:close`
- `ai:read-prescription`

### 3. Papéis Padrão (Roles)
| Papel | Descrição do Acesso |
|---|---|
| **OWNER** | Acesso total ao sistema, incluindo gestão de usuários e configurações. |
| **MANAGER** | Acesso operacional e financeiro total, exceto gestão de usuários e papéis. |
| **VENDOR** | Acesso a vendas, clientes e ordens de serviço. Sem acesso ao financeiro/caixa. |

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
