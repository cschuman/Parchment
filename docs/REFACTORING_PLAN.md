# MarkdownViewController Refactoring Plan

## Current State
- **File**: MarkdownViewController.swift
- **Lines**: 963 (unacceptable for maintainability)
- **Responsibilities**: 10+ mixed concerns
- **Risk**: High coupling, difficult to test, hard to maintain

## Goal
Break down into focused, single-responsibility classes that are:
- Under 200 lines each
- Testable in isolation
- Follow SOLID principles
- Maintain backward compatibility

## Refactoring Strategy

### Phase 1: Extract SyntaxHighlighter ✅ LOWEST RISK
**Lines to extract**: 234 lines
**New file**: `Sources/Parchment/Rendering/CodeSyntaxHighlighter.swift`

**What moves**:
- `highlightCode()` method
- `applySyntaxHighlighting()` method
- All language-specific highlight methods (Swift, JS, Python, JSON, HTML, CSS)
- Regex patterns and color definitions

**Interface**:
```swift
protocol SyntaxHighlighting {
    func highlight(code: String, language: String?, theme: Theme) -> NSAttributedString
}
```

**Why first**: Self-contained, no state dependencies, pure transformation function

### Phase 2: Extract GestureManager
**Lines to extract**: 157 lines
**New file**: `Sources/Parchment/Interaction/MarkdownGestureManager.swift`

**What moves**:
- `setupGestureRecognizers()`
- All gesture handlers (pinch, swipe, double-tap)
- Zoom animation logic
- Navigation gestures

**Interface**:
```swift
protocol GestureManagerDelegate: AnyObject {
    func gestureManagerDidRequestZoom(_ delta: CGFloat)
    func gestureManagerDidRequestNavigation(_ direction: NavigationDirection)
    func gestureManagerDidToggleFocusMode()
}
```

**Why second**: Clear boundaries, delegates back to VC for actions

### Phase 3: Extract TypewriterScrollManager
**Lines to extract**: 76 lines
**New file**: `Sources/Parchment/Features/TypewriterScrollManager.swift`

**What moves**:
- Typewriter mode state management
- Center line calculations
- Auto-scrolling logic
- Line position calculations

**Interface**:
```swift
class TypewriterScrollManager {
    func enable(for textView: NSTextView, scrollView: NSScrollView)
    func disable()
    func centerCurrentLine()
}
```

**Why third**: Feature is toggleable, minimal dependencies

### Phase 4: Extract StatisticsManager  
**Lines to extract**: 46 lines
**New file**: `Sources/Parchment/Analytics/ReadingStatisticsManager.swift`

**What moves**:
- Reading time calculation
- Word/character counting
- Progress tracking
- Statistics overlay creation

**Interface**:
```swift
struct ReadingStatistics {
    let wordCount: Int
    let readingTime: TimeInterval
    let progress: Double
}

class StatisticsManager {
    func calculate(for document: MarkdownDocument) -> ReadingStatistics
    func showOverlay(in view: NSView, statistics: ReadingStatistics)
}
```

### Phase 5: Extract DocumentRenderer
**Lines to extract**: ~100 lines
**New file**: `Sources/Parchment/Rendering/DocumentRenderer.swift`

**What moves**:
- Document parsing logic
- Attributed string generation
- Image placeholder handling
- Render caching logic

**Interface**:
```swift
protocol DocumentRendering {
    func render(_ document: MarkdownDocument, theme: Theme) async -> NSAttributedString
}
```

### Phase 6: Extract NavigationCoordinator
**Lines to extract**: ~80 lines
**New file**: `Sources/Parchment/Navigation/DocumentNavigationCoordinator.swift`

**What moves**:
- Header navigation
- Scroll-to-location
- History navigation
- Search result navigation

## After Refactoring

### New MarkdownViewController Structure (~250 lines)
```swift
class MarkdownViewController {
    // Managers
    private let syntaxHighlighter: SyntaxHighlighting
    private let gestureManager: MarkdownGestureManager
    private let typewriterManager: TypewriterScrollManager
    private let statisticsManager: StatisticsManager
    private let renderer: DocumentRendering
    private let navigator: DocumentNavigationCoordinator
    
    // Core UI
    var scrollView: NSScrollView!
    var textView: MarkdownTextView!
    
    // State
    var currentDocument: MarkdownDocument?
    
    // Simplified methods
    func loadDocument(_ document: MarkdownDocument)
    func updateDocument(_ document: MarkdownDocument, diff: DiffResult)
}
```

## Testing Strategy

After each extraction:
1. Run existing app functionality tests
2. Verify no visual regressions
3. Check performance metrics remain stable
4. Add unit tests for extracted component

## Rollback Plan

Each phase is atomic. If issues arise:
1. Git revert the extraction commit
2. Investigate issue in isolation
3. Fix and retry extraction

## Success Metrics

- [ ] MarkdownViewController under 300 lines
- [ ] Each extracted class under 200 lines
- [ ] Zero functionality regressions
- [ ] Improved test coverage (target: 80%)
- [ ] Build time improvement
- [ ] Easier to onboard new developers

## Execution Order

1. **Today**: Extract SyntaxHighlighter (least risk, biggest win)
2. **Next**: Extract GestureManager (clear boundaries)
3. **Then**: Extract smaller managers (TypewriterScrollManager, StatisticsManager)
4. **Finally**: Extract core rendering/navigation (most complex)

## Notes

- Each extraction should maintain the same public API initially
- Refactor internals after extraction is stable
- Add comprehensive tests after each extraction
- Document new interfaces thoroughly