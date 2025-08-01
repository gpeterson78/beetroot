# Beetroot Service Import

This folder allows you to import Docker Compose projects into Beetroot. Simply place your Compose YAML file or a folder here and run:

```bash
./mose.sh import
```

The script will move and register the project inside Beetroot's managed environment (`docker/`).

---

## What You Can Import

### Option 1: Single Compose File

A file named like `myservice.yaml`

```bash
shared/import/myservice.yaml  ➔  docker/myservice/docker-compose.yaml
```

### Option 2: Full Project Directory

A folder named `myservice/` containing a valid `docker-compose.yaml` and any supporting files/directories.

```bash
shared/import/myservice/  ➔  docker/myservice/
```

---

## Compose File Requirements

### 1. External Network

Beetroot expects services to use the shared `beetroot` Docker network. Your `docker-compose.yaml` should include:

```yaml
networks:
  default:
    name: beetroot
    external: true
```

This allows Traefik and other Beetroot core services to connect to your containers.

### 2. (Optional) Traefik Routing

If you want your service to be accessible via HTTPS and DNS, add labels like:

```yaml
services:
  myapp:
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.local`)
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.services.myapp.loadbalancer.server.port=80"
```

Traefik is optional but encouraged for externally accessible apps.

---

## Resources

* [Compose file reference (v3)](https://docs.docker.com/compose/compose-file/compose-versioning/)
* [Networking in Compose](https://docs.docker.com/compose/networking/)
* [Installing Docker Compose](https://docs.docker.com/compose/install/)

---

## After Importing

Use `mose.sh` to manage your new service:

```bash
./mose.sh up --project myservice
```

Once imported, the service is fully managed by the Beetroot platform.

---

Happy homelabbing! 
