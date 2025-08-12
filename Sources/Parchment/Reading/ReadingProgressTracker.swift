import Cocoa
import QuartzCore

final class ReadingProgressTracker {
    
    var showProgressIndicator = false
    
    struct ReadingSession: Codable {
        let documentURL: URL
        let startTime: Date
        var endTime: Date?
        var wordsRead: Int
        var scrollPositions: [TimeInterval: CGFloat]
        var focusedTime: TimeInterval
        var totalTime: TimeInterval
        var completionPercentage: Double
    }
    
    struct ReadingMetrics {
        var wordsPerMinute: Double
        var averageSessionLength: TimeInterval
        var totalReadingTime: TimeInterval
        var documentsRead: Int
        var favoriteReadingTime: DateComponents
        var readingStreak: Int
        var comprehensionScore: Double
    }
    
    private var currentSession: ReadingSession?
    private var sessions: [ReadingSession] = []
    private var progressView: ReadingProgressView?
    private weak var scrollView: NSScrollView?
    private weak var textView: NSTextView?
    
    private var sessionTimer: Timer?
    private var focusTimer: Timer?
    private var idleTimer: Timer?
    private var isIdle = false
    private var lastScrollPosition: CGFloat = 0
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "ReadingProgress"
    private let metricsKey = "ReadingMetrics"
    
