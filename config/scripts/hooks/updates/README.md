# Beetroot Update Hooks

This directory contains optional shell scripts that are executed during the `beetsync.sh` process.

## Purpose

Update hooks are used for tasks that need to be performed **outside of Docker**, such as:

- Updating system services
- Rebuilding local indexes
- Syncing content or assets
- Managing user-installed utilities

These allow you to extend the sync process without modifying the core platform logic.

## Hook Structure

Each hook must be:

- A `.sh` file
- Executable (`chmod +x`)
- Located in this directory

They will be executed in **lexical order** by filename.

## Example

`sample.sh`:
```bash
#!/bin/bash
# Example update hook for Beetroot platform

echo "[hook] Running sample update hook"
# Add custom update logic here
