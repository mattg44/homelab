# Stage 1: Build
FROM python:3.11-slim AS builder

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/

WORKDIR /app

# Copy only the files needed to install dependencies
COPY pyproject.toml uv.lock ./

# Generate a standard requirements.txt file and install it into a folder
RUN uv export --format requirements-txt > requirements.txt
RUN pip install --target=/install --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.11-slim
WORKDIR /app

# Copy the libraries from builder to the system's python path
COPY --from=builder /install /usr/local/lib/python3.11/site-packages
# Copy your app code
COPY app.py .

EXPOSE 80

CMD ["python", "app.py"]