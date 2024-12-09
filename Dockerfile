# Etapa Base: Use Python Alpine para começar com uma imagem pequena
FROM python:3.13-alpine AS base

# Configuração do ambiente
ENV PYTHONFAULTHANDLER=1 \
    PYTHONHASHSEED=random \
    PYTHONUNBUFFERED=1

# Criar usuário não-root
RUN addgroup -g 1000 uvuser && \
    adduser -u 1000 -G uvuser -h /home/uvuser -D uvuser

# Diretório de trabalho
WORKDIR /app

# Etapa Builder: Instale UV e dependências
FROM base AS builder

# Instale dependências mínimas para compilação
RUN apk add --no-cache gcc musl-dev libffi-dev libstdc++ libffi curl

# Copiar o UV binário da imagem oficial
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Copiar apenas os arquivos necessários para dependências
COPY pyproject.toml uv.lock /app/

# Instalar dependências de produção
RUN uv sync --frozen

# Copiar o código da aplicação
COPY . /app

# Etapa Final: Criar imagem final leve
FROM base AS final

# Copiar apenas as dependências sincronizadas
COPY --from=builder /app /app

# Copiar o UV binário da imagem oficial
# COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Mudar para usuário não-root
USER uvuser

# Configurar PATH para UV e Python
ENV PATH="/app/.venv/bin:${PATH}" \
    VIRTUAL_ENV="/app/.venv"

# Comando para rodar o UV e iniciar a aplicação
CMD ["python", "./flaskteste/flaskteste.py"]