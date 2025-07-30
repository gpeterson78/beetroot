# Traefik Core (Beetroot Ingress)

This is the core Traefik configuration for the Beetroot platform. It serves as the ingress layer for all services.

## Features

- Exposes HTTP (80) and HTTPS (443)
- Automatically redirects HTTP to HTTPS
- Uses Docker provider with label-based routing
- Does not expose services by default
- Creates shared `beetroot` network for cross-service connectivity

## Usage

```bash
docker compose up -d
