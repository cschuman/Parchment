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

## Phase 1: "Make It Work" (Q1 2025)
*Fix the broken, add the expected*

### Critical Fixes
- [ ] Fix Focus Mode discovery (Cmd+Shift+F shortcut, add to menu)
- [ ] Auto dark/light mode switching (follow system appearance)
- [ ] Restore reading position on file reopen
- [ ] Transform status bar (parse time → word count, reading time, progress %)

### Table Stakes Features
- [ ] LaTeX/Math rendering (KaTeX integration)
- [ ] Mermaid diagram support
- [ ] Complete GFM support (task lists, footnotes, emoji shortcodes)

### UX Quick Wins
- [ ] Keyboard navigation for headers (Cmd+[ previous, Cmd+] next)
- [ ] Jump to top/bottom (Cmd+Up, Cmd+Down)
- [ ] Contextual onboarding tooltips

---

## Phase 2: "Make It Delightful" (Q2 2025)
*The details that create love*

### Typography Excellence
- [ ] Optical font weight adjustment (lighter weights at larger sizes)
- [ ] Variable font support for heading scales
- [ ] Baseline grid alignment (8pt)
- [ ] Maximum line length constraint (680pt centered)

### Reading Mode
- [ ] Distraction-free mode (remove ALL chrome with single keystroke)
- [ ] Reading progress indicator (subtle vertical bar)
- [ ] Enhanced Focus Mode with typewriter scrolling

### Visual Polish
- [ ] Smooth theme transitions (0.3s cross-fade)
- [ ] Document loading animations
- [ ] Link hover previews (show URL tooltip)
- [ ] Scroll physics refinement

### Power User Features
- [ ] Enhanced Find (regex support, headers-only option)
- [ ] Export preview before saving
- [ ] Three new themes (Dracula, Nord, Solarized)

---

## Phase 3: "Make It Essential" (Q3-Q4 2025)
*Integration and stickiness*

### Workflow Integration
- [ ] CLI tool (`parchment file.md` from terminal)
- [ ] VS Code extension ("Open in Parchment")
- [ ] Alfred/Raycast integration
- [ ] Homebrew distribution

### Customization
- [ ] Custom CSS themes
- [ ] User-defined keyboard shortcuts
- [ ] Export templates (academic, GitHub, manuscript)

### Platform Excellence
- [ ] Touch Bar support
- [ ] Handoff between devices
- [ ] Stage Manager optimization
- [ ] Shortcuts app actions
- [ ] Spotlight content indexing

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
