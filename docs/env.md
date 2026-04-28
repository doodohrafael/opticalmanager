# .env — Documentação de Variáveis de Ambiente

> Arquivo de configuração de ambiente local. Contém segredos e configurações sensíveis **não versionados**.
> Nunca faça commit do `.env` real — o arquivo está no `.gitignore`.

---

> [!CAUTION]
> O `.env` contém chaves de API, tokens e segredos. **Jamais exponha este arquivo publicamente ou versione no Git.**
> Use um gerenciador de segredos (ex: Railway Variables, Google Secret Manager) em produção.

---

## Grupos de Variáveis

### Google Cloud / Vertex AI

| Variável     | Descrição                                                             | Obrigatória |
|--------------|-----------------------------------------------------------------------|-------------|
| `PROJECT_ID` | ID do projeto no Google Cloud usado pela API do Vertex AI (Gemini)   | Sim         |

> Obtenha em: https://console.cloud.google.com → selecione o projeto → copie o **Project ID**.

---

### JWT (Autenticação)

| Variável                            | Descrição                                                        | Valor de Desenvolvimento | Obrigatória |
|-------------------------------------|------------------------------------------------------------------|--------------------------|-------------|
| `JWT_SECRET`                        | Chave secreta HMAC-SHA256 para assinar e verificar os tokens JWT | String hex 256-bit       | Sim         |
| `JWT_ACCESS_TOKEN_EXPIRATION_HOURS` | Duração do access token em horas                                 | `1`                      | Sim         |
| `JWT_REFRESH_TOKEN_EXPIRATION_DAYS` | Duração do refresh token em dias                                 | `7`                      | Sim         |

> [!IMPORTANT]
> O `JWT_SECRET` nunca deve ser hardcoded no código. Leia a regra em [`docs/security.md`](technical-rules.md).
> Para gerar uma nova chave segura: `openssl rand -hex 32`

---

### Mercado Pago (Pagamentos / PIX)

| Variável                  | Descrição                                                                | Obrigatória |
|---------------------------|--------------------------------------------------------------------------|-------------|
| `MERCADOPAGO_ACCESS_TOKEN` | Token de acesso à API do Mercado Pago — PIX QR Code e assinaturas SaaS | Sim         |

> Obtenha em: https://www.mercadopago.com.br/developers → Credenciais.
> Use o token de **produção** apenas em ambiente `prd`.

---

### Resend (Email Transacional)

| Variável        | Descrição                                     | Obrigatória |
|-----------------|-----------------------------------------------|-------------|
| `RESEND_API_KEY` | Chave de API do Resend para envio de emails  | Sim         |

> Usado para alertas de receita vencendo e emails de onboarding do tenant.
> Plano gratuito: até 3.000 emails/mês.
> Obtenha em: https://resend.com/api-keys

---

### Cloudflare R2 (Storage de Fotos)

| Variável                   | Descrição                                              | Obrigatória |
|----------------------------|--------------------------------------------------------|-------------|
| `CLOUDFLARE_TOKEN`         | Token de API do Cloudflare (permissão Workers R2)      | Sim         |
| `CLOUDFLARE_R2_ACCOUNT_ID` | ID da conta Cloudflare                                 | Sim         |
| `CLOUDFLARE_R2_ACCESS_KEY` | Access Key do bucket R2 (equivalente à AWS Access Key) | Sim         |
| `CLOUDFLARE_R2_SECRET_KEY` | Secret Key do bucket R2 (equivalente à AWS Secret Key) | Sim         |
| `CLOUDFLARE_R2_BUCKET`     | Nome do bucket R2 onde as fotos de receita são salvas  | Sim         |

> O R2 é compatível com a API S3 da AWS — por isso o projeto usa o AWS SDK v2.
> Plano gratuito: até 10GB de armazenamento.
> Obtenha em: https://dash.cloudflare.com → R2 Object Storage.

---

## Template `.env` para Novo Ambiente

```dotenv
# Google Cloud / Vertex AI
PROJECT_ID=seu-project-id

# JWT
JWT_SECRET=                          # openssl rand -hex 32
JWT_ACCESS_TOKEN_EXPIRATION_HOURS=1
JWT_REFRESH_TOKEN_EXPIRATION_DAYS=7

# Mercado Pago
MERCADOPAGO_ACCESS_TOKEN=

# Resend
RESEND_API_KEY=

# Cloudflare R2
CLOUDFLARE_TOKEN=
CLOUDFLARE_R2_ACCOUNT_ID=
CLOUDFLARE_R2_ACCESS_KEY=
CLOUDFLARE_R2_SECRET_KEY=
CLOUDFLARE_R2_BUCKET=

# Banco de Dados
DB_HOST=containerdbname:5432
DB_NAME=opticalmanager
DB_USERNAME=user
DB_PASSWORD=password
```

---

## Variáveis de Banco de Dados

As variáveis de banco de dados devem ser definidas no `.env` para apontar ao container de banco de dados local:

| Variável        | Valor Local       | Obrigatória em produção |
|-----------------|-------------------|-------------------------|
| `DB_HOST`       | `localhost:5432`  | Sim                     |
| `DB_NAME`       | `opticalmanager`  | Sim                     |
| `DB_USERNAME`   | `user`            | Sim                     |
| `DB_PASSWORD`   | `password`        | Sim                     |

> Em produção (Railway), configure essas variáveis diretamente no painel do serviço.

---

## Ambientes

| Ambiente | Onde configurar               | Perfil Spring ativo          |
|----------|-------------------------------|------------------------------|
| Local    | `.env` na raiz do projeto     | `dev`                        |
| Produção | Railway Variables / GCloud    | `prd`                        |

> O perfil é controlado pela variável `SPRING_PROFILES_ACTIVE` no `docker-compose.yml`.
