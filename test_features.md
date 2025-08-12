# Parchment Feature Test Document

## Table of Contents
This document tests all the new features we've implemented in our award-winning markdown viewer.

## 📚 Typography & Reading Modes

### Normal Reading Mode
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

### Focus Mode Test
This paragraph should be highlighted when focus mode is enabled. The surrounding paragraphs will be dimmed to help you concentrate on the current content. This creates a distraction-free reading environment.

### Speed Reading Content
Quick facts for rapid scanning:
- Performance: 60fps guaranteed
- Load time: < 100ms
- Memory efficient
- Battery optimized

## 🎨 Code Blocks with Theater Mode

### Swift Example
```swift
class Parchment {
    func renderDocument(_ markdown: String) -> NSAttributedString {
        // This code block can be viewed in theater mode
        let parser = MarkdownParser()
        let ast = parser.parse(markdown)
        return renderer.render(ast)
    }
}
```

### JavaScript Example
```javascript
const markdownViewer = {
    render: function(markdown) {
        // Theater mode with syntax highlighting
        const ast = parse(markdown);
        return renderToHTML(ast);
    }
};
```

## 📊 Smart Tables

| Feature | Status | Performance |
|---------|--------|------------|
| Metal Rendering | ✅ Complete | 60fps |
| Progressive Loading | ✅ Complete | < 50ms |
| Glyph Caching | ✅ Complete | 95% hit rate |
| Focus Mode | ✅ Complete | Smooth |
| Theater Mode | ✅ Complete | Instant |

## 🔗 Navigation Testing

### Wiki-style Links
This document links to [[another document]] using wiki-style syntax. The backlinks panel will show all documents that link here.

### Regular Links
- [GitHub Repository](https://github.com/example/repo)
- [Documentation](https://docs.example.com)
- [Support](https://support.example.com)

## 📈 Long Content for Scroll Testing

### Section 1: Performance Metrics
The new rendering engine achieves consistent 60fps performance even with complex documents. The Metal-accelerated text rendering provides smooth scrolling and instant response times.

### Section 2: Typography Excellence
Our adaptive typography system adjusts line length, spacing, and font size based on the reading environment. This ensures optimal readability across all screen sizes.

### Section 3: Navigation Features
The floating table of contents tracks your reading progress in real-time. Each section shows a circular progress indicator that fills as you read through the content.

### Section 4: Search Capabilities
The instant fuzzy search finds content as you type, with live highlighting and categorized results. Search through headings, paragraphs, code blocks, and links with lightning speed.

### Section 5: Focus Enhancement
Multiple focus modes help you concentrate:
- Paragraph focus: Highlights current paragraph
- Sentence focus: Highlights current sentence
- Line focus: Highlights current line
- Gradual focus: Smooth gradient fade
- Spotlight: Circular highlight following cursor

## 🎯 Bionic Reading Test

This paragraph tests the **bi**onic **rea**ding **mo**de where the **fir**st **let**ters of **ea**ch **wo**rd are **bol**ded to **hel**p **yo**ur **bra**in **proc**ess **tex**t **fas**ter. **Stu**dies **sho**w this can **incr**ease **rea**ding **spe**ed by 30-50%.

## 🌙 Night Mode Content

This section is perfect for testing night mode with warm colors and reduced blue light. The sepia tones and adjusted contrast make reading comfortable in low-light conditions.

## 📝 Lists and Nested Content

1. First level item
   - Nested bullet point
   - Another nested item
     * Deep nesting test
     * With multiple levels
2. Second level item
   - More nested content
3. Third level item

## 💡 Blockquotes

> "The best markdown viewer isn't just about rendering text—it's about creating an exceptional reading experience."
> 
> — Anonymous Developer

## 🔬 Testing Section for Performance

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus lacinia odio vitae vestibulum. Donec auctor a lacus in tincidunt. Proin blandit, tortor at ultrices tincidunt, elit sapien facilisis lectus, nec accumsan nulla massa a odio. Sed cursus turpis in mauris vehicula, et consequat nisl faucibus. Donec auctor a lacus in tincidunt. Proin blandit, tortor at ultrices tincidunt, elit sapien facilisis lectus, nec accumsan nulla massa a odio.

---

## Footer
This document tests all major features of our enhanced Parchment. Each section is designed to showcase specific capabilities and ensure everything works perfectly.

**Reading time**: ~5 minutes  
**Word count**: ~750 words  
**Complexity**: Medium