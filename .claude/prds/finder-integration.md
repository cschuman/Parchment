---
name: finder-integration
description: Right-click "Open With" support for all markdown file types in Finder
status: backlog
created: 2025-08-22T01:50:00Z
---

# PRD: Finder Integration

## Executive Summary

Enable seamless Finder integration for Parchment, allowing users to right-click any markdown file and select "Open with Parchment" from the context menu. This feature will register Parchment as a handler for all markdown file extensions and provide proper file type associations in macOS.

## Problem Statement

Currently, users must either drag files to Parchment or open files from within the application. This creates friction in the workflow, especially when browsing files in Finder. Users expect native macOS applications to integrate seamlessly with the system's file manager, allowing quick access through right-click context menus.

## User Stories

### Primary User: Developer/Writer
- **As a** developer working with documentation
- **I want to** right-click any .md file in Finder and open it with Parchment
- **So that** I can quickly preview markdown files without launching the app first

### Secondary User: Knowledge Worker
- **As a** knowledge worker with various markdown files
- **I want to** set Parchment as my default markdown viewer
- **So that** double-clicking any markdown file opens it in Parchment

### Acceptance Criteria
- [ ] Right-click menu shows "Open with → Parchment" for .md files
- [ ] Parchment appears in "Open With" submenu for all markdown extensions
- [ ] Can set Parchment as default app via "Get Info" panel
- [ ] File icons update when Parchment is set as default

## Requirements

### Functional Requirements

1. **File Type Registration**
   - Register with Launch Services for markdown UTIs
   - Support extensions: .md, .markdown, .mdown, .mkd, .mdwn, .mkdown, .text
   - Declare as both viewer and editor in Info.plist

2. **Document Type Declaration**
   - Define CFBundleDocumentTypes in Info.plist
   - Include proper UTI conformance (public.text, public.plain-text)
   - Provide document icons for registered types

3. **Launch Services Integration**
   - Handle NSApplication file open events
   - Support opening multiple files simultaneously
   - Maintain file opening queue during app launch

4. **System Integration**
   - Respond to AppleEvents for file opening
   - Support "Open With" for both single and multiple file selection
   - Handle file paths with spaces and special characters

### Non-Functional Requirements

1. **Performance**
   - File association registration < 100ms on first launch
   - Zero performance impact when not selected
   - Instant response when selected from menu

2. **Compatibility**
   - Support macOS 13.0+
   - Work with both Intel and Apple Silicon
   - Maintain compatibility with Markdown Editor Pro, iA Writer, etc.

3. **User Experience**
   - Seamless integration without configuration
   - Respect user's default app preferences
   - No aggressive default app hijacking

## Success Criteria

- 90% of users can successfully open files via right-click within first attempt
- Zero crashes related to file opening from Finder
- File associations persist across app updates
- Parchment appears in all standard "Open With" locations

## Constraints & Assumptions

### Constraints
- Must use Apple's Launch Services API
- Cannot modify system files or require admin privileges
- Must respect macOS Gatekeeper and notarization requirements

### Assumptions
- Users have standard Finder configuration
- Markdown files are not already strongly associated with another app
- App bundle is properly code-signed

## Out of Scope

- Custom Finder toolbar buttons
- Finder preview pane integration (separate from Quick Look)
- File type conversion on open
- Batch processing from Finder
- Custom file icons per document

## Dependencies

### Technical Dependencies
- Proper code signing certificate
- Info.plist configuration
- AppDelegate file handling implementation
- Launch Services framework

### Process Dependencies
- App notarization for distribution
- Testing on multiple macOS versions
- Icon design for document types

## Implementation Notes

### Info.plist Configuration
```xml
<key>CFBundleDocumentTypes</key>
<array>
    <dict>
        <key>CFBundleTypeName</key>
        <string>Markdown Document</string>
        <key>CFBundleTypeRole</key>
        <string>Viewer</string>
        <key>LSHandlerRank</key>
        <string>Default</string>
        <key>LSItemContentTypes</key>
        <array>
            <string>net.daringfireball.markdown</string>
        </array>
    </dict>
</array>
```

### AppDelegate Implementation
- Override `application(_:open:)` method
- Handle both single and multiple file opening
- Queue files if app is still launching