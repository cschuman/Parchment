# Parchment Roadmap

## Vision
**Parchment**: The fastest, most reliable markdown viewer on macOS that just works.

## Development Principles
1. **Performance First** - Every feature must maintain sub-500ms file open times
2. **Reliability** - Features must work 100% of the time
3. **Simplicity** - Avoid complexity that doesn't directly benefit users
4. **Native Feel** - Leverage macOS capabilities, follow Apple HIG

## Release Timeline

### Version 1.0 - Foundation (Current)
**Status:** ✅ Complete  
**Focus:** Core viewing experience

Achievements:
- Fast, reliable markdown rendering
- Clean, native macOS interface
- Basic export capabilities
- Preferences and customization
- Search functionality

### Version 1.1 - Enhanced Navigation (Q1 2025)
**Status:** 🔴 Planned  
**Timeline:** 4-6 weeks  
**Theme:** Better document navigation

Features:
- [ ] Multi-tab support for multiple documents
- [ ] Quick file switcher (⌘P)
- [ ] Improved Table of Contents with collapsible sections
- [ ] Bookmarks within documents
- [ ] Enhanced search with regex support

Success Metrics:
- Switch between 10 tabs without lag
- Quick switcher opens in <100ms
- Zero crashes with 20+ tabs open

### Version 1.2 - Visual Enhancements (Q2 2025)
**Status:** 🔴 Planned  
**Timeline:** 6-8 weeks  
**Theme:** Better visual presentation

Features:
- [ ] Mermaid diagram support
- [ ] Custom CSS stylesheets
- [ ] Additional built-in themes (3-5 total)
- [ ] Improved math rendering
- [ ] Better image handling (zoom, galleries)

Success Metrics:
- Render complex diagrams in <1s
- Theme switching without reload
- Support images up to 50MB

### Version 1.3 - Productivity Features (Q2 2025)
**Status:** 🔴 Planned  
**Timeline:** 4-6 weeks  
**Theme:** Power user features

Features:
- [ ] Split view (2 documents side by side)
- [ ] Document statistics (word count, reading time)
- [ ] Export to DOCX
- [ ] Custom keyboard shortcuts
- [ ] Basic editing capabilities

Success Metrics:
- Split view maintains 60fps scrolling
- Export accuracy >95%
- Edit/preview toggle <100ms

### Version 1.4 - Integration (Q3 2025)
**Status:** 🔴 Planned  
**Timeline:** 6-8 weeks  
**Theme:** Ecosystem integration

Features:
- [ ] File tree sidebar
- [ ] Global search across files
- [ ] Quick Look plugin
- [ ] URL scheme handler
- [ ] Basic plugin API

Success Metrics:
- Search 1000 files in <3s
- Plugin load time <50ms
- Quick Look preview in <200ms

### Version 2.0 - Professional (Q4 2025)
**Status:** 🔴 Planned  
**Timeline:** 8-10 weeks  
**Theme:** Professional workflows

Features:
- [ ] Presentation mode
- [ ] Export templates
- [ ] Citation management
- [ ] TextBundle support
- [ ] AppleScript automation

Success Metrics:
- Support documents >100MB
- 99.9% uptime
- <0.1% crash rate

## Immediate Priorities (Next 30 Days)

### Week 1-2: Foundation Improvements
- [ ] Fix any critical bugs from user feedback
- [ ] Optimize memory usage for large files
- [ ] Improve error messages and recovery

### Week 3-4: Multi-tab Implementation
- [ ] Design tab UI following macOS conventions
- [ ] Implement tab management logic
- [ ] Add keyboard shortcuts for tab navigation
- [ ] Test with 20+ tabs

## Technical Roadmap

### Q1 2025: Architecture
- [ ] Complete modularization of MarkdownViewController
- [ ] Implement proper document model
- [ ] Create plugin architecture foundation
- [ ] Add comprehensive logging

### Q2 2025: Performance
- [ ] Optimize for Apple Silicon
- [ ] Implement smarter caching strategies
- [ ] Add performance monitoring
- [ ] Reduce memory footprint by 30%

### Q3 2025: Quality
- [ ] Achieve 80% test coverage
- [ ] Add integration test suite
- [ ] Implement crash reporting
- [ ] Add analytics (privacy-focused)

### Q4 2025: Distribution
- [ ] Mac App Store submission
- [ ] Homebrew formula
- [ ] Auto-updater (Sparkle)
- [ ] Beta testing program

## Distribution Strategy

### Phase 1: Direct Distribution (Current)
- GitHub releases
- Direct download from website
- Manual updates

### Phase 2: Package Managers (Q2 2025)
- Homebrew cask
- MacPorts

### Phase 3: App Store (Q4 2025)
- Mac App Store
- Setapp (evaluate)

## Success Metrics

### Performance
- File open time: <500ms for 10MB files
- Scroll performance: Consistent 60fps
- Memory usage: <100MB for typical documents
- CPU usage: <5% when idle

### Quality
- Crash rate: <0.1%
- User rating: >4.5 stars
- Test coverage: >80%
- Bug fix time: <48 hours for critical issues

### Adoption
- Month 3: 1,000 active users
- Month 6: 5,000 active users
- Month 12: 20,000 active users

## Risk Mitigation

### Technical Risks
- **Performance degradation**: Continuous benchmarking
- **Feature creep**: Strict feature evaluation matrix
- **Technical debt**: 20% time allocation for refactoring

### Market Risks
- **Competition**: Focus on speed and reliability differentiators
- **Platform changes**: Stay current with macOS betas
- **User adoption**: Focus on core user needs

## Community Engagement

### Open Source
- Keep core viewer open source
- Accept community contributions
- Maintain clear contribution guidelines

### Feedback Channels
- GitHub issues for bugs
- Discussion forum for features
- Beta testing program
- User surveys quarterly

## Revenue Model (Future)

### Freemium Approach (v2.0+)
- **Free**: Core viewing, basic export
- **Pro**: Advanced features, priority support
- **Team**: Collaboration features, admin tools

### Pricing Strategy
- Free forever for basic use
- Pro: $19.99 one-time
- Team: $9.99/user/month

## Long-term Vision (2-3 Years)

### Potential Expansions
- iOS/iPadOS companion app
- Cloud sync via iCloud
- Collaboration features
- AI-powered features (summaries, etc.)
- Windows/Linux versions

### Maintain Focus
- Never compromise on performance
- Keep core product simple
- Listen to users but maintain vision
- Quality over quantity

---

*Last Updated: August 2025*  
*Next Review: September 2025*