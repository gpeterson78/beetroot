# Beetroot API Reference Draft (v0.1)

> This API is internal-only and served by the local admin backend. It is not exposed via Traefik or routed to the hostname. All endpoints are accessible via machine IP on port `4200` (by default).

---
## System API (`/api/system/`)

|Endpoint|Method|Description|
|---|---|---|
|`/status`|`GET`|Returns basic system info (hostname, IP, uptime, version/hash info).|
|`/update`|`POST`|Triggers `beetsync` to pull latest repo version and apply changes.|
|`/shutdown`|`POST`|Shuts down the system or backend (optional safeguard flag).|
|`/restart`|`POST`|Restarts the backend or optionally the host.|

---

## Environment (`/api/env/`)

|Endpoint|Method|Description|
|---|---|---|
|`/list`|`GET`|Lists detected services under `docker/`, with .env and routing status.|
|`/generate`|`POST`|Runs `beetenv` for all or specified service(s).|
|`/validate`|`GET`|Validates .env files and Compose structures, returns warnings if missing pieces.|

---

## Compose & Orchestration (`/api/orch/`)

| Endpoint    | Method | Description                                          |
| ----------- | ------ | ---------------------------------------------------- |
| `/services` | `GET`  | Lists active services with status (via `docker ps`). |
| `/up`       | `POST` | Starts one or all services via `mose.sh up`.         |
| `/down`     | `POST` | Stops one or all services.                           |
| `/logs`     | `GET`  | Retrieves logs for a given service.                  |

---

## Git & Versioning (`/api/version/`)

| Endpoint | Method | Description                                                        |
| -------- | ------ | ------------------------------------------------------------------ |
| `/hash`  | `GET`  | Returns current local Git commit hash.                             |
| `/check` | `GET`  | Compares local vs remote hash and returns update availability.     |
| `/pull`  | `POST` | Manually triggers `git pull`. (Wrapper for `beetsync --no-check`.) |

---

## Configuration (`/api/config/`)

|Endpoint|Method|Description|
|---|---|---|
|`/get`|`GET`|Retrieves current configuration (hostname, ports, flags).|
|`/set`|`POST`|Updates the configuration file.|
|`/reset`|`POST`|Resets to default configuration.|

---

## DNS (future, via Pi-hole API)

|Endpoint|Method|Description|
|---|---|---|
|`/dns/list`|`GET`|Returns current custom DNS records.|
|`/dns/add`|`POST`|Adds a new record for service routing.|
|`/dns/remove`|`POST`|Deletes a DNS record.|
