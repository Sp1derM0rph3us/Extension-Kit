#!/bin/bash
set -euo pipefail

if [ -z "${1:-}" ]; then
    echo "Usage: $0 <agent_name>"
    echo "Example: $0 NoNameAx"
    exit 1
fi

AGENT_NAME="$1"

# Every AxScript function that takes an agent type array
PATTERN='register_commands_group\|menu\.add_session_agent\|menu\.add_session_access\|menu\.add_filebrowser\|menu\.add_processbrowser\|event\.on_filebrowser_disks\|event\.on_filebrowser_list\|event\.on_processbrowser_list'

PATCHED=0
SKIPPED=0

find . -type f -name "*.axs" -print0 | sort -z | while IFS= read -r -d '' file; do
    # Skip files with no registration calls
    grep -q "$PATTERN" "$file" 2>/dev/null || continue

    # Check if any registration line is missing this agent
    if grep "$PATTERN" "$file" | grep -qv "\"$AGENT_NAME\""; then
        echo "[+] Patching: $file"
        # On registration lines where agent is absent:
        # the first "] on the line always closes the agent type array
        # (OS array and extras come after). Replace it to append the new agent.
        sed -i "/$PATTERN/{/\"$AGENT_NAME\"/!s/\"\]/\", \"$AGENT_NAME\"]/}" "$file"
    else
        echo "[=] Already patched: $file"
    fi
done

echo "--- Complete ---"
