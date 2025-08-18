# Parchment Recovery Plan

## Current State Assessment (August 18, 2025)
- **31MB binary** checked into git
- **Zero test coverage** (1 fake test)
- **76 debug fputs statements** throughout codebase
- **1829-line god object** (MarkdownViewController.swift)
- **Overengineered features** (Metal rendering, plugin system, graph viz, etc.)
- **Two markdown libraries** when one would suffice

## Mission Shift
**FROM:** Swiss-army knife markdown viewer with every feature imaginable  
**TO:** The fastest, most reliable markdown viewer on macOS that just works

## Recovery Phases

### Phase 1: Stop the Bleeding (Immediate)
- [ ] Remove binary from git, add proper .gitignore
- [ ] Strip all fputs debug statements
- [ ] Fix Metal shader build warnings
- [ ] Commit these emergency fixes

### Phase 2: Simplify Ruthlessly (Week 1)
**Delete these overengineered features:**
- [ ] Metal rendering system (NSTextView is plenty fast)
- [ ] Plugin system (YAGNI - not a single real plugin exists)
- [ ] Graph visualization (wrong tool for the job)
- [ ] Theater mode for code blocks
- [ ] Bionic reading mode
- [ ] Reduce 7 typography modes to just Light/Dark
- [ ] Multiple caching layers → One simple LRU cache
- [ ] Wiki-links/Backlinks (unless core to the vision)

**Consolidate dependencies:**
- [ ] Remove swift-markdownkit (keep only swift-markdown)
- [ ] Audit all other dependencies for actual usage

### Phase 3: Core Architecture Fix (Week 2)
**Break up the 1829-line MarkdownViewController:**
```
MarkdownViewController.swift → 
├── MarkdownViewController.swift (200 lines - coordination)
├── MarkdownRenderer.swift (parsing/rendering)
├── MarkdownScrollHandler.swift (scrolling/viewport)
├── MarkdownEventHandler.swift (user interactions)
└── MarkdownTextStorage.swift (NSTextStorage subclass)
```

**Add proper logging:**
```swift
import os.log
extension Logger {
    static let app = Logger(subsystem: "com.parchment", category: "app")
    static let render = Logger(subsystem: "com.parchment", category: "render")
}
```

### Phase 4: Testing & Quality (Week 3)
**Write actual tests for:**
- [ ] Markdown parsing basic cases
- [ ] File open/save operations
- [ ] Scroll performance benchmarks
- [ ] Link clicking behavior
- [ ] Export to PDF/HTML
- [ ] Recent documents persistence

**Target: 80% coverage on core features**

### Phase 5: Polish What Remains (Week 4)
**Core features to perfect:**
1. **Fast viewing** - Sub-500ms open for 10MB files
2. **File management** - Recent docs, quick open (no fuzzy finder)
3. **Export** - Reliable PDF/HTML generation
4. **Search** - Fast in-document search
5. **TOC** - Simple, useful table of contents

## Success Metrics
- [ ] Opens 10MB markdown in < 500ms
- [ ] 60fps scrolling without Metal
- [ ] < 10MB app size (from current 31MB)
- [ ] 80% test coverage
- [ ] Zero debug prints in release
- [ ] All features work reliably

## Implementation Checklist

### Today (Phase 1)
```bash
# 1. Remove binary from git
git rm -r --cached Parchment.app
git rm -r --cached .build

# 2. Create proper .gitignore
cat > .gitignore << 'EOF'
# Build artifacts
.build/
DerivedData/
*.xcodeproj
.swiftpm/

# App bundle
Parchment.app/
*.app/

# Code signing
*.xcarchive
*.ipa
*.dSYM.zip
*.dSYM

# macOS
.DS_Store
*.swp
*~

# Xcode
xcuserdata/
*.xcscmblueprint
*.xccheckout
EOF

# 3. Strip debug statements
find Sources -name "*.swift" -exec sed -i '' '/fputs(/d' {} \;

# 4. Commit emergency fixes
git add .
git commit -m "Emergency cleanup: Remove binary, debug statements, add .gitignore"
```

### This Week (Phase 2)
1. Delete Metal rendering (Sources/Parchment/Rendering/MetalTextRenderer.swift, etc.)
2. Delete plugin system (Sources/Parchment/Plugins/*)
3. Delete graph viz (Sources/Parchment/KnowledgeGraph/GraphVisualizationView.swift)
4. Simplify typography modes
5. Remove swift-markdownkit dependency

### Next Week (Phase 3)
1. Refactor MarkdownViewController into smaller components
2. Implement proper logging with os.log
3. Set up basic CI/CD with GitHub Actions

## Anti-Patterns to Avoid
- ❌ "What if we need it later?" - YAGNI
- ❌ "But it's cool tech!" - Not if it doesn't help users
- ❌ "It's already built" - Sunk cost fallacy
- ❌ "Make it configurable" - Make it work first
- ❌ "Add more caching" - Fix the root cause

## The Mantra
**Every line deleted is a line you don't have to maintain.**

## Progress Tracking
- [ ] Phase 1 Complete
- [ ] Phase 2 Complete
- [ ] Phase 3 Complete
- [ ] Phase 4 Complete
- [ ] Phase 5 Complete

---
*Last Updated: August 18, 2025*
*Recovery Lead: @corey*