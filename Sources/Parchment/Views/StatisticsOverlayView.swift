import Cocoa

class StatisticsOverlayView: NSView {
    private var visualEffectView: NSVisualEffectView!
    private var wordCountLabel: NSTextField!
    private var readingTimeLabel: NSTextField!
    private var complexityLabel: NSTextField!
    private var progressIndicator: NSProgressIndicator!
    private var closeButton: NSButton!
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        
        visualEffectView = NSVisualEffectView()
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.material = .hudWindow
        visualEffectView.state = .active
        visualEffectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(visualEffectView)
        
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.spacing = 12
        stackView.edgeInsets = NSEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = createLabel(text: "Reading Statistics", size: 14, weight: .semibold)
        stackView.addArrangedSubview(titleLabel)
        
        wordCountLabel = createLabel(text: "Words: 0", size: 12, weight: .regular)
        stackView.addArrangedSubview(wordCountLabel)
        
        readingTimeLabel = createLabel(text: "Reading time: 0 min", size: 12, weight: .regular)
        stackView.addArrangedSubview(readingTimeLabel)
        
        complexityLabel = createLabel(text: "Complexity: Simple", size: 12, weight: .regular)
        stackView.addArrangedSubview(complexityLabel)
        
        progressIndicator = NSProgressIndicator()
        progressIndicator.style = .bar
        progressIndicator.isIndeterminate = false
        progressIndicator.minValue = 0
        progressIndicator.maxValue = 100
        progressIndicator.doubleValue = 0
        stackView.addArrangedSubview(progressIndicator)
        
        closeButton = NSButton()
        closeButton.image = NSImage(systemSymbolName: "xmark.circle.fill", accessibilityDescription: "Close")
        closeButton.isBordered = false
        closeButton.target = self
        closeButton.action = #selector(close)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffectView.addSubview(stackView)
        visualEffectView.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            visualEffectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            visualEffectView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            
            closeButton.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 8),
            closeButton.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -8),
            closeButton.widthAnchor.constraint(equalToConstant: 20),
            closeButton.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        alphaValue = 0
    }
    
    private func createLabel(text: String, size: CGFloat, weight: NSFont.Weight) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: size, weight: weight)
        label.textColor = .labelColor
        return label
    }
    
    func updateStatistics(_ stats: ReadingStatistics) {
        wordCountLabel.stringValue = "Words: \(stats.wordCount)"
        readingTimeLabel.stringValue = "Reading time: \(stats.readingTime) min"
        
        let complexityText: String
        switch stats.complexityScore {
        case 0..<30:
            complexityText = "Simple"
        case 30..<60:
            complexityText = "Moderate"
        case 60..<80:
            complexityText = "Complex"
        default:
            complexityText = "Very Complex"
        }
        complexityLabel.stringValue = "Complexity: \(complexityText)"
        
        progressIndicator.doubleValue = stats.progress * 100
    }
    
    func show() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            self.alphaValue = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            self?.hide()
        }
    }
    
    func hide() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.allowsImplicitAnimation = true
            self.alphaValue = 0.0
        }
    }
    
    @objc private func close() {
        hide()
    }
}