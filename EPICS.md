# Parchment Development Epics

## Epic Structure
Each epic follows this format:
- **Goal**: Clear business/user value
- **Success Criteria**: Measurable outcomes
- **User Stories**: Specific features/tasks
- **Dependencies**: What must come before
- **Estimated Effort**: T-shirt sizing (S/M/L/XL)

---

## 🎨 Epic 1: Typography & Visual Excellence
**Status**: 🟡 In Progress  
**Priority**: P0 (Critical)  
**Target Release**: v1.1  
**Effort**: L (Large)  

### Goal
Transform Parchment into the most visually beautiful markdown viewer on macOS with exceptional typography and readability.

### Success Criteria
- [ ] Typography system with optical sizing implemented
- [ ] Golden ratio heading scales active
- [ ] Line height and spacing optimized for readability
- [ ] Kerning and ligatures properly rendered
- [ ] All text renders crisp on Retina displays

### User Stories
```
✅ DONE: As a reader, I want beautiful typography so that reading is effortless
- [x] Create TypographyEngine.swift with optical sizing
- [x] Implement golden ratio heading scales
- [x] Add kerning and ligature support

🚧 TODO: Integration & Polish
- [ ] Integrate TypographyEngine with MarkdownAttributedStringVisitor
- [ ] Add font preference UI in Preferences window
- [ ] Implement dynamic type support for accessibility
- [ ] Add custom font loading from system
- [ ] Create font preview in preferences
```

### Technical Tasks
- [ ] Replace current font handling in MarkdownAttributedStringVisitor
- [ ] Add UserDefaults for typography preferences
- [ ] Implement font caching for performance
- [ ] Add unit tests for typography engine
- [ ] Profile and optimize attributed string generation

### Dependencies
- None (foundational epic)

---

## ⚡ Epic 2: Performance Optimization
**Status**: 🟡 In Progress  
**Priority**: P0 (Critical)  
**Target Release**: v1.1  
**Effort**: M (Medium)  

### Goal
Achieve industry-leading performance with <50ms file opening and 120fps scrolling on all Mac hardware.

### Success Criteria
- [ ] 99% of files under 10MB open in <50ms
- [ ] Consistent 120fps scrolling on ProMotion displays
- [ ] Memory usage <50MB for typical documents
- [ ] No beach balls or UI freezes ever

### User Stories
```
✅ DONE: Fast file opening foundation
- [x] Create FastFileOpener with parallel processing
- [x] Implement smart caching system
- [x] Add memory-mapped file reading

🚧 TODO: Integration & Optimization
- [ ] Replace current file opening with FastFileOpener
- [ ] Implement progressive rendering for large files
- [ ] Add render cancellation for quick file switching
- [ ] Optimize syntax highlighting performance
- [ ] Implement virtual scrolling for huge documents
```

### Technical Tasks
- [ ] Profile current bottlenecks with Instruments
- [ ] Implement lazy image loading
- [ ] Add WebP/AVIF image support
- [ ] Cache rendered attributed strings
- [ ] Optimize table rendering performance
- [ ] Add performance regression tests

### Dependencies
- Typography epic (for rendering optimization)

---

## 🎭 Epic 3: Smooth Animations & Physics
**Status**: 🟡 In Progress  
**Priority**: P1 (High)  
**Target Release**: v1.1  
**Effort**: M (Medium)  

### Goal
Create delightful, iOS-quality animations throughout the app with consistent spring physics.

### Success Criteria
- [ ] All scrolling uses spring physics
- [ ] Zoom animations are smooth and natural
- [ ] View transitions have consistent timing
- [ ] No jarring or instant changes
- [ ] Animations run at 60-120fps

### User Stories
```
✅ DONE: Physics foundation
- [x] Create SmoothScrollManager with spring physics
- [x] Implement rubber banding and momentum

🚧 TODO: Integration & Polish
- [ ] Wire up SmoothScrollManager to main scroll view
- [ ] Add smooth zoom with pinch gestures
- [ ] Implement smooth TOC navigation
- [ ] Add view transition animations
- [ ] Create focus mode fade animations
```

