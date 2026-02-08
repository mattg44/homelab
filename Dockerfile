# --- Stage 1: Build Stage ---
FROM python:3.11-slim AS builder

# Install uv from the official binaries
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

# Set the working directory
WORKDIR /app

# 1. Optimization: Prevent uv from creating a virtualenv in a random spot
ENV UV_PROJECT_ENVIRONMENT=/app/.venv
# 2. Optimization: Pre-compile Python bytecode for faster startup
ENV UV_COMPILE_BYTECODE=1
# 3. Requirement: Use copy instead of symlinks so the venv is portable to Stage 2
ENV UV_LINK_MODE=copy

# Install dependencies using Docker BuildKit cache mounts
# This makes subsequent builds lightning fast by caching the uv registry
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev

# --- Stage 2: Runtime Stage ---
FROM python:3.11-slim

# Install curl for the Healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the virtual environment from the builder stage
COPY --from=builder /app/.venv /app/.venv
# Copy your application code
COPY app.py .

# Put the virtual environment's bin folder at the front of the PATH
# This ensures 'python' and any installed CLI tools work automatically
ENV PATH="/app/.venv/bin:$PATH"

# Expose the port your app runs on
EXPOSE 8080

# DevOps Best Practice: Healthcheck
# This tells Docker/Portainer if your app is actually responding to requests
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# Run the application
ENTRYPOINT ["/app/.venv/bin/python"]
CMD ["app.py"]