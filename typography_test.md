# Typography Excellence Test Document

This document tests all the new typography features in Parchment's enhanced rendering engine.

## Heading Hierarchy with Golden Ratio

# Heading 1 - Largest (40pt)
## Heading 2 - Large (33pt)
### Heading 3 - Medium Large (28pt)
#### Heading 4 - Medium (23pt)
##### Heading 5 - Small Medium (19pt)
###### Heading 6 - Base Size (16pt)

## Typography Features

### Smart Quotes and Punctuation

"These quotes should be curly" and 'single quotes too'. Notice how we handle contractions like don't, won't, and it's.

Em dashes -- like this -- should render as proper — em dashes.

Ellipsis... should become a single … character.

### Emphasis and Strong Text

This is *italic text* that should use the font's true italic variant, not just slanted.

This is **bold text** that should use proper bold weights.

This is ***bold italic*** combining both styles.

This is ~~strikethrough text~~ with a line through it.

### Code Blocks and Inline Code

Here's some `inline code` that should use monospace font with subtle background.

```swift
// Code block with syntax highlighting
func testTypography() -> String {
    let greeting = "Hello, beautiful typography!"
    return greeting
}
```

```python
# Python example
def golden_ratio(n):
    """Calculate golden ratio scaling"""
    phi = 1.618033988749
    return n * phi
```

### Lists with Proper Indentation

Unordered lists:
- First level bullet point
  - Second level with circle bullet
    - Third level with square bullet
      - Fourth level with hollow bullet
- Back to first level

Ordered lists:
1. First item with proper numbering
2. Second item with consistent spacing
   1. Nested item with sub-numbering
   2. Another nested item
3. Back to main level

### Block Quotes

> This is a blockquote that should be visually distinct with italic text and indentation.
> 
> Multiple paragraphs in quotes should maintain consistent styling.
> > Nested quotes should have additional indentation.

### Links and References

Check out [Parchment on GitHub](https://github.com/cschuman/Parchment) for more information.

Here's a [reference-style link][ref] for testing.

[ref]: https://example.com "Reference Title"

### Tables

| Feature | Status | Notes |
|---------|--------|-------|
| Typography Engine | ✅ Complete | Golden ratio, optical sizing |
| Smooth Scrolling | ✅ Complete | Spring physics, 120fps |
| Theme System | ✅ Complete | 5 beautiful themes |
| Performance | ✅ Complete | <50ms file opening |

### Long Paragraph for Line Height Testing

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. This paragraph tests line height, paragraph spacing, and text wrapping with our enhanced typography engine. The text should be comfortable to read with proper leading and measure.

### Special Characters and Unicode

Mathematical: ∑ ∏ √ ∞ ≈ ≠ ≤ ≥ ± × ÷

Arrows: → ← ↑ ↓ ⇒ ⇐ ⇑ ⇓

Typography: — – • … " " ' ' « » ‹ ›

Emoji: 🎨 ✨ 🚀 💎 🎯 ⚡ 🔥 ⭐

### Performance Test Section

The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs. The five boxing wizards jump quickly. How vexingly quick daft zebras jump! Bright vixens jump; dozy fowl quack.

---

## Testing Instructions

1. **Scroll Performance**: Scroll through this document rapidly and observe smoothness
2. **Theme Switching**: Try different themes to see typography adjustments
3. **Zoom Levels**: Test zoom in/out to see optical sizing
4. **Selection**: Select text to see selection colors
5. **Window Resize**: Resize window to test text reflow

---

*Document generated to test Parchment's enhanced typography engine*