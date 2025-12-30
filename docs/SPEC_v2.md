# Parchment v2.0 Specification

> Technical specification for Phase 1-3 features

---

## Phase 1: "Make It Work"

### 1.1 Fix Focus Mode Discovery

**Problem**: Focus Mode exists but is invisible to users. Cmd+F is Find, not Focus. No keyboard shortcut in menu.

**Requirements**:
- Assign `Cmd+Shift+F` as Focus Mode shortcut
- Add shortcut indicator in View menu: "Toggle Focus Mode ⇧⌘F"
- First activation shows tooltip: "Focus Mode: Current paragraph highlighted, surroundings dimmed"
- Focus Mode should include typewriter scrolling (current line stays vertically centered)

**Implementation**:
```
File: Sources/Parchment/App/AppDelegate.swift
- Update menu item keyEquivalent to "F" with shift modifier

File: Sources/Parchment/ViewControllers/MarkdownViewController.swift
- Ensure typewriter scrolling activates with focus mode
- Add first-use tooltip via UserDefaults flag
```

**Acceptance Criteria**:
- [ ] Cmd+Shift+F toggles Focus Mode
- [ ] Menu shows shortcut
- [ ] Typewriter scrolling works in Focus Mode
- [ ] First-use tooltip appears once

---

### 1.2 Auto Dark/Light Mode

**Problem**: Users must manually switch themes. Modern apps follow system appearance.

**Requirements**:
- Add preference: "Follow System Appearance" (default: ON)
- When enabled, auto-switch between designated light/dark themes
- Light theme default: Minimal
- Dark theme default: Midnight
- Transition smoothly (0.3s cross-fade)
- Persist user's manual choice if preference is OFF

**Implementation**:
```
File: Sources/Parchment/App/AppDelegate.swift
- Register for NSApplication.didChangeOcclusionStateNotification
- Or use effectiveAppearance observation

File: Sources/Parchment/Theme/ParchmentThemes.swift
- Add lightThemeForAutoSwitch and darkThemeForAutoSwitch properties
- Add preference storage
```

**Acceptance Criteria**:
- [ ] App follows system appearance by default
- [ ] Theme transitions smoothly
- [ ] Preference to disable auto-switching
- [ ] Manual theme choice persists when auto-switch is off

---

### 1.3 Reading Position Restoration

**Problem**: Opening a file always starts at top. Users lose their place.

**Requirements**:
- Save scroll position (as percentage) per document URL
- On reopen, animate scroll to saved position (0.4s ease-out)
- Show subtle toast: "Resumed at 63%"
- Store in UserDefaults with document URL as key
- Limit storage to last 100 documents (LRU eviction)

**Implementation**:
```
File: Sources/Parchment/Services/ReadingPositionManager.swift (NEW)
- Save/load scroll percentage per URL
- LRU cache with 100 document limit

File: Sources/Parchment/ViewControllers/MarkdownViewController.swift
- Call save on scroll end (debounced 500ms)
- Call restore on document load
- Show toast notification
```

**Data Structure**:
```swift
struct ReadingPosition: Codable {
    let url: URL
    let scrollPercentage: Double
    let lastAccessed: Date
}
```

**Acceptance Criteria**:
- [ ] Position saved when scrolling stops
- [ ] Position restored on file reopen
- [ ] Toast shows "Resumed at X%"
- [ ] Old positions evicted after 100 documents

---

### 1.4 Transform Status Bar

**Problem**: Status bar shows developer metrics (parse time, render time, cache hit) instead of useful reading information.

**Current**: `test.md | 1.2KB | 45 lines | Parse: 0.003s | Render: 0.012s | Cache: 67%`

**Proposed**: `test.md | 842 words | ~4 min read | 63% complete`

**Requirements**:
- Replace parse/render/cache metrics with:
  - Word count
  - Estimated reading time (@ 200 WPM)
  - Scroll progress percentage
