#!/usr/bin/env bash
set -e

# Post-tool-use hook that tracks edited files
# Fixed shebang for NixOS compatibility
# Language-agnostic: works with any project type

# Read tool information from stdin
tool_info=$(cat)

# Extract relevant data
tool_name=$(echo "$tool_info" | jq -r '.tool_name // empty')
file_path=$(echo "$tool_info" | jq -r '.tool_input.file_path // empty')
session_id=$(echo "$tool_info" | jq -r '.session_id // empty')

# Skip if no file path
if [[ -z "$file_path" ]]; then
    exit 0
fi

# Skip markdown files
if [[ "$file_path" =~ \.(md|markdown)$ ]]; then
    exit 0
fi

# Create cache directory
cache_dir="$CLAUDE_PROJECT_DIR/.claude/edit-cache/${session_id:-default}"
mkdir -p "$cache_dir"

# Find git root for the file (if any)
find_git_root() {
    local dir="$1"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.git" ]]; then
            echo "$dir"
            return
        fi
        dir=$(dirname "$dir")
    done
    echo ""
}

# Get file extension
get_extension() {
    local file="$1"
    echo "${file##*.}"
}

# Detect git root
file_dir=$(dirname "$file_path")
git_root=$(find_git_root "$file_dir")

# Use project dir as fallback if no git root
if [[ -z "$git_root" ]]; then
    git_root="$CLAUDE_PROJECT_DIR"
fi

# Get relative path from git root
relative_path="${file_path#$git_root/}"

# Get file extension for language tracking
extension=$(get_extension "$file_path")

# Log edited file: timestamp|absolute_path|relative_path|extension|git_root
echo "$(date +%s)|$file_path|$relative_path|$extension|$git_root" >> "$cache_dir/edited-files.log"

# Track unique directories modified
dir_path=$(dirname "$relative_path")
if [[ -n "$dir_path" ]] && [[ "$dir_path" != "." ]]; then
    echo "$dir_path" >> "$cache_dir/dirs.tmp"
    sort -u "$cache_dir/dirs.tmp" > "$cache_dir/affected-dirs.txt" 2>/dev/null || true
    rm -f "$cache_dir/dirs.tmp"
fi

# Track unique extensions (languages) modified
if [[ -n "$extension" ]]; then
    echo "$extension" >> "$cache_dir/ext.tmp"
    sort -u "$cache_dir/ext.tmp" > "$cache_dir/extensions.txt" 2>/dev/null || true
    rm -f "$cache_dir/ext.tmp"
fi

exit 0
