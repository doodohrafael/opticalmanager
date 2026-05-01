# Convenções e Definições de Desenvolvimento — Optical Manager

Este documento detalha as convenções de codificação e padrões técnicos que devem ser seguidos por todos os desenvolvedores e IAs que atuam no projeto.

---

## 1. Importações
- **Sem Importações Coringa**: Não utilize o asterisco (`*`) em importações. Cada classe deve ser importada individualmente para evitar conflitos de nomes e facilitar a leitura das dependências.
  - **Certo**: `import java.util.List;`
  - **Errado**: `import java.util.*;`

## 2. Nomenclatura e Estilo
- **Classes e Interfaces**: `PascalCase` (ex: `ServiceOrderService`).
- **Métodos e Variáveis**: `camelCase` (ex: `calculateTotalValue`).
- **Constantes**: `SCREAMING_SNAKE_CASE` (ex: `MAX_RETRIES`).
- **Pacotes**: Minúsculos, sem sublinhados (ex: `br.com.rebootsystems.opticalmanager.shared`).

### 3. Imutabilidade e Records
- **Records**: Use `record` sempre que possível para DTOs e Value Objects.
- **Final**: Use a palavra-chave `final` para variáveis locais e campos de classe que não devem ser reatribuídos após a inicialização.
- **Injeção de Dependência**: Prefira injeção via construtor com campos `private final`.

### 4. Consultas ao Banco
- **SQL Nativo**: Implementar **sempre** consultas nativas (`nativeQuery = true`) para aproveitar o máximo do PostgreSQL e garantir performance. Evitar JPQL ou Criteria API.


## 4. Tratamento de Exceções
- **Checked Exceptions**: Evite o uso de exceções verificadas (`Exception`). Prefira exceções não verificadas (`RuntimeException`).
- **Mensagens**: Utilize mensagens claras. Se a exceção for chegar ao usuário final, siga o padrão definido em `docs/development.md`.

## 5. Logs e Observabilidade
- **SLF4J**: Utilize a abstração SLF4J (geralmente via `@Slf4j` do Lombok ou Logger manual).
- **Níveis de Log**:
  - `INFO`: Ações significativas do sistema (ex: início de processamento).
  - `WARN`: Problemas que não impedem a execução mas exigem atenção.
  - `ERROR`: Falhas críticas que interrompem um fluxo.
  - `DEBUG`: Detalhes técnicos para auxílio em desenvolvimento.

## 6. Comentários e Documentação
- **Autoexplicativo**: O código deve ser escrito de forma que comentários sejam raramente necessários.
- **Por quê, não o quê**: Se um comentário for necessário, foque em explicar o *porquê* de uma decisão complexa, não o *o que* o código está fazendo.
