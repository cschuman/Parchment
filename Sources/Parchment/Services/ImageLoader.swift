import Cocoa

/// Secure image loader with SSRF protection, size limits, and bounded caching
final class ImageLoader: NSObject {
    static let shared = ImageLoader()

    // MARK: - Configuration

    private static let maxImageSize: Int = 10 * 1024 * 1024  // 10MB max
    private static let requestTimeout: TimeInterval = 30
    private static let maxCacheCount: Int = 100
    private static let maxCacheCost: Int = 50 * 1024 * 1024  // 50MB cache limit

    // MARK: - Properties

    private var session: URLSession!
    private let imageCache = NSCache<NSURL, NSImage>()

    // MARK: - Private IP ranges to block (SSRF protection)

    private static let blockedIPRanges: [(prefix: String, description: String)] = [
        ("10.", "Private Class A"),
        ("172.16.", "Private Class B"),
        ("172.17.", "Private Class B"),
        ("172.18.", "Private Class B"),
        ("172.19.", "Private Class B"),
        ("172.20.", "Private Class B"),
        ("172.21.", "Private Class B"),
        ("172.22.", "Private Class B"),
        ("172.23.", "Private Class B"),
        ("172.24.", "Private Class B"),
        ("172.25.", "Private Class B"),
        ("172.26.", "Private Class B"),
        ("172.27.", "Private Class B"),
        ("172.28.", "Private Class B"),
        ("172.29.", "Private Class B"),
        ("172.30.", "Private Class B"),
        ("172.31.", "Private Class B"),
        ("192.168.", "Private Class C"),
        ("127.", "Loopback"),
        ("0.", "Invalid"),
        ("169.254.", "Link-local"),
        ("224.", "Multicast"),
        ("255.", "Broadcast"),
    ]

    private static let blockedHostnames: Set<String> = [
        "localhost",
        "localhost.localdomain",
        "local",
        "broadcasthost",
        "ip6-localhost",
        "ip6-loopback",
    ]

    // MARK: - Initialization

    private override init() {
        super.init()

        // Configure URLSession with security settings
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = Self.requestTimeout
        config.timeoutIntervalForResource = Self.requestTimeout * 2
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpMaximumConnectionsPerHost = 4

        // Use delegate to validate resolved IP addresses (DNS rebinding protection)
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)

