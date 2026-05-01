# Visão do Produto e Infraestrutura — Optical Manager

## Visão e Valor
**Posicionamento:**
> "O sistema que otimiza suas operações, aumenta suas vendas e melhora a experiência dos seus clientes."

**Público-alvo MVP:** Óticas de bairro sem sistema ou com sistema insuficiente.

**Pilares de Valor:**
- **Otimizar operações**: Leitura de receita por foto, OS automatizada, caixa automatizado, estoque com reserva.
- **Aumentar vendas**: Alerta de receita vencendo, venda domiciliar, histórico completo do cliente.
- **Melhorar experiência**: Comprovante PDF, status da OS, PIX QR Code, interface mobile-friendly (PWA).

**Diferenciais Estratégicos:**
- Leitura de receita por foto (AI) — elimina digitação e erro.
- Alerta automático de receita vencendo — retenção proativa de clientes.
- PIX com QR Code gerado na tela.
- Preço acessível — R$ 149/mês.

**Comparativo de Mercado:**
| Atributo | Optical Manager | Concorrentes Tradicionais |
|---|---|---|
| Preço | R$ 149/mês (sem fidelidade) | R$ 299-529/mês (com contrato) |
| IA | Nativa (leitura de receita) | Inexistente ou via terceiros caro |
| Interface | PWA Moderno Mobile-first | Sistemas desktop legados |
| Trial | 14 dias grátis (sem cartão) | Raro ou com burocracia |

---

## Planos e Período de Teste

### MVP — Plano Pro (Único)
| Feature | Pro |
|---|---|
| OS por mês | 200 |
| Usuários | 5 |
| Filiais | 1 |
| Relatórios avançados | ✅ |
| AI — leitura de receita | 50/mês |
| Alerta receita vencendo | ✅ |
| PIX QR Code | ✅ |
| Suporte | Email |
| Preço | R$ 149/mês |

### Regras do Trial:
- **14 dias grátis**: Sem necessidade de cartão no cadastro.
- **Onboarding**: Emails automáticos nos dias 12 (aviso), 13 (último dia) e 14 (expiração).
- **Bloqueio**: Acesso bloqueado após 14 dias sem assinatura, direcionando para tela de planos.
- **Preservação**: Dados preservados por 30 dias após a expiração. Se assinar nesse período, tudo é restaurado.

---

## Infraestrutura MVP
- **Backend/DB**: Railway (Java 25 + PostgreSQL 17). Custo est.: ~R$ 55/mês.
- **Storage**: Cloudflare R2 (Fotos de receitas). Grátis até 10GB.
- **Email**: Resend (Transacional). Grátis até 3k/mês.
- **Pagamentos**: Mercado Pago (Assinaturas e PIX). Taxa PIX: 0,99%.
- **Total Fixo Est.**: ~R$ 60/mês.

---

## Viabilidade Financeira (Break-even)
- **Custo fixo base**: R$ 60/mês (Servidores + Infra básica).
- **Custo AI (Claude/Gemini)**: Est. R$ 4/mês por cliente ativo (uso médio).
- **Ponto de Equilíbrio**: 2 clientes pagantes cobrem os custos fixos e variáveis iniciais.
- **Lembrete**: Plano Free -> Nunca. O modelo de baixo custo garante a sustentabilidade.

---

## Decisões de MVP (O que NÃO implementar agora)
| Feature | Decisão |
|---|---|
| NF-e | Fase 2 — Integração Focus NF-e API |
| WhatsApp Bot | Fase 2 |
| Plano Max | Fase 2 (Multifiliais + AI avançada) |
| Filiais múltiplas | Fase 2 |
| Integração maquineta | Fase 2 (Stone/PagSeguro) |
| Crediário próprio | Nunca (Risco financeiro alto) |
| Convênio | Nunca |
| Plano Free | Nunca |

---

## Visão de Longo Prazo
O Optical Manager é o "projeto piloto" de um ecossistema de SaaS verticais. A arquitetura modular e o boilerplate (Auth, Multi-tenancy, AI Integration, Payments) serão replicados para:
1. Petshop SaaS
2. Veterinário SaaS
3. Mercadinho SaaS
