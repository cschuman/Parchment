import Foundation
import Cocoa

/// Manages diff highlighting when documents are refreshed
class DiffHighlighter {
    
    struct DiffResult {
        let added: [NSRange]
        let deleted: [NSRange]
        let modified: [NSRange]
    }
    
    /// Compute the diff between old and new content
    static func computeDiff(old: String, new: String) -> DiffResult {
        let oldLines = old.components(separatedBy: .newlines)
        let newLines = new.components(separatedBy: .newlines)
        
        var added: [NSRange] = []
        var deleted: [NSRange] = []
        var modified: [NSRange] = []
        
        // Use LCS (Longest Common Subsequence) algorithm
        let lcs = longestCommonSubsequence(oldLines, newLines)
        
        var oldIndex = 0
        var newIndex = 0
        var currentLocation = 0
        
        for common in lcs {
            // Process deletions before the common line
            while oldIndex < common.oldIndex {
                let deletedLine = oldLines[oldIndex]
                deleted.append(NSRange(location: currentLocation, length: deletedLine.count))
                oldIndex += 1
            }
            
            // Process additions before the common line
            while newIndex < common.newIndex {
                let addedLine = newLines[newIndex]
                added.append(NSRange(location: currentLocation, length: addedLine.count))
                currentLocation += addedLine.count + 1 // +1 for newline
                newIndex += 1
            }
            
            // Skip the common line
            if oldIndex < oldLines.count && newIndex < newLines.count {
                let commonLine = newLines[newIndex]
                currentLocation += commonLine.count + 1
                oldIndex += 1
                newIndex += 1
            }
        }
        
        // Process remaining additions
        while newIndex < newLines.count {
            let addedLine = newLines[newIndex]
            added.append(NSRange(location: currentLocation, length: addedLine.count))
            currentLocation += addedLine.count + 1
            newIndex += 1
        }
        
        // Process remaining deletions
        while oldIndex < oldLines.count {
            oldIndex += 1
        }
        
        // Detect modified lines (changed but not added/deleted)
        modified = detectModifiedLines(oldLines: oldLines, newLines: newLines, lcs: lcs)
        
        return DiffResult(added: added, deleted: deleted, modified: modified)
    }
    
