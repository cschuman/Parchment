#!/usr/bin/env swift

import Foundation
import ArgumentParser

struct ParchmentCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "parchment",
        abstract: "A blazingly fast, native macOS markdown viewer",
        discussion: """
            Opens markdown files in Parchment viewer.
            
            Examples:
              parchment README.md           Open a single file
              parchment docs/               Open file browser at directory
              parchment *.md               Open all markdown files
              parchment                    Open Parchment with last document
            """,
        version: "2.0.0"
    )
    
    @Flag(name: .shortAndLong, help: "Open files in new window")
    var newWindow = false
    
    @Flag(name: [.customShort("t"), .long], help: "Open files in tabs (default)")
    var tab = false
    
    @Flag(name: .shortAndLong, help: "Wait for files to be closed before returning")
    var wait = false
    
    @Flag(name: .shortAndLong, help: "Don't bring app to foreground")
    var background = false
    
    @Flag(help: "Start in focus mode")
    var focus = false
    
    @Option(help: "Use specific theme")
    var theme: String?
    
    @Argument(help: "Files or directories to open")
    var paths: [String] = []
    
    mutating func run() throws {
        // Find Parchment.app
        let appPath = try findParchmentApp()
        
        // Resolve file paths
        let fileURLs = try resolvePaths(paths)
        
        // Build the open command
        var openArgs = ["-a", appPath]
        
        if newWindow {
            openArgs.append("-n")
        }
        
        if !background {
            openArgs.append("-F")  // Bring to foreground
        }
        
        if wait {
            openArgs.append("-W")
        }
        
        // Add file arguments
        if !fileURLs.isEmpty {
            openArgs.append("--args")
            for url in fileURLs {
                openArgs.append(url.path)
            }
        }
        
        // Execute open command
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = openArgs
        
        try process.run()
        
        if wait {
            process.waitUntilExit()
        }
    }
    
    private func findParchmentApp() throws -> String {
        // Check common locations
        let appPaths = [
            "/Applications/Parchment.app",
            "\(NSHomeDirectory())/Applications/Parchment.app",
            // Check if we're running from build directory
            "\(FileManager.default.currentDirectoryPath)/Parchment.app"
        ]
        
        for path in appPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try to find using mdfind
        let findProcess = Process()
        findProcess.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        findProcess.arguments = ["kMDItemCFBundleIdentifier == 'com.parchment.app'"]
        
        let pipe = Pipe()
        findProcess.standardOutput = pipe
        
        try findProcess.run()
        findProcess.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !output.isEmpty {
            let apps = output.split(separator: "\n")
            if let firstApp = apps.first {
                return String(firstApp)
            }
        }
        
        throw ValidationError("Parchment.app not found. Please install Parchment first.")
    }
    
    private func resolvePaths(_ paths: [String]) throws -> [URL] {
        var urls: [URL] = []
        let fileManager = FileManager.default
        
        for path in paths {
            // Expand tilde if present
            let expandedPath = NSString(string: path).expandingTildeInPath
            
            // Create URL (handle relative paths)
            let url: URL
            if expandedPath.hasPrefix("/") {
                url = URL(fileURLWithPath: expandedPath)
            } else {
                let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
                url = currentDirectory.appendingPathComponent(expandedPath)
            }
            
            // Check if path exists
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // For directories, we'll open the file browser at this location
                    urls.append(url)
                } else {
                    // For files, check if it's a markdown file
                    let markdownExtensions = ["md", "markdown", "mdown", "mkd", "mdwn", "mkdown", "text"]
                    if markdownExtensions.contains(url.pathExtension.lowercased()) {
                        urls.append(url)
                    } else {
                        print("Warning: \(path) is not a markdown file, opening anyway...")
                        urls.append(url)
                    }
                }
            } else {
                // Handle wildcards using glob
                let globPattern = url.path
                
                var globResult = glob_t()
                defer { globfree(&globResult) }
                
                let flags = GLOB_TILDE | GLOB_BRACE | GLOB_MARK
                if glob(globPattern, flags, nil, &globResult) == 0 {
                    for i in 0..<Int(globResult.gl_pathc) {
                        if let pathPtr = globResult.gl_pathv[i] {
                            let path = String(cString: pathPtr)
                            urls.append(URL(fileURLWithPath: path))
                        }
                    }
                } else {
                    throw ValidationError("File not found: \(path)")
                }
            }
        }
        
        return urls
    }
}

// For better error messages
struct ValidationError: Error, LocalizedError {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var errorDescription: String? {
        return message
    }
}

// Run the CLI
ParchmentCLI.main()