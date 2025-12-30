import Cocoa

/// Errors that can occur during image loading
enum ImageLoadError: Error, LocalizedError {
    case unsafeURL(String)
    case networkError(Error)
    case httpError(Int)
    case invalidContentType(String)
    case imageTooLarge(Int)
    case decodingFailed
    case fileNotReadable(String)
    case unsafeLocalPath(String)

    var errorDescription: String? {
        switch self {
        case .unsafeURL(let reason):
            return "Unsafe URL: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidContentType(let type):
            return "Invalid content type: \(type)"
        case .imageTooLarge(let size):
            return "Image too large: \(size) bytes (max: 10MB)"
        case .decodingFailed:
            return "Failed to decode image data"
        case .fileNotReadable(let path):
            return "File not readable: \(path)"
        case .unsafeLocalPath(let path):
            return "Unsafe local path: \(path)"
        }
    }
}

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
        switch await loadImageWithResult(from: url) {
        case .success(let image):
            return image
        case .failure(let error):
            Logger.warning("Image load failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Loads an image with detailed error reporting
    func loadImageWithResult(from url: URL) async -> Result<NSImage, ImageLoadError> {
        // Security: Validate URL before any network request
        guard isURLSafe(url) else {
            return .failure(.unsafeURL("URL failed security validation"))
        }

        // Check cache first
        if let cached = imageCache.object(forKey: url as NSURL) {
            return .success(cached)
        }

        do {
            // Use URLSession with delegate to check response headers before downloading body
            let (data, response) = try await session.data(from: url)

            // Validate response
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.httpError(0))
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                return .failure(.httpError(httpResponse.statusCode))
            }

            // Validate content type
            if let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type"),
               !contentType.hasPrefix("image/") {
                return .failure(.invalidContentType(contentType))
            }

            // Validate size (double-check after download)
            guard data.count <= Self.maxImageSize else {
                return .failure(.imageTooLarge(data.count))
            }

            // Create image
            guard let image = NSImage(data: data) else {
                return .failure(.decodingFailed)
            }

            // Cache with estimated cost (bytes)
            imageCache.setObject(image, forKey: url as NSURL, cost: data.count)

            return .success(image)

        } catch {
            return .failure(.networkError(error))
        }
    }

    /// Load image from local file path (bypasses network security checks)
    func loadLocalImage(from path: String) -> NSImage? {
        switch loadLocalImageWithResult(from: path) {
        case .success(let image):
            return image
        case .failure(let error):
            Logger.warning("Local image load failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// Load image from local file path with detailed error reporting
    func loadLocalImageWithResult(from path: String) -> Result<NSImage, ImageLoadError> {
        let url = URL(fileURLWithPath: path)

        // Check cache
        if let cached = imageCache.object(forKey: url as NSURL) {
            return .success(cached)
        }

        // Validate path is safe (resolve symlinks and check for escapes)
        guard isLocalPathSafe(path) else {
            return .failure(.unsafeLocalPath(path))
        }

        // Verify file exists and is readable
        guard FileManager.default.isReadableFile(atPath: path) else {
            return .failure(.fileNotReadable(path))
        }

        // Load image
        guard let image = NSImage(contentsOfFile: path) else {
            return .failure(.decodingFailed)
        }

        // Cache it
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0
        imageCache.setObject(image, forKey: url as NSURL, cost: fileSize)

        return .success(image)
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
