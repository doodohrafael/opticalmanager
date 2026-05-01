# Padrões de Testes — Optical Manager

## Filosofia: TDD (Test Driven Development)
O desenvolvimento é guiado por testes. O código só é escrito para fazer um teste passar.
1. **Red**: Escreve o teste que falha.
2. **Green**: Escreve o mínimo de código para passar.
3. **Blue**: Refatora mantendo o comportamento verde.

## Pirâmide de Testes

### 1. Testes Unitários (70%)
- **Escopo**: Camada de `Domain` e `Application`.
- **Regra**: Sem Spring, sem Banco. Usar `Mockito` para mocks.
- **Velocidade**: Devem ser instantâneos.

### 2. Testes de Integração (20%)
- **Escopo**: Repositories e fluxos complexos de Use Case com banco.
- **Ferramenta**: `Testcontainers` com PostgreSQL real.
- **Validam**: Migrations, constraints de banco, queries JPA.

### 3. Testes de API (10%)
- **Escopo**: Controllers e Segurança.
- **Ferramenta**: `MockMvc`.
- **Validam**: Contratos JSON, Auth/RBAC, Status HTTP.

---

## O que TESTAR OBRIGATORIAMENTE

- **Isolamento de Tenant**: Garantir que o Tenant A nunca acesse ou altere dados do Tenant B.
- **Máquina de Estados**: Todas as transições válidas e inválidas de OS e Venda.
- **Estoque**: Reserva ao abrir OS, baixa ao entregar, liberação ao cancelar.
- **Financeiro**: Cálculo de totais, descontos e imutabilidade de caixa fechado.
- **Domínio**: Validações de Value Objects (ex: eixo da receita 0–180).
- **Planos**: Limites de uso da AI e bloqueio após expiração do trial.

---

## Nomenclatura e Estilo
Usamos o padrão `should_{behavior}_when_{condition}`:

```java
@Test
void should_throw_exception_when_axis_is_out_of_range() { ... }

@Test
void should_reserve_stock_when_service_order_is_opened() { ... }

@Test
void should_return_403_when_user_has_no_permission() { ... }
```
