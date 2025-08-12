# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Parchment is a native macOS markdown viewer application built with Swift and AppKit. It provides high-performance markdown rendering with advanced features like wiki-links, backlinks, and Metal-accelerated text rendering.

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
- `BacklinksViewController.swift` - Backlinks panel for wiki-style navigation

**Rendering Pipeline** (`Sources/Parchment/Rendering/`)
- `MarkdownRenderingEngine.swift` - Core rendering engine using swift-markdown
- `MetalTextRenderer.swift` - Metal-accelerated text rendering
- `SyntaxHighlighter.swift` - Code block syntax highlighting using SwiftSyntax

**Knowledge Graph** (`Sources/Parchment/KnowledgeGraph/`)
- `WikiLinkParser.swift` - Parses `[[wiki-links]]` syntax
- `GraphVisualizationView.swift` - Interactive document relationship visualization

### Key Design Patterns

1. **Async Rendering**: Uses Swift concurrency for non-blocking markdown rendering
2. **Caching Strategy**: Multi-level caching (render cache, image cache, document cache)
3. **File Watching**: Live updates using FSEvents when markdown files change
4. **Visitor Pattern**: Used in markdown parsing and attributed string generation

## Dependencies

- `swift-markdown` - Apple's markdown parsing library
- `swift-syntax` - Syntax highlighting for code blocks
- `swift-markdownkit` - Additional markdown processing
- `swift-argument-parser` - Command-line argument parsing

## Development Notes

- The app uses AppKit (not SwiftUI) for performance and native macOS integration
- Metal rendering is implemented for smooth 60fps scrolling
- Images are loaded asynchronously with caching for performance
- The app supports both local and remote images
- Wiki-links enable Obsidian-style document connections