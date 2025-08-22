---
name: quick-look
description: Quick Look plugin for markdown preview in Finder with spacebar
status: backlog
created: 2025-08-22T01:50:00Z
---

# PRD: Quick Look Support

## Executive Summary

Develop a Quick Look plugin that enables users to preview markdown files directly in Finder by pressing the spacebar, providing instant visual preview without opening Parchment. This feature integrates Parchment's rendering engine into macOS's native preview system.

## Problem Statement

When users press spacebar on a markdown file in Finder, they see raw markdown text instead of rendered content. This makes it difficult to quickly preview documentation, notes, or README files without opening them in an application. Users need the same quick preview experience for markdown that they have for images and PDFs.

## User Stories

### Primary User: Developer
- **As a** developer browsing project documentation
- **I want to** press spacebar on README.md files to see formatted content
- **So that** I can quickly understand project documentation without opening an editor

### Secondary User: Content Creator
- **As a** writer reviewing multiple markdown drafts
- **I want to** quickly preview rendered markdown with spacebar
- **So that** I can identify the right document without opening each one

### Tertiary User: System Administrator
- **As a** sysadmin reviewing documentation
- **I want to** preview markdown files in Finder columns view
- **So that** I can navigate documentation hierarchies efficiently

### Acceptance Criteria
- [ ] Spacebar shows rendered markdown, not raw text
- [ ] Preview appears within 200ms
- [ ] Supports all standard markdown features
- [ ] Shows syntax-highlighted code blocks
- [ ] Works in all Finder views (icon, list, column, gallery)
- [ ] Includes "Open with Parchment" button in preview

## Requirements

### Functional Requirements

1. **Quick Look Plugin Architecture**
   - Implement QLPreviewingController protocol
   - Bundle as .qlgenerator plugin
   - Install to ~/Library/QuickLook/ or /Library/QuickLook/
   - Auto-register with Quick Look server

2. **Preview Generation**
   - Convert markdown to HTML for display
   - Apply consistent, readable styling
   - Include syntax highlighting for code blocks
   - Handle images (local and remote)
   - Support tables, lists, and blockquotes

3. **File Type Support**
   - Handle all markdown extensions (.md, .markdown, .mdown, etc.)
   - Detect markdown content even without extension
   - Support CommonMark and GitHub Flavored Markdown
   - Gracefully handle malformed markdown

4. **Preview Features**
   - Scrollable content for long documents
   - Zoom in/out support
   - Text selection and copying
   - "Open with Parchment" action button
   - Display file metadata (size, modified date)

5. **Performance Optimization**
   - Cache rendered previews
   - Progressive rendering for large files
   - Thumbnail generation for Finder
   - Maximum file size limits (e.g., 10MB)

### Non-Functional Requirements

1. **Performance**
   - Initial preview in < 200ms for files under 100KB
   - Smooth scrolling at 60fps
   - Memory usage < 50MB per preview
   - CPU usage < 10% when idle

2. **Compatibility**
   - Support macOS 13.0+
   - Work with both Intel and Apple Silicon
   - Coexist with other Quick Look plugins
   - Handle sandboxing restrictions

3. **Reliability**
   - Graceful degradation for unsupported features
   - No crashes that affect Finder
   - Timeout handling for slow rendering
   - Error messages for corrupted files

## Success Criteria

- Quick Look preview used by 95% of Parchment users
- Preview generation time < 200ms for 90% of files
- Zero Finder crashes attributed to the plugin
- User satisfaction rating > 4.5/5 for preview quality

## Constraints & Assumptions

### Constraints
- Must operate within Quick Look sandbox
- Cannot access network without entitlements
- Limited to read-only file access
- Must be signed and notarized for distribution
- File size limitations imposed by Quick Look

### Assumptions
- Users have Quick Look enabled (default in macOS)
- Most markdown files are < 1MB
- Users expect GitHub-flavored markdown support
- Basic CSS styling is sufficient (no themes)

## Out of Scope

- Interactive elements (collapsible sections, tabs)
- Live reload when file changes
- Mermaid diagrams or LaTeX math
- Custom CSS themes
- Export or print from Quick Look
- Full wiki-link resolution
- JavaScript execution

## Dependencies

### Technical Dependencies
- Quick Look framework
- Uniform Type Identifiers framework
- WebKit for HTML rendering
- Swift-markdown for parsing
- Syntax highlighting library

### System Dependencies
- Quick Look server (qlmanage)
- Launch Services for registration
- Markdown UTI definitions
- Code signing certificate

## Implementation Notes

### Plugin Structure
```
Parchment.qlgenerator/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── Parchment (executable)
│   └── Resources/
│       ├── preview.css
│       └── template.html
```

### Info.plist Configuration
```xml
<key>QLSupportedContentTypes</key>
<array>
    <string>net.daringfireball.markdown</string>
    <string>public.plain-text</string>
</array>
<key>QLThumbnailMinimumSize</key>
<integer>32</integer>
```

### Rendering Pipeline
1. Receive markdown file URL from Quick Look
2. Read and parse markdown content
3. Convert to HTML with syntax highlighting
4. Apply CSS styling
5. Return preview to Quick Look
6. Cache for subsequent requests

### Testing Considerations
- Test with qlmanage command-line tool
- Verify with various file sizes
- Test special characters in filenames
- Validate memory usage under load
- Test installation and uninstallation