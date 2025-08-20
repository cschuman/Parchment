# Directory Cleanup Plan

## Current Situation
**67 files in root directory** - This is a maintenance nightmare that makes the project look amateur.

## Target Structure
Clean, professional organization with **~15 files max in root**.

```
/ (root)
├── Package.swift              # Core Swift Package Manager file
├── Package.resolved           # Dependency lock file  
├── Info.plist                # Main app configuration
├── LICENSE                   # Legal requirement
├── README.md                 # Primary documentation
├── build_release.sh          # Main release build (keep for CI)
├── build_dev.sh             # Main dev build (keep for convenience)
├── .gitignore               # Git configuration
├── CLAUDE.md                # Project instructions (keep for Claude)
├── Sources/                 # Source code
├── Tests/                   # Test suite
├── Resources/               # App resources
├── Parchment.app/          # Built app
├── homebrew/               # Homebrew formula (conventional)
├── release/                # Release artifacts (conventional)
├── scripts/                # NEW: All executable scripts
├── docs/                   # NEW: All documentation
├── test-content/           # NEW: Test markdown files
└── assets/                 # NEW: Icons and resources
```

## Execution Plan

### Phase 1: Create Directory Structure
```bash
mkdir -p scripts/{build,tools,signing}
mkdir -p docs/{signing,development}
mkdir -p test-content/drag-drop
mkdir -p assets
```

### Phase 2: Move Files by Category

#### Scripts (35+ files → scripts/)
- **Build Scripts** → `scripts/build/`
- **Development Tools** → `scripts/tools/`
- **Code Signing** → `scripts/signing/`

#### Documentation (10+ files → docs/)
- **General Docs** → `docs/`
- **Signing Docs** → `docs/signing/`
- **Development** → `docs/development/`

#### Test Content (15+ files → test-content/)
- **Test Markdown** → `test-content/`
- **Drag Drop Tests** → `test-content/drag-drop/`

#### Assets (2+ files → assets/)
- **Icons** → `assets/`
- **Resources** → `assets/`

### Phase 3: Delete Obsolete Files (9 files)
- Old executables (mdview, mdview_safe, etc.)
- Log files (debug_output.txt, viewer.log)
- Generated files (test-comprehensive.pdf)

### Phase 4: Update References
- Update build scripts that reference moved files
- Update documentation links
- Update any CI/CD references
- Update CLAUDE.md if needed

## Benefits
1. **Professional Appearance** - Clean, scannable root directory
2. **Easier Navigation** - Logical file organization
3. **Better Maintenance** - Find files quickly
4. **Onboarding** - New developers understand structure instantly
5. **CI/CD** - Cleaner build scripts and paths

## Risk Mitigation
- Test builds after each major move
- Keep git history intact
- Update all references before finalizing
- Validate that all functionality still works

## Success Criteria
- Root directory has ≤15 files
- All builds still work
- All functionality preserved
- Documentation updated
- Professional appearance achieved