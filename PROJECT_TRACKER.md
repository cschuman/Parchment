# Parchment v2.0 Project Tracker

> Check items off as they are completed. This is the source of truth for project progress.

**Started**: December 2024
**Target**: Q4 2025

---

## Phase 1: "Make It Work" (Q1 2025)

### 1.1 Fix Focus Mode Discovery
- [ ] Add Cmd+Shift+F keyboard shortcut to menu
- [ ] Update AppDelegate menu item with keyEquivalent
- [ ] Enable typewriter scrolling in Focus Mode
- [ ] Add first-use tooltip (UserDefaults flag)
- [ ] Test shortcut works correctly
- [ ] **DONE: Focus Mode Discovery**

### 1.2 Auto Dark/Light Mode
- [ ] Add "Follow System Appearance" preference
- [ ] Implement appearance change observer
- [ ] Map light appearance → Minimal theme
- [ ] Map dark appearance → Midnight theme
- [ ] Add smooth transition animation (0.3s)
- [ ] Add preference UI in Preferences window
- [ ] Test appearance switching
- [ ] **DONE: Auto Dark/Light Mode**

### 1.3 Reading Position Restoration
- [ ] Create ReadingPositionManager service
- [ ] Save scroll percentage on scroll end (debounced)
- [ ] Load and restore position on document open
- [ ] Implement LRU cache (100 documents max)
- [ ] Add "Resumed at X%" toast notification
- [ ] Animate scroll to restored position
- [ ] Test with multiple documents
- [ ] **DONE: Reading Position Restoration**

### 1.4 Transform Status Bar
- [ ] Remove parse time label
- [ ] Remove render time label
- [ ] Remove cache hit rate label
- [ ] Add word count label
- [ ] Add reading time estimate label (@ 200 WPM)
- [ ] Add scroll progress percentage label
- [ ] Update progress in real-time on scroll
- [ ] Test status bar updates
- [ ] **DONE: Transform Status Bar**

### 1.5 LaTeX/Math Rendering
- [ ] Research: Choose KaTeX vs MathJax vs native
- [ ] Create MathRenderer service
- [ ] Implement inline math detection ($...$)
- [ ] Implement block math detection ($$...$$)
- [ ] Render math via WebKit/KaTeX
- [ ] Cache rendered math as images
- [ ] Integrate with EnhancedMarkdownRenderer
- [ ] Add graceful fallback on render error
- [ ] Test with complex equations
- [ ] Performance test (<100ms per equation)
- [ ] **DONE: LaTeX/Math Rendering**

