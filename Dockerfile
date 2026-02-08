# --- Stage 1: Build ---
FROM python:3.11-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# 1. Force uv to NOT use symlinks. This is the fix.
ENV UV_LINK_MODE=copy
ENV UV_COMPILE_BYTECODE=1

# Install dependencies
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# --- Stage 2: Runtime ---
FROM python:3.11-slim
WORKDIR /app

# 2. Copy the entire venv folder
COPY --from=builder /app/.venv /app/.venv
COPY app.py .

# 3. Instead of Entrypoint, let's use the PATH method 
# but point it explicitly to the venv
ENV VIRTUAL_ENV=/app/.venv
ENV PATH="/app/.venv/bin:$PATH"

# Install curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

# Use 'python' - since it's now first in PATH, it will find the venv one
CMD ["python", "app.py"]