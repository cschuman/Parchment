# Markdown Formatting Test

This document tests **all** the _various_ inline formatting options.

## Inline Formatting

- **Bold text** using double asterisks
- *Italic text* using single asterisks
- _Alternative italic_ using underscores
- ***Bold and italic*** combined
- `Inline code` with backticks
- ~~Strikethrough text~~ with tildes

## Links and References

- [Link to GitHub](https://github.com)
- [Link with **bold** text](https://example.com)
- Raw URL: https://www.apple.com
- Reference-style link: [link text][1]

[1]: https://www.google.com "Google"

## Code Blocks

Inline code: `const x = 42;` looks different from blocks:

```javascript
function hello() {
    console.log("Hello, World!");
    return 42;
}
```

```python
def factorial(n):
    if n <= 1:
        return 1
    return n * factorial(n - 1)
```

## Tables

| Feature | Status | Notes |
|---------|--------|-------|
| **Bold** | ✅ Working | Renders correctly |
| *Italic* | ✅ Working | Also renders |
| `Code` | ✅ Working | Monospace font |
| Links | ✅ Working | Clickable |

## Block Quotes

> This is a blockquote with **bold** and *italic* text.
> It can span multiple lines.
> 
> > And even be nested!

## Lists with Formatting

1. First item with **bold text**
2. Second item with *italic text*
3. Third item with `inline code`
   - Nested item with ~~strikethrough~~
   - Another nested with [a link](https://example.com)

## Mixed Content

This paragraph contains **bold text**, *italic text*, `inline code`, [links](https://example.com), and even ~~strikethrough~~. All in one place!

### Complex Example

The `markdown-viewer` app supports **all standard markdown** including:
- Lists with *formatting*
- Tables with `code`
- Links like [this one](https://github.com)

> **Note:** This blockquote contains `code` and [links](https://example.com) too!