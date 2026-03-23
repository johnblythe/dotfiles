#!/bin/bash

input=$(cat)

dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
remaining=$(echo "$input" | jq -r '.context_window.remaining_percentage // empty')
cost=$(echo "$input" | jq -r '.session.cost_usd // empty')
session_name=$(echo "$input" | jq -r '.session.name // empty')

current_dir=$(basename "${dir:-$PWD}")

# Git info
branch=""
lines=""
repo=""
if cd "$dir" 2>/dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
  repo=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)")
  branch=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  stat=$(git diff --shortstat 2>/dev/null)
  ins=$(echo "$stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
  del=$(echo "$stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')
  staged=$(git diff --cached --shortstat 2>/dev/null)
  sins=$(echo "$staged" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')
  sdel=$(echo "$staged" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')
  total_ins=$(( ${ins:-0} + ${sins:-0} ))
  total_del=$(( ${del:-0} + ${sdel:-0} ))
  if [ "$total_ins" -gt 0 ] || [ "$total_del" -gt 0 ]; then
    lines="+${total_ins}-${total_del}"
  fi
fi

# Repo
if [ -n "$repo" ]; then
  printf "\033[36m%s\033[0m" "$repo"
else
  printf "\033[36m%s\033[0m" "$current_dir"
fi

# Branch
if [ -n "$branch" ]; then
  printf "\033[2m:\033[34m%s\033[0m" "$branch"
fi

# Lines changed
if [ -n "$lines" ]; then
  printf " \033[32m%s\033[0m" "$lines"
fi

# Session name
if [ -n "$session_name" ]; then
  printf " \033[2m|\033[0m \033[33m%s\033[0m" "$session_name"
fi

# Separator
printf " \033[2m|\033[0m "

# Cost
if [ -n "$cost" ] && [ "$cost" != "0" ]; then
  printf "\033[2m\$%s\033[0m " "$cost"
fi

# Context — green->yellow->red
if [ -n "$remaining" ]; then
  pct=${remaining%.*}
  if [ "$pct" -gt 50 ] 2>/dev/null; then
    color="32"
  elif [ "$pct" -gt 25 ] 2>/dev/null; then
    color="33"
  else
    color="31"
  fi
  printf "\033[${color}m%.0f%%\033[0m" "$remaining"
fi