### 1.6 Mermaid Diagram Support
- [ ] Create MermaidRenderer service
- [ ] Bundle Mermaid.js or load from CDN
- [ ] Detect ```mermaid code blocks
- [ ] Render diagrams via WebKit
- [ ] Cache rendered diagrams by content hash
- [ ] Support light/dark theme variants
- [ ] Show placeholder during render
- [ ] Test flowcharts
- [ ] Test sequence diagrams
- [ ] Test other diagram types
- [ ] **DONE: Mermaid Diagram Support**

### 1.7 Complete GFM Support
- [ ] Task lists: Render - [ ] as checkbox
- [ ] Task lists: Render - [x] as checked checkbox
- [ ] Footnotes: Collect footnote definitions
- [ ] Footnotes: Render footnote references as links
- [ ] Footnotes: Render footnote section at bottom
- [ ] Emoji shortcodes: Add conversion dictionary
- [ ] Emoji shortcodes: Replace :name: with emoji
- [ ] Verify autolinks working
- [ ] Verify strikethrough working
- [ ] Test all GFM features together
- [ ] **DONE: Complete GFM Support**

### 1.8 Keyboard Navigation
- [ ] Add Cmd+] menu item (Next Header)
- [ ] Add Cmd+[ menu item (Previous Header)
- [ ] Add Cmd+Up menu item (Jump to Top)
- [ ] Add Cmd+Down menu item (Jump to Bottom)
- [ ] Implement jumpToNextHeader()
- [ ] Implement jumpToPreviousHeader()
- [ ] Implement jumpToTop()
- [ ] Implement jumpToBottom()
- [ ] Add smooth scroll animation
- [ ] Test all navigation shortcuts
- [ ] **DONE: Keyboard Navigation**

### 1.9 Contextual Onboarding
- [ ] Create OnboardingManager service
- [ ] Add UserDefaults flags for each tip
- [ ] First TOC open: Show navigation tip
- [ ] First Focus Mode: Show explanation
- [ ] First theme change: Show auto-switch tip
- [ ] Make tooltips dismissible
- [ ] Test onboarding flow
- [ ] **DONE: Contextual Onboarding**

---

## Phase 1 Completion Checklist
- [ ] All Phase 1 features implemented
- [ ] All Phase 1 tests passing
- [ ] Performance benchmarks met
- [ ] Build and run successfully
- [ ] Manual QA complete
- [ ] **PHASE 1 COMPLETE**

---

## Phase 2: "Make It Delightful" (Q2 2025)

### 2.1 Optical Font Weight Adjustment
- [ ] Implement opticalWeight() function
- [ ] Integrate with TypographyEngine
- [ ] Reduce weight for headings >28pt
- [ ] Lighten weight in dark themes
- [ ] Test across all themes
- [ ] **DONE: Optical Font Weights**

### 2.2 Reading Mode (Distraction-Free)
- [ ] Add keyboard shortcut (Cmd+Ctrl+F or similar)
- [ ] Hide status bar in reading mode
- [ ] Hide toolbar in reading mode
- [ ] Hide TOC in reading mode
- [ ] Center text column (max 680pt)
- [ ] Enter full screen
- [ ] Escape key exits reading mode
- [ ] Add smooth fade transition
- [ ] **DONE: Reading Mode**

### 2.3 Reading Progress Indicator
- [ ] Create ReadingProgressView
- [ ] Position on right edge (2pt wide)
- [ ] Calculate progress from scroll position
- [ ] Use theme-aware color (30% opacity)
- [ ] Fade in on scroll start
- [ ] Fade out after 1.5s idle
- [ ] Test with long documents
- [ ] **DONE: Reading Progress Indicator**

### 2.4 Smooth Theme Transitions
- [ ] Replace instant theme switch with animation
- [ ] Implement 0.3s cross-fade
- [ ] Maintain scroll position during transition
- [ ] Test all theme combinations
- [ ] No flash or flicker
- [ ] **DONE: Smooth Theme Transitions**

### 2.5 Link Hover Previews
- [ ] Detect mouse hover on links
- [ ] Show tooltip with URL after 0.5s delay
- [ ] Style tooltip to match theme
- [ ] Fade in over 0.15s
- [ ] **DONE: Link Hover Previews**

### 2.6 Document Loading Animation
- [ ] Show skeleton/placeholder for 100ms
- [ ] Fade in content over 200ms
- [ ] Subtle top-to-bottom reveal
- [ ] **DONE: Document Loading Animation**

### 2.7 Enhanced Find
- [ ] Add regex search option
- [ ] Add "headers only" search option
- [ ] Show match context preview
- [ ] **DONE: Enhanced Find**

### 2.8 New Themes
- [ ] Implement Dracula theme
- [ ] Implement Nord theme
- [ ] Implement Solarized Light theme
- [ ] Add to theme picker
- [ ] Test all new themes
- [ ] **DONE: New Themes**

---

## Phase 2 Completion Checklist
- [ ] All Phase 2 features implemented
- [ ] All Phase 2 tests passing
- [ ] Visual polish approved
- [ ] **PHASE 2 COMPLETE**

---

## Phase 3: "Make It Essential" (Q3-Q4 2025)

### 3.1 CLI Tool
- [ ] Verify argument parsing works
- [ ] Add --help output
- [ ] Add --version output
- [ ] Create Homebrew formula
- [ ] Test `parchment file.md` command
- [ ] Test opening in existing instance
- [ ] Submit to Homebrew
- [ ] **DONE: CLI Tool**

### 3.2 VS Code Extension
- [ ] Create extension project
- [ ] Implement "Open in Parchment" command
- [ ] Add context menu for .md files
- [ ] Configure keyboard shortcut
- [ ] Test with VS Code
- [ ] Publish to VS Code Marketplace
- [ ] **DONE: VS Code Extension**

### 3.3 Alfred/Raycast Integration
- [ ] Create Alfred workflow
- [ ] Create Raycast extension
- [ ] Test integrations
- [ ] Publish to respective stores
- [ ] **DONE: Alfred/Raycast Integration**

### 3.4 Custom CSS Themes
- [ ] Define theme directory location
- [ ] Scan for custom theme files
- [ ] Load and validate CSS
- [ ] Apply CSS to rendered output
- [ ] Show custom themes in picker
- [ ] Create template CSS file
- [ ] Document theme format
- [ ] **DONE: Custom CSS Themes**

### 3.5 Touch Bar Support
- [ ] Design Touch Bar layout
- [ ] Implement theme switching
- [ ] Implement navigation controls
- [ ] Test on Touch Bar Mac
- [ ] **DONE: Touch Bar Support**

### 3.6 Shortcuts App Actions
- [ ] Define Shortcuts intents
- [ ] Implement "Open Document" action
- [ ] Implement "Export Document" action
- [ ] Test with Shortcuts app
- [ ] **DONE: Shortcuts App Actions**

### 3.7 Spotlight Integration
- [ ] Implement Spotlight importer
- [ ] Index document content
- [ ] Index document metadata
- [ ] Test Spotlight search
- [ ] **DONE: Spotlight Integration**

---

## Phase 3 Completion Checklist
- [ ] All Phase 3 features implemented
- [ ] All integrations published
- [ ] Documentation complete
- [ ] **PHASE 3 COMPLETE**

---

## Project Milestones

- [ ] **v1.4.0** - Phase 1 Complete (Focus Mode, Dark Mode, Reading Position)
- [ ] **v1.5.0** - Math & Mermaid Support
- [ ] **v1.6.0** - GFM Complete + Keyboard Navigation
- [ ] **v2.0.0** - Phase 2 Complete (Delightful Polish)
- [ ] **v2.1.0** - CLI + Integrations
- [ ] **v2.2.0** - Phase 3 Complete

---

## Quick Stats

**Phase 1 Progress**: 0 / 9 features complete
**Phase 2 Progress**: 0 / 8 features complete
**Phase 3 Progress**: 0 / 7 features complete

**Overall Progress**: 0 / 24 features complete

---

*Last Updated: December 2024*
