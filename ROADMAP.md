# Parchment Roadmap

## Vision
The premier native markdown viewer for macOS - beautiful, fast, and invisible until you need it.

## Core Principles
1. **Native First** - Leverage macOS APIs for best-in-class performance
2. **Visual Excellence** - Every pixel should be thoughtfully designed
3. **Reading Focus** - Optimize for the reading experience above all else
4. **Simplicity** - Features that enhance, not complicate

## Release Timeline

### v1.1 - "Perfect Polish" (Next 2-4 weeks)
**Theme: Make what we have exceptional**

#### High Priority - Quick Wins
- [x] Enhanced typography with optical sizing ✓
- [x] Smooth spring-physics scrolling ✓ 
- [x] Beautiful built-in themes ✓
- [ ] **Print styles optimization** - Beautiful PDF/print output
  - Proper page breaks at headings
  - Remove UI elements from print
  - Optimized margins and typography for paper
- [ ] **Quick Look thumbnail generation** - Beautiful previews in Finder
- [ ] **Smooth zoom animations** - Pinch-to-zoom with spring physics
- [ ] **Focus mode polish** - Subtle vignette effect, smooth transitions

#### Implementation Priority
1. Connect new components to existing UI
2. Polish animations and transitions
3. Optimize print/export pipeline
4. Performance profiling and optimization

### v1.2 - "Reading Intelligence" (4-6 weeks)
**Theme: Smart features that enhance reading**

#### Reading Progress & Navigation
- [ ] **Reading progress indicators**
  - Subtle progress bar
  - "5 min left in document"
  - Scroll position memory per document
- [ ] **Smart bookmarks**
  - Auto-bookmark on app switch
  - Visual bookmark indicators in scroll bar
  - Bookmark history (last 10 positions)
- [ ] **Enhanced TOC**
  - Mini-map style preview
  - Current section highlighting
  - Breadcrumb navigation bar

#### Visual Enhancements  
- [ ] **Better image handling**
  - Lazy loading with blur-up effect
  - Click to zoom with lightbox
  - Retina optimization
  - Image caching improvements
- [ ] **Code block enhancements**
  - Line numbers option
  - Copy button on hover
  - Language badge
  - Syntax theme matching

### v1.3 - "Professional Polish" (6-8 weeks)
**Theme: Features for power users**

#### Export Excellence
- [ ] **PDF export with perfect fidelity**
  - Preserve syntax highlighting
  - Embed fonts
  - Generate TOC/bookmarks
  - Custom headers/footers
- [ ] **Export templates**
  - Academic paper style
  - GitHub README style
  - Book manuscript style
  - Custom CSS injection

#### Advanced Features
- [ ] **Split view** - Compare two documents side by side
- [ ] **Presentation mode** - Full screen, large type, arrow key navigation
- [ ] **Reading statistics dashboard** - Time spent, words per minute, heat map
- [ ] **Custom keyboard shortcuts** - User-definable shortcuts

### v2.0 - "Platform Integration" (3-6 months)
**Theme: Deep macOS integration**

#### System Integration
- [ ] **Spotlight integration** - Index and search markdown content
- [ ] **Quick Actions** - Right-click services in Finder
- [ ] **Handoff support** - Continue reading on iOS (future companion app)
- [ ] **Stage Manager optimization** - Perfect window management
- [ ] **System text services** - Dictionary lookup, translation

#### Modern Mac Features
- [ ] **Live Text in images** - OCR for images in markdown
- [ ] **Shortcuts app integration** - Automation support
- [ ] **Focus filters** - Different themes for different Focus modes
- [ ] **SharePlay** - Read together over FaceTime

### Future Considerations

#### Potential Features (Not Committed)
- iOS/iPadOS companion app (requires significant investment)
- CloudKit sync (only if iOS app exists)
- Plugin architecture (may complicate simplicity)
- AI features (summarization, Q&A) - watching market

#### Explicitly Not Doing
- ❌ Wiki-links/Knowledge graphs (not our focus)
- ❌ Editing capabilities (viewer only)
- ❌ Note-taking features (stay focused)
- ❌ Collaboration features (different market)
- ❌ Cross-platform (Windows/Linux)

## Success Metrics

### Performance Targets
- App launch: <100ms
- Document open: <50ms for 99% of files
- Scroll performance: Consistent 120fps on ProMotion
- Memory: <50MB for typical document
- Battery: Minimal energy impact rating

### Quality Metrics  
- Crash-free rate: >99.9%
- App Store rating: >4.8 stars
- User retention: >80% weekly active

### Design Excellence
- Every animation at 60-120fps
- Consistent spring physics throughout
- Perfect typography at all zoom levels
- Pixel-perfect rendering on Retina displays

## Development Philosophy

### When Adding Features
Ask yourself:
1. Does this make reading markdown better?
2. Does this maintain our simplicity?
3. Is this truly native to macOS?
4. Would Steve Jobs ship this?

### Code Quality Standards
- Performance over features
- Native APIs over custom solutions
- Swift idioms and best practices
- Comprehensive error handling
- Accessibility from day one

## Community & Feedback

### Feedback Channels
- GitHub Issues for bugs/features
- Twitter/X for quick feedback
- App Store reviews for user sentiment
- Direct email for power users

### Open Source Strategy
- Core viewer remains open source
- Premium themes as potential revenue
- Sponsor program for sustainable development

---

*"The best markdown viewer is the one you forget you're using."*