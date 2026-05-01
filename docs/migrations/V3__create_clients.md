# Migration V3 — Create Clients

## Visão Geral
Esta migration define a estrutura para gestão de clientes, seus contatos e receitas oftalmológicas (óculos e lentes de contato).

- **Módulo**: `clients`
- **Tabelas**: `client`, `contact`, `prescription`, `prescription_grade`
- **Objetivo**: Armazenar o histórico clínico e de contato dos clientes das óticas.

---

## Convenções Adotadas
- **Contatos Polimórficos**: A tabela `contact` atende tanto clientes quanto fornecedores (`owner_type`).
- **Prescription Grades**: Armazenadas como registros separados para Olho Direito (OD) e Olho Esquerdo (OE).
- **Validação de Receita**: Regras estritas para eixos (0-180), adição e distância pupilar (DP).
- **Origem da Receita**: Rastreia se a receita veio de um médico, do próprio óptico ou foi informada pelo cliente.

---

## Tabelas Criadas

### 1. `client`
Dados cadastrais básicos dos clientes finais.
- **Campos Principais**:
  - `cpf`: Opcional.
  - `birth_date`: Data de nascimento.
  - `notes`: Observações internas da ótica.

### 2. `contact`
Central de contatos (telefone, email, whatsapp).
- **Polimorfismo**: Usa `owner_type` e `owner_id` para identificar o dono do contato.
- **Flag `principal`**: Indica o contato preferencial para notificações automáticas.

### 3. `prescription`
Cabeçalho da receita oftalmológica.
- **Campos Principais**:
  - `type`: Óculos ou Lentes de Contato.
  - `origin`: Origem da informação (Médico, Óptico ou Cliente).
  - `photo_url`: Link da foto da receita original (processada via IA).
- **Regra**: Receitas "Informadas pelo Cliente" exigem preenchimento obrigatório de observações.

### 4. `prescription_grade`
Graus detalhados da receita.
- **Estrutura**: Sempre 2 registros por receita (`eye` OD/OE).
- **Campos Técnicos**:
  - `spherical`: Esférico.
  - `cylindrical`: Cilíndrico.
  - `axis`: Eixo (0-180).
  - `addition`: Adição (presbiopia).
  - `dp`: Distância Pupilar.

---

## Índices e Constraints
- **Unicidade**: Olho (OD/OE) por receita na `prescription_grade`.
- **Checks**:
  - `chk_contact_owner_type`: CLIENT, SUPPLIER.
  - `chk_prescription_type`: GLASSES, CONTACT_LENS.
  - `chk_prescription_grade_axis`: 0 a 180.
- **Índices**: Buscas otimizadas por nome de cliente, CPF, tenant e expiração de receitas.
