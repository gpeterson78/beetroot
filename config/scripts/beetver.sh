#!/bin/bash
# beetver.sh -- beetroot version tracking and update notifier

check_for_update() {
    HASH_FILE="$(dirname "$(dirname "$(dirname "$0")")")/config/.last_synced_commit"
    REPO="gpeterson78/beetroot"

    if command -v curl >/dev/null 2>&1; then
        CURRENT_HASH=""
        [ -f "$HASH_FILE" ] && CURRENT_HASH=$(cat "$HASH_FILE")

        LATEST_HASH=$(curl -s "https://api.github.com/repos/$REPO/commits/main" \
                      | grep '"sha"' | head -n 1 | cut -d '"' -f 4)

        if [ -n "$CURRENT_HASH" ] && [ "$CURRENT_HASH" != "$LATEST_HASH" ]; then
            echo -e "\033[1;32m[beetroot] Update available -- run './beetsync.sh' to apply it.\033[0m"
        fi
    fi
}