### Technical Tasks
- [ ] Integrate CVDisplayLink with scroll view
- [ ] Add gesture recognizers for smooth zoom
- [ ] Implement CASpringAnimation for UI transitions
- [ ] Add interruption handling for animations
- [ ] Create animation settings in preferences
- [ ] Profile animation performance

### Dependencies
- None (can be developed in parallel)

---

## 🎨 Epic 4: Theme System
**Status**: 🟡 In Progress  
**Priority**: P1 (High)  
**Target Release**: v1.1  
**Effort**: S (Small)  

### Goal
Ship with 5 beautiful, hand-crafted themes that showcase the renderer's capabilities.

### Success Criteria
- [ ] 5 distinct themes shipped
- [ ] Instant theme switching without flicker
- [ ] Themes persist across launches
- [ ] Each theme is visually cohesive
- [ ] Accessibility theme included

### User Stories
```
✅ DONE: Theme foundation
- [x] Create ParchmentThemes.swift with 5 themes
- [x] Define theme structure and properties

🚧 TODO: Integration & UI
- [ ] Add theme picker UI
- [ ] Implement live theme preview
- [ ] Wire up theme switching
- [ ] Add theme hotkeys (⌘1-5)
- [ ] Create smooth theme transition
```

### Technical Tasks
- [ ] Create ThemePickerViewController
- [ ] Add theme menu in View menu
- [ ] Implement theme persistence
- [ ] Apply themes to all UI components
- [ ] Add theme export/import (future)
- [ ] Test themes with various content

### Dependencies
- Typography epic (themes include font settings)

---

## 📄 Epic 5: Export & Print Pipeline
**Status**: 🔴 Not Started  
**Priority**: P1 (High)  
**Target Release**: v1.2  
**Effort**: L (Large)  

### Goal
Perfect PDF export and printing with beautiful formatting that preserves syntax highlighting and images.

### Success Criteria
- [ ] PDF export preserves all formatting
- [ ] Syntax highlighting in exports
- [ ] Custom headers/footers supported
- [ ] Print preview accurate
- [ ] Page breaks at logical points

### User Stories
```
As a user, I want to export/print documents that look as good as on screen
- [ ] Export to PDF with perfect fidelity
- [ ] Print with optimized formatting
- [ ] Export to HTML with inline styles
- [ ] Export to DOCX (stretch goal)
- [ ] Custom CSS injection for exports
```

### Technical Tasks
- [ ] Implement NSPrintOperation customization
- [ ] Create PDF generation pipeline
- [ ] Add page break logic at headings
- [ ] Implement print stylesheets
- [ ] Create export options dialog
- [ ] Add watermark/header support
- [ ] Test with various printers

### Dependencies
- Typography epic (for print typography)
- Theme system (for export styling)

---

## 📖 Epic 6: Reading Intelligence
**Status**: 🔴 Not Started  
**Priority**: P2 (Medium)  
**Target Release**: v1.2  
**Effort**: L (Large)  

### Goal
Add smart features that enhance the reading experience without adding complexity.

### Success Criteria
- [ ] Reading progress tracked per document
- [ ] Auto-bookmarking works reliably
- [ ] Reading time estimates accurate
- [ ] Progress indicators subtle but useful

### User Stories
```
As a reader, I want the app to remember where I was
- [ ] Show reading progress bar
- [ ] Auto-bookmark on app switch
- [ ] Display "5 min left" indicator
- [ ] Remember scroll position per file
- [ ] Show bookmark history
- [ ] Add reading statistics
```

### Technical Tasks
- [ ] Create ReadingProgressTracker
- [ ] Implement bookmark storage (Core Data?)
- [ ] Add progress UI overlay
- [ ] Calculate accurate reading time
- [ ] Create bookmark manager UI
- [ ] Add reading heat map (future)

### Dependencies
- Performance epic (needs efficient tracking)

