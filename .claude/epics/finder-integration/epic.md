---
name: finder-integration
status: backlog
created: 2025-08-22T02:18:00Z
progress: 0%
prd: .claude/prds/finder-integration.md
github: https://github.com/cschuman/Parchment/issues/3
---

# Epic: Finder Integration

## Overview

Implement macOS Finder integration through Info.plist configuration and minimal AppDelegate modifications to register Parchment as a markdown file handler. This lightweight approach leverages existing macOS APIs without requiring new components, enabling right-click "Open With" functionality and default app registration.

## Architecture Decisions

### Key Technical Decisions
- **Info.plist Configuration**: Primary method for file type registration (no code needed)
- **Existing AppDelegate**: Enhance current file handling methods instead of adding new components
- **Launch Services**: Use native macOS registration (automatic on app launch)
- **UTI Declaration**: Register for standard markdown UTIs plus custom extensions
- **Minimal Code Changes**: Most functionality achieved through configuration

### Technology Choices
- Info.plist for document type declarations
- Native NSApplication file handling
- Launch Services framework (implicit)
- Existing AppDelegate infrastructure

### Design Patterns
- Declaration-based configuration (Info.plist)
- Event-driven file handling (AppDelegate)
- Queue pattern for startup file handling

## Technical Approach

### Configuration Components
- **Info.plist Updates**: Add CFBundleDocumentTypes array
- **UTI Registration**: Declare support for markdown UTIs
- **Icon Resources**: Add document type icons to Resources
- **Bundle Identifier**: Ensure proper app identification

### Code Modifications
- **AppDelegate Enhancement**: Improve existing file open handling
- **Multiple File Support**: Handle array of files from Finder
- **Queue Management**: Buffer files during app startup
- **Path Normalization**: Handle spaces and special characters

### System Integration
- **Automatic Registration**: Launch Services registers on first run
- **No Manual Setup**: Works immediately after installation
- **Coexistence**: Respects other markdown apps
- **User Choice**: Appears in "Open With" menu

## Implementation Strategy

### Development Phases

1. **Phase 1 - Info.plist Configuration**
   - Add CFBundleDocumentTypes entries
   - Define supported UTIs and extensions
   - Set handler rank appropriately

2. **Phase 2 - AppDelegate Updates**
   - Enhance application(_:open:) method
   - Add file queue for startup handling
   - Improve path processing

3. **Phase 3 - Testing & Polish**
   - Test with various file types
   - Verify "Open With" menu appearance
   - Ensure proper icon display

### Risk Mitigation
- **Testing**: Verify on clean macOS installations
- **Compatibility**: Test alongside other markdown apps
- **Code Signing**: Ensure proper signing for registration
- **Documentation**: Clear user instructions

### Testing Approach
- Manual testing of right-click menu
- Multiple file selection testing
- Default app setting verification
- Cross-version macOS testing

## Task Breakdown Preview

Minimal task set for complete implementation:
- [ ] Configure Info.plist with document types and UTIs
- [ ] Enhance AppDelegate file opening methods
- [ ] Add document type icons to Resources
- [ ] Test Launch Services registration
- [ ] Verify multi-file handling
- [ ] Document user instructions

## Dependencies

### External Dependencies
- None - using only native macOS capabilities

### Internal Dependencies
- Existing AppDelegate implementation
- Current file opening logic in MarkdownViewController
- App bundle structure and resources

### Prerequisite Work
- Ensure app is properly code-signed
- Have app bundle identifier configured

## Success Criteria (Technical)

### Performance Benchmarks
- Registration completes in < 100ms
- File opening from Finder < 500ms
- No UI blocking during file operations
- Smooth handling of 10+ files

### Quality Gates
- Appears in all "Open With" menus
- Respects user's default app choice
- Handles all markdown extensions
- No crashes from malformed paths

### Acceptance Criteria
- Right-click shows Parchment option
- Double-click works when set as default
- Multiple file selection supported
- File associations persist after updates
- Icons display correctly in Finder

## Estimated Effort

### Overall Timeline
- **Configuration**: 0.5 days
- **Code Updates**: 1 day
- **Testing**: 1 day
- **Documentation**: 0.5 days
- **Total**: 3 days

### Resource Requirements
- 1 developer
- Multiple macOS test environments
- Various markdown file samples

### Critical Path Items
1. Info.plist configuration (enables everything)
2. AppDelegate file handling (core functionality)
3. Testing on clean system (validation)