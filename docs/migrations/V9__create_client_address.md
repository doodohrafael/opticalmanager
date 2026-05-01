# Migration V9 — Create Client Address

## Visão Geral
Esta migration introduz a gestão de múltiplos endereços por cliente, permitindo entregas em domicílio e maior flexibilidade no cadastro.

- **Módulo**: `clients` (Fase 2)
- **Tabelas**: `client_address`
- **Objetivo**: Armazenar endereços de entrega (casa, trabalho, etc.) de forma estruturada e independente da entidade principal do cliente.

---

## Convenções Adotadas
- **Identidade Própria**: Diferente das filiais (onde o endereço é embutido), o endereço do cliente possui identidade própria (`UUID`) pois um cliente pode possuir múltiplos locais de entrega.
- **Persistência Histórica**: Vendas utilizam este endereço como base, mas copiam os dados para campos de snapshot na própria tabela de vendas. Isso garante que, se um endereço for excluído ou alterado, o registro da venda passada permaneça íntegro.
- **Desativação Lógica**: Endereços utilizam a flag `active` para exclusão lógica, preservando a integridade referencial histórica.

---

## Tabelas Criadas

### 1. `client_address`
Catálogo de endereços dos clientes.
- **Campos Principais**:
  - `label`: Identificador amigável (ex: "Casa", "Trabalho", "Apartamento Praia").
  - `is_default`: Indica o endereço principal para sugestão automática em novas vendas.
  - Campos de localização padrão (CEP, Logradouro, Número, etc.).
  - `reference`: Ponto de referência para facilitar a logística de entrega.

---

## Índices e Constraints
- **Checks**:
  - Garantia de que a UF (`state`) possua sempre 2 caracteres.
- **Índices**: 
  - Otimizados para buscas por tenant e cliente.
  - Índice parcial para localizar rapidamente o endereço padrão ativo do cliente.
