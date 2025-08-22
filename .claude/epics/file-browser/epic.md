---
name: file-browser
status: backlog
created: 2025-08-22T02:15:23Z
progress: 0%
prd: .claude/prds/file-browser.md
github: https://github.com/cschuman/Parchment/issues/2
---

# Epic: File Browser

## Overview

Implement a collapsible sidebar file browser using native NSOutlineView that provides efficient navigation through markdown files. The solution leverages existing macOS components and patterns to minimize new code while delivering a familiar, performant experience similar to Xcode or VS Code.

## Architecture Decisions

### Key Technical Decisions
- **NSOutlineView**: Use native AppKit component for tree view (no custom rendering)
- **Lazy Loading**: Load folder contents only when expanded to handle large directories
- **FSEvents Integration**: Monitor file system changes for automatic updates
- **NSSplitView**: Leverage existing split view for sidebar integration
- **Shared Data Model**: Reuse existing DocumentCache for file metadata

### Technology Choices
- Native AppKit components (NSOutlineView, NSSplitView)
- FSEvents for file watching (already used in project)
- NSFileManager for directory traversal
- UserDefaults for persistence

### Design Patterns
- MVC pattern with FileTreeViewController
- Delegate pattern for tree interactions
- Observer pattern for file system changes
- Lazy loading pattern for performance

## Technical Approach

### UI Components
- **FileTreeViewController**: Main controller managing the sidebar
- **NSOutlineView**: Native tree view component
- **NSSearchField**: Filter box at top of sidebar
- **NSToolbar Integration**: Toggle button for sidebar visibility

### Data Management
- **FileTreeItem**: Lightweight model representing files/folders
- **Lazy Children Loading**: Load subdirectories on-demand
- **Cache Integration**: Reuse existing DocumentCache for opened files
- **State Persistence**: Save expanded folders and selection in UserDefaults

### File System Integration
- **Directory Traversal**: Recursive enumeration with NSFileManager
- **File Filtering**: Show only markdown files by default
- **FSEvents Monitoring**: Auto-refresh on file system changes
- **Sandboxing Compliance**: Respect macOS security model

## Implementation Strategy

### Development Phases

1. **Phase 1 - Core Sidebar**
   - Add NSSplitView to MainWindowController
   - Create basic FileTreeViewController
   - Implement NSOutlineView with static test data

2. **Phase 2 - File System Integration**
   - Connect to NSFileManager for real directory listing
   - Implement lazy loading for folders
   - Add markdown file filtering

3. **Phase 3 - Interactivity & Polish**
   - Double-click to open files
   - Keyboard navigation
   - Context menu
   - Visual polish (icons, colors, animations)

### Risk Mitigation
- **Performance**: Use lazy loading and caching
- **Large Directories**: Virtual scrolling in NSOutlineView
- **Sandboxing**: Request appropriate entitlements
- **Memory Usage**: Release unused tree nodes

### Testing Approach
- Unit tests for file filtering logic
- Performance tests with large directories
- UI tests for tree interactions
- Manual testing with various folder structures

## Task Breakdown Preview

Simplified task categories (keeping to minimum):
- [ ] Create sidebar UI with NSSplitView and NSOutlineView
- [ ] Implement file system data source with lazy loading
- [ ] Add file opening and navigation interactions
- [ ] Integrate FSEvents for auto-refresh
- [ ] Add keyboard shortcuts and menu items
- [ ] Implement search/filter functionality
- [ ] Add preferences for file browser settings
- [ ] Polish UI with icons and animations

## Dependencies

### External Dependencies
- None - using only native AppKit components

### Internal Dependencies
- MainWindowController for window layout
- MarkdownViewController for file opening
- DocumentCache for file metadata
- Existing FSEvents monitoring

### Prerequisite Work
- None - can be developed independently

## Success Criteria (Technical)

### Performance Benchmarks
- Directory load time < 500ms for 1000 files
- Smooth 60fps scrolling with 10,000 items
- Memory overhead < 10MB for typical project
- Instant response to user interactions

### Quality Gates
- Full keyboard navigation support
- VoiceOver accessibility compliance
- No UI freezing during file operations
- Proper dark mode support

### Acceptance Criteria
- Toggle sidebar with ⌘B shortcut
- Tree view with expand/collapse
- Double-click opens files
- Current file highlighted
- State persists between launches
- Search field filters in real-time

## Estimated Effort

### Overall Timeline
- **Core Implementation**: 3 days
- **Integration & Polish**: 2 days
- **Testing & Bug Fixes**: 1 day
- **Total**: 6 days

### Resource Requirements
- 1 developer
- Access to various folder structures for testing
- Test projects with 1000+ markdown files

### Critical Path Items
1. NSSplitView integration with existing window
2. NSOutlineView data source implementation
3. File opening coordination with MarkdownViewController
4. FSEvents integration for auto-refresh