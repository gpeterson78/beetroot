# Hooks for beetup.sh

Scripts in this directory run after each `beetup.sh` update cycle.

- Must be executable and have `.sh` extension
- Run in alphabetical order
- Abort the update if any hook fails (due to `set -euo pipefail`)