# Jira TUI Backlog

Tracking progress on the interactive TUI (`lazyjira`).

## Current State
- ✅ Dashboard displays all panels with [1]-[5] hotkeys
- ✅ Single keypress drill-down (1-5 jumps to panel report)
- ✅ Styled drill-down output (bordered, colored headers)
- ✅ Auto-refresh works (--refresh=N flag or /auto)
- ✅ `lazyjira` and `lazyroi` commands work
- ✅ Interactive mode with gum filter (typeahead via /)
- ✅ All 13 commands with descriptions
- ✅ Hotkeys: q=quit, r=refresh, s=search, t=team, c=theme, h=help
- ✅ Ticket search with fuzzy filter /search
- ✅ Color themes (default, ocean, forest, sunset, mono) /theme
- ✅ /help shows all commands with descriptions
- ✅ Optional glow support for markdown rendering (if installed)

## Backlog

### P0 - Core Interactivity ✅ DONE
- [x] **Keyboard input handling** - gum choose handles arrow keys
- [x] **Command execution** - Select from menu to run commands
- [x] **Panel navigation** - gum menu for command selection
- [x] **Action menu** - Menu shows all commands, enter to run

### P1 - Navigation & UX ✅ DONE
- [x] Help screen (press `?`)
- [x] Quit confirmation or instant `q` to quit
- [x] Team switcher (press `t` to toggle platform/roio/roip)
- [x] Refresh on demand (press `r`)

### P2 - Enhanced Views ✅ DONE
- [x] Drill-down into panels - menu shows all commands to drill into
- [x] Ticket search & view - [s] search by key or text, opens in browser
- [x] Configurable refresh interval - [a] auto-refresh with custom interval
- [ ] Scrollable panels for long lists (deferred - gum limitation)

### P1.5 - WIP Limits 🚨 ✅ DONE
- [x] **WIP warning banner** - flash alert when In Progress count exceeds threshold
- [x] **Per-person WIP** - highlight individuals with 3+ items in flight
- [ ] **"Stop starting" mode** - block new work visibility until WIP under limit (deferred)
- [x] **Configurable threshold** - default 5 in `jira-data/config.yaml`

### P1.7 - Pod Views ✅ DONE
- [x] **Pod config** - `pods:` section in config.yaml with label-based filtering
- [x] **[p] hotkey** - switch between pod views (intake-logging, platform-pod, fulfillment-qc)
- [x] **Header shows pod** - displays "pod-name (pod)" when active
- [x] **JQL filter** - uses `labels in (label)` instead of Team(s) field

### P3 - Nice to Have ✅ MOSTLY DONE
- [ ] Mouse support (deferred - terminal limitation)
- [x] Configurable refresh interval - MOVED TO P2
- [x] Color themes - 5 themes: default, ocean, forest, sunset, mono
- [ ] Notifications/alerts overlay (future)

## Technical Options

| Approach | Pros | Cons |
|----------|------|------|
| **Bash + read -n1** | No deps, pure bash | Complex key handling, limited |
| **gum** | Pretty, easy menus | External dep, not full TUI |
| **fzf** | Great fuzzy search | Better for selection than dashboard |
| **Python + textual** | Rich TUI, easy | Python dep |
| **Go + bubbletea** | Best UX (like lazygit) | Needs Go, more work |

## Notes
- Implementation uses bash + gum for interactive menus
- All P0-P2 features complete, most P3 done
- gum handles arrow keys, enter selection natively
- Theme and team persist during session, not across restarts

---
*Last updated: 2026-01-02*
