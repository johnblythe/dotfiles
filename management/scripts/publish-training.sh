#!/usr/bin/env bash
# Publishes training decks from mgmt repo → healthsource-scripts
# Source of truth: ~/code/management/training/sessions/
# Run after updating any training HTML

set -e

SRC="$HOME/code/management/training/sessions"
DEST="$HOME/code/healthsource-scripts/training/sessions"

mkdir -p "$DEST"
cp "$SRC"/*.html "$DEST/"

cd "$HOME/code/healthsource-scripts"
git add training/
git commit -m "Update training decks"
echo "Done. Don't forget to push: cd ~/code/healthsource-scripts && git push"