    /// Apply diff highlighting to an attributed string
    static func applyDiffHighlighting(
        to attributedString: NSMutableAttributedString,
        diff: DiffResult,
        duration: TimeInterval = 2.0
    ) {
        let addedColor = NSColor.systemGreen.withAlphaComponent(0.3)
        let modifiedColor = NSColor.systemYellow.withAlphaComponent(0.3)
        let deletedColor = NSColor.systemRed.withAlphaComponent(0.3)
        
        // Apply highlighting
        for range in diff.added {
            if range.location + range.length <= attributedString.length {
                attributedString.addAttribute(
                    .backgroundColor,
                    value: addedColor,
                    range: range
                )
            }
        }
        
        for range in diff.modified {
            if range.location + range.length <= attributedString.length {
                attributedString.addAttribute(
                    .backgroundColor,
                    value: modifiedColor,
                    range: range
                )
            }
        }
        
        // Deleted lines are shown with strikethrough since they're no longer in the text
        for range in diff.deleted {
            if range.location < attributedString.length {
                // Insert a placeholder for deleted content
                let deletedPlaceholder = NSAttributedString(
                    string: "[Line deleted]\n",
                    attributes: [
                        .backgroundColor: deletedColor,
                        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                        .font: NSFont.systemFont(ofSize: 12),
                        .foregroundColor: NSColor.secondaryLabelColor
                    ]
                )
                attributedString.insert(deletedPlaceholder, at: min(range.location, attributedString.length))
            }
        }
        
        // Schedule removal of highlighting
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            removeHighlighting(from: attributedString, diff: diff)
        }
    }
    
    /// Remove diff highlighting after a delay
    private static func removeHighlighting(from attributedString: NSMutableAttributedString, diff: DiffResult) {
        let allRanges = diff.added + diff.modified
        
        for range in allRanges {
            if range.location + range.length <= attributedString.length {
                attributedString.removeAttribute(.backgroundColor, range: range)
            }
        }
        
        // Remove deleted placeholders
        let deletedPattern = "\\[Line deleted\\]\\n"
        if let regex = try? NSRegularExpression(pattern: deletedPattern) {
            let matches = regex.matches(
                in: attributedString.string,
                range: NSRange(location: 0, length: attributedString.length)
            )
            
            // Remove from back to front to maintain indices
            for match in matches.reversed() {
                attributedString.deleteCharacters(in: match.range)
            }
        }
    }
    
    // MARK: - LCS Algorithm
    
    private struct CommonLine {
        let oldIndex: Int
        let newIndex: Int
        let line: String
    }
    
    private static func longestCommonSubsequence(_ old: [String], _ new: [String]) -> [CommonLine] {
        let m = old.count
        let n = new.count
        
        // Create DP table
        var dp = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        // Fill DP table
        for i in 1...m {
            for j in 1...n {
                if old[i-1] == new[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }
        
        // Backtrack to find LCS
        var lcs: [CommonLine] = []
        var i = m
        var j = n
        
        while i > 0 && j > 0 {
            if old[i-1] == new[j-1] {
                lcs.append(CommonLine(oldIndex: i-1, newIndex: j-1, line: old[i-1]))
                i -= 1
                j -= 1
            } else if dp[i-1][j] > dp[i][j-1] {
                i -= 1
            } else {
                j -= 1
            }
        }
        
        return lcs.reversed()
    }
    
    private static func detectModifiedLines(
        oldLines: [String],
        newLines: [String],
        lcs: [CommonLine]
    ) -> [NSRange] {
        var modified: [NSRange] = []
        var currentLocation = 0
        
        // Create sets of common line indices
        let commonOldIndices = Set(lcs.map { $0.oldIndex })
        let commonNewIndices = Set(lcs.map { $0.newIndex })
        
        // Check for lines that exist in similar positions but aren't identical
        for (newIndex, newLine) in newLines.enumerated() {
            if !commonNewIndices.contains(newIndex) {
                // Check if there's a similar line in the old content
                if newIndex < oldLines.count {
                    let oldLine = oldLines[newIndex]
                    let similarity = stringSimilarity(oldLine, newLine)
                    
                    if similarity > 0.5 && similarity < 1.0 {
                        // Line was modified, not added
                        modified.append(NSRange(location: currentLocation, length: newLine.count))
                    }
                }
            }
            currentLocation += newLine.count + 1
        }
        
        return modified
    }
    
    /// Calculate similarity between two strings (0.0 to 1.0)
    private static func stringSimilarity(_ s1: String, _ s2: String) -> Double {
        let longer = s1.count > s2.count ? s1 : s2
        let shorter = s1.count > s2.count ? s2 : s1
        
        if longer.isEmpty { return 1.0 }
        
        let editDistance = levenshteinDistance(shorter, longer)
        return Double(longer.count - editDistance) / Double(longer.count)
    }
    
    /// Calculate Levenshtein distance between two strings
    private static func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let m = s1.count
        let n = s2.count
        
        if m == 0 { return n }
        if n == 0 { return m }
        
        var matrix = Array(repeating: Array(repeating: 0, count: n + 1), count: m + 1)
        
        for i in 0...m { matrix[i][0] = i }
        for j in 0...n { matrix[0][j] = j }
        
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        
        for i in 1...m {
            for j in 1...n {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,      // deletion
                    matrix[i][j-1] + 1,      // insertion
                    matrix[i-1][j-1] + cost  // substitution
                )
            }
        }
        
        return matrix[m][n]
    }
}

// MARK: - Visual Effects

extension DiffHighlighter {
    
    /// Animate the diff highlighting with a fade-in effect
    static func animateDiffHighlighting(
        in textView: NSTextView,
        diff: DiffResult
    ) {
        guard let textStorage = textView.textStorage else { return }
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            
            // Create temporary overlay views for animation
            for range in diff.added {
                if let rect = rectForRange(range, in: textView) {
                    let overlay = createOverlay(rect: rect, color: .systemGreen, in: textView)
                    overlay.animator().alphaValue = 0.3
                }
            }
            
            for range in diff.modified {
                if let rect = rectForRange(range, in: textView) {
                    let overlay = createOverlay(rect: rect, color: .systemYellow, in: textView)
                    overlay.animator().alphaValue = 0.3
                }
            }
        }
    }
    
    private static func rectForRange(_ range: NSRange, in textView: NSTextView) -> NSRect? {
        guard let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer else { return nil }
        
        let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
        return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
    }
    
    private static func createOverlay(rect: NSRect, color: NSColor, in textView: NSTextView) -> NSView {
        let overlay = NSView(frame: rect)
        overlay.wantsLayer = true
        overlay.layer?.backgroundColor = color.withAlphaComponent(0).cgColor
        overlay.alphaValue = 0
        textView.addSubview(overlay)
        
        // Auto-remove after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            overlay.removeFromSuperview()
        }
        
        return overlay
    }
}