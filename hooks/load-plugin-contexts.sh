#!/bin/bash
# Load Plugin Contexts
# This hook scans all installed plugins and outputs their CLAUDE.md contexts
# so agents have access to plugin-specific instructions.
#
# Add to SessionStart hook in .claude/settings.json:
#   "command": "~/.gt/hooks/load-plugin-contexts.sh"

set -euo pipefail

GT_ROOT="${GT_ROOT:-$HOME/gt}"
PLUGINS_DIR="$GT_ROOT/plugins"

# Check if plugins directory exists
if [[ ! -d "$PLUGINS_DIR" ]]; then
    exit 0
fi

# Find all plugin CLAUDE.md files
FOUND_PLUGINS=0
OUTPUT=""

for plugin_dir in "$PLUGINS_DIR"/*/; do
    if [[ -d "$plugin_dir" ]]; then
        plugin_name=$(basename "$plugin_dir")
        claude_md="$plugin_dir/CLAUDE.md"

        if [[ -f "$claude_md" ]]; then
            FOUND_PLUGINS=$((FOUND_PLUGINS + 1))
            CONTENT=$(cat "$claude_md")
            OUTPUT+="
---
## Plugin: $plugin_name

$CONTENT
"
        fi
    fi
done

# Only output if we found plugins with context
if [[ $FOUND_PLUGINS -gt 0 ]]; then
    echo "# Installed Plugin Contexts ($FOUND_PLUGINS plugins)"
    echo "$OUTPUT"
fi
