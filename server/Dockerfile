FROM python:3.11-slim

# Speed up builds and installs in slower networks
ENV PIP_NO_CACHE_DIR=1 \
    PIP_DEFAULT_TIMEOUT=600

# Optional build-time proxies and PyPI mirrors
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG PIP_INDEX_URL
ARG PIP_EXTRA_INDEX_URL

WORKDIR /app
COPY server/requirements.txt /app/requirements.txt

RUN pip install -r /app/requirements.txt

COPY server/app /app/app
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

