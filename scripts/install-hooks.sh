#!/bin/bash

# Install git hooks for SpotDrop macOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Handle submodule case - .git is a file pointing to the real git dir
if [ -f "$REPO_ROOT/.git" ]; then
    # Extract the gitdir path from the .git file
    GIT_DIR=$(cat "$REPO_ROOT/.git" | sed 's/gitdir: //')
    # Resolve relative path
    HOOKS_DIR="$(cd "$REPO_ROOT" && cd "$GIT_DIR" && pwd)/hooks"
else
    HOOKS_DIR="$REPO_ROOT/.git/hooks"
fi

echo "Installing git hooks to $HOOKS_DIR..."

# Create hooks directory if it doesn't exist
mkdir -p "$HOOKS_DIR"

# Copy pre-commit hook
cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

echo "Git hooks installed successfully!"
echo "Pre-commit hook will now validate build and run tests before each commit."
