---
name: quick-look
status: backlog
created: 2025-08-22T02:25:49Z
progress: 0%
prd: .claude/prds/quick-look.md
github: [Will be updated when synced to GitHub]
---

# Epic: Quick Look Support

## Overview

Implement a Quick Look plugin (.qlgenerator) that renders markdown files as HTML when users press spacebar in Finder. The solution reuses Parchment's existing markdown parsing capabilities, wraps them in a minimal Quick Look extension, and provides instant previews without launching the full application.

## Architecture Decisions

### Key Technical Decisions
- **Minimal Plugin Architecture**: Create lightweight .qlgenerator bundle using existing swift-markdown parser
- **Static HTML Generation**: Convert markdown to self-contained HTML (no external resources)
- **Shared Rendering Logic**: Extract core markdown rendering from main app for reuse
- **Template-Based Styling**: Single CSS template embedded in plugin resources
- **No WebKit Dependency**: Use Quick Look's built-in HTML renderer

### Technology Choices
- Quick Look Generator API (native macOS)
- Existing swift-markdown parser from main app
- Embedded CSS for styling (no external stylesheets)
- Standard HTML5 for output

### Design Patterns
- Plugin architecture (.qlgenerator bundle)
- Template pattern for HTML generation
- Factory pattern for preview creation
- Cache-aside pattern for performance

## Technical Approach

### Plugin Components
- **Quick Look Extension**: Minimal QLPreviewingController implementation
- **Markdown Renderer**: Reuse existing parser with HTML output adapter
- **Resource Bundle**: CSS template and Info.plist configuration
- **Installation Script**: Copy to ~/Library/QuickLook/

### Rendering Pipeline
- **Parse**: Use swift-markdown to parse file content
- **Transform**: Convert AST to HTML with inline styles
- **Template**: Wrap in HTML template with embedded CSS
- **Return**: Provide NSData to Quick Look for display

### Code Reuse Strategy
- **Shared Module**: Extract markdown parsing to shared framework
- **Conditional Compilation**: Use #if flags for Quick Look specific code
- **Minimal Dependencies**: Only include essential parsing logic

## Implementation Strategy

### Development Phases

1. **Phase 1 - Plugin Shell**
   - Create .qlgenerator bundle structure
   - Configure Info.plist for markdown UTIs
   - Implement basic QLPreviewingController

2. **Phase 2 - Rendering Integration**
   - Extract markdown parsing to shared module
   - Implement HTML generation
   - Add CSS styling template

3. **Phase 3 - Polish & Optimization**
   - Add syntax highlighting for code blocks
   - Implement preview caching
   - Test and optimize performance

### Risk Mitigation
- **Sandboxing**: Design for Quick Look's restricted environment
- **Performance**: Keep plugin under 5MB total size
- **Compatibility**: Test with multiple macOS versions
- **Fallback**: Graceful degradation to plain text

### Testing Approach
- Use qlmanage CLI tool for development testing
- Test with various markdown file sizes
- Verify memory usage stays under 50MB
- Ensure no Finder crashes

## Task Breakdown Preview

Streamlined task list for implementation:
- [ ] Create Quick Look plugin bundle structure and Info.plist
- [ ] Extract markdown rendering to shared module
- [ ] Implement QLPreviewingController with HTML generation
- [ ] Add CSS template and styling resources
- [ ] Implement syntax highlighting for code blocks
- [ ] Create installation script and test deployment
- [ ] Add preview caching for performance
- [ ] Test and validate with qlmanage

## Dependencies

### External Dependencies
- Quick Look framework (system provided)
- swift-markdown (already in project)

### Internal Dependencies
- Existing markdown parsing logic
- Syntax highlighting components (simplified version)

### Prerequisite Work
- Code signing certificate for plugin
- Developer ID for notarization

## Success Criteria (Technical)

### Performance Benchmarks
- Preview generation < 200ms for typical files
- Memory usage < 50MB per preview
- Plugin size < 5MB installed
- Cache hit rate > 80% for repeated previews

### Quality Gates
- No Finder crashes or hangs
- Correct rendering of CommonMark spec
- Proper syntax highlighting display
- Smooth scrolling in preview window

### Acceptance Criteria
- Spacebar triggers markdown preview
- All standard markdown renders correctly
- Code blocks have syntax highlighting
- Preview appears within 200ms
- Works in all Finder view modes
- "Open with Parchment" button functional

## Estimated Effort

### Overall Timeline
- **Core Implementation**: 3 days
- **Integration & Testing**: 2 days
- **Distribution Setup**: 1 day
- **Total**: 6 days

### Resource Requirements
- 1 developer
- Access to multiple macOS versions
- Code signing certificate
- Test markdown files of various sizes

### Critical Path Items
1. Quick Look plugin registration
2. Markdown to HTML conversion
3. Installation and distribution mechanism