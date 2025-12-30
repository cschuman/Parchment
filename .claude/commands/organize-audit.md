# Ultra-Comprehensive Project Organization Audit

Perform a forensic-level audit of the ENTIRE project - code, docs, scripts, config, tests, assets. Think OCD perfectionist.

## Full Project Audit Checklist

### 1. Root Level Analysis

**What belongs at root:**
```
✅ README.md           - Project overview
✅ LICENSE             - License file
✅ Package.swift       - Swift package manifest
✅ .gitignore          - Git ignore rules
✅ CLAUDE.md           - Claude instructions
```

**What does NOT belong at root:**
```
❌ Build scripts       → scripts/build/
❌ Install scripts     → scripts/install/
❌ Test files          → test-content/ or Tests/
❌ One-off scripts     → DELETE or scripts/tools/
❌ .DS_Store           → DELETE (add to .gitignore)
```

### 2. Documentation Audit (`docs/`)

**Healthy docs structure:**
```
docs/
├── FEATURES.md        - Feature documentation
├── ROADMAP.md         - Future plans
├── RELEASE_NOTES.md   - Version history
├── HOMEBREW_SETUP.md  - Installation guide
└── signing/           - Code signing guides (if needed)
```

**Delete stale docs:**
- `TODO.md` → Use GitHub Issues
- `RECOVERY_PLAN.md` → Delete when completed
- `REFACTORING_PLAN.md` → Delete when completed
- `*_CLEANUP_PLAN.md` → Delete when completed

### 3. Scripts Organization (`scripts/`)

**Proper structure:**
```
scripts/
├── build/             - Build and compilation
│   ├── build_dev.sh
│   ├── build_release.sh
│   └── create-app.sh
├── install/           - Installation scripts
│   ├── install-cli.sh
│   └── uninstall-cli.sh
├── signing/           - Code signing scripts
│   ├── sign_dev.sh
│   └── sign_release.sh
├── tools/             - Development utilities
│   └── test_drag_drop.sh
└── test-utilities/    - Test helper scripts
```

### 4. Test Content Organization

**For test markdown files (`test-content/`):**
```
test-content/
├── basic/             - Simple test cases
├── formatting/        - Typography tests
├── features/          - Feature-specific tests
└── edge-cases/        - Edge case tests
```

**Or flatten if < 15 files**

**Swift test utilities:**
```
❌ test-content/*.swift  → scripts/test-utilities/ or Tests/
```

### 5. Source Code Organization (`Sources/`)

**Standard structure:**
```
Sources/{AppName}/
├── App/               - Entry point, lifecycle (main.swift, AppDelegate)
├── Coordinators/      - UI flow coordination
├── Extensions/        - Type extensions
├── Models/            - Data structures
├── Rendering/         - Output generation
├── Services/          - Business logic (stateful)
├── Theme/             - Visual styling
├── Utilities/         - Pure functions (stateless)
├── ViewControllers/   - View coordination
├── Views/             - UI components
└── Windows/           - Window controllers
```

### 6. Configuration Audit (`.claude/`)

**Clean structure:**
```
.claude/
├── CLAUDE.md          - Main instructions
├── agents/            - Agent definitions
├── commands/          - Slash commands
├── rules/             - Behavioral rules
├── context/           - Context files
├── scripts/           - Helper scripts
└── settings.local.json - Local settings (single file!)
```

**Delete:**
- `.DS_Store` files
- Duplicate config files (e.g., `settings.local 2.json`)
- Stale task files

### 7. Assets Organization

**Proper structure:**
```
assets/
├── icons/             - App icons
│   └── {AppName}.iconset/
├── images/            - Other images
└── fonts/             - Custom fonts (or Resources/Fonts/)
```

### 8. Naming Convention Audit

| Pattern | Correct | Incorrect |
|---------|---------|-----------|
| Directories | lowercase, hyphenated | CamelCase, underscores |
| Scripts | snake_case.sh | camelCase.sh |
| Swift files | PascalCase.swift | snake_case.swift |
| Test files | *_test.md or test_*.md | Mixed patterns |
| Config | lowercase | UPPERCASE |

### 9. Dependency Audit

**Check for:**
- Orphaned dependencies in Package.swift
- Unused imports in source files
- Stale `.build/` artifacts (consider `swift package clean`)

### 10. Git Hygiene

**.gitignore should include:**
```
.DS_Store
.build/
*.xcodeproj
xcuserdata/
.swiftpm/
```

## Output Format

```markdown
## Full Project Audit Report

### Critical (Must Fix Now)
1. ❌ [Issue] at [Location]
   Fix: [Exact command]

### Warnings (Should Fix)
1. ⚠️ [Issue] at [Location]
   Fix: [Exact command]

### Suggestions (Nice to Have)
1. 💡 [Suggestion] for [Location]

### Statistics
- Root files: X (should be ~5-7)
- docs/ files: X
- scripts/ organized: Yes/No
- Source directories: X
- Stale files found: X
- .DS_Store files: X

### Recommended Action Sequence
1. [ ] Delete stale files
2. [ ] Move misplaced files
3. [ ] Rename inconsistent files
4. [ ] Update .gitignore
5. [ ] Verify build
6. [ ] Commit with message: "..."
```

## Quick Commands

```bash
# Find all .DS_Store files
find . -name ".DS_Store" -type f

# Find duplicate/backup files
find . -name "*copy*" -o -name "* 2.*" -o -name "*.bak"

# Count files per directory
for dir in */; do echo "$dir: $(find "$dir" -type f | wc -l)"; done

# Find large files (potential binaries)
find . -size +1M -type f

# Find empty directories
find . -type d -empty
```
