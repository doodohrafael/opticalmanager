# Padrões de Desenvolvimento e Stack Tecnológica — Optical Manager

## Stack Tecnológica
| Camada | Tecnologia | Versão |
|---|---|---|
| Linguagem | Java 25 |
| Framework | Spring Boot 3.x |
| Segurança | Spring Security + JWT (JJWT) |
| ORM | Spring Data JPA + Hibernate |
| Banco | PostgreSQL 17+ |
| Migrations | Flyway |
| AI | Spring AI + Gemini Flash 2.5 |
| Testes | JUnit 5 + Mockito + Testcontainers |
| Documentação API | SpringDoc OpenAPI (Swagger em interface separada) |
| Build | Maven |
| Deploy | Railway |
| Storage fotos | Cloudflare R2 |
| Email transacional | Resend (grátis até 3k/mês) |
| Pagamento assinatura SaaS | Mercado Pago (recorrência) |
| Camada | Tecnologia | Versão |
|---|---|---|
| Linguagem | Java 25 | |
| Framework | Spring Boot | 4.0.5 |
| Spring AI | Spring AI | 1.0.5 estável |
| SpringDoc | OpenAPI | 2.8.6 |

---

## Idioma do Código
- **Inglês**: Estrutura técnica, métodos, variáveis, classes, pacotes, banco de dados (ex: `ServiceOrderRepository`, `findClientById`).
- **Português**: Mensagens de erro para o usuário final, comentários de regras de negócio complexas, ADRs.

---

## Estrutura de Pacotes (Por Módulo)
Seguimos uma estrutura orientada a domínios dentro de `br.com.rebootsystems.opticalmanager`:
```
modulo/
  ├── domain/         # Entidades, Value Objects, Repositories (Interfaces)
  ├── application/    # Use Cases (Commands), Events
  ├── infra/          # Repositories JPA, Adaptadores de Infra
  ├── api/            # Controllers e Filtros HTTP
  │   ├── spec/       # Interfaces Swagger (separadas do código)
  │   └── dto/        # Request e Response DTOs
  └── README.md       # Documentação específica do módulo
```

---

## Padrões de Implementação

### 1. Injeção de Dependência
- **Sempre** utilize injeção via construtor com campos `private final`.
- **NUNCA** utilize `@Autowired` em campos.

### 2. Use Cases
- Um Use Case por ação de negócio.
- Recebe um `Command` (entrada), executa a lógica e retorna o resultado.
- **NUNCA** deve conhecer detalhes de HTTP ou frameworks.

### 3. Controllers
- Devem apenas delegar para o Use Case.
- Implementam obrigatoriamente a interface correspondente em `api/spec/`.
- Usam `@RequirePermissao("recurso:acao")` para segurança.

### 4. Value Objects (Records)
- Usar `record` para imutabilidade.
- Validação obrigatória no construtor canônico.

### 5. Swagger em interface separada
- A documentação OpenAPI fica em interfaces no pacote `spec`, mantendo o Controller limpo apenas com a lógica de delegação.

---

## Testes e Qualidade (TDD)
Seguimos a pirâmide de testes:
- **70% Unitários**: JUnit 5 + Mockito.
- **20% Integração**: Testcontainers (PostgreSQL, R2).
- **10% API**: MockMvc.

**Nomenclatura**: `should_{behavior}_when_{condition}`
Ex: `should_reserve_stock_when_service_order_is_opened()`

---

## Tratamento de Erros
Hierarquia baseada em `OticaException`:
- `BusinessRuleException` (422)
- `ResourceNotFoundException` (404)
- `PermissionDeniedException` (403)
- `PlanLimitException` (402)
- `InvalidStatusTransitionException` (422)
- `InsufficientStockException` (422)
- `TenantInactiveException` (402)
- `InvalidTokenException` (401)
- `SecurityViolationException` (403)

**Padrão de Resposta de Erro (JSON):**

  "error": "Unprocessable Entity",
  "message": "Invalid transition: DELIVERED -> IN_PRODUCTION",
  "userMessage": "Não é possível alterar o status de Entregue para Em Produção.",
  "path": "/api/service-orders/123/status",
  "details": []
}
```

---

## Níveis de Documentação
1. **ADR** (`docs/adr/`): Decisões arquiteturais importantes.
2. **Convenções** (`docs/conventions.md`): Padrões de codificação e estilo.
3. **README por Módulo**: Responsabilidades e regras específicas.
4. **Swagger**: `/swagger-ui.html` gerado a partir das interfaces em `api/spec/`.
5. **Javadoc**: Apenas em comportamentos críticos ou não óbvios.