---

## 🖥️ Epic 7: macOS Platform Integration
**Status**: 🔴 Not Started  
**Priority**: P3 (Low)  
**Target Release**: v2.0  
**Effort**: XL (Extra Large)  

### Goal
Deep integration with macOS features to feel like a first-party Apple application.

### Success Criteria
- [ ] Spotlight indexes markdown content
- [ ] Quick Actions in Finder work
- [ ] Handoff ready for future iOS app
- [ ] Stage Manager optimized
- [ ] System services integrated

### User Stories
```
As a Mac power user, I want Parchment to integrate with the OS
- [ ] Search markdown content in Spotlight
- [ ] Use Quick Actions in Finder
- [ ] Dictionary lookup in documents
- [ ] Share sheets for content
- [ ] Shortcuts app integration
- [ ] Focus mode integration
```

### Technical Tasks
- [ ] Implement Spotlight indexer
- [ ] Create Quick Action extensions
- [ ] Add NSUserActivity for Handoff
- [ ] Implement system text services
- [ ] Add Shortcuts intents
- [ ] Test with Stage Manager

### Dependencies
- All core epics complete
- Requires macOS 13+ APIs

---

## 🐛 Epic 8: Quality & Polish
**Status**: 🟢 Ongoing  
**Priority**: P0 (Critical)  
**Target Release**: Every release  
**Effort**: M (Medium)  

### Goal
Achieve exceptional quality with >99.9% crash-free rate and delightful attention to detail.

### Success Criteria
- [ ] Crash-free rate >99.9%
- [ ] All animations 60fps+
- [ ] No memory leaks
- [ ] Accessibility complete
- [ ] Error handling graceful

### User Stories
```
As a user, I expect perfect reliability
- [ ] Fix all crash reports
- [ ] Handle edge cases gracefully
- [ ] Add helpful error messages
- [ ] Implement crash reporting
- [ ] Add analytics (privacy-friendly)
- [ ] Create onboarding experience
```

### Technical Tasks
- [ ] Add Sentry or similar crash reporting
- [ ] Implement proper error boundaries
- [ ] Add unit test coverage >80%
- [ ] Create UI tests for critical paths
- [ ] Add performance benchmarks
- [ ] Regular profiling with Instruments

### Dependencies
- Continuous throughout development

---

## 📊 Epic Prioritization Matrix

### Must Have (v1.1)
1. **Typography & Visual Excellence** - Core differentiator
2. **Performance Optimization** - Table stakes
3. **Smooth Animations** - Premium feel
4. **Theme System** - Visual variety

### Should Have (v1.2)
5. **Export & Print Pipeline** - Professional use
6. **Reading Intelligence** - Differentiation

### Nice to Have (v2.0)
7. **macOS Platform Integration** - Long-term vision

### Ongoing
8. **Quality & Polish** - Continuous improvement

---

## 🚀 Implementation Order

### Phase 1: Foundation (Week 1-2)
- Complete Typography integration
- Wire up Performance optimizations
- Integrate Smooth animations
- Ship Theme system

### Phase 2: Polish (Week 3-4)
- Export pipeline basics
- Print optimization
- Bug fixes from Phase 1
- Performance tuning

### Phase 3: Intelligence (Week 5-8)
- Reading progress
- Bookmarking system
- Statistics dashboard
- User feedback integration

### Phase 4: Platform (Month 3+)
- macOS integrations
- Advanced features
- Market expansion

---

## 📈 Success Metrics

### Per Epic KPIs
- **Typography**: Time to first readable text <100ms
- **Performance**: P95 file open <50ms
- **Animations**: Consistent 120fps on M1+
- **Themes**: <16ms theme switch time
- **Export**: <2s PDF generation for 50-page doc
- **Reading**: 90% bookmark restoration accuracy
- **Platform**: All system integrations functional
- **Quality**: >4.8 App Store rating

---

*Last Updated: [Current Date]*
*Next Review: [Weekly Sprint Planning]*