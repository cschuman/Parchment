# Parchment

A beautifully crafted, blazingly fast native macOS markdown viewer that puts reading experience first.

![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![macOS](https://img.shields.io/badge/macOS-13.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## ✨ Why Parchment?

Parchment is the markdown viewer for Mac users who appreciate native performance and exceptional design. Built with Swift and AppKit, it launches instantly, renders beautifully, and feels like a true Mac app should feel.

### Core Excellence
- **Instant Launch** - Native Swift/AppKit means no Electron overhead
- **Beautiful Typography** - Carefully tuned rendering for optimal readability  
- **Focus Mode** - Eliminate distractions with intelligent content dimming and typewriter scrolling
- **Smart Navigation** - Hierarchical table of contents with smooth scrolling
- **Live Preview** - See changes instantly as your files update
- **Reading Statistics** - Word count, reading time, and reading progress

### Design Features
- **Native Performance** - Optimized for smooth 120Hz scrolling on ProMotion displays
- **Thoughtful Themes** - Hand-crafted light and dark themes with perfect contrast
- **Syntax Highlighting** - Beautiful code block rendering that matches your theme
- **Distraction-Free** - Clean interface that gets out of your way
- **Quick Look Support** - Preview markdown files with spacebar in Finder

## 🚀 Real-World Performance

- **Instant** - Sub-100ms launch time
- **Lightweight** - Under 50MB memory usage for typical documents
- **Smooth** - Consistent 60-120fps scrolling
- **Responsive** - No beach balls, no lag, no waiting
- **Native** - True Mac app performance and efficiency

## 📦 Installation

### Building from Source

1. Clone the repository:
```bash
git clone https://github.com/cschuman/Parchment.git
cd Parchment
```

2. Build with Swift Package Manager:
```bash
swift build -c release
```

3. Run the application:
```bash
swift run Parchment
```

### Command Line Usage

```bash
# Open a specific markdown file
Parchment path/to/document.md

# Open with the GUI
open -a Parchment document.md
```

## ⌨️ Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Open File | `⌘O` |
| Export as PDF | `⌘E` |
| Toggle Focus Mode | `⌘F` |
| Toggle Table of Contents | `⌘T` |
| Show Reading Statistics | `⌘/` |
| Zoom In | `⌘+` |
| Zoom Out | `⌘-` |
| Actual Size | `⌘0` |
| Navigate to Next Header | `→` (three-finger swipe) |
| Navigate to Previous Header | `←` (three-finger swipe) |

## 🎯 Perfect For

### Documentation Review
- Preview README files with beautiful rendering
- Navigate large docs with the table of contents
- Copy code blocks with syntax highlighting preserved

### Focused Reading
- Distraction-free mode for long-form content
- Typewriter scrolling keeps your focus centered
- Reading statistics help track progress

### Quick Preview
- Spacebar preview in Finder via Quick Look
- Instant file switching with no lag
- Live updates as files change

## 🏗️ Clean Architecture

```
Parchment/
├── App/                    # Application lifecycle
├── Windows/                # Window management
├── ViewControllers/        # View controllers  
├── Views/                  # Custom views
├── Rendering/              # Markdown rendering pipeline
│   ├── MarkdownAttributedStringVisitor.swift
│   └── CodeSyntaxHighlighter.swift
├── Theme/                  # Theme management
├── Navigation/             # TOC and navigation
├── Export/                 # Export functionality
├── Performance/            # Performance monitoring
├── Utilities/              # Helper classes
└── Resources/             # Assets and themes
```

## 🔧 Configuration

Preferences are available through `⌘,` with options for:

- **Appearance**: Theme, font size, line spacing
- **Editor**: Focus mode, typewriter scrolling, syntax highlighting
- **General**: Default editor, recent files, auto-update
- **Advanced**: Cache management, performance tuning

## 🧪 Testing

Run the test suite:
```bash
swift test
```

## 💎 What Makes Parchment Different

Unlike Electron-based viewers, Parchment is a true native Mac app:
- Launches instantly, no spinner
- Uses native fonts and rendering
- Respects your system preferences
- Works perfectly with Mission Control and Spaces
- Minimal battery impact

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [swift-markdown](https://github.com/apple/swift-markdown) for markdown parsing
- [swift-syntax](https://github.com/apple/swift-syntax) for syntax highlighting
- The macOS developer community for inspiration

## 🗺️ Roadmap

### Near Term - Polish & Performance
- [ ] Enhanced typography with optical sizing
- [ ] Smooth spring-physics scrolling
- [ ] More beautiful built-in themes
- [ ] Faster document loading (<20ms)
- [ ] Print styles optimization

### Medium Term - Reading Experience
- [ ] Reading progress indicators
- [ ] Automatic bookmarks
- [ ] Export with custom styling
- [ ] Better image handling
- [ ] PDF export with perfect fidelity

### Long Term - Platform Excellence  
- [ ] Touch Bar support
- [ ] Handoff between devices
- [ ] Stage Manager optimization
- [ ] System text services integration

## 💬 Support

For issues, questions, or suggestions, please [open an issue](https://github.com/cschuman/Parchment/issues).

---

Built with ❤️ for the macOS community