---
name: file-browser
description: Sidebar file browser panel for navigating and opening markdown files
status: backlog
created: 2025-08-22T01:50:00Z
---

# PRD: File Browser

## Executive Summary

Implement a native file browser sidebar panel that allows users to navigate their filesystem and open markdown files directly within Parchment. This feature provides a familiar IDE-like experience for users working with multiple markdown files in a project structure.

## Problem Statement

Users working with documentation projects or knowledge bases need to quickly navigate between multiple markdown files. Currently, they must use Finder or the File > Open dialog repeatedly, which disrupts their workflow. A built-in file browser would allow seamless navigation within the app, similar to how developers work in IDEs.

## User Stories

### Primary User: Documentation Writer
- **As a** technical writer managing documentation
- **I want to** see my project's folder structure in a sidebar
- **So that** I can quickly switch between related documents without leaving the app

### Secondary User: Note Taker
- **As a** student or researcher with organized notes
- **I want to** browse my notes hierarchy visually
- **So that** I can find and open related notes while maintaining context

### Tertiary User: Developer
- **As a** developer working on a project
- **I want to** see all markdown files in my project tree
- **So that** I can navigate documentation like I navigate code

### Acceptance Criteria
- [ ] Toggle sidebar with keyboard shortcut (⌘B)
- [ ] Display folder tree with expand/collapse
- [ ] Show only markdown files and folders by default
- [ ] Double-click or Enter to open files
- [ ] Visual indicator for currently open file
- [ ] Remember expanded state between sessions

## Requirements

### Functional Requirements

1. **Sidebar Panel**
   - Collapsible/expandable sidebar (250px default width)
   - Resizable with minimum (150px) and maximum (500px) widths
   - Toggle via menu item, keyboard shortcut, or toolbar button
   - Smooth animation for show/hide

2. **File Tree Display**
   - Hierarchical folder structure
   - Expand/collapse folders with disclosure triangles
   - File type icons (folder, markdown file)
   - Sort folders first, then files alphabetically
   - Show file extensions optionally

3. **File Filtering**
   - Show markdown files (.md, .markdown, .mdown, etc.)
   - Option to show all files
   - Option to show/hide hidden files (dot files)
   - Search/filter box at top of panel

4. **Navigation Features**
   - Single-click to select
   - Double-click or Enter to open
   - Arrow keys for keyboard navigation
   - Tab to switch focus between browser and editor
   - Context menu with options (Open, Reveal in Finder, Copy Path)

5. **Project Management**
   - "Open Folder" button to set root directory
   - Recent folders dropdown
   - Bookmark frequently used folders
   - Remember last opened folder

6. **Visual Feedback**
   - Highlight currently open file
   - Different colors for modified files
   - Subtle hover effects
   - Loading indicator for large directories

### Non-Functional Requirements

1. **Performance**
   - Load directories with 1000+ files in < 500ms
   - Smooth scrolling with 10,000+ items
   - Lazy loading for deep hierarchies
   - Efficient file watching for updates

2. **User Experience**
   - Familiar tree view like Finder or VS Code
   - Responsive to window resizing
   - Maintain selection during refresh
   - Smooth animations and transitions

3. **Accessibility**
   - Full keyboard navigation
   - VoiceOver support
   - High contrast mode support
   - Focus indicators

## Success Criteria

- 80% of users use file browser for multi-file workflows
- Average time to locate and open a file < 3 seconds
- File browser adds < 10MB to memory footprint
- No performance degradation with large folder structures

## Constraints & Assumptions

### Constraints
- Must use native NSOutlineView or similar AppKit component
- Cannot access files without user permission (sandboxing)
- Must respect macOS file permissions

### Assumptions
- Users organize markdown files in folder structures
- Most users work with < 10,000 files per project
- Users want to see folder hierarchy, not flat list

## Out of Scope

- File operations (create, delete, rename)
- Drag and drop to move files
- Git status indicators
- File preview on hover
- Multiple root folders simultaneously
- Virtual folders or tags
- File content search (just filename filtering)

## Dependencies

### Technical Dependencies
- NSOutlineView or NSTableView
- NSFileManager for directory traversal
- FSEvents for file watching
- NSSplitView for sidebar integration

### Design Dependencies
- Icon set for file types
- Consistent with macOS design language
- Theme support (light/dark mode)

## Implementation Notes

### Architecture Considerations
```swift
// Suggested component structure
FileTreeViewController: NSViewController {
    - NSOutlineView for tree display
    - FileSystemDataSource for lazy loading
    - FSEventStream for watching changes
}

FileTreeItem: NSObject {
    - URL: file location
    - children: lazy-loaded array
    - isExpandable: computed property
}
```

### Performance Optimizations
- Implement lazy loading for folders
- Cache folder contents with TTL
- Virtual scrolling for large lists
- Debounce file system events

### Integration Points
- MainWindowController for sidebar management
- MarkdownViewController for file opening
- Preferences for browser settings
- Recent files integration