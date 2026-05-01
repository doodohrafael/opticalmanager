# AI — Inteligência Artificial — Optical Manager

## Visão Geral
O Optical Manager utiliza IA (via **Spring AI**) para automatizar tarefas repetitivas e aumentar a precisão dos dados, focando em aumentar a conversão de vendas e reduzir erros humanos.

---

## 1. Leitura de Receita por Foto (MVP)
Esta é a funcionalidade central do MVP, utilizando visão computacional para extrair graus de receitas oftalmológicas.

- **Fluxo**:
  1. Usuário envia foto via Mobile/Web.
  2. Backend armazena a imagem no **Cloudflare R2**.
  3. Backend chama a API (Gemini/Claude) via Spring AI.
  4. IA retorna JSON estruturado.
  5. **Importante**: O vendedor **DEVE** validar os dados na tela antes de salvar.

### Prompt Padrão
```text
Analyze this eye prescription and extract the data.
Return ONLY valid JSON:
{ 
  "od": { "spherical", "cylindrical", "axis", "addition" },
  "oe": { "spherical", "cylindrical", "axis", "addition" },
  "dp": null 
}
Missing fields must be null.
Negative values are valid.
```

### Limites e Custos
- **Plano Pro**: Limite de 50 leituras por mês por tenant.
- **Log**: Todo uso é registrado para auditoria e controle de cobrança futura.

---

## 2. Alerta de Receita Vencendo
Um motor de regras simples que utiliza inteligência de negócio para reativar clientes.

- **Job**: `@Scheduled(cron = "0 0 8 * * *")` (Diário às 8h).
- **Lógica**: Busca receitas que vencem em exatos 30 dias.
- **Canal**: E-mail (via Resend) no MVP; WhatsApp na Fase 2.

---

## 3. Roadmap de IA (Fase 2+)
- **WhatsApp Bot**: Agendamento e dúvidas frequentes.
- **Previsão de Estoque**: IA para sugerir compras de armações baseada em tendências de venda.
- **CRM Inteligente**: Sugestão de produtos baseada no perfil e histórico do cliente.