- Keep file name and size
- Update progress in real-time as user scrolls

**Implementation**:
```
File: Sources/Parchment/Views/StatusBarView.swift
- Remove performance labels
- Add wordCountLabel, readingTimeLabel, progressLabel
- Subscribe to scroll notifications for progress updates
```

**Acceptance Criteria**:
- [ ] Shows word count
- [ ] Shows reading time estimate
- [ ] Shows scroll progress percentage
- [ ] Progress updates live while scrolling

---

### 1.5 LaTeX/Math Rendering

**Problem**: Technical documentation often contains math equations. Without LaTeX support, we can't properly display 40% of technical docs.

**Requirements**:
- Render inline math: `$E = mc^2$`
- Render block math: `$$\sum_{i=1}^{n} x_i$$`
- Use KaTeX for fast rendering (faster than MathJax)
- Graceful fallback: show raw LaTeX if rendering fails

**Implementation Options**:
1. **WebKit approach**: Render math blocks in small WKWebViews with KaTeX
2. **Native approach**: Use iosMath or SwiftMath library
3. **Hybrid**: Pre-render to images, cache results

**Recommended**: Option 1 (WebKit) for accuracy, with aggressive caching

```
File: Sources/Parchment/Rendering/MathRenderer.swift (NEW)
- KaTeX rendering via WKWebView
- Cache rendered math as NSImage
- Insert images into attributed string

File: Sources/Parchment/Rendering/EnhancedMarkdownRenderer.swift
- Detect math delimiters during parsing
- Call MathRenderer for math blocks
```

**Acceptance Criteria**:
- [ ] Inline math renders correctly
- [ ] Block math renders correctly
- [ ] Performance: <100ms for typical equation
- [ ] Graceful fallback on error

---

### 1.6 Mermaid Diagram Support

**Problem**: GitHub natively renders Mermaid diagrams. README files increasingly use them for flowcharts, sequence diagrams, architecture diagrams.

**Requirements**:
- Detect ```mermaid code blocks
- Render using Mermaid.js via WebKit
- Support: flowchart, sequence, class, state, ER diagrams
- Cache rendered diagrams
- Show placeholder during render

**Implementation**:
```
File: Sources/Parchment/Rendering/MermaidRenderer.swift (NEW)
- WKWebView with Mermaid.js loaded
- Render diagram to PNG/SVG
- Cache by content hash

