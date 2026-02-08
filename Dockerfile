# --- Stage 1: Build ---
FROM python:3.11-slim AS builder
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Install dependencies into a specific folder (/install) 
# instead of a virtualenv to avoid path/symlink issues
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv pip install --target /install --frozen -r <(uv export --format requirements-txt)

# --- Stage 2: Runtime ---
FROM python:3.11-slim
WORKDIR /app

# Copy the installed libraries from the builder
COPY --from=builder /install /usr/local/lib/python3.11/site-packages
# Copy your app code
COPY app.py .

# Install curl for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

# Now the system python will see Flask in its site-packages
CMD ["python", "app.py"]