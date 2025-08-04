# Beetroot supporting scripts go here
all work in progress and untested currently.

### `mose.sh` — Beetroot Service Orchestration Utility

`mose.sh` is the main orchestrator script for managing all Docker-based services within Beetroot. It wraps Docker Compose commands to simplify common operations across all or specific services, which reside in the `docker/` directory.

#### Supported Actions:

| Action    | Description                                                                                        |
| --------- | -------------------------------------------------------------------------------------------------- |
| `up`      | Starts the project containers (`docker-compose up -d`).                                            |
| `down`    | Stops and removes containers (`docker-compose down`).                                              |
| `restart` | Restarts running containers.                                                                       |
| `pull`    | Pulls the latest Docker images.                                                                    |
| `upgrade` | Pulls images and starts updated containers (`pull + up -d`).                                       |
| `ps`      | Shows the container status for each project (`docker-compose ps`).                                 |
| `import`  | Imports new projects from `shared/import` directory. Supports `.yaml` file or full folder drop-in. |

#### Flags:

| Flag        | Description                                                     |
| ----------- | --------------------------------------------------------------- |
| `--project` | Apply the action to only one specific project (by folder name). |
| `--json`    | Return output as machine-readable JSON.                         |
| `--pretty`  | Pretty-print JSON (used with `--json`). Requires `jq`.          |
| `--help`    | Show usage help.                                                |

#### Import Functionality:

* Drop a single file (`projectname.yaml`) or full folder (`projectname/`) into `shared/import/`.
* On `mose.sh import`, it will:

  * Validate structure (must contain `docker-compose.yaml`)
  * Move valid projects into `docker/projectname/`
  * Report skipped items or errors

> 💡 Traefik and other shared infrastructure should use the `beetroot` Docker network. `mose.sh` will automatically ensure the network exists when needed.

#### Example Usage:

```bash
./mose.sh up --project immich
./mose.sh down
./mose.sh ps --json --pretty
./mose.sh import
```