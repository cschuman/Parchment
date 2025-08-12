import Foundation
import Cocoa
import WebKit
import MarkdownKit

/// Renders Mermaid diagrams in markdown
class MermaidRenderer: NSObject {
    
    static let shared = MermaidRenderer()
    
    private var webView: WKWebView?
    private var pendingRenders: [(id: String, code: String, completion: (NSImage?) -> Void)] = []
    private var isWebViewReady = false
    
    override init() {
        super.init()
        setupWebView()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.preferences.javaScriptEnabled = true
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView?.navigationDelegate = self
        
        // Load Mermaid HTML template
        loadMermaidTemplate()
    }
    
    private func loadMermaidTemplate() {
        let html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body {
                    margin: 0;
                    padding: 20px;
                    background: white;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Helvetica, Arial, sans-serif;
                }
                #output {
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    min-height: 100px;
                }
                .mermaid {
                    text-align: center;
                }
                .error {
                    color: red;
                    font-size: 14px;
                    padding: 10px;
                    border: 1px solid red;
                    border-radius: 4px;
                    background: #ffeeee;
                }
            </style>
            <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
            <script>
                mermaid.initialize({ 
                    startOnLoad: false,
                    theme: 'default',
                    themeVariables: {
                        primaryColor: '#007AFF',
                        primaryTextColor: '#000',
                        primaryBorderColor: '#007AFF',
                        lineColor: '#333',
                        secondaryColor: '#f0f0f0',
                        tertiaryColor: '#fff'
                    }
                });
                
                async function renderDiagram(code) {
                    const output = document.getElementById('output');
                    try {
                        // Clear previous content
                        output.innerHTML = '';
                        
                        // Create unique ID
                        const id = 'mermaid-' + Date.now();
                        
                        // Render the diagram
                        const { svg } = await mermaid.render(id, code);
                        output.innerHTML = svg;
                        
                        // Send success message
                        window.webkit.messageHandlers.mermaidResult.postMessage({
                            success: true,
                            svg: svg
                        });
                    } catch (error) {
                        output.innerHTML = '<div class="error">Failed to render diagram: ' + error.message + '</div>';
                        window.webkit.messageHandlers.mermaidResult.postMessage({
                            success: false,
                            error: error.message
                        });
                    }
                }
            </script>
        </head>
        <body>
            <div id="output"></div>
        </body>
        </html>
        """
        
        webView?.loadHTMLString(html, baseURL: nil)
    }
    
    /// Render a Mermaid diagram to an image
    func renderDiagram(_ code: String, completion: @escaping (NSImage?) -> Void) {
        let id = UUID().uuidString
        pendingRenders.append((id: id, code: code, completion: completion))
        
        if isWebViewReady {
            processPendingRenders()
        }
    }
    
    private func processPendingRenders() {
        guard let render = pendingRenders.first else { return }
        
        // Add message handler for results
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "mermaidResult")
        webView?.configuration.userContentController.add(self, name: "mermaidResult")
        
        // Execute render
        let escapedCode = render.code
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\"", with: "\\\"")
        
        let js = "renderDiagram(`\(escapedCode)`);"
        webView?.evaluateJavaScript(js) { _, error in
            if let error = error {
                print("Mermaid render error: \(error)")
                self.pendingRenders.removeFirst()
                render.completion(nil)
                self.processPendingRenders()
            }
        }
    }
    
    /// Check if content is a Mermaid diagram
    static func isMermaidDiagram(_ code: String) -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let mermaidKeywords = ["graph", "sequenceDiagram", "classDiagram", "stateDiagram",
                               "erDiagram", "gantt", "pie", "flowchart", "gitGraph",
                               "journey", "quadrantChart", "requirementDiagram", "C4Context"]
        
        return mermaidKeywords.contains { keyword in
            trimmed.hasPrefix(keyword)
        }
    }
    
    /// Create a placeholder image while rendering
    static func createPlaceholderImage(size: NSSize = NSSize(width: 400, height: 200)) -> NSImage {
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        // Background
        NSColor.controlBackgroundColor.setFill()
        NSRect(origin: .zero, size: size).fill()
        
        // Border
        NSColor.separatorColor.setStroke()
        let borderPath = NSBezierPath(rect: NSRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5))
        borderPath.lineWidth = 1
        borderPath.stroke()
        
        // Loading text
        let text = "Loading Mermaid diagram..."
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.secondaryLabelColor
        ]
        
        let textSize = text.size(withAttributes: attributes)
        let textRect = NSRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        text.draw(in: textRect, withAttributes: attributes)
        
        image.unlockFocus()
        
        return image
    }
}

// MARK: - WKNavigationDelegate

extension MermaidRenderer: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isWebViewReady = true
        processPendingRenders()
    }
}

// MARK: - WKScriptMessageHandler

extension MermaidRenderer: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "mermaidResult",
              let result = message.body as? [String: Any],
              let success = result["success"] as? Bool else { return }
        
        if success, let svgString = result["svg"] as? String {
            // Convert SVG to NSImage
            if let svgData = svgString.data(using: .utf8),
               let image = NSImage(data: svgData) {
                
                if let render = pendingRenders.first {
                    pendingRenders.removeFirst()
                    render.completion(image)
                    
                    // Process next render
                    processPendingRenders()
                }
            } else {
                // Try to create image from SVG using WebView snapshot
                captureWebViewAsImage()
            }
        } else {
            if let render = pendingRenders.first {
                pendingRenders.removeFirst()
                render.completion(nil)
                processPendingRenders()
            }
        }
    }
    
    private func captureWebViewAsImage() {
        guard let webView = webView else { return }
        
        webView.takeSnapshot(with: nil) { image, error in
            if let render = self.pendingRenders.first {
                self.pendingRenders.removeFirst()
                render.completion(image)
                self.processPendingRenders()
            }
        }
    }
}