    init(scrollView: NSScrollView, textView: NSTextView) {
        self.scrollView = scrollView
        self.textView = textView
        setupObservers()
        loadSavedProgress()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(scrollViewDidScroll),
            name: NSScrollView.didLiveScrollNotification,
            object: scrollView
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: scrollView?.window
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidResignKey),
            name: NSWindow.didResignKeyNotification,
            object: scrollView?.window
        )
        
        NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .keyDown]) { [weak self] event in
            self?.resetIdleTimer()
            return event
        }
    }
    
    func startTracking(for documentURL: URL, content: String) {
        endCurrentSession()
        
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        
        currentSession = ReadingSession(
            documentURL: documentURL,
            startTime: Date(),
            endTime: nil,
            wordsRead: 0,
            scrollPositions: [:],
            focusedTime: 0,
            totalTime: 0,
            completionPercentage: 0
        )
        
        startSessionTimer()
        if showProgressIndicator {
            displayProgressIndicator()
        }
    }
    
    func stopTracking() {
        endCurrentSession()
        hideProgressIndicator()
    }
    
    private func startSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateSessionMetrics()
        }
        
        focusTimer?.invalidate()
        focusTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateFocusTime()
        }
        
        resetIdleTimer()
    }
    
    private func resetIdleTimer() {
        isIdle = false
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.isIdle = true
        }
    }
    
    private func updateSessionMetrics() {
        guard var session = currentSession else { return }
        
        session.totalTime += 1
        
        if !isIdle {
            session.focusedTime += 1
        }
        
        let scrollPosition = scrollView?.contentView.bounds.origin.y ?? 0
        session.scrollPositions[session.totalTime] = scrollPosition
        
        session.completionPercentage = calculateReadingProgress()
        
        let wordsVisible = calculateVisibleWords()
        if scrollPosition > lastScrollPosition {
            session.wordsRead += wordsVisible
        }
        lastScrollPosition = scrollPosition
        
        currentSession = session
        
        updateProgressView()
        
        if session.totalTime.truncatingRemainder(dividingBy: 60) == 0 {
            saveProgress()
        }
    }
    
    private func updateFocusTime() {
        guard NSApp.isActive,
              scrollView?.window?.isKeyWindow ?? false,
              !isIdle else { return }
        
        currentSession?.focusedTime += 0.5
    }
    
    private func calculateReadingProgress() -> Double {
        guard let scrollView = scrollView,
              let documentView = scrollView.documentView else { return 0 }
        
        let visibleRect = scrollView.contentView.visibleRect
        let totalHeight = documentView.frame.height
        let scrollPosition = visibleRect.origin.y + visibleRect.height
        
        return min(1.0, max(0, scrollPosition / totalHeight))
    }
    
    private func calculateVisibleWords() -> Int {
        guard let textView = textView,
              let textStorage = textView.textStorage else { return 0 }
        
        let visibleRange = textView.visibleRange()
        let visibleText = (textStorage.string as NSString).substring(with: visibleRange)
        
        return visibleText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
    }
    
    private func endCurrentSession() {
        guard var session = currentSession else { return }
        
        session.endTime = Date()
        sessions.append(session)
        
        saveProgress()
        
        sessionTimer?.invalidate()
        focusTimer?.invalidate()
        idleTimer?.invalidate()
        
        currentSession = nil
    }
    
    private func displayProgressIndicator() {
        guard progressView == nil,
              let window = scrollView?.window else { return }
        
        progressView = ReadingProgressView()
        progressView?.translatesAutoresizingMaskIntoConstraints = false
        
        window.contentView?.addSubview(progressView!)
        
        NSLayoutConstraint.activate([
            progressView!.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            progressView!.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            progressView!.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            progressView!.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        progressView?.animateIn()
    }
    
    private func hideProgressIndicator() {
        progressView?.animateOut {
            self.progressView?.removeFromSuperview()
            self.progressView = nil
        }
    }
    
    private func updateProgressView() {
        guard let session = currentSession else { return }
        
        progressView?.updateProgress(
            percentage: session.completionPercentage,
            wordsRead: session.wordsRead,
            timeSpent: session.focusedTime,
            wordsPerMinute: calculateWPM()
        )
    }
    
    private func calculateWPM() -> Double {
        guard let session = currentSession,
              session.focusedTime > 0 else { return 0 }
        
        let minutes = session.focusedTime / 60.0
        return Double(session.wordsRead) / max(minutes, 1)
    }
    
    func getReadingMetrics() -> ReadingMetrics {
        let totalWords = sessions.reduce(0) { $0 + $1.wordsRead }
        let totalTime = sessions.reduce(0) { $0 + $1.focusedTime }
        let avgWPM = totalTime > 0 ? Double(totalWords) / (totalTime / 60.0) : 0
        
        let avgSessionLength = sessions.isEmpty ? 0 :
            totalTime / TimeInterval(sessions.count)
        
        let favoriteHour = calculateFavoriteReadingHour()
        
        return ReadingMetrics(
            wordsPerMinute: avgWPM,
            averageSessionLength: avgSessionLength,
            totalReadingTime: totalTime,
            documentsRead: Set(sessions.map { $0.documentURL }).count,
            favoriteReadingTime: favoriteHour,
            readingStreak: calculateReadingStreak(),
            comprehensionScore: calculateComprehensionScore()
        )
    }
    
    private func calculateFavoriteReadingHour() -> DateComponents {
        var hourCounts: [Int: Int] = [:]
        
        for session in sessions {
            let hour = Calendar.current.component(.hour, from: session.startTime)
            hourCounts[hour, default: 0] += 1
        }
        
        let favoriteHour = hourCounts.max { $0.value < $1.value }?.key ?? 0
        
        var components = DateComponents()
        components.hour = favoriteHour
        return components
    }
    
    private func calculateReadingStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        for _ in 0..<365 {
            let hasSession = sessions.contains { session in
                calendar.isDate(session.startTime, inSameDayAs: currentDate)
            }
            
            if hasSession {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func calculateComprehensionScore() -> Double {
        guard !sessions.isEmpty else { return 0 }
        
        var score = 0.0
        
        for session in sessions {
            let focusRatio = session.focusedTime / max(session.totalTime, 1)
            
            let wpm = Double(session.wordsRead) / max(session.focusedTime / 60.0, 1)
            let wpmScore = min(1.0, wpm / 300.0)
            
            let completionScore = session.completionPercentage
            
            let sessionScore = (focusRatio * 0.4 + wpmScore * 0.3 + completionScore * 0.3)
            score += sessionScore
        }
        
        return (score / Double(sessions.count)) * 100
    }
    
    private func saveProgress() {
        let encoder = JSONEncoder()
        
        if let session = currentSession,
           let data = try? encoder.encode(session) {
            userDefaults.set(data, forKey: "\(progressKey)_current")
        }
        
        if let data = try? encoder.encode(sessions) {
            userDefaults.set(data, forKey: "\(progressKey)_history")
        }
    }
    
    private func loadSavedProgress() {
        let decoder = JSONDecoder()
        
        if let data = userDefaults.data(forKey: "\(progressKey)_history"),
           let savedSessions = try? decoder.decode([ReadingSession].self, from: data) {
            sessions = savedSessions
        }
    }
    
    @objc private func scrollViewDidScroll(_ notification: Notification) {
        resetIdleTimer()
    }
    
    @objc private func windowDidBecomeKey(_ notification: Notification) {
        resetIdleTimer()
    }
    
    @objc private func windowDidResignKey(_ notification: Notification) {
        isIdle = true
    }
}

class ReadingProgressView: NSView {
    private var progressBar: CALayer!
    private var statsLabel: NSTextField!
    private var isAnimating = false
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        wantsLayer = true
        layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
        
        progressBar = CALayer()
        progressBar.backgroundColor = NSColor.systemBlue.cgColor
        progressBar.cornerRadius = 2
        layer?.addSublayer(progressBar)
        
        statsLabel = NSTextField(labelWithString: "")
        statsLabel.font = NSFont.systemFont(ofSize: 10)
        statsLabel.textColor = NSColor.secondaryLabelColor
        statsLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(statsLabel)
        
        NSLayoutConstraint.activate([
            statsLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            statsLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    func updateProgress(percentage: Double, wordsRead: Int, timeSpent: TimeInterval, wordsPerMinute: Double) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.3)
        
        let width = bounds.width * CGFloat(percentage)
        progressBar.frame = CGRect(x: 0, y: 0, width: width, height: bounds.height)
        
        CATransaction.commit()
        
        let minutes = Int(timeSpent / 60)
        let wpm = Int(wordsPerMinute)
        statsLabel.stringValue = "\(Int(percentage * 100))% • \(wordsRead) words • \(minutes)m • \(wpm) wpm"
        
        let hue = CGFloat(percentage * 0.3)
        progressBar.backgroundColor = NSColor(hue: hue, saturation: 0.7, brightness: 0.9, alpha: 1.0).cgColor
    }
    
    func animateIn() {
        alphaValue = 0
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            self.animator().alphaValue = 1
        }
    }
    
    func animateOut(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            self.animator().alphaValue = 0
        }) {
            completion()
        }
    }
}

// NSTextView.visibleRange() extension is defined in AnimationEngine.swift