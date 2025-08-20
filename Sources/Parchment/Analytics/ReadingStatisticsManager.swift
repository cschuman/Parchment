import Cocoa

/// Protocol for statistics calculation
protocol StatisticsCalculating {
    func calculateStatistics(for document: MarkdownDocument, scrollProgress: Double) -> ReadingStatistics
    func calculateReadingTime(wordCount: Int) -> Int
    func calculateComplexity(text: String) -> Int
}

/// Manages reading statistics calculation and display
final class ReadingStatisticsManager: StatisticsCalculating {
    
    // MARK: - Properties
    
    private weak var parentView: NSView?
    private var statisticsOverlay: StatisticsOverlayView?
    
    // MARK: - Configuration
    
    private struct Configuration {
        static let averageReadingSpeed = 200 // words per minute
        static let overlayWidth: CGFloat = 250
        static let overlayHeight: CGFloat = 150
        static let overlayMargin: CGFloat = 20
    }
    
    // MARK: - Initialization
    
    init(parentView: NSView? = nil) {
        self.parentView = parentView
    }
    
    // MARK: - Public Interface
    
    /// Show statistics overlay for the given document
    func showStatistics(for document: MarkdownDocument, scrollProgress: Double) {
        guard let parentView = parentView else { return }
        
        // Create overlay if needed
        if statisticsOverlay == nil {
            createOverlay(in: parentView)
        }
        
        let statistics = calculateStatistics(for: document, scrollProgress: scrollProgress)
        statisticsOverlay?.updateStatistics(statistics)
        statisticsOverlay?.show()
    }
    
    /// Hide the statistics overlay
    func hideStatistics() {
        statisticsOverlay?.hide()
    }
    
    /// Toggle statistics visibility
    func toggleStatistics(for document: MarkdownDocument, scrollProgress: Double) {
        if statisticsOverlay?.superview != nil && statisticsOverlay?.isHidden == false {
            hideStatistics()
        } else {
            showStatistics(for: document, scrollProgress: scrollProgress)
        }
    }
    
    // MARK: - Statistics Calculation
    
    func calculateStatistics(for document: MarkdownDocument, scrollProgress: Double) -> ReadingStatistics {
        let text = document.content
        
        // Word count
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        let wordCount = words.count
        
        // Character count
        let characterCount = text.count
        
        // Reading time
        let readingTime = calculateReadingTime(wordCount: wordCount)
        
        // Complexity score
        let complexityScore = calculateComplexity(text: text)
        
        return ReadingStatistics(
            wordCount: wordCount,
            characterCount: characterCount,
            readingTime: readingTime,
            complexityScore: complexityScore,
            progress: scrollProgress
        )
    }
    
    func calculateReadingTime(wordCount: Int) -> Int {
        return Int(ceil(Double(wordCount) / Double(Configuration.averageReadingSpeed)))
    }
    
    func calculateComplexity(text: String) -> Int {
        // Split into sentences
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        guard !sentences.isEmpty else { return 0 }
        
        // Calculate average words per sentence
        let avgWordsPerSentence = Double(words.count) / Double(sentences.count)
        
        // Calculate average word length
        let totalCharacters = words.reduce(0) { $0 + $1.count }
        let avgWordLength = words.isEmpty ? 0 : Double(totalCharacters) / Double(words.count)
        
        // Simple complexity formula
        // Considers sentence length and word length
        let sentenceLengthScore = min(50, Int(avgWordsPerSentence * 2))
        let wordLengthScore = min(50, Int(avgWordLength * 7))
        
        return min(100, sentenceLengthScore + wordLengthScore)
    }
    
    // MARK: - Private Methods
    
    private func createOverlay(in parentView: NSView) {
        statisticsOverlay = StatisticsOverlayView()
        parentView.addSubview(statisticsOverlay!)
        
        statisticsOverlay?.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statisticsOverlay!.topAnchor.constraint(
                equalTo: parentView.topAnchor,
                constant: Configuration.overlayMargin
            ),
            statisticsOverlay!.trailingAnchor.constraint(
                equalTo: parentView.trailingAnchor,
                constant: -Configuration.overlayMargin
            ),
            statisticsOverlay!.widthAnchor.constraint(
                equalToConstant: Configuration.overlayWidth
            ),
            statisticsOverlay!.heightAnchor.constraint(
                equalToConstant: Configuration.overlayHeight
            )
        ])
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        statisticsOverlay?.removeFromSuperview()
        statisticsOverlay = nil
    }
}

// MARK: - Advanced Statistics

extension ReadingStatisticsManager {
    
    /// Calculate Flesch Reading Ease score (0-100, higher = easier)
    func calculateFleschReadingEase(text: String) -> Double {
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        let syllables = words.reduce(0) { $0 + countSyllables(in: $1) }
        
        guard !sentences.isEmpty && !words.isEmpty else { return 0 }
        
        let avgSentenceLength = Double(words.count) / Double(sentences.count)
        let avgSyllablesPerWord = Double(syllables) / Double(words.count)
        
        // Flesch Reading Ease formula
        let score = 206.835 - 1.015 * avgSentenceLength - 84.6 * avgSyllablesPerWord
        
        return max(0, min(100, score))
    }
    
    private func countSyllables(in word: String) -> Int {
        let vowels = CharacterSet(charactersIn: "aeiouAEIOU")
        var count = 0
        var previousWasVowel = false
        
        for char in word.unicodeScalars {
            let isVowel = vowels.contains(char)
            if isVowel && !previousWasVowel {
                count += 1
            }
            previousWasVowel = isVowel
        }
        
        // Adjust for silent 'e' at end
        if word.lowercased().hasSuffix("e") && count > 1 {
            count -= 1
        }
        
        return max(1, count) // Every word has at least one syllable
    }
}