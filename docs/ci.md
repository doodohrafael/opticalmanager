# Configuração de CI/CD — Optical Manager

Este documento descreve a configuração do pipeline de Integração Contínua e Entrega Contínua (CI/CD) para o projeto Optical Manager. O objetivo é automatizar os processos de build, teste e deploy.

Atualmente, estamos utilizando o GitHub Actions para este pipeline. O arquivo de configuração principal é `.github/workflows/ci.yml`.

## 1. Arquivo de Configuração: `.github/workflows/ci.yml`

```yaml
# Nome do workflow
name: Optical Manager CI/CD

# Gatilhos: Executa em push para a branch 'main' ou em pull requests para 'main'
on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

# Jobs (tarefas) a serem executadas
jobs:
  build-and-test:
    name: Build and Test
    runs-on: ubuntu-latest # Ambiente de execução

    steps:
      # 1. Checkout do código fonte
      - name: Checkout code
        uses: actions/checkout@v4

      # 2. Configurar ambiente Java
      - name: Set up JDK 21
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '21'
          cache: 'maven' # Habilita cache do Maven para acelerar downloads

      # 3. Construir e testar o projeto com Maven
      - name: Build and Test with Maven
        run: ./mvnw clean install
        env:
          # Variáveis de ambiente necessárias para testes, se houver
          # Exemplo: DATABASE_URL: ${{ secrets.DATABASE_URL }}
          # Exemplo: JWT_SECRET: ${{ secrets.JWT_SECRET }}
          # Para testes que precisam de um banco de dados real, pode ser necessário configurar Testcontainers ou um serviço de banco de dados no GitHub Actions

  build-docker-image:
    name: Build Docker Image
    runs-on: ubuntu-latest
    needs: build-and-test # Depende do job anterior ter sucesso
    if: github.ref == 'refs/heads/main' # Executa apenas para a branch main

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      # 4. Montar imagem Docker
      # Assume que o Dockerfile está na raiz do projeto.
      # Se houver um Dockerfile específico, ajuste o caminho.
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Login to Docker Hub (ou outro registry, se necessário)
        uses: docker/login-action@v3
        with:
          # Usar secrets para credenciais de registry
          # Exemplo: username: ${{ secrets.DOCKERHUB_USERNAME }}
          # password: ${{ secrets.DOCKERHUB_TOKEN }}
          # Para Railway, o deploy geralmente não requer push para um registry público/privado antes,
          # pois Railway pode construir a imagem diretamente do código fonte ou de um Dockerfile.
          # Este passo pode ser removido ou adaptado dependendo do método de deploy do Railway.
          registry: ghcr.io # Exemplo para GitHub Container Registry
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: . # Diretório onde está o Dockerfile
          push: true # Envia a imagem para o registry
          tags: |
            ghcr.io/${{ github.repository_owner }}/optical-manager:${{ github.sha }}
            ghcr.io/${{ github.repository_owner }}/optical-manager:latest
          # Se o deploy for via Railway e ele não puxa de um registry, este passo pode ser adaptado
          # para apenas construir a imagem localmente se necessário para algum teste.

  deploy-to-railway:
    name: Deploy to Railway
    runs-on: ubuntu-latest
    needs: build-docker-image # Depende da construção da imagem Docker (ou do build principal se Railway constrói direto)
    if: github.ref == 'refs/heads/main' # Executa apenas em push para a branch 'main'

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      # 5. Executar o deploy para Railway
      # O Railway CLI pode ser usado para deploy.
      # É necessário ter o Railway CLI instalado e o token de acesso configurado como secret.
      - name: Set up Railway CLI
        run: |
          curl -fsSL https://railway.app/install.sh | sh
          echo "${{ secrets.RAILWAY_TOKEN }}" > ~/.railway-token # Salva o token em um arquivo temporário
          # ou use a variável de ambiente diretamente se o CLI suportar:
          # export RAILWAY_TOKEN="${{ secrets.RAILWAY_TOKEN }}"

      - name: Deploy to Railway
        run: |
          # Assumindo que o 'railway up' pode ser executado diretamente.
          # Pode ser necessário especificar o serviço e o projeto do Railway.
          # Ex: railway up --service <service-id> --project <project-id>
          # A documentação do Railway CLI deve ser consultada para os comandos exatos.
          # Este exemplo é genérico.
          railway up --service optical-manager-service # Substitua pelo ID real do seu serviço Railway
        env:
          RAILWAY_TOKEN: ${{ secrets.RAILWAY_TOKEN }}
          # Outras variáveis de ambiente necessárias para o deploy ou para a aplicação em tempo de execução
          # Ex: NODE_ENV: production
          # Ex: DATABASE_URL: ${{ secrets.DATABASE_URL }}

## 2. Explicação dos Componentes

### Gatilhos (`on:`)
- `push:`: O workflow é acionado quando há um `push` para a branch `main`.
- `pull_request:`: O workflow é acionado quando um `pull request` é aberto ou atualizado para a branch `main`.

### Jobs (`jobs:`)

#### `build-and-test`
- **Propósito**: Compilar o código-fonte e executar todos os testes unitários e de integração.
- **Ambiente**: `ubuntu-latest` com Java 21 e cache Maven.
- **Comando**: `./mvnw clean install`. Este comando compila o projeto, executa os testes e gera os artefatos necessários.
- **Variáveis de Ambiente**: Espaço reservado para secrets (como URLs de banco de dados, chaves JWT) que podem ser necessários para a execução dos testes.

#### `build-docker-image`
- **Propósito**: Construir a imagem Docker da aplicação.
- **Dependência**: Executa após `build-and-test` ter sucesso (`needs: build-and-test`).
- **Condição**: Executa apenas em pushes para a branch `main` (`if: github.ref == 'refs/heads/main'`).
- **Passos**:
    - `setup-buildx-action`: Configura o ambiente para construir imagens Docker de forma eficiente.
    - `login-action`: Autentica em um registry de containers (ex: GHCR, Docker Hub). **Nota**: Para Railway, este passo pode ser omitido ou adaptado, pois o Railway pode construir a imagem diretamente do Dockerfile no repositório.
    - `build-push-action`: Constrói a imagem Docker usando o `Dockerfile` na raiz do projeto e a envia para o registry com tags `latest` e o commit SHA.

#### `deploy-to-railway`
- **Propósito**: Realizar o deploy da aplicação para a plataforma Railway.
- **Dependência**: Executa após `build-docker-image` ter sucesso (`needs: build-docker-image`).
- **Condição**: Executa apenas em pushes para a branch `main` (`if: github.ref == 'refs/heads/main'`).
- **Passos**:
    - `Set up Railway CLI`: Instala o CLI do Railway e configura o token de acesso (obtido via `secrets.RAILWAY_TOKEN`).
    - `Deploy to Railway`: Executa o comando `railway up` para iniciar o deploy. O comando exato pode precisar ser ajustado com base no ID do serviço e projeto no Railway.

## 3. Variáveis de Ambiente e Secrets
- **`secrets.RAILWAY_TOKEN`**: Essencial para autenticar com a plataforma Railway e realizar o deploy. Deve ser configurado nas settings do GitHub Actions.
- **Secrets para Testes**: Se os testes precisarem de credenciais de banco de dados, chaves de API, etc., eles devem ser configurados como secrets no GitHub e referenciados no job `build-and-test`.

## 4. Customização
- **Branches**: Modifique a seção `on:` para incluir outras branches de deploy ou para desativar deploys automáticos.
- **Comandos de Build/Teste**: Adapte o comando `./mvnw clean install` se precisar de flags específicas ou passos adicionais.
- **Docker**: Ajuste o `Dockerfile` e os passos de build/push da imagem se a estrutura do projeto ou o registry mudar.
- **Deploy**: O comando `railway up` é um exemplo. Consulte a documentação do Railway CLI para opções avançadas de deploy, como especificar serviços e ambientes.
- **Serviços Externos**: Se a aplicação depender de outros serviços (ex: um banco de dados externo, cache), configure-os como variáveis de ambiente ou secrets.

---
## Documentação Adicional
- **GitHub Actions**: [https://docs.github.com/en/actions](https://docs.github.com/en/actions)
- **Railway CLI**: [https://railway.app/docs/cli](https://railway.app/docs/cli)
- **Maven**: [https://maven.apache.org/](https://maven.apache.org/)
