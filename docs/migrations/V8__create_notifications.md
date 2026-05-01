# Migration V8 — Create Notifications

## Visão Geral
Esta migration estabelece a estrutura para auditoria e log de todas as comunicações enviadas aos clientes e lojistas.

- **Módulo**: `notifications`
- **Tabelas**: `notification_log`
- **Objetivo**: Rastrear o envio de alertas automáticos e evitar disparos duplicados para o mesmo evento.

---

## Convenções Adotadas
- **Log de Auditoria**: Cada tentativa de envio (seja via e-mail, WhatsApp ou SMS) é registrada com seu status final.
- **Prevenção de Duplicidade**: Índices únicos parciais garantem que notificações recorrentes (como expiração de receita) não sejam enviadas mais de uma vez por dia para o mesmo registro.
- **Vínculos Contextuais**: Notificações guardam referências para o documento que as originou (OS, Receita, etc.), facilitando a rastreabilidade.

---

## Tabelas Criadas

### 1. `notification_log`
Registro central de todas as comunicações.
- **Tipos de Notificação**:
  - `PRESCRIPTION_EXPIRY`: Alerta de receita vencendo.
  - `OS_READY`: Aviso de que o óculos está pronto para retirada.
  - `TRIAL_EXPIRING` / `TRIAL_EXPIRED`: Alertas de expiração do SaaS (para o lojista).
  - `SALE_CONFIRMED`: Confirmação de venda realizada.
- **Canais**: `EMAIL` (padrão), `WHATSAPP`, `SMS`.
- **Estados**: `SENT` (Enviado com sucesso), `FAILED` (Erro no provedor), `SKIPPED` (Ignorado por política de duplicidade).

---

## Índices e Constraints
- **Unicidade Anti-Spam**: `idx_notification_log_no_duplicate` impede que o mesmo tipo de alerta para a mesma receita seja enviado no mesmo dia.
- **Checks**:
  - Valida que notificações de expiração possuam o vínculo com `prescription_id`.
  - Valida que avisos de "Pronto" possuam o vínculo com `service_order_id`.
- **Índices**: 
  - Otimizados para buscas por tenant, cliente e data de envio.
  - Índice parcial para busca rápida por notificações vinculadas a receitas.
