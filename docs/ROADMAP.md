# Parchment Roadmap v2.0

> **North Star**: *"The reading experience so good, you forget you're reading markdown."*

## Vision

Parchment is **Preview.app for Markdown** - the definitive read-only markdown viewer for developers on macOS. We don't edit, we don't organize, we perfect the viewing experience.

## Positioning

| We Are | We Are NOT |
|--------|------------|
| A reading experience | An editor (use VS Code, iA Writer) |
| Native macOS excellence | Cross-platform Electron |
| One-time purchase ($19.99) | Subscription software |
| Focused & opinionated | Feature-bloated |

## Target Users

1. **Developers (70%)** - Viewing READMEs, docs, RFCs, technical specs
2. **Technical Writers (20%)** - Previewing their work alongside editors
3. **Reviewers (10%)** - Reading PRs, proposals, documentation

---

## Phase 1: "Make It Work" ✅ COMPLETE
*Fix the broken, add the expected*

### Critical Fixes
- [x] Fix Focus Mode discovery (Cmd+Shift+F shortcut, add to menu)
- [x] Auto dark/light mode switching (follow system appearance)
- [x] Restore reading position on file reopen
- [x] Transform status bar (parse time → word count, reading time, progress %)

### Table Stakes Features
- [x] LaTeX/Math rendering (KaTeX integration)
- [x] Mermaid diagram support
- [x] Complete GFM support (task lists, footnotes, emoji shortcodes, strikethrough)

### UX Quick Wins
- [x] Keyboard navigation for headers (Cmd+[ previous, Cmd+] next)
- [x] Jump to top/bottom (Cmd+Up, Cmd+Down)
- [x] Contextual onboarding tooltips

---

## Phase 2: "Make It Delightful" ✅ COMPLETE
*The details that create love*

### Typography Excellence
- [x] Optical font weight adjustment (lighter weights at larger sizes)
- [x] Variable font support for heading scales
- [x] Baseline grid alignment (8pt)
- [x] Maximum line length constraint (680pt centered)

### Reading Mode
- [x] Distraction-free mode (remove ALL chrome with single keystroke)
- [x] Reading progress indicator (subtle vertical bar)
- [x] Enhanced Focus Mode with typewriter scrolling

### Visual Polish
- [x] Smooth theme transitions (0.3s cross-fade)
- [x] Document loading animations
- [x] Link hover previews (show URL tooltip)
- [x] Scroll physics refinement

### Power User Features
- [x] Enhanced Find (regex support, headers-only option)
- [x] Export preview before saving
- [x] Three new themes (Dracula, Nord, Solarized)

---

## Phase 3: "Make It Essential" ✅ COMPLETE
*Integration and stickiness*

### Workflow Integration
- [x] CLI tool (`parchment file.md` from terminal)
- [ ] VS Code extension ("Open in Parchment") - *Future: separate project*
- [x] Alfred/Raycast integration
- [x] Homebrew distribution

### Customization
- [x] Custom CSS themes
- [x] User-defined keyboard shortcuts
- [x] Export templates (academic, GitHub, manuscript)

### Platform Excellence
- [x] Touch Bar support
- [x] Handoff between devices
- [x] Stage Manager optimization
- [x] Shortcuts app actions
- [x] Spotlight content indexing

---

## Anti-Roadmap: What We Will NOT Build

| Feature | Reason |
|---------|--------|
| Editing capabilities | Not our lane - use VS Code, iA Writer |
| Note organization/folders | Not our lane - use Obsidian, Bear |
| Cloud sync | Files live in Git/Dropbox/iCloud already |
| Mobile apps | One platform, done perfectly |
| AI features | Resist hype, focus on rendering excellence |
| Windows/Linux | Native Mac is our sustainable moat |
| Subscriptions | Developers hate them |
| Wiki-links/graphs | Different product category |

---

## Success Metrics

### Performance Targets
- App launch: <100ms
- Document open: <50ms for 99% of files
- Scroll performance: Consistent 120fps on ProMotion
- Memory: <50MB for typical document

### Phase 1 Success
- Focus Mode usage increases 5x
- Zero complaints about missing dark mode
- 4.5+ star App Store rating

### Phase 2 Success
- "Beautiful" mentioned in 30%+ of reviews
- Power users adopt keyboard navigation
- 30-day retention > 60%

### Phase 3 Success
- CLI becomes primary entry point for 20% of users
- VS Code extension > 10k installs
- Word of mouth drives 50% of new users

---

## Competitive Landscape

| Competitor | Position | Price | Our Advantage |
|------------|----------|-------|---------------|
| Marked 2 | Preview companion | $13.99 | Modern, maintained, better UX |
| Typora | WYSIWYG editor | $49.99 | Lighter, faster, viewing-focused |
| MacDown | Free editor | Free | Dead project (3+ years), we're alive |
| Obsidian | Knowledge management | Free/$50 | Simpler, focused, no learning curve |
| iA Writer | Minimalist writing | $13.99 | Reading-first, not writing-first |

**The Gap**: No modern, native, maintained markdown *viewer* exists. We fill that gap.

---

## Development Philosophy

### When Adding Features
1. Does this make *reading* markdown better?
2. Does this maintain our simplicity?
3. Is this truly native to macOS?
4. Would we use this ourselves every day?

### Code Quality Standards
- Performance over features
- Native APIs over custom solutions
- Swift idioms and best practices
- Accessibility from day one

---

*"The best markdown viewer is the one you forget you're using."*

*Last updated: December 2024*
*v2.0.0 Released: All phases complete*
