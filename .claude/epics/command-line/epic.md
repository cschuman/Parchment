---
name: command-line
status: backlog
created: 2025-08-22T02:13:17Z
progress: 50%
prd: .claude/prds/command-line.md
github: https://github.com/cschuman/Parchment/issues/1
---

# Epic: Command Line Support

## Overview
Implement a lightweight CLI tool that enables users to launch Parchment and open markdown files directly from the terminal. The solution uses a separate Swift executable that communicates with the main Parchment.app via the standard macOS `open` command, ensuring clean separation and minimal overhead.

## Architecture Decisions

### Key Technical Decisions
- **Separate CLI Binary**: Create standalone `parchment` executable instead of embedding CLI logic in main app
- **ArgumentParser Framework**: Use Apple's Swift ArgumentParser for robust command-line parsing
- **Communication via open**: Leverage macOS `open` command rather than complex IPC mechanisms
- **Smart App Discovery**: Automatically locate Parchment.app in standard locations
- **No Daemon Process**: Keep it simple - CLI launches and exits immediately (unless --wait)

### Technology Choices
- Swift 5.9 with ArgumentParser for CLI
- Native macOS APIs (no external dependencies)
- Standard Unix conventions for options and arguments

### Design Patterns
- Command pattern for argument handling
- Strategy pattern for app discovery
- Builder pattern for open command construction

## Technical Approach

### CLI Components
- **ParchmentCLI Target**: Separate Swift Package Manager target
- **Argument Parser**: Handles all command-line options and validation
- **Path Resolver**: Expands wildcards, validates paths, handles relative/absolute conversion
- **App Launcher**: Finds and launches Parchment.app with appropriate arguments

### Integration Points
- **App Discovery**: Search /Applications, ~/Applications, and current directory
- **File Passing**: Use `--args` flag with open command to pass file paths
- **Options Mapping**: Convert CLI flags to open command parameters
- **Error Handling**: Clear user-friendly messages for common issues

### Distribution Strategy
- **Installation Script**: Shell script to copy CLI to /usr/local/bin
- **Uninstallation Script**: Clean removal script
- **Homebrew Formula**: Future enhancement for easier distribution
- **Shell Completions**: Bash/Zsh/Fish completion scripts (future)

## Implementation Strategy

### Development Phases
1. **Phase 1 - Core CLI** ✅ (Completed)
   - Basic argument parsing
   - File path resolution
   - App launching via open command

2. **Phase 2 - Installation**
   - Installation/uninstallation scripts
   - PATH configuration guidance
   - Basic documentation

3. **Phase 3 - Polish**
   - Shell completion scripts
   - Man page generation
   - Homebrew formula

### Risk Mitigation
- **App Translocation**: Handle relocated apps gracefully
- **Sandboxing**: Work within macOS security constraints
- **PATH Issues**: Provide clear setup instructions
- **Performance**: Keep CLI lightweight (<1MB binary)

### Testing Approach
- Unit tests for path resolution
- Integration tests for app launching
- Manual testing across different shells
- Performance benchmarking

## Task Breakdown Preview

High-level task categories to complete implementation:
- [x] Create CLI parser with ArgumentParser
- [x] Implement app discovery and launching
- [x] Add installation/uninstallation scripts
- [ ] Update AppDelegate to handle CLI arguments properly
- [ ] Add shell completion scripts
- [ ] Create man page documentation
- [ ] Package for Homebrew distribution
- [ ] Add integration tests

## Dependencies

### External Dependencies
- Swift Argument Parser (already added to Package.swift)
- macOS 13.0+ APIs

### Internal Dependencies
- AppDelegate modifications for argument handling
- No changes needed to existing Parchment architecture

### Prerequisite Work
- None - can be developed independently

## Success Criteria (Technical)

### Performance Benchmarks
- CLI startup time < 50ms
- Total execution time < 100ms for file opening
- Binary size < 1MB

### Quality Gates
- All command-line options functional
- Clear error messages for all failure cases
- Works across zsh, bash, fish shells
- No regression in GUI functionality

### Acceptance Criteria
- ✅ Single file opening works
- ✅ Multiple file handling implemented
- ✅ Wildcard expansion functional
- ✅ Help and version flags work
- [ ] Directory opening triggers file browser (when implemented)
- ✅ Installation script works without sudo (when possible)

## Estimated Effort

### Overall Timeline
- **Remaining Work**: 1-2 days
- **Testing & Polish**: 1 day
- **Documentation**: 0.5 days
- **Total**: ~3 days

### Resource Requirements
- 1 developer
- Access to multiple macOS versions for testing
- Various shell environments for compatibility testing

### Critical Path Items
1. AppDelegate argument handling refinement
2. Shell completion scripts
3. Homebrew formula creation