File: Sources/Parchment/Rendering/EnhancedMarkdownRenderer.swift
- Detect mermaid code blocks
- Replace with rendered image
```

**Acceptance Criteria**:
- [ ] Flowcharts render
- [ ] Sequence diagrams render
- [ ] Other diagram types render
- [ ] Cached on subsequent views
- [ ] Theme-aware (light/dark)

---

### 1.7 Complete GFM Support

**Problem**: Missing some GitHub Flavored Markdown features.

**Requirements**:
- Task lists: `- [ ]` and `- [x]` render as checkboxes
- Footnotes: `[^1]` with footnote definitions
- Emoji shortcodes: `:smile:` → 😄
- Autolinks: URLs automatically become links
- Strikethrough: `~~text~~` (verify working)

**Implementation**:
```
File: Sources/Parchment/Rendering/EnhancedMarkdownRenderer.swift
- Add task list rendering (checkbox images or SF Symbols)
- Add footnote collection and rendering
- Add emoji shortcode replacement dictionary
```

**Acceptance Criteria**:
- [ ] Task lists show checkboxes
- [ ] Footnotes render with links
- [ ] Emoji shortcodes convert
- [ ] URLs auto-link
- [ ] Strikethrough works

---

### 1.8 Keyboard Navigation

**Requirements**:
- `Cmd+]` - Jump to next header
- `Cmd+[` - Jump to previous header
- `Cmd+Up` - Jump to document top
- `Cmd+Down` - Jump to document bottom
- `Cmd+1-6` - Jump to next H1-H6 (optional)

**Implementation**:
```
File: Sources/Parchment/App/AppDelegate.swift
- Add menu items with keyboard shortcuts

File: Sources/Parchment/ViewControllers/MarkdownViewController.swift
- Implement navigation methods
- Use header positions from document parsing
```

**Acceptance Criteria**:
- [ ] Cmd+] jumps to next header
- [ ] Cmd+[ jumps to previous header
- [ ] Cmd+Up jumps to top
- [ ] Cmd+Down jumps to bottom
- [ ] Smooth scroll animation to target

---

## Phase 2: "Make It Delightful"

### 2.1 Optical Font Weight Adjustment

**Problem**: Large headings look too heavy. Dark mode text can feel harsh.

**Requirements**:
- Reduce font weight as size increases
- Lighten font weight in dark themes
- Seamless, not jarring

**Algorithm**:
```swift
func opticalWeight(baseWeight: NSFont.Weight, pointSize: CGFloat, isDark: Bool) -> NSFont.Weight {
    var weight = baseWeight

    // Larger text = lighter weight
    if pointSize > 28 { weight = weight.lighter() }
    else if pointSize > 20 { weight = weight.lighter(by: 50) }

    // Dark mode = slightly lighter
    if isDark { weight = weight.lighter(by: 30) }

    return weight
}
```

---

### 2.2 Reading Mode (Distraction-Free)

**Requirements**:
- Single keystroke: `Cmd+Shift+R` or `Ctrl+Cmd+F`
- Removes: status bar, toolbar, title bar, TOC
- Full screen, centered text column (max 680pt)
- Escape key exits
- Smooth 0.3s fade transition

---

### 2.3 Reading Progress Indicator

**Requirements**:
- Subtle vertical bar on right edge (2pt wide)
- Shows position in document
- Theme-aware color (30% opacity)
- Fades in on scroll, out after 1.5s idle
- Does not interfere with scrollbar

---

### 2.4 Smooth Theme Transitions

**Requirements**:
- 0.3s cross-fade between themes
- Maintain scroll position during transition
- No flash or flicker
- Use CAAnimation or NSAnimationContext

---

### 2.5 Three New Themes

**Dracula**:
- Background: #282a36
- Text: #f8f8f2
- Purple accents

**Nord**:
- Background: #2e3440
- Text: #eceff4
- Blue/cyan accents

**Solarized Light**:
- Background: #fdf6e3
- Text: #657b83
- Yellow/orange accents

---

## Phase 3: "Make It Essential"

### 3.1 CLI Tool

**Requirements**:
- Install via: `brew install parchment` or direct download
- Usage: `parchment file.md` opens in Parchment
- Usage: `parchment --version` shows version
- Usage: `parchment --help` shows help
- If Parchment running, open in existing instance
- If not running, launch Parchment

**Implementation**: Already have argument parsing, need Homebrew formula

---

### 3.2 VS Code Extension

**Requirements**:
- "Open in Parchment" command
- "Open in Parchment" context menu on .md files
- Keyboard shortcut configurable
- Works with current file or selected file in explorer

---

### 3.3 Custom CSS Themes

**Requirements**:
- Load CSS from `~/Library/Application Support/Parchment/themes/`
- CSS applies to rendered output
- Theme picker shows custom themes
- Validate CSS before applying
- Provide template CSS file

---

## Technical Notes

### Performance Budgets
- Feature must not add >10ms to document open time
- Feature must not add >5MB to memory baseline
- Animations must hit 60fps minimum

### Testing Requirements
- Unit tests for all new managers/services
- UI tests for keyboard shortcuts
- Performance tests for math/mermaid rendering

### Accessibility Requirements
- All new features must work with VoiceOver
- Keyboard navigation must be complete
- Reduced motion preference must be respected

---

*Specification Version: 2.0*
*Last Updated: December 2024*
