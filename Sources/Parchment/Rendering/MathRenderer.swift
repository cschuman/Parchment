import Cocoa
import WebKit
import CryptoKit

/// Renders LaTeX math expressions using KaTeX via WebKit
final class MathRenderer {

    // MARK: - Singleton

    static let shared = MathRenderer()

    // MARK: - Types

    enum MathType {
        case inline  // $...$
        case block   // $$...$$
    }

    struct MathExpression {
        let content: String
        let type: MathType
        let range: Range<String.Index>
    }

    // MARK: - Properties

    private var cache = NSCache<NSString, NSImage>()
    private let webView: WKWebView
    private let semaphore = DispatchSemaphore(value: 0)
    private var renderedImage: NSImage?
    private var renderError: Error?

    // MARK: - Initialization

    private init() {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: config)
        webView.navigationDelegate = nil

        // Load KaTeX HTML template
        loadKaTeXTemplate()
    }

    // MARK: - Public Interface

    /// Find all math expressions in text
    func findMathExpressions(in text: String) -> [MathExpression] {
        var expressions: [MathExpression] = []

        // Find block math first ($$...$$)
        let blockPattern = "\\$\\$([^$]+)\\$\\$"
        if let blockRegex = try? NSRegularExpression(pattern: blockPattern, options: [.dotMatchesLineSeparators]) {
            let nsText = text as NSString
            let matches = blockRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for match in matches {
                if let range = Range(match.range, in: text),
                   let contentRange = Range(match.range(at: 1), in: text) {
                    let content = String(text[contentRange])
                    expressions.append(MathExpression(content: content, type: .block, range: range))
                }
            }
        }

        // Find inline math ($...$) - but not $$
        let inlinePattern = "(?<!\\$)\\$([^$]+)\\$(?!\\$)"
        if let inlineRegex = try? NSRegularExpression(pattern: inlinePattern, options: []) {
            let nsText = text as NSString
            let matches = inlineRegex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))

            for match in matches {
                if let range = Range(match.range, in: text),
                   let contentRange = Range(match.range(at: 1), in: text) {
                    // Skip if this range overlaps with a block expression
                    let overlaps = expressions.contains { $0.range.overlaps(range) }
                    if !overlaps {
                        let content = String(text[contentRange])
                        expressions.append(MathExpression(content: content, type: .inline, range: range))
                    }
                }
            }
        }

        // Sort by range start position
        return expressions.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }

    /// Render a math expression to an image
    func render(_ expression: String, type: MathType, theme: ParchmentTheme) -> NSImage? {
        let cacheKey = cacheKeyFor(expression: expression, type: type, theme: theme)

        // Check cache first
        if let cached = cache.object(forKey: cacheKey as NSString) {
            return cached
        }

        // Render via KaTeX
        guard let image = renderWithKaTeX(expression: expression, type: type, theme: theme) else {
            return nil
        }

        // Cache the result
        cache.setObject(image, forKey: cacheKey as NSString)

        return image
    }

    /// Create an attributed string with math replaced by images
    func processText(_ text: String, baseAttributes: [NSAttributedString.Key: Any], theme: ParchmentTheme) -> NSAttributedString {
        let expressions = findMathExpressions(in: text)

        if expressions.isEmpty {
            return NSAttributedString(string: text, attributes: baseAttributes)
        }

        let result = NSMutableAttributedString()
        var lastEnd = text.startIndex

        for expr in expressions {
            // Add text before this expression
            if lastEnd < expr.range.lowerBound {
                let beforeText = String(text[lastEnd..<expr.range.lowerBound])
                result.append(NSAttributedString(string: beforeText, attributes: baseAttributes))
            }

            // Render math or fallback to raw text
            if let image = render(expr.content, type: expr.type, theme: theme) {
                let attachment = NSTextAttachment()
                attachment.image = image

                // Adjust vertical alignment for inline math
                if expr.type == .inline {
                    let font = baseAttributes[.font] as? NSFont ?? NSFont.systemFont(ofSize: 14)
                    let yOffset = (font.capHeight - image.size.height) / 2
                    attachment.bounds = NSRect(x: 0, y: yOffset, width: image.size.width, height: image.size.height)
                }

                result.append(NSAttributedString(attachment: attachment))
            } else {
                // Fallback: show raw LaTeX with styling
                let fallbackText = expr.type == .block ? "$$\(expr.content)$$" : "$\(expr.content)$"
                var fallbackAttrs = baseAttributes
                fallbackAttrs[.foregroundColor] = NSColor.systemOrange
                fallbackAttrs[.font] = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
                result.append(NSAttributedString(string: fallbackText, attributes: fallbackAttrs))
            }

            lastEnd = expr.range.upperBound
        }

        // Add remaining text
        if lastEnd < text.endIndex {
            let afterText = String(text[lastEnd...])
            result.append(NSAttributedString(string: afterText, attributes: baseAttributes))
        }

        return result
    }

    // MARK: - Private Methods

    private func cacheKeyFor(expression: String, type: MathType, theme: ParchmentTheme) -> String {
        let input = "\(expression)|\(type)|\(theme.name)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func loadKaTeXTemplate() {
        // KaTeX will be loaded from CDN in the HTML
    }

    private func renderWithKaTeX(expression: String, type: MathType, theme: ParchmentTheme) -> NSImage? {
        let isDark = theme.name == "Midnight"
        let textColor = isDark ? "#d0d0d0" : "#333333"
        let displayMode = type == .block ? "true" : "false"

        // Escape the expression for JavaScript
        let escapedExpr = expression
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.css">
            <script src="https://cdn.jsdelivr.net/npm/katex@0.16.9/dist/katex.min.js"></script>
            <style>
                body {
                    margin: 0;
                    padding: 8px;
                    background: transparent;
                    display: inline-block;
                }
                #math {
                    color: \(textColor);
                    font-size: 16px;
                }
            </style>
        </head>
        <body>
            <div id="math"></div>
            <script>
                try {
                    katex.render('\(escapedExpr)', document.getElementById('math'), {
                        displayMode: \(displayMode),
                        throwOnError: false,
                        output: 'html'
                    });
                    // Signal render complete
                    window.webkit.messageHandlers.renderComplete.postMessage({
                        width: document.body.scrollWidth,
                        height: document.body.scrollHeight
                    });
                } catch (e) {
                    window.webkit.messageHandlers.renderError.postMessage(e.message);
                }
            </script>
        </body>
        </html>
        """

        // For simplicity in this implementation, we'll use a synchronous approach
        // with a timeout. In production, this should be fully async.
        var resultImage: NSImage?

        DispatchQueue.main.sync {
            // Create a temporary web view for this render
            let config = WKWebViewConfiguration()
            let contentController = WKUserContentController()

            var completed = false

            class MessageHandler: NSObject, WKScriptMessageHandler {
                var onComplete: ((CGSize) -> Void)?
                var onError: ((String) -> Void)?

                func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                    if message.name == "renderComplete", let body = message.body as? [String: Any] {
                        let width = body["width"] as? CGFloat ?? 100
                        let height = body["height"] as? CGFloat ?? 30
                        onComplete?(CGSize(width: width, height: height))
                    } else if message.name == "renderError" {
                        onError?(message.body as? String ?? "Unknown error")
                    }
                }
            }

            let handler = MessageHandler()
            handler.onComplete = { size in
                completed = true
            }
            handler.onError = { _ in
                completed = true
            }

            contentController.add(handler, name: "renderComplete")
            contentController.add(handler, name: "renderError")
            config.userContentController = contentController

            let tempWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 100), configuration: config)
            tempWebView.loadHTMLString(html, baseURL: nil)

            // Wait for render with timeout
            let timeout = Date().addingTimeInterval(2.0)
            while !completed && Date() < timeout {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
            }

            if completed {
                // Take snapshot
                let snapshotConfig = WKSnapshotConfiguration()
                snapshotConfig.afterScreenUpdates = true

                let semaphore = DispatchSemaphore(value: 0)

                tempWebView.takeSnapshot(with: snapshotConfig) { image, error in
                    if let image = image {
                        // Crop to content
                        resultImage = self.cropToContent(image)
                    }
                    semaphore.signal()
                }

                _ = semaphore.wait(timeout: .now() + 1.0)
            }
        }

        return resultImage
    }

    private func cropToContent(_ image: NSImage) -> NSImage {
        // For now, just return the image as-is
        // A more sophisticated implementation would detect and crop whitespace
        return image
    }
}
