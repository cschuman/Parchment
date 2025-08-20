# TODO List

## Codebase TODOs

These TODOs are found in the current codebase and need to be addressed:

### Theme System
- [ ] **Theme customization panel** - `Sources/Parchment/Views/ThemeSelectorWindow.swift:249`
  - Implement UI for customizing theme colors, fonts, and styles
  - Priority: Medium
  
- [ ] **Custom theme loading** - `Sources/Parchment/Theme/ThemeManager.swift:231`
  - Implement loading custom themes from JSON files
  - Priority: Low
  
- [ ] **Custom theme saving** - `Sources/Parchment/Theme/ThemeManager.swift:264`
  - Implement saving custom themes to JSON files
  - Priority: Low

### Performance
- [ ] **Cache limiting for low memory** - `Sources/Parchment/Utilities/PerformanceOptimizer.swift:216`
  - Implement cache size limits when system memory is low
  - Priority: Medium

## Bug Fixes

### High Priority
- [ ] Fix occasional crash when opening very large files (>50MB)
- [ ] Fix table rendering alignment issues with complex tables
- [ ] Fix image loading timeout for slow network connections

### Medium Priority
- [x] Fix scroll position not preserved when live-reloading ✅
- [x] Fix TOC not updating when document structure changes ✅
- [x] Fix keyboard shortcuts not working in full-screen mode ✅

### Low Priority
- [ ] Fix minor memory leak in image cache
- [ ] Fix occasional flicker when switching themes
- [ ] Fix RTF export not preserving all formatting

## Performance Improvements

- [ ] Optimize initial render time for documents with many images
- [ ] Reduce memory usage for cached rendered content
- [ ] Improve scroll performance for documents with complex tables
- [ ] Add lazy loading for images below the fold

## Testing

### Unit Tests
- [ ] Add tests for markdown parsing edge cases
- [ ] Add tests for theme switching logic
- [ ] Add tests for export functionality
- [ ] Add tests for file watching

### Integration Tests
- [ ] Test multi-file workflows
- [ ] Test keyboard navigation
- [x] Test drag and drop functionality ✅
- [ ] Test performance with various file sizes

### UI Tests
- [ ] Test preference window interactions
- [ ] Test search functionality
- [ ] Test TOC navigation
- [ ] Test context menus

## Documentation

- [ ] Create user guide/manual
- [ ] Add inline code documentation
- [ ] Create API documentation for future plugin system
- [ ] Add troubleshooting guide
- [ ] Create video tutorials

## Build & Release

- [ ] Set up GitHub Actions CI/CD
- [ ] Implement automatic version bumping
- [ ] Create release notes automation
- [ ] Set up code signing workflow
- [ ] Implement crash reporting

## Refactoring

- [ ] Further break down MarkdownViewController (currently 900+ lines)
- [ ] Extract search functionality into separate class
- [ ] Create proper view models for MVVM pattern
- [ ] Consolidate duplicate image loading code
- [ ] Improve error handling consistency

## Future Considerations

These are ideas to explore but not committed to:

- [ ] Investigate WebKit vs NSTextView for rendering
- [ ] Research incremental parsing for better performance
- [ ] Explore Core Data for document metadata
- [ ] Consider CloudKit for sync functionality
- [ ] Evaluate Catalyst for iPad version

## Completed Recently ✅

- [x] Removed overengineered features (Metal, plugins, graph viz)
- [x] Simplified codebase from 18k to 8.8k lines
- [x] Added proper logging with os.log
- [x] Broke up 1829-line god object
- [x] Added real test coverage
- [x] Removed debug fputs statements
- [x] Added preferences window
- [x] Implemented search functionality
- [x] Implemented drag and drop support for markdown files

---

*Last Updated: August 2025*  
*Review Frequency: Weekly*