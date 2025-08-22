---
name: command-line
description: Command-line interface for opening files and folders with parchment command
status: in-progress
created: 2025-08-22T01:50:00Z
updated: 2025-08-22T02:00:00Z
---

# PRD: Command Line Support

## Executive Summary

Implement a command-line interface that allows users to launch Parchment directly from Terminal, enabling quick file opening, batch operations, and integration with developer workflows. Users will be able to type `parchment file.md` or `parchment folder/` to open files or browse directories.

## Problem Statement

Developers and power users work extensively in the terminal and expect their tools to be accessible from the command line. Currently, Parchment requires GUI interaction or complex `open -a` commands. A dedicated CLI would streamline workflows, enable scripting, and improve productivity for terminal-focused users.

## User Stories

### Primary User: Developer
- **As a** developer working in terminal
- **I want to** type `parchment README.md` to open documentation
- **So that** I can quickly view rendered markdown without leaving my terminal workflow

### Secondary User: DevOps Engineer
- **As a** DevOps engineer writing scripts
- **I want to** open multiple markdown files programmatically
- **So that** I can automate documentation workflows

### Tertiary User: Technical Writer
- **As a** technical writer using build scripts
- **I want to** preview generated markdown files from command line
- **So that** I can integrate Parchment into my build pipeline

### Acceptance Criteria
- [ ] `parchment file.md` opens single file
- [ ] `parchment folder/` opens folder in file browser
- [ ] `parchment` alone opens app with last document
- [ ] Supports relative and absolute paths
- [ ] Handles multiple files: `parchment *.md`
- [ ] Available in PATH after installation

## Requirements

### Functional Requirements

1. **CLI Binary**
   - Standalone executable: `/usr/local/bin/parchment`
   - Lightweight wrapper (~100KB)
   - Links to main Parchment.app bundle
   - Self-contained with no external dependencies

2. **Command Syntax**
   ```bash
   parchment [options] [file|directory...]
   
   Options:
     -h, --help        Show help information
     -v, --version     Show version information
     -n, --new-window  Open in new window
     -t, --tab         Open in new tab (default)
     -w, --wait        Wait for file to be closed
     -b, --background  Don't bring app to foreground
     --theme <name>    Use specific theme
     --focus           Start in focus mode
   ```

3. **File Handling**
   - Single file: Open in current or new window
   - Multiple files: Open each in tabs
   - Directory: Open file browser at location
   - Wildcard: Expand and open matching files
   - No arguments: Open app with recent file

4. **Path Resolution**
   - Support relative paths from CWD
   - Expand ~ to home directory
   - Handle symlinks correctly
   - Support paths with spaces (quoted)
   - Validate file existence

5. **Process Management**
   - Launch GUI app if not running
   - Reuse existing instance by default
   - Return immediately unless --wait
   - Forward stdin for piping (future)
   - Proper exit codes

6. **Installation Methods**
   - Homebrew formula: `brew install parchment`
   - Direct symlink from app bundle
   - Manual PATH configuration
   - Automatic on first app launch (with permission)

### Non-Functional Requirements

1. **Performance**
   - CLI startup < 50ms
   - App launch < 500ms
   - Zero overhead when app running
   - Minimal memory footprint

2. **Compatibility**
   - Work with zsh, bash, fish shells
   - Support macOS 13.0+
   - Handle both Intel and Apple Silicon
   - Work with Terminal, iTerm2, etc.

3. **User Experience**
   - Intuitive command structure
   - Helpful error messages
   - Tab completion support
   - Man page documentation

## Success Criteria

- 60% of power users use CLI regularly
- Command execution time < 100ms
- Zero issues with PATH configuration
- 90% success rate for first-time users

## Constraints & Assumptions

### Constraints
- Must work within macOS sandboxing
- Cannot modify system directories without permission
- Must handle app translocation
- Limited to launching GUI (not headless)

### Assumptions
- Users have basic CLI knowledge
- Most users have Homebrew installed
- Users expect Unix-style options
- Primary use is opening files, not processing

## Out of Scope

- Headless markdown rendering
- Export/conversion operations
- REPL or interactive mode
- Markdown validation/linting
- Direct markdown content input (stdin)
- Plugin management via CLI
- Configuration file editing
- Remote file support

## Dependencies

### Technical Dependencies
- Swift Argument Parser
- AppKit for app communication
- Foundation Process API
- Launch Services framework

### Distribution Dependencies
- Code signing for CLI binary
- Homebrew tap repository
- Installation script
- Uninstallation script

## Implementation Notes

### Architecture Design
```swift
// CLI Tool Structure
ParchmentCLI
├── main.swift           // Entry point
├── CommandParser.swift  // Argument parsing
├── AppLauncher.swift   // Communication with GUI
└── PathResolver.swift  // File path handling
```

### Communication Strategy
1. CLI parses arguments
2. Resolves file paths
3. Launches Parchment.app with Apple Events
4. Passes file URLs via NSApplication
5. Returns control to terminal

### Installation Script
```bash
#!/bin/bash
# Install parchment CLI
ln -sf /Applications/Parchment.app/Contents/MacOS/parchment-cli \
       /usr/local/bin/parchment
```

### Homebrew Formula
```ruby
class Parchment < Formula
  desc "Fast native markdown viewer for macOS"
  homepage "https://github.com/cschuman/Parchment"
  url "..."
  version "1.0.0"
  
  def install
    bin.install "parchment"
    # Link to app bundle
  end
end
```

### Shell Completion
- Provide completion scripts for:
  - Zsh: `_parchment` completion function
  - Bash: `parchment-completion.bash`
  - Fish: `parchment.fish`

### Error Handling
- File not found → Clear error with suggestion
- App not installed → Installation instructions
- Permission denied → Sandbox explanation
- Invalid options → Show usage help