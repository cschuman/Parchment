# Parchment Features

## Feature Status Legend
- 🟢 **Implemented** - Feature is complete and working
- 🟡 **In Progress** - Currently being developed
- 🔴 **Planned** - In backlog, not started
- 🟣 **Under Review** - Implemented but needs testing/refinement
- ⚫ **Deprecated** - Removed or will be removed

## Core Features (Implemented) 🟢

### Document Handling
- [x] Open markdown files via File menu
- [x] Open markdown files via drag & drop (window and app icon)
- [x] Recent documents menu
- [x] File watching with live reload
- [x] Support for large files (10MB+)
- [x] Command-line file opening

### Rendering
- [x] Basic markdown syntax (headers, lists, links, etc.)
- [x] Code block syntax highlighting
- [x] Tables with proper alignment
- [x] Images (local and remote)
- [x] Inline code styling
- [x] Blockquotes
- [x] Horizontal rules
- [x] Task lists with checkboxes
- [x] Strikethrough text
- [x] Math expressions (LaTeX)

### Navigation
- [x] Table of Contents sidebar
- [x] Smooth scrolling
- [x] Click to navigate headers
- [x] Search within document (⌘F)
- [x] Go to line functionality

### Export
- [x] Export to PDF
- [x] Export to HTML
- [x] Export to RTF
- [x] Print support

### User Interface
- [x] Light/Dark theme
- [x] Customizable font size
- [x] Preferences window
- [x] Full-screen support
- [x] Window state persistence
- [x] Keyboard shortcuts
- [x] Context menus

### Performance
- [x] Async rendering pipeline
- [x] Image caching
- [x] Render caching
- [x] Efficient scrolling

## Feature Backlog 🔴

### High Priority
- [x] ~~**Drag to app icon** - Drag markdown file onto app icon in Dock/Finder to open~~ ✅ Implemented
- [ ] **Command-line launcher** - Full CLI support (`parchment file.md` from terminal)
- [ ] **Folder browser** - Open folder to browse/navigate between markdown files
- [ ] **Quick Look plugin** - Space bar preview of .md files in Finder
- [ ] **Multi-tab support** - Open multiple documents in tabs
- [ ] **Split view** - View two documents side by side
- [ ] **Markdown editing** - Basic text editing capabilities
- [ ] **Custom CSS** - User-defined stylesheets
- [ ] **Plugin API** - Simple, focused plugin system
- [ ] **Quick switcher** - ⌘P style file switcher
- [ ] **Outline view** - Collapsible document structure

### Medium Priority
- [ ] **Mermaid diagrams** - Render mermaid diagram blocks
- [ ] **PlantUML support** - UML diagram rendering
- [ ] **Custom themes** - User-created color schemes
- [ ] **Export to Markdown** - Clean markdown export
- [ ] **Export to DOCX** - Word document export
- [ ] **Presentation mode** - Slide-like viewing
- [ ] **Reading time estimate** - Calculate reading time
- [ ] **Word/character count** - Document statistics
- [ ] **File tree sidebar** - Browse folder structure
- [ ] **Global search** - Search across multiple files

### Low Priority
- [ ] **Citations/References** - Academic citation support
- [ ] **Footnotes** - Proper footnote rendering
- [ ] **Markdown extensions** - Support for CommonMark, GFM, etc.
- [ ] **Export templates** - Customizable export formats
- [ ] **Touch Bar support** - MacBook Touch Bar integration
- [ ] **AppleScript support** - Automation capabilities
- [ ] **URL scheme handler** - parchment:// URLs
- [ ] **Markdown linting** - Syntax validation
- [ ] **Auto-save** - Periodic document saving

### Nice to Have
- [ ] **Typewriter mode** - Center current line
- [ ] **Focus mode** - Highlight current paragraph
- [ ] **Reading progress** - Visual progress indicator
- [ ] **Bookmarks** - Save positions in documents
- [ ] **Document templates** - Starter templates
- [ ] **Export to ePub** - E-book format
- [ ] **TextBundle support** - TextBundle format
- [ ] **MultiMarkdown** - MMD syntax support
- [ ] **Custom keybindings** - User-defined shortcuts
- [ ] **Vim keybindings** - Vim navigation mode

## Removed Features ⚫

These features were removed during the recovery/simplification phase:

- [x] ~~Metal rendering~~ - Unnecessary complexity
- [x] ~~Plugin system~~ - Over-engineered
- [x] ~~Graph visualization~~ - Out of scope
- [x] ~~Wiki-links~~ - Too specialized
- [x] ~~Backlinks panel~~ - Too specialized
- [x] ~~Bionic reading mode~~ - Gimmicky
- [x] ~~Theater mode~~ - Unnecessary
- [x] ~~Virtual scrolling~~ - Premature optimization
- [x] ~~7 typography modes~~ - Reduced to Light/Dark

## Feature Requests from Users

### Recently Requested (August 2025)
- [x] ~~**Drag to app icon** - Drag file onto Dock/Finder app icon to open~~ ✅ Implemented
- [ ] **CLI launcher** - Full command-line support for opening files
- [ ] **Folder browser** - Open folder to navigate between markdown docs
- [ ] **Quick Look plugin** - Space bar preview in Finder

### Previously Requested
- [ ] Better table editing experience
- [ ] Collapsible sections
- [ ] Sticky headers while scrolling
- [ ] Zoom with ⌘+ and ⌘-
- [ ] Copy as HTML/RTF
- [ ] Open links in default browser
- [ ] Custom fonts selection

## Technical Debt & Improvements

### Code Quality
- [ ] Increase test coverage to 80%
- [ ] Add integration tests
- [ ] Add performance benchmarks
- [ ] Improve error handling
- [ ] Add proper logging levels

### Architecture
- [ ] Further modularize MarkdownViewController
- [ ] Implement proper MVVM pattern
- [ ] Create rendering pipeline abstraction
- [ ] Improve memory management
- [ ] Optimize for Apple Silicon

### Build & Distribution
- [ ] Homebrew formula
- [ ] Mac App Store release
- [ ] Sparkle auto-updater
- [ ] Code signing with Developer ID
- [ ] Notarization for Gatekeeper

## Feature Decision Matrix

When evaluating new features, consider:

| Criteria | Weight | Description |
|----------|--------|-------------|
| **User Value** | 40% | Does this solve a real user problem? |
| **Complexity** | 30% | How much code/maintenance will this add? |
| **Performance** | 20% | Will this impact app speed/responsiveness? |
| **Scope** | 10% | Does this align with "fast, reliable markdown viewer"? |

## Notes

- Features should align with the core mission: "The fastest, most reliable markdown viewer on macOS that just works"
- Avoid feature creep - each addition should be carefully considered
- Performance and reliability always take precedence over new features
- User feedback should drive prioritization