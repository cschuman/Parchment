# Project Organization Fix

Execute organization fixes based on audit findings. This skill applies standardized fixes for common organizational issues.

## Prerequisites

Run `/organize-audit` first to identify issues.

## Fix Categories

### 1. Move Misplaced Files

**Pattern: Move file to correct directory**
```bash
# Create target directory if needed
mkdir -p Sources/App/TargetDirectory

# Move file (git tracks the rename)
git mv Sources/App/WrongDir/File.swift Sources/App/CorrectDir/File.swift
```

**Common moves:**
| From | To | When |
|------|-----|------|
| `Utilities/*Cache*.swift` | `Services/` | Stateful caching |
| `Utilities/*Loader*.swift` | `Services/` | Async data loading |
| `Utilities/*Watcher*.swift` | `Services/` | Event-based state |
| `Services/*Coordinator*.swift` | `Coordinators/` | UI flow control |
| `root/main.swift` | `App/main.swift` | Entry point |

### 2. Rename for Consistency

**Pattern: Rename file**
```bash
git mv Sources/App/Dir/OldName.swift Sources/App/Dir/NewName.swift
```

**Standard renames:**
| Pattern | From | To |
|---------|------|-----|
| Coordinator consistency | `*Manager.swift` (if coordinates UI) | `*Coordinator.swift` |
| Singular directories | `Models/` | Keep (convention) |
| Plural to singular | `ParchmentThemes.swift` | `ParchmentTheme.swift` |
| Remove verbose prefix | `MarkdownGestureManager.swift` | `GestureManager.swift` |
| Extension naming | `*+EnhancedMenus.swift` | `*+Menus.swift` |

### 3. Consolidate Single-File Directories

**Decision tree:**
```
Is it a standard pattern (Models, Extensions)?
  → YES: Keep even with 1 file
  → NO: Will more files be added soon?
    → YES: Keep
    → NO: Merge into related directory
```

**Merge targets:**
| Single-file dir | Merge into | Rationale |
|-----------------|------------|-----------|
| `Extensions/` with 1 file | `Utilities/` | Unless more expected |
| `Helpers/` | `Utilities/` | Same purpose |
| `Constants/` | `App/` or relevant dir | Co-locate with usage |
| `Protocols/` | Same file as implementor | Unless 3+ protocols |

### 4. Split Overstuffed Directories

**When to split (> 10 files):**

| Original | Split into | Criteria |
|----------|------------|----------|
| `Utilities/` (15 files) | `Utilities/` + `Services/` | Stateful vs stateless |
| `Views/` (20 files) | `Views/` + `Views/Components/` | Reusable vs specific |
| `Services/` (12 files) | `Services/` + `Coordinators/` | Flow vs logic |

### 5. Fix Extension Files

**Standard pattern:** `TypeName+Category.swift`

```bash
# Rename to standard pattern
git mv AppDelegate+EnhancedMenus.swift AppDelegate+Menus.swift
git mv MarkdownViewController+Features.swift MarkdownViewController+Focus.swift
```

**Category naming:**
| Category | Use for |
|----------|---------|
| `+Menus` | Menu building |
| `+Actions` | @objc action methods |
| `+Delegates` | Protocol conformance |
| `+Layout` | Constraint setup |
| `+Styling` | Appearance configuration |

### 6. Update Imports After Moves

After moving files, search and update imports:

```bash
# Find files importing moved type
grep -r "import.*MovedType" Sources/
grep -r "from.*MovedType" src/  # For JS/TS

# Update paths in build files if needed
```

### 7. Clean Empty Directories

```bash
# Remove empty directories (safe, git won't track them anyway)
find Sources -type d -empty -delete
```

## Execution Order

1. **Backup/Commit current state** (safety)
2. **Move files** (one directory at a time)
3. **Rename files** (after moves complete)
4. **Build/Test** (verify nothing broke)
5. **Remove empty directories**
6. **Commit with descriptive message**

## Verification

After fixes:
```bash
# Verify build
swift build  # or npm run build, cargo build, etc.

# Verify no broken imports
grep -r "OldPath" Sources/

# Verify directory structure
tree Sources/ -d
```

## Commit Message Template

```
Reorganize project structure for consistency

Moves:
- OldDir/File.swift → NewDir/File.swift
- ...

Renames:
- OldName.swift → NewName.swift
- ...

Consolidations:
- Merged SingleFileDir/ into ParentDir/
- ...
```
