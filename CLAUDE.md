# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Important Instructions

- **NEVER add Claude as a co-author in git commits**
- Do not include "Co-Authored-By: Claude" or any similar attribution
- Do not add emoji or "Generated with Claude Code" to commit messages

## Project Overview

Parchment is a native macOS markdown viewer application built with Swift and AppKit. It provides markdown rendering with syntax highlighting, theming support, and a table of contents.

## Build Commands

### Development
```bash
# Quick debug build (fastest)
./build_dev.sh

# Standard debug build
swift build

# Run tests
swift test
```

### Release
```bash
# Build release version with app bundle
./build_release.sh

# Build release executable only
swift build -c release
```

### Running the Application
```bash
# Run from app bundle
open Parchment.app

# Run with a specific file
open Parchment.app --args test.md

# Run executable directly
.build/debug/Parchment test.md
```

## Architecture

### Core Components

**App Lifecycle** (`Sources/Parchment/App/`)
- `AppDelegate.swift` - Main application delegate handling lifecycle, file opening, and menu setup
- `main.swift` - Entry point that creates NSApplication and AppDelegate

**Window Management** (`Sources/Parchment/Windows/`)
- `MainWindowController.swift` - Primary window controller managing document display

**View Controllers** (`Sources/Parchment/ViewControllers/`)
- `MarkdownViewController.swift` - Main view controller for markdown content
- `TableOfContentsViewController.swift` - TOC navigation panel

**Rendering Pipeline** (`Sources/Parchment/Rendering/`)
- `EnhancedMarkdownRenderer.swift` - Core markdown to attributed string renderer
- `CodeSyntaxHighlighter.swift` - Code block syntax highlighting

**Theme System** (`Sources/Parchment/Theme/`)
- `ParchmentThemes.swift` - Theme definitions (Minimal, Elegant, Midnight, Sepia, High Contrast)

### Key Design Patterns

1. **Caching Strategy**: NSCache-based caching for images and documents
2. **File Watching**: Debounced live updates when markdown files change
3. **Theming**: Unified theme system with syntax highlighting colors

## Dependencies

- `swift-markdown` - Apple's markdown parsing library
- `swift-argument-parser` - Command-line argument parsing

## Development Notes

- The app uses AppKit (not SwiftUI) for native macOS integration
- Images are loaded asynchronously with security validation (HTTPS only, size limits)
- Document exports support PDF, HTML, RTF, DOCX, and plain text formats