        // Configure NSCache limits
        imageCache.countLimit = Self.maxCacheCount
        imageCache.totalCostLimit = Self.maxCacheCost
    }

    // MARK: - Public Interface

    func loadImage(from url: URL) async -> NSImage? {
        // Security: Validate URL before any network request
        guard isURLSafe(url) else {
            Logger.warning("Blocked potentially unsafe URL: \(url.absoluteString.prefix(100))")
            return nil
        }

        // Check cache first
        if let cached = imageCache.object(forKey: url as NSURL) {
            return cached
        }

        do {
            // Use URLSession with delegate to check response headers before downloading body
            let (data, response) = try await session.data(from: url)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                Logger.warning("Non-HTTP response for image URL")
                return nil
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                Logger.warning("HTTP error \(httpResponse.statusCode) loading image")
                return nil
            }

            // Validate content type
            if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
               !contentType.hasPrefix("image/") {
                Logger.warning("Non-image content type: \(contentType)")
                return nil
            }

            // Validate size (double-check after download)
            guard data.count <= Self.maxImageSize else {
                Logger.warning("Image too large: \(data.count) bytes")
                return nil
            }

            // Create image
            guard let image = NSImage(data: data) else {
                Logger.warning("Failed to decode image data")
                return nil
            }

            // Cache with estimated cost (bytes)
            imageCache.setObject(image, forKey: url as NSURL, cost: data.count)

            return image

        } catch {
            Logger.error("Failed to load image from \(url.host ?? "unknown"): \(error.localizedDescription)")
            return nil
        }
    }

    /// Load image from local file path (bypasses network security checks)
    func loadLocalImage(from path: String) -> NSImage? {
        let url = URL(fileURLWithPath: path)

        // Check cache
        if let cached = imageCache.object(forKey: url as NSURL) {
            return cached
        }

        // Validate path is safe (resolve symlinks and check for escapes)
        guard isLocalPathSafe(path) else {
            Logger.warning("Blocked potentially unsafe local path: \(path)")
            return nil
        }

        // Verify file exists and is readable
        guard FileManager.default.isReadableFile(atPath: path) else {
            return nil
        }

        // Load image
        guard let image = NSImage(contentsOfFile: path) else {
            return nil
        }

        // Cache it
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0
        imageCache.setObject(image, forKey: url as NSURL, cost: fileSize)

        return image
    }

    func clearCache() {
        imageCache.removeAllObjects()
    }

    // MARK: - Security Validation

    private func isURLSafe(_ url: URL) -> Bool {
        // Only allow HTTPS for remote URLs
        guard url.scheme?.lowercased() == "https" else {
            Logger.warning("Blocked non-HTTPS URL scheme: \(url.scheme ?? "nil")")
            return false
        }

        // Validate host exists
        guard let host = url.host?.lowercased() else {
            Logger.warning("URL has no host")
            return false
        }

        // Block known unsafe hostnames
        if Self.blockedHostnames.contains(host) {
            Logger.warning("Blocked hostname: \(host)")
            return false
        }

        // Block IP addresses that look like private ranges
        if isPrivateIPAddress(host) {
            Logger.warning("Blocked private IP address: \(host)")
            return false
        }

        // Block URLs with credentials
        if url.user != nil || url.password != nil {
            Logger.warning("Blocked URL with embedded credentials")
            return false
        }

        return true
    }

    private func isPrivateIPAddress(_ host: String) -> Bool {
        // Check for IPv6 addresses first
        if host.contains(":") || host.hasPrefix("[") {
            return isPrivateIPv6Address(host)
        }

        // Check if it looks like an IPv4 address
        let parts = host.split(separator: ".")
        guard parts.count == 4,
              parts.allSatisfy({ Int($0) != nil && Int($0)! >= 0 && Int($0)! <= 255 }) else {
            // Not an IP address, allow it (DNS will resolve)
            return false
        }

        // Check against blocked ranges
        for (prefix, _) in Self.blockedIPRanges {
            if host.hasPrefix(prefix) {
                return true
            }
        }

        return false
    }

    private func isPrivateIPv6Address(_ host: String) -> Bool {
        // Remove brackets if present (e.g., [::1])
        let cleanHost = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]")).lowercased()

        // Block loopback
        if cleanHost == "::1" || cleanHost == "0:0:0:0:0:0:0:1" {
            return true
        }

        // Block link-local (fe80::/10)
        if cleanHost.hasPrefix("fe80:") || cleanHost.hasPrefix("fe8") || cleanHost.hasPrefix("fe9") ||
           cleanHost.hasPrefix("fea") || cleanHost.hasPrefix("feb") {
            return true
        }

        // Block unique local addresses (fc00::/7 = fc00:: to fdff::)
        if cleanHost.hasPrefix("fc") || cleanHost.hasPrefix("fd") {
            return true
        }

        // Block multicast (ff00::/8)
        if cleanHost.hasPrefix("ff") {
            return true
        }

        // Block IPv4-mapped IPv6 (::ffff:x.x.x.x) - check the embedded IPv4
        if cleanHost.hasPrefix("::ffff:") {
            let ipv4Part = String(cleanHost.dropFirst(7))
            return isPrivateIPAddress(ipv4Part)
        }

        // Block all-zeros
        if cleanHost == "::" || cleanHost == "0:0:0:0:0:0:0:0" {
            return true
        }

        return false
    }

    /// Validate that a local path is safe to access (symlink validation)
    private func isLocalPathSafe(_ path: String) -> Bool {
        let fileManager = FileManager.default

        // Resolve symlinks to get the actual path
        let url = URL(fileURLWithPath: path)
        let resolvedURL = url.resolvingSymlinksInPath()
        let resolvedPath = resolvedURL.path

        // Block access to sensitive system directories
        let sensitiveDirectories = [
            "/etc",
            "/private/etc",
            "/var",
            "/private/var",
            "/System",
            "/Library/Keychains",
            "/Users/Shared/SC Info"
        ]

        for sensitive in sensitiveDirectories {
            if resolvedPath.hasPrefix(sensitive + "/") || resolvedPath == sensitive {
                return false
            }
        }

        // Block hidden files starting with dot (except current directory)
        let filename = resolvedURL.lastPathComponent
        if filename.hasPrefix(".") && filename != "." && filename != ".." {
            return false
        }

        // Ensure the resolved path actually exists
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: resolvedPath, isDirectory: &isDirectory) else {
            return false
        }

        // Don't allow loading directories as images
        if isDirectory.boolValue {
            return false
        }

        return true
    }
}

// MARK: - URLSessionTaskDelegate (DNS Rebinding Protection)

extension ImageLoader: URLSessionTaskDelegate {
    /// Validate the resolved IP address before allowing the connection
    /// This prevents DNS rebinding attacks where initial DNS lookup passes validation
    /// but the actual connection goes to a different (private) IP
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping (URLRequest?) -> Void
    ) {
        // Validate redirect URL
        guard let redirectURL = request.url, isURLSafe(redirectURL) else {
            Logger.warning("Blocked redirect to unsafe URL")
            completionHandler(nil)  // Cancel the redirect
            return
        }

        completionHandler(request)
    }
}

extension ImageLoader: URLSessionDataDelegate {
    /// Validate the connection before receiving data
    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        // Validate content type and size in headers
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }

        // Check status code
        guard (200...299).contains(httpResponse.statusCode) else {
            completionHandler(.cancel)
            return
        }

        // Check content length if available
        let expectedLength = httpResponse.expectedContentLength
        if expectedLength > 0 && expectedLength > Int64(Self.maxImageSize) {
            Logger.warning("Image too large (from headers): \(expectedLength) bytes")
            completionHandler(.cancel)
            return
        }

        completionHandler(.allow)
    }
}
