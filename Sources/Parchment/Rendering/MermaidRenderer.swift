import Cocoa
import WebKit
import CryptoKit

/// Renders Mermaid diagrams using Mermaid.js via WebKit
final class MermaidRenderer {

    // MARK: - Singleton

    static let shared = MermaidRenderer()

    // MARK: - Properties

    private var cache = NSCache<NSString, NSImage>()

    // MARK: - Initialization

    private init() {
        cache.countLimit = 50  // Limit cache to 50 diagrams
    }

    // MARK: - Public Interface

    /// Render a Mermaid diagram to an image
    func render(_ diagramCode: String, theme: ParchmentTheme) -> NSImage? {
        let cacheKey = cacheKeyFor(diagram: diagramCode, theme: theme)

        // Check cache first
        if let cached = cache.object(forKey: cacheKey as NSString) {
            return cached
        }

        // Render via Mermaid.js
        guard let image = renderWithMermaid(diagram: diagramCode, theme: theme) else {
            return nil
        }

        // Cache the result
        cache.setObject(image, forKey: cacheKey as NSString)

        return image
    }

    /// Create an attributed string with the rendered diagram or fallback
    func renderToAttributedString(_ diagramCode: String, theme: ParchmentTheme, baseAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        if let image = render(diagramCode, theme: theme) {
            let attachment = NSTextAttachment()
            attachment.image = image

            let result = NSMutableAttributedString()
            result.append(NSAttributedString(string: "\n"))
            result.append(NSAttributedString(attachment: attachment))
            result.append(NSAttributedString(string: "\n"))

            return result
        } else {
            // Fallback: show code block with error message
            return createFallback(diagramCode: diagramCode, baseAttributes: baseAttributes)
        }
    }

    // MARK: - Private Methods

    private func cacheKeyFor(diagram: String, theme: ParchmentTheme) -> String {
        let input = "\(diagram)|\(theme.name)"
        let hash = SHA256.hash(data: Data(input.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    private func renderWithMermaid(diagram: String, theme: ParchmentTheme) -> NSImage? {
        let isDark = theme.name == "Midnight"
        let mermaidTheme = isDark ? "dark" : "default"
        let bgColor = isDark ? "#1a1a1a" : "#ffffff"

        // Escape the diagram for JavaScript - encode as base64 to avoid injection
        let diagramData = diagram.data(using: .utf8) ?? Data()
        let base64Diagram = diagramData.base64EncodedString()

        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
            <style>
                body {
                    margin: 0;
                    padding: 16px;
                    background: \(bgColor);
                    display: flex;
                    justify-content: center;
                }
                #diagram {
                    display: inline-block;
                }
            </style>
        </head>
        <body>
            <div id="diagram"></div>
            <script>
                mermaid.initialize({
                    startOnLoad: false,
                    theme: '\(mermaidTheme)',
                    securityLevel: 'strict'
                });

                async function renderDiagram() {
                    try {
                        // Decode base64 diagram safely
                        const diagramCode = atob('\(base64Diagram)');

                        // Use mermaid's render API which returns sanitized SVG
                        const { svg } = await mermaid.render('mermaid-svg', diagramCode);

                        // Create SVG element safely using DOM APIs
                        const container = document.getElementById('diagram');
                        const parser = new DOMParser();
                        const svgDoc = parser.parseFromString(svg, 'image/svg+xml');
                        const svgElement = svgDoc.documentElement;

                        // Clear and append
                        while (container.firstChild) {
                            container.removeChild(container.firstChild);
                        }
                        container.appendChild(document.importNode(svgElement, true));

                        // Wait for SVG to render
                        await new Promise(resolve => setTimeout(resolve, 100));

                        const svgEl = container.querySelector('svg');
                        if (svgEl) {
                            const rect = svgEl.getBoundingClientRect();
                            window.webkit.messageHandlers.renderComplete.postMessage({
                                width: Math.ceil(rect.width) + 32,
                                height: Math.ceil(rect.height) + 32
                            });
                        } else {
                            window.webkit.messageHandlers.renderError.postMessage('SVG not found');
                        }
                    } catch (e) {
                        window.webkit.messageHandlers.renderError.postMessage(e.message || 'Unknown error');
                    }
                }

                renderDiagram();
            </script>
        </body>
        </html>
        """

        var resultImage: NSImage?

        DispatchQueue.main.sync {
            let config = WKWebViewConfiguration()
            let contentController = WKUserContentController()

            var completed = false
            var renderSize = CGSize(width: 400, height: 300)

            class MessageHandler: NSObject, WKScriptMessageHandler {
                var onComplete: ((CGSize) -> Void)?
                var onError: ((String) -> Void)?

                func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                    if message.name == "renderComplete", let body = message.body as? [String: Any] {
                        let width = body["width"] as? CGFloat ?? 400
                        let height = body["height"] as? CGFloat ?? 300
                        onComplete?(CGSize(width: width, height: height))
                    } else if message.name == "renderError" {
                        onError?(message.body as? String ?? "Unknown error")
                    }
                }
            }

            let handler = MessageHandler()
            handler.onComplete = { size in
                renderSize = size
                completed = true
            }
            handler.onError = { error in
                Logger.warning("Mermaid render error: \(error)")
                completed = true
            }

            contentController.add(handler, name: "renderComplete")
            contentController.add(handler, name: "renderError")
            config.userContentController = contentController

            let tempWebView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: config)
            tempWebView.loadHTMLString(html, baseURL: nil)

            // Wait for render with timeout
            let timeout = Date().addingTimeInterval(5.0)  // Longer timeout for complex diagrams
            while !completed && Date() < timeout {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
            }

            if completed {
                // Resize webview to content
                tempWebView.frame = NSRect(origin: .zero, size: renderSize)

                // Take snapshot
                let snapshotConfig = WKSnapshotConfiguration()
                snapshotConfig.afterScreenUpdates = true

                let semaphore = DispatchSemaphore(value: 0)

                tempWebView.takeSnapshot(with: snapshotConfig) { image, error in
                    resultImage = image
                    semaphore.signal()
                }

                _ = semaphore.wait(timeout: .now() + 2.0)
            }
        }

        return resultImage
    }

    private func createFallback(diagramCode: String, baseAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let result = NSMutableAttributedString()

        // Add error header
        var headerAttrs = baseAttributes
        headerAttrs[.foregroundColor] = NSColor.systemOrange
        headerAttrs[.font] = NSFont.systemFont(ofSize: 12, weight: .medium)
        result.append(NSAttributedString(string: "\n[Mermaid diagram - rendering failed]\n", attributes: headerAttrs))

        // Add the code
        var codeAttrs = baseAttributes
        codeAttrs[.font] = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        codeAttrs[.foregroundColor] = NSColor.secondaryLabelColor
        result.append(NSAttributedString(string: diagramCode, attributes: codeAttrs))
        result.append(NSAttributedString(string: "\n", attributes: baseAttributes))

        return result
    }
}
