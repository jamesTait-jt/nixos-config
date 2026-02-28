#!/usr/bin/env bash
set -e

# UserPromptSubmit hook that reads recent edit history
# and injects context about what's been modified

# How far back to look (in seconds) - default 24 hours
LOOKBACK_SECONDS=${CLAUDE_EDIT_LOOKBACK:-86400}

# Cache directory
cache_base="$CLAUDE_PROJECT_DIR/.claude/edit-cache"

# Skip if no cache exists
if [[ ! -d "$cache_base" ]]; then
    exit 0
fi

# Current timestamp
now=$(date +%s)
cutoff=$((now - LOOKBACK_SECONDS))

# Collect recent edits from all session caches
recent_files=""
declare -A seen_files

for session_dir in "$cache_base"/*/; do
    log_file="${session_dir}edited-files.log"
    if [[ -f "$log_file" ]]; then
        while IFS='|' read -r timestamp abs_path rel_path extension git_root; do
            # Skip if too old
            if [[ "$timestamp" -lt "$cutoff" ]]; then
                continue
            fi
            # Skip if already seen
            if [[ -n "${seen_files[$rel_path]}" ]]; then
                continue
            fi
            seen_files[$rel_path]=1
            recent_files+="  - $rel_path ($extension)"$'\n'
        done < "$log_file"
    fi
done

# Only output if there are recent edits
if [[ -n "$recent_files" ]]; then
    echo "<session-context>"
    echo "Recently modified files in this project:"
    echo "$recent_files"
    echo "</session-context>"
fi

exit 0
