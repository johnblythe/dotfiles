#!/bin/bash
# Create a new zellij project config
# Usage: ./new-project.sh <project-name> <project-path>

set -e

PROJECT="$1"
PROJECT_PATH="$2"

if [ -z "$PROJECT" ] || [ -z "$PROJECT_PATH" ]; then
    echo "Usage: $0 <project-name> <project-path>"
    echo "Example: $0 myapp ~/code/myapp"
    exit 1
fi

ZELLIJ_DIR="$HOME/.config/zellij"
CONFIG_FILE="$ZELLIJ_DIR/$PROJECT.kdl"

if [ -f "$CONFIG_FILE" ]; then
    echo "Config already exists: $CONFIG_FILE"
    exit 1
fi

# Create config from template
sed -e "s|{{PROJECT}}|$PROJECT|g" \
    -e "s|{{PROJECT_PATH}}|$PROJECT_PATH|g" \
    "$(dirname "$0")/project.kdl.template" > "$CONFIG_FILE"

echo "Created: $CONFIG_FILE"
echo ""
echo "Add this alias to your .zshrc:"
echo "alias z$PROJECT='cd $PROJECT_PATH && zellij --config ~/.config/zellij/$PROJECT.kdl -s $PROJECT'